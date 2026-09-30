import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/services/api_client.dart';
import 'package:infrast/core/services/storage_service.dart';

/// Service autentikasi yang terhubung ke backend **Laravel** via REST API.
///
/// Semua endpoint menggunakan [ApiClient] yang secara otomatis:
/// - Menyertakan header JSON
/// - Menyertakan header Authorization Bearer (jika diperlukan)
///
/// Token disimpan secara lokal menggunakan [StorageService] (SharedPreferences).
///
/// ## Alur Login
/// ```
/// Flutter → POST /api/login → Laravel Sanctum → token → SharedPreferences
/// ```
///
/// ## Alur Request Terproteksi
/// ```
/// Flutter → GET /api/user + header "Authorization: Bearer <token>" → Laravel
/// ```
class AuthService {
  AuthService._(); // prevent instantiation

  // ─── Session ────────────────────────────────────────────────────────────────

  /// Periksa apakah user sudah login (ada token tersimpan secara lokal).
  /// Bersifat **async** karena membaca SharedPreferences.
  static Future<bool> get isLoggedIn => StorageService.hasToken();

  /// Ambil token yang tersimpan. Gunakan ini untuk request ke API terproteksi.
  static Future<String?> getToken() => StorageService.getToken();

  /// Ambil data user yang tersimpan secara lokal.
  static Future<Map<String, dynamic>?> getUser() => StorageService.getUser();

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Login menggunakan email dan password khusus akun **Masyarakat**.
  ///
  /// Mengirimkan parameter `client_role: 'masyarakat'` ke server.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await ApiClient.post(
      '/login',
      body: {
        'email': email,
        'password': password,
        'client_role': 'masyarakat',
      },
      requiresAuth: false,
    );

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final role = data['role'] ?? 'masyarakat';

      // Pastikan role memang masyarakat
      if (role != 'masyarakat') {
        return {
          'success': false,
          'role_mismatch': true,
          'user_role': role,
          'message': 'Akun Anda terdaftar sebagai $role. Aplikasi ini khusus untuk Warga Masyarakat.',
        };
      }

      // Simpan token & data user ke SharedPreferences
      await StorageService.saveToken(data['access_token'] as String);
      if (data['user'] != null) {
        final user = Map<String, dynamic>.from(data['user'] as Map);
        user['role'] = role;
        if (data['role_data'] != null) {
          user['role_data'] = data['role_data'];
        }
        await StorageService.saveUser(user);
      }

      return {'success': true, 'message': 'Berhasil masuk'};
    }

    return {
      'success':        false,
      'message':        response['message'] ?? 'Gagal masuk. Periksa email dan kata sandi Anda.',
      'role_mismatch':  response['role_mismatch'] == true,
      'user_role':      response['user_role'],
      'expected_role':  response['expected_role'],
      'isNetworkError': response['isNetworkError'] == true,
      'statusCode':     response['statusCode'],
      'url':            response['url'],
    };
  }

  /// Cek kesehatan / status koneksi server Laravel.
  static Future<Map<String, dynamic>> checkHealth([String? customUrl]) async {
    final targetUrl = customUrl != null
        ? ApiConstants.endpoint('/health', customUrl)
        : '/health';
    return await ApiClient.get(targetUrl, requiresAuth: false);
  }

  // ─── Register ──────────────────────────────────────────────────────────────

  /// Mendaftarkan user baru sebagai **Masyarakat**.
  ///
  /// Mengembalikan `{'success': bool, 'message': String, 'autoLogin': bool}`.
  /// Laravel selalu mengembalikan token saat register berhasil, jadi `autoLogin`
  /// selalu `true` (tidak perlu verifikasi email seperti Supabase).
  ///
  /// Endpoint: `POST /api/register`
  /// Body: `{ name, email, password, no_hp }`
  /// Response sukses: `{ message, access_token, token_type, user, role }`
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.register,
      body: {
        'name':     name,
        'email':    email,
        'password': password,
        'no_hp':    phone,
      },
      requiresAuth: false, // Belum ada token saat register
    );

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;

      // Simpan token & data user ke SharedPreferences
      await StorageService.saveToken(data['access_token'] as String);
      if (data['user'] != null) {
        final user = Map<String, dynamic>.from(data['user'] as Map);
        user['role'] = data['role'] ?? 'masyarakat';
        await StorageService.saveUser(user);
      }

      return {
        'success':   true,
        'message':   'Pendaftaran berhasil!',
        'autoLogin': true, // Laravel selalu langsung login setelah register
      };
    }

    return {
      'success':   false,
      'message':   response['message'] ?? 'Pendaftaran gagal. Silakan coba lagi.',
      'autoLogin': false,
    };
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  /// Logout: batalkan token di server (Laravel) lalu hapus data lokal.
  ///
  /// Endpoint: `POST /api/logout`
  /// Header: `Authorization: Bearer <token>`
  static Future<void> logout() async {
    // Coba revoke token di server (abaikan error jaringan)
    try {
      await ApiClient.post(ApiConstants.logout, requiresAuth: true);
    } catch (_) {
      // Tetap lanjutkan hapus data lokal meski request gagal
    }

    // Hapus token & data user dari SharedPreferences
    await StorageService.clearAll();
  }

  // ─── Get Profile ───────────────────────────────────────────────────────────

  /// Ambil data profil user dari server (data terkini).
  ///
  /// Endpoint: `GET /api/user`
  /// Header: `Authorization: Bearer <token>`
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final response = await ApiClient.get(ApiConstants.me);
    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      return data['user'] as Map<String, dynamic>?;
    }
    return null;
  }
}
