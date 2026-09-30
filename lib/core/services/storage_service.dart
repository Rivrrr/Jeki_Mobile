import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan dan mengambil data autentikasi secara lokal
/// menggunakan [SharedPreferences].
///
/// Data yang disimpan:
/// - [_keyToken]    : Bearer token dari Laravel Sanctum
/// - [_keyUserData] : Data user dalam format JSON string
class StorageService {
  StorageService._(); // prevent instantiation

  static const String _keyToken    = 'auth_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBaseUrl  = 'custom_base_url';

  // ─── Base URL ──────────────────────────────────────────────────────────────

  /// Simpan custom base URL ke SharedPreferences.
  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }

  /// Ambil custom base URL. Mengembalikan `null` jika belum ada pengaturan kustom.
  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl);
  }

  /// Hapus kustomisasi base URL dan kembali ke bawaan sistem.
  static Future<void> clearBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
  }

  // ─── Token ─────────────────────────────────────────────────────────────────

  /// Simpan token Sanctum ke SharedPreferences.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  /// Ambil token yang tersimpan. Mengembalikan `null` jika belum login.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Periksa apakah token tersedia (user sudah login).
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── User Data ─────────────────────────────────────────────────────────────

  /// Simpan data user sebagai JSON.
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(user));
  }

  /// Ambil data user. Mengembalikan `null` jika belum tersimpan.
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserData);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ─── Clear ─────────────────────────────────────────────────────────────────

  /// Hapus semua data sesi (token + user). Dipanggil saat logout.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }
}
