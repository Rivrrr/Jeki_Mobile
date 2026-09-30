import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:infrast/core/services/storage_service.dart';

/// Konstanta URL untuk koneksi ke backend Laravel dengan deteksi otomatis.
class ApiConstants {
  ApiConstants._();

  static String? _cachedWorkingUrl;

  /// Daftar kandidat URL berdasarkan lingkungan perangkat
  static List<String> get candidateUrls {
    if (kIsWeb) {
      return const ['http://127.0.0.1:8000/api', 'http://localhost:8000/api'];
    }
    try {
      if (Platform.isAndroid) {
        return const [
          'http://10.0.2.2:8000/api',       // Android Emulator (utama di emulator)
          'http://192.168.1.13:8000/api',   // HP Fisik via Wi-Fi
          'http://127.0.0.1:8000/api',      // HP Fisik via USB adb reverse / Localhost
        ];
      }
    } catch (_) {}
    return const [
      'http://127.0.0.1:8000/api',
      'http://localhost:8000/api',
      'http://192.168.1.13:8000/api',
    ];
  }

  /// Default fallback URL
  static String get defaultBaseUrl => candidateUrls.first;

  /// Cari kandidat URL pertama yang merespons /health dalam waktu singkat (maks 1.5 detik)
  static Future<String> _findFirstWorkingUrl(List<String> candidates) {
    final completer = Completer<String>();
    int remaining = candidates.length;

    for (final url in candidates) {
      http.get(Uri.parse('$url/health'))
          .timeout(const Duration(milliseconds: 1500))
          .then((res) {
        if (!completer.isCompleted && res.statusCode >= 200 && res.statusCode < 400) {
          completer.complete(url);
        }
      }).catchError((_) {
        // Abaikan kegagalan individu
      }).whenComplete(() {
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(candidates.first);
        }
      });
    }

    return completer.future;
  }

  /// Base URL aktif dengan Auto-Discovery cerdas:
  /// 1. Mengutamakan custom URL jika pernah disimpan oleh user di modal pengaturan.
  /// 2. Menggunakan cache memori jika sudah pernah terdeteksi aktif.
  /// 3. Memeriksa kandidat URL (10.0.2.2, 192.168.1.13, 127.0.0.1) secara paralel.
  static Future<String> getActiveBaseUrl() async {
    final customUrl = await StorageService.getBaseUrl();
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      return customUrl.trim();
    }

    if (_cachedWorkingUrl != null) {
      return _cachedWorkingUrl!;
    }

    try {
      final working = await _findFirstWorkingUrl(candidateUrls);
      _cachedWorkingUrl = working;
      return working;
    } catch (_) {
      return defaultBaseUrl;
    }
  }

  /// Reset cache auto-discovery (misal ketika user mengganti jaringan)
  static void resetCache() {
    _cachedWorkingUrl = null;
  }

  // Fallback sinkron untuk kompatibilitas kode lama
  static String get baseUrl => defaultBaseUrl;

  // ─── Endpoints Helper ──────────────────────────────────────────────────────
  static String endpoint(String path, [String? base]) {
    final root = base ?? baseUrl;
    final cleanRoot = root.endsWith('/') ? root.substring(0, root.length - 1) : root;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanRoot$cleanPath';
  }

  static String get health   => endpoint('/health');
  static String get login    => endpoint('/login');
  static String get register => endpoint('/register');
  static String get logout   => endpoint('/logout');
  static String get me       => endpoint('/user');

  // ─── Timeout ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
