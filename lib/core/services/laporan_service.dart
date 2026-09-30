import 'package:infrast/core/services/api_client.dart';
import 'package:infrast/core/utils/foto_helper.dart';

/// Service untuk operasi laporan masyarakat:
/// - Fetch kategori & kecamatan dari API
/// - Buat laporan baru (dengan foto PhotoItem)
/// - Ambil daftar laporan milik user
class LaporanService {
  LaporanService._();

  /// Ambil daftar kategori dari backend.
  /// GET /api/kategori — boleh diakses tanpa login.
  static Future<Map<String, dynamic>> fetchKategori() async {
    return ApiClient.get('/kategori', requiresAuth: false);
  }

  /// Ambil daftar kecamatan dari backend.
  /// GET /api/kecamatan — boleh diakses tanpa login.
  static Future<Map<String, dynamic>> fetchKecamatan() async {
    return ApiClient.get('/kecamatan', requiresAuth: false);
  }

  /// Ambil daftar laporan milik masyarakat yang login.
  /// GET /api/laporan
  static Future<Map<String, dynamic>> fetchMyLaporan() async {
    return ApiClient.get('/laporan');
  }

  /// Ambil semua laporan (seluruh wilayah) untuk ditampilkan di peta.
  /// GET /api/laporan/peta
  static Future<Map<String, dynamic>> fetchAllLaporan() async {
    return ApiClient.get('/laporan/peta');
  }


  /// Ambil detail satu laporan.
  /// GET /api/laporan/{id}
  static Future<Map<String, dynamic>> fetchDetailLaporan(int id) async {
    return ApiClient.get('/laporan/$id');
  }

  /// Buat laporan baru dengan upload foto.
  /// POST /api/laporan (multipart/form-data berbasis bytes, kompatibel Web & Mobile)
  static Future<Map<String, dynamic>> createLaporan({
    required int kategoriId,
    required int kecamatanId,
    required String judul,
    String? deskripsi,
    String? lokasi,
    double? latitude,
    double? longitude,
    String? prioritas,
    List<PhotoItem> foto = const [],
  }) async {
    final fields = <String, String>{
      'kategori_id':  kategoriId.toString(),
      'kecamatan_id': kecamatanId.toString(),
      'judul':        judul,
      if (deskripsi != null && deskripsi.isNotEmpty) 'deskripsi': deskripsi,
      if (lokasi != null && lokasi.isNotEmpty) 'lokasi': lokasi,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (prioritas != null && prioritas.isNotEmpty) 'prioritas': prioritas,
    };

    final files = foto.map((item) {
      return (
        fieldName: 'foto[]',
        bytes:     item.bytes,
        fileName:  item.name,
      );
    }).toList();

    return ApiClient.postMultipart(
      '/laporan',
      fields: fields,
      files: files.isEmpty ? null : files,
    );
  }
}
