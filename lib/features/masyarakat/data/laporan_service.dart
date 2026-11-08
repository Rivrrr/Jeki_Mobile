import 'package:image_picker/image_picker.dart';
import 'package:infrast/core/services/api_client.dart';

/// Service untuk operasi laporan masyarakat via REST API.
class LaporanService {
  LaporanService._();

  // ─── Referensi ────────────────────────────────────────────────────────────

  /// Ambil daftar kategori laporan.
  static Future<Map<String, dynamic>> fetchKategori() =>
      ApiClient.get('/kategori', requiresAuth: false);

  /// Ambil daftar kecamatan.
  static Future<Map<String, dynamic>> fetchKecamatan() =>
      ApiClient.get('/kecamatan', requiresAuth: false);

  // ─── Laporan CRUD ─────────────────────────────────────────────────────────

  /// Ambil semua laporan milik user yang login.
  static Future<Map<String, dynamic>> fetchMyLaporan() =>
      ApiClient.get('/laporan');

  /// Ambil semua laporan berkoordinat untuk ditampilkan di peta.
  static Future<Map<String, dynamic>> fetchAllLaporan() =>
      ApiClient.get('/laporan/peta');

  /// Ambil detail satu laporan.
  static Future<Map<String, dynamic>> fetchLaporanDetail(int id) =>
      ApiClient.get('/laporan/$id');

  /// Buat laporan baru, opsional dengan foto.
  static Future<Map<String, dynamic>> createLaporan({
    required String judul,
    required int kategoriId,
    required int kecamatanId,
    String? deskripsi,
    String? lokasi,
    double? latitude,
    double? longitude,
    List<XFile>? foto,
  }) async {
    final fields = <String, String>{
      'judul': judul,
      'kategori_id': kategoriId.toString(),
      'kecamatan_id': kecamatanId.toString(),
      if (deskripsi != null && deskripsi.isNotEmpty) 'deskripsi': deskripsi,
      if (lokasi != null && lokasi.isNotEmpty) 'lokasi': lokasi,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
    };

    final files = foto != null
        ? await Future.wait(foto.asMap().entries.map((e) async => (
              fieldName: 'foto[]',
              bytes: await e.value.readAsBytes(),
              fileName: 'foto_${e.key + 1}.jpg',
            )))
        : null;

    return ApiClient.postMultipart('/laporan', fields: fields, files: files);
  }

  /// Konfirmasi penyelesaian pengerjaan oleh warga pelapor.
  static Future<Map<String, dynamic>> konfirmasiSelesai(int id, {String status = 'setuju', String? catatan}) =>
      ApiClient.post('/laporan/$id/konfirmasi-selesai', body: {
        'status_konfirmasi': status,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      });
}
