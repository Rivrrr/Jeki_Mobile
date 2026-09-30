import 'dart:math';
import 'package:flutter/services.dart';

/// Objek foto independen platform (mendukung Web, Android, iOS, Windows).
/// Menggunakan in-memory Uint8List bytes sehingga tidak bergantung pada direktori filesystem atau dart:io.
class PhotoItem {
  final String name;
  final Uint8List bytes;

  PhotoItem({
    required this.name,
    required this.bytes,
  });
}

/// Helper untuk simulasi dan pengelolaan foto bukti laporan & koordinat GPS.
/// Menghasilkan [PhotoItem] berbasis byte in-memory yang valid untuk Flutter Web maupun Mobile/Desktop,
/// serta menghasilkan koordinat GPS realistis di wilayah Kabupaten Jember.
class FotoHelper {
  FotoHelper._();

  static final Random _random = Random();

  // Daftar aset foto infrastruktur nyata
  static const List<String> _sampleAssets = [
    'assets/images/sample_jalan_rusak.jpg',
    'assets/images/sample_drainase_rusak.jpg',
    'assets/images/sample_lampu_jalan_rusak.jpg',
  ];

  static const List<String> _sampleLabels = [
    'Jalan Aspal Berlubang & Retak',
    'Saluran Drainase Tersumbat Sampah',
    'Tiang Lampu Jalan PJU Rusak/Miring',
  ];

  /// Mengambil data foto sampel secara acak atau berdasarkan indeks tertentu.
  /// Menghasilkan [PhotoItem] yang kompatibel 100% dengan Web dan Mobile tanpa error _Namespace.
  static Future<PhotoItem> getDevSamplePhoto({int? index}) async {
    final idx = (index != null && index >= 0) 
        ? index % _sampleAssets.length 
        : _random.nextInt(_sampleAssets.length);
    final assetPath = _sampleAssets[idx];
    final fileName = 'bukti_jeki_${DateTime.now().millisecondsSinceEpoch}_${idx + 1}.jpg';

    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      return PhotoItem(name: fileName, bytes: bytes);
    } catch (_) {
      // Fallback: minimal valid JPEG file (1x1 red dot JPEG)
      final fallbackBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
        0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
        0x00, 0xBF, 0x80, 0xFF, 0xD9
      ]);
      return PhotoItem(name: 'bukti_fallback.jpg', bytes: fallbackBytes);
    }
  }

  /// Menghasilkan koordinat GPS realistis di sekitar Kabupaten Jember.
  /// Titik pusat: Lat -8.1724, Lng 113.6980.
  static Map<String, dynamic> generateJemberCoordinate({String? kecamatanNama}) {
    // Offset acak sekitar +- 0.008 derajat (~ 800 meter)
    final latOffset = (_random.nextDouble() - 0.5) * 0.016;
    final lngOffset = (_random.nextDouble() - 0.5) * 0.016;

    final lat = -8.1724 + latOffset;
    final lng = 113.6980 + lngOffset;

    final formattedLat = double.parse(lat.toStringAsFixed(6));
    final formattedLng = double.parse(lng.toStringAsFixed(6));

    final kec = kecamatanNama != null && kecamatanNama.isNotEmpty
        ? kecamatanNama
        : 'Patrang';

    return {
      'latitude': formattedLat,
      'longitude': formattedLng,
      'label': 'Kec. $kec, Kab. Jember',
      'accuracy': '±${3 + _random.nextInt(4)}m',
    };
  }

  /// Mendapatkan label nama infrastruktur sampel berdasarkan indeks.
  static String getSampleLabel(int index) {
    return _sampleLabels[index % _sampleLabels.length];
  }
}
