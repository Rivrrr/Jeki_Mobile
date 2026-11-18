import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
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
    var response = await ApiClient.post(
      '/login',
      body: {'email': email.trim().toLowerCase(), 'password': password.trim()},
      requiresAuth: false,
    );

    if (response['isNetworkError'] == true) {
      ApiConstants.resetCache();
      response = await ApiClient.post(
        '/login',
        body: {
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
        },
        requiresAuth: false,
      );
    }

    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>;
      final role = (data['role'] ?? 'masyarakat') as String;

      // Hanya izinkan role masyarakat dan pelaksana di app mobile
      if (role != 'masyarakat' && role != 'pelaksana') {
        return {
          'success': false,
          'role_mismatch': true,
          'user_role': role,
          'message': 'Akun ini tidak dapat digunakan di aplikasi HP. Silakan masuk melalui situs resmi JEKI.',
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
      'success': false,
      'message':
          response['message'] ??
          'Gagal masuk. Periksa email dan kata sandi Anda.',
      'role_mismatch': response['role_mismatch'] == true,
      'user_role': response['user_role'],
      'expected_role': response['expected_role'],
      'isNetworkError': response['isNetworkError'] == true,
      'statusCode': response['statusCode'],
      'url': response['url'],
    };
  }

  /// Login masyarakat memakai akun Google (SSO).
  ///
  /// Alur:
  /// 1. Buka pemilih akun Google lewat `google_sign_in`.
  /// 2. Ambil `idToken` hasil login.
  /// 3. Kirim ke `POST /api/auth/google` di backend Laravel.
  /// 4. Simpan token & role seperti login biasa.
  ///
  /// Catatan konfigurasi: dibutuhkan OAuth Client ID Android di
  /// `android/app/google-services.json` / Google Cloud Console, dan
  /// `GOOGLE_CLIENT_ID` (tipe Web application) di `.env` backend agar
  /// klaim `aud` token dapat diverifikasi.
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);

      // Paksa pemilih akun agar pengguna bisa berganti akun.
      await googleSignIn.signOut();

      final account = await googleSignIn.signIn();
      if (account == null) {
        return {
          'success': false,
          'cancelled': true,
          'message': 'Login dibatalkan.',
        };
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        return {
          'success': false,
          'message':
              'Gagal memperoleh ID token dari Google. '
              'Periksa konfigurasi OAuth Client ID Android.',
        };
      }

      var response = await ApiClient.post(
        '/auth/google',
        body: {'id_token': idToken},
        requiresAuth: false,
      );

      if (response['isNetworkError'] == true) {
        ApiConstants.resetCache();
        response = await ApiClient.post(
          '/auth/google',
          body: {'id_token': idToken},
          requiresAuth: false,
        );
      }

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final role = (data['role'] ?? 'masyarakat') as String;

        if (role != 'masyarakat') {
          await googleSignIn.signOut();
          return {
            'success': false,
            'role_mismatch': true,
            'user_role': role,
            'message': 'Akun Google ini bukan akun masyarakat JEKI.',
          };
        }

        await StorageService.saveToken(data['access_token'] as String);
        await StorageService.saveRole(role);

        if (data['user'] != null) {
          final user = Map<String, dynamic>.from(data['user'] as Map);
          user['role'] = role;
          await StorageService.saveUser(user);
        }

        return {'success': true, 'role': role, 'message': 'Berhasil masuk'};
      }

      return {
        'success': false,
        'message':
            response['message'] ??
            'Gagal masuk dengan Google. Silakan coba lagi.',
        'isNetworkError': response['isNetworkError'] == true,
        'statusCode': response['statusCode'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login Google gagal: ${e.toString()}',
      };
    }
  }

  /// Cek kesehatan / status koneksi server Laravel.
  static Future<Map<String, dynamic>> checkHealth([String? customUrl]) async {
    final base = customUrl?.trim();
    final canConnect = await ApiConstants.canConnect(base);

    if (canConnect) {
      return {
        'success': true,
        'message': 'Server terjangkau dari perangkat ini.',
      };
    }

    final targetUrl = base != null && base.isNotEmpty
        ? ApiConstants.endpoint('/health', base)
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
    var response = await ApiClient.post(
      ApiConstants.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'no_hp': phone,
      },
      requiresAuth: false,
    );

    if (response['isNetworkError'] == true) {
      ApiConstants.resetCache();
      response = await ApiClient.post(
        ApiConstants.register,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'no_hp': phone,
        },
        requiresAuth: false,
      );
    }

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
        'success': true,
        'message': 'Pendaftaran berhasil!',
        'autoLogin': true, // Laravel selalu langsung login setelah register
      };
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Pendaftaran gagal. Silakan coba lagi.',
      'autoLogin': false,
      'isNetworkError': response['isNetworkError'] == true,
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
            // Angkat field profil masyarakat ke level atas supaya halaman
            // Profil bisa membacanya langsung (no_hp, foto_profil_url).
            final roleData = data['role_data'];
            if (roleData is Map) {
              for (final key in const [
                'no_hp',
                'alamat',
                'gender',
                'birth_date',
                'nik',
                'foto_profil',
                'foto_profil_url',
              ]) {
                if (roleData[key] != null) {
                  updatedUser[key] = roleData[key];
                }
              }
            }
          }

          await StorageService.saveUser(updatedUser);
          return updatedUser;
        }
      }
    } catch (_) {}
    return await StorageService.getUser();
  }

  /// Mengubah kata sandi user.
  /// Endpoint: `POST /api/change-password`
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await ApiClient.post(
      ApiConstants.changePassword,
      body: {'current_password': currentPassword, 'new_password': newPassword},
      requiresAuth: true,
    );

    if (response['success'] == true) {
      return {
        'success': true,
        'message': response['message'] ?? 'Kata sandi berhasil diperbarui',
      };
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Gagal mengubah kata sandi',
    };
  }

  /// Update profil ke server Laravel lalu sinkronkan ke lokal
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
    String? address,
    String? birthDate,
    String? gender,
  }) async {
    final response = await ApiClient.put(
      ApiConstants.me,
      body: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'no_hp': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (birthDate != null && birthDate.isNotEmpty) 'birth_date': birthDate,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
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

  /// Unggah foto profil masyarakat ke server.
  ///
  /// Endpoint: `POST /api/user/foto-profil` (multipart/form-data, field `foto`)
  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
    String fieldName = 'foto',
  }) async {
    final response = await ApiClient.postMultipart(
      ApiConstants.uploadFotoProfil,
      fields: const {},
      files: [(fieldName: fieldName, bytes: bytes, fileName: fileName)],
    );

    if (response['success'] == true) {
      await syncUser();
      return {
        'success': true,
        'message': response['message'] ?? 'Foto profil berhasil diperbarui',
      };
    }

    return {
      'success': false,
      'message': response['message'] ?? 'Gagal mengunggah foto profil',
    };
  }

  /// Hapus foto profil masyarakat (kembali ke avatar inisial).
  ///
  /// Endpoint: `DELETE /api/user/foto-profil`
  static Future<Map<String, dynamic>> deleteProfilePhoto() async {
    final response = await ApiClient.delete(ApiConstants.uploadFotoProfil);
    if (response['success'] == true) {
      await syncUser();
      return {
        'success': true,
        'message': response['message'] ?? 'Foto profil berhasil dihapus',
      };
    }
    return {
      'success': false,
      'message': response['message'] ?? 'Gagal menghapus foto profil',
    };
  }
}
