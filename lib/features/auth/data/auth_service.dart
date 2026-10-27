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
/// ## Alur Login (Multi-Role)
/// ```
/// Flutter → POST /api/login → Laravel Sanctum → token + role → SharedPreferences
///   role = 'masyarakat' → MainNavigation
///   role = 'pelaksana'  → PelaksanaHomePage
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

  /// Ambil role user yang tersimpan secara lokal.
  static Future<String?> getRole() => StorageService.getRole();

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Login multi-role: menerima akun **masyarakat** maupun **pelaksana**.
  ///
  /// Backend menentukan role yang valid. Hasilnya disimpan ke storage
  /// sehingga splash screen bisa melakukan routing yang benar.
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await ApiClient.post(
      '/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
      },
      requiresAuth: false,
    );

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final role = (data['role'] ?? 'masyarakat') as String;

      // Hanya izinkan role masyarakat dan pelaksana di app mobile
      if (role != 'masyarakat' && role != 'pelaksana') {
        return {
          'success': false,
          'role_mismatch': true,
          'user_role': role,
          'message': 'Akun Anda ($role) tidak dapat menggunakan aplikasi mobile JEKI. '
              'Akses Web Dashboard di browser: http://localhost:8000/login',
        };
      }

      // Simpan token, role, & data user ke SharedPreferences
      await StorageService.saveToken(data['access_token'] as String);
      await StorageService.saveRole(role);

      if (data['user'] != null) {
        final user = Map<String, dynamic>.from(data['user'] as Map);
        user['role'] = role;
        if (data['role_data'] != null) {
          user['role_data'] = data['role_data'];
        }
        await StorageService.saveUser(user);
      }

      return {'success': true, 'role': role, 'message': 'Berhasil masuk'};
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
      final role = (data['role'] ?? 'masyarakat') as String;

      // Simpan token, role & data user ke SharedPreferences
      await StorageService.saveToken(data['access_token'] as String);
      await StorageService.saveRole(role);
      if (data['user'] != null) {
        final user = Map<String, dynamic>.from(data['user'] as Map);
        user['role'] = role;
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

    // Hapus token, role & data user dari SharedPreferences
    await StorageService.clearAll();
  }

  // ─── Get Profile ───────────────────────────────────────────────────────────

  /// Ambil data profil user dari server (data terkini).
  ///
  /// Endpoint: `GET /api/user`
  /// Header: `Authorization: Bearer <token>`
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final response = await ApiClient.get(ApiConstants.me);
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      return data['user'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Sinkronisasi profil user dari server ke SharedPreferences.
  /// Memastikan data user (seperti nama yang diubah di database) selalu up-to-date.
  static Future<Map<String, dynamic>?> syncUser() async {
    try {
      final hasToken = await StorageService.hasToken();
      if (!hasToken) return null;

      final response = await ApiClient.get(ApiConstants.me);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final userData = data['user'];
        if (userData is Map) {
          final currentUser = await StorageService.getUser() ?? {};
          final updatedUser = Map<String, dynamic>.from(currentUser);

          updatedUser['id'] = userData['id'];
          updatedUser['name'] = userData['name'];
          updatedUser['email'] = userData['email'];
          if (data['role'] != null) {
            updatedUser['role'] = data['role'];
            await StorageService.saveRole(data['role'] as String);
          }
          if (data['role_data'] != null) {
            updatedUser['role_data'] = data['role_data'];
          }

          await StorageService.saveUser(updatedUser);
          return updatedUser;
        }
      }
    } catch (_) {}
    return await StorageService.getUser();
  }

  /// Update nama / profil ke server Laravel lalu sinkronkan ke lokal
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    final response = await ApiClient.put(
      ApiConstants.me,
      body: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'no_hp': phone,
      },
    );

    if (response['success'] == true) {
      final synced = await syncUser();
      return {
        'success': true,
        'message': response['message'] ?? 'Profil berhasil diperbarui',
        'user': synced,
      };
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Gagal memperbarui profil',
    };
  }
}
