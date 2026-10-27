import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:infrast/core/services/api_client.dart';
import 'package:infrast/core/services/storage_service.dart';

/// Service untuk mengelola tugas pelaksana via REST API.
/// Di-adaptasi dari project pelaksana, menggunakan ApiClient infrast
/// sehingga berbagi pengaturan base URL yang sama.
class TugasService {

  // ─── Internal helpers ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> _get(String path) =>
      ApiClient.get(path);

  static Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) =>
      ApiClient.post(path, body: body ?? {});

  static Future<String> _getBaseUrl() async {
    final custom = await StorageService.getBaseUrl();
    if (custom != null && custom.isNotEmpty) return custom;
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
    } catch (_) {}
    return 'http://127.0.0.1:8000/api';
  }

  static Map<String, dynamic> _parseRaw(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      return {
        'success':    ok,
        'statusCode': res.statusCode,
        'data':       ok ? body : null,
        'message':    body['message'] ?? (ok ? 'Berhasil' : 'Terjadi kesalahan.'),
      };
    } catch (_) {
      return {
        'success':    false,
        'statusCode': res.statusCode,
        'message':    'Format respons tidak valid (${res.statusCode}).',
      };
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Ambil daftar semua tugas milik pelaksana yang login.
  static Future<Map<String, dynamic>> fetchTugas() =>
      _get('/pelaksana/tugas');

  /// Ambil detail satu tugas.
  static Future<Map<String, dynamic>> fetchTugasDetail(int id) =>
      _get('/pelaksana/tugas/$id');

  /// Ambil statistik tugas.
  static Future<Map<String, dynamic>> fetchStats() =>
      _get('/pelaksana/stats');

  /// Mulai mengerjakan tugas (status: ditugaskan → dikerjakan).
  static Future<Map<String, dynamic>> mulaiTugas(int id) =>
      _post('/pelaksana/tugas/$id/mulai');

  /// Kirim hasil tinjauan lapangan.
  static Future<Map<String, dynamic>> kirimTinjauan({
    required int tugasId,
    required String catatan,
    String? bahanKebutuhan,
    double? estimasiBiaya,
    String? estimasiWaktu,
  }) =>
      _post('/pelaksana/tugas/$tugasId/kirim-tinjauan', {
        'catatan_tinjauan': catatan,
        if (bahanKebutuhan != null && bahanKebutuhan.isNotEmpty)
          'bahan_kebutuhan': bahanKebutuhan,
        if (estimasiBiaya != null) 'estimasi_biaya': estimasiBiaya,
        if (estimasiWaktu != null && estimasiWaktu.isNotEmpty)
          'estimasi_waktu': estimasiWaktu,
      });

  /// Perbarui progress tugas dengan foto opsional.
  static Future<Map<String, dynamic>> updateProgress(
    int id,
    int persentase,
    String? catatan, {
    dynamic foto, // File?
  }) async {
    if (foto == null) {
      return _post('/pelaksana/tugas/$id/progress', {
        'persentase': persentase,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      });
    }

    final baseUrl = await _getBaseUrl();
    final url = '$baseUrl/pelaksana/tugas/$id/progress';
    try {
      final token = await StorageService.getToken();
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.fields['persentase'] = persentase.toString();
      if (catatan != null && catatan.isNotEmpty) req.fields['catatan'] = catatan;
      final file = foto as dynamic;
      req.files.add(await http.MultipartFile.fromPath('foto', file.path as String));
      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamed);
      return _parseRaw(res);
    } catch (e) {
      return {
        'success': false,
        'isNetworkError': true,
        'message': 'Gagal mengirim progress: ${e.toString()}',
      };
    }
  }

  /// Selesaikan tugas dengan catatan, foto bukti, dan koordinat GPS.
  static Future<Map<String, dynamic>> selesaikanTugas(
    int id, {
    required String catatan,
    Uint8List? fotoBytes,
    String? fotoName,
    double? latitude,
    double? longitude,
  }) async {
    final baseUrl = await _getBaseUrl();
    final url = '$baseUrl/pelaksana/tugas/$id/selesai';
    try {
      final token = await StorageService.getToken();
      final req = http.MultipartRequest('POST', Uri.parse(url));
      req.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.fields['catatan_selesai'] = catatan;
      if (latitude != null) req.fields['latitude'] = latitude.toString();
      if (longitude != null) req.fields['longitude'] = longitude.toString();
      if (fotoBytes != null && fotoBytes.isNotEmpty) {
        req.files.add(http.MultipartFile.fromBytes(
          'foto',
          fotoBytes,
          filename: fotoName ?? 'bukti_selesai_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return _parseRaw(res);
    } catch (e) {
      return {
        'success': false,
        'isNetworkError': true,
        'message': 'Gagal mengirim laporan selesai: ${e.toString()}',
      };
    }
  }

  /// Ambil notifikasi pelaksana.
  static Future<Map<String, dynamic>> fetchNotifikasi() =>
      _get('/notifikasi');
}
