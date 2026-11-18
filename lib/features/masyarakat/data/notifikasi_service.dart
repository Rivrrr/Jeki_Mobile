import 'package:infrast/core/services/api_client.dart';

/// Service untuk mengambil dan menandai notifikasi milik user yang login.
///
/// Notifikasi disimpan di backend (tabel `notifikasi`) setiap kali status
/// laporan berubah, sehingga riwayat tetap ada walaupun push FCM terlewat
/// atau perangkat sedang offline.
class NotifikasiService {
  NotifikasiService._();

  /// Ambil 50 notifikasi terbaru milik user.
  static Future<Map<String, dynamic>> fetchAll() =>
      ApiClient.get('/notifikasi');

  /// Tandai satu notifikasi sebagai sudah dibaca.
  static Future<Map<String, dynamic>> markAsRead(int id) =>
      ApiClient.post('/notifikasi/$id/baca');

  /// Tandai semua notifikasi sebagai sudah dibaca.
  static Future<Map<String, dynamic>> markAllRead() =>
      ApiClient.post('/notifikasi/baca-semua');
}
