import 'package:shared_preferences/shared_preferences.dart';

/// Service penyimpanan preferensi notifikasi di perangkat (lokal).
///
/// Preferensi ini bersifat perangkat, bukan per akun, sehingga disimpan di
/// [SharedPreferences] dan tidak dikirim ke backend.
///
/// Data yang disimpan:
/// - [_keyEnabled]       : master switch notifikasi push
/// - [_keySound]         : bunyi notifikasi
/// - [_keyVibration]     : getaran
/// - [_keyLaporanUpdate] : notifikasi status laporan
/// - [_keyPengumuman]    : notifikasi pengumuman / info layanan
class NotificationSettingsService {
  NotificationSettingsService._();

  static const String _keyEnabled       = 'notif_enabled';
  static const String _keySound         = 'notif_sound';
  static const String _keyVibration     = 'notif_vibration';
  static const String _keyLaporanUpdate = 'notif_laporan_update';
  static const String _keyPengumuman    = 'notif_pengumuman';

  /// Nama key publik agar halaman pengaturan bisa memetakan nilai dari [getAll].
  static const String keyEnabled = _keyEnabled;
  static const String keySound = _keySound;
  static const String keyVibration = _keyVibration;
  static const String keyLaporanUpdate = _keyLaporanUpdate;
  static const String keyPengumuman = _keyPengumuman;

  /// Nilai bawaan sebelum pengguna pernah membuka halaman pengaturan.
  static const Map<String, bool> defaults = {
    _keyEnabled: true,
    _keySound: true,
    _keyVibration: true,
    _keyLaporanUpdate: true,
    _keyPengumuman: true,
  };

  static Future<bool> getEnabled() async => _read(_keyEnabled);

  static Future<void> setEnabled(bool value) async => _write(_keyEnabled, value);

  static Future<bool> getSound() async => _read(_keySound);

  static Future<void> setSound(bool value) async => _write(_keySound, value);

  static Future<bool> getVibration() async => _read(_keyVibration);

  static Future<void> setVibration(bool value) async => _write(_keyVibration, value);

  static Future<bool> getLaporanUpdate() async => _read(_keyLaporanUpdate);

  static Future<void> setLaporanUpdate(bool value) async => _write(_keyLaporanUpdate, value);

  static Future<bool> getPengumuman() async => _read(_keyPengumuman);

  static Future<void> setPengumuman(bool value) async => _write(_keyPengumuman, value);

  /// Ambil seluruh preferensi sekaligus (dipakai saat memuat halaman).
  static Future<Map<String, bool>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in defaults.keys)
        key: prefs.getBool(key) ?? defaults[key]!,
    };
  }

  static Future<bool> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaults[key]!;
  }

  static Future<void> _write(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
