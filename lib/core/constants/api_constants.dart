import 'dart:async';
import 'dart:io' show Platform, NetworkInterface, InternetAddressType;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:infrast/core/services/storage_service.dart';

/// Konstanta URL untuk koneksi ke backend Laravel dengan Deteksi Otomatis
/// (Desktop, Android Emulator, dan Device Fisik via Wi-Fi/USB).
class ApiConstants {
  ApiConstants._();

  static String? _cachedWorkingUrl;
  static Completer<String>? _ongoingDiscovery;

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Default IP komputer pengembang saat terhubung ke Wi-Fi lokal
  static const String _pcLocalWifiIp = '192.168.1.22';
  static const String _pcOldWifiIp = '192.168.1.13';

  /// Daftar kandidat URL statis berdasarkan platform saat ini
  static List<String> get candidateUrls {
    final env = _sanitizeBaseUrl(_envBaseUrl);

    // 1. Web & Desktop (Windows, macOS, Linux): berjalan di mesin yang sama dengan Laravel
    if (kIsWeb) {
      return _dedupe([
        if (env != null) env,
        'http://127.0.0.1:8000/api',
        'http://localhost:8000/api',
      ]);
    }

    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return _dedupe([
          if (env != null) env,
          'http://127.0.0.1:8000/api',
          'http://localhost:8000/api',
          'http://$_pcLocalWifiIp:8000/api',
        ]);
      }

      // 2. Android (Emulator maupun HP Fisik)
      if (Platform.isAndroid) {
        return _dedupe([
          if (env != null) env,
          'http://10.0.2.2:8000/api',          // Prioritas 1 untuk Android Emulator
          'http://$_pcLocalWifiIp:8000/api',   // Prioritas 1 untuk HP Fisik via Wi-Fi
          'http://127.0.0.1:8000/api',         // HP Fisik via USB (adb reverse tcp:8000 tcp:8000)
          'http://$_pcOldWifiIp:8000/api',     // Fallback IP lama jika DHCP berubah
          'http://localhost:8000/api',
        ]);
      }
    } catch (_) {}

    return _dedupe([
      if (env != null) env,
      'http://127.0.0.1:8000/api',
      'http://localhost:8000/api',
      'http://$_pcLocalWifiIp:8000/api',
      'http://10.0.2.2:8000/api',
    ]);
  }

  /// Default fallback URL
  static String get defaultBaseUrl => candidateUrls.first;

  /// Normalisasi string URL agar berakhiran `/api` tanpa trailing slash ganda
  static String? _sanitizeBaseUrl(String? raw) {
    if (raw == null) return null;
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    final noTrailingSlash = value.endsWith('/')
        ? value.substring(0, value.length - 1)
        : value;
    return noTrailingSlash.endsWith('/api')
        ? noTrailingSlash
        : '$noTrailingSlash/api';
  }

  static List<String> _dedupe(List<String> urls) {
    final seen = <String>{};
    final result = <String>[];
    for (final u in urls) {
      if (seen.add(u)) {
        result.add(u);
      }
    }
    return result;
  }

  /// Probe cepat ke endpoint /health atau /kecamatan untuk mengecek keterjangkauan host
  static Future<bool> _isReachable(String baseUrl, {int timeoutMs = 900}) async {
    final healthUri = Uri.parse(endpoint('/health', baseUrl));
    try {
      final res = await http.get(healthUri).timeout(Duration(milliseconds: timeoutMs));
      if (res.statusCode > 0 && res.statusCode < 500) {
        return true;
      }
    } catch (_) {
      // Jika /health gagal, coba sekali ke /kecamatan
      try {
        final secUri = Uri.parse(endpoint('/kecamatan', baseUrl));
        final res = await http.get(secUri).timeout(Duration(milliseconds: timeoutMs));
        if (res.statusCode > 0 && res.statusCode < 500) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Dapatkan kandidat dinamis dari subnet Wi-Fi perangkat (khusus Android HP fisik)
  static Future<List<String>> _getDynamicSubnetCandidates() async {
    if (kIsWeb) return const [];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final list = <String>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final parts = addr.address.split('.');
          if (parts.length == 4) {
            final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
            list.add('http://$subnet.22:8000/api');
            list.add('http://$subnet.13:8000/api');
            list.add('http://$subnet.1:8000/api');
          }
        }
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Probe kandidat secara PARALEL dan ambil kandidat pertama yang merespons
  static Future<String?> _findFirstWorkingUrl(List<String> candidates) {
    if (candidates.isEmpty) return Future.value(null);

    final completer = Completer<String?>();
    int pending = candidates.length;

    for (final url in candidates) {
      _isReachable(url).then((ok) {
        if (ok && !completer.isCompleted) {
          completer.complete(url);
        }
      }).catchError((_) {
        // Abaikan error per kandidat
      }).whenComplete(() {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  /// Base URL aktif dengan Auto-Discovery Cerdas:
  /// - Desktop/Web: langsung `127.0.0.1:8000/api` tanpa delay
  /// - Android Emulator: otomatis temukan `10.0.2.2:8000/api`
  /// - Device Fisik: otomatis temukan `192.168.1.22:8000/api` / Wi-Fi subnet
  /// - Sekali ditemukan, di-cache di memori agar request berikutnya instan (0 ms overhead)
  static Future<String> getActiveBaseUrl() async {
    // 1. Jika sudah ada di cache memori, gunakan langsung tanpa probe berulang
    if (_cachedWorkingUrl != null) {
      return _cachedWorkingUrl!;
    }

    // 2. Jika ada proses discovery yang sedang berjalan, tunggu hasilnya bersama
    if (_ongoingDiscovery != null) {
      return _ongoingDiscovery!.future;
    }

    final completer = Completer<String>();
    _ongoingDiscovery = completer;

    try {
      // 3. Periksa kustomisasi manual jika pernah disimpan user
      final savedUrl = _sanitizeBaseUrl(await StorageService.getBaseUrl());
      if (savedUrl != null) {
        final ok = await _isReachable(savedUrl, timeoutMs: 800);
        if (ok) {
          _cachedWorkingUrl = savedUrl;
          completer.complete(savedUrl);
          _ongoingDiscovery = null;
          return savedUrl;
        }
      }

      // 4. Kumpulkan seluruh kandidat (statis + dinamis)
      final staticCandidates = candidateUrls;
      final dynamicCandidates = await _getDynamicSubnetCandidates();
      final allCandidates = _dedupe([...staticCandidates, ...dynamicCandidates]);

      // 5. Uji semua kandidat secara paralel (respons tercepat langsung menang)
      final working = await _findFirstWorkingUrl(allCandidates);
      if (working != null) {
        _cachedWorkingUrl = working;
        // Simpan ke SharedPreferences agar boot berikutnya langsung cepat
        StorageService.saveBaseUrl(working).ignore();
        completer.complete(working);
        _ongoingDiscovery = null;
        return working;
      }

      // Fallback aman
      final fallback = defaultBaseUrl;
      _cachedWorkingUrl = fallback;
      completer.complete(fallback);
      _ongoingDiscovery = null;
      return fallback;
    } catch (_) {
      final fallback = defaultBaseUrl;
      _cachedWorkingUrl = fallback;
      completer.complete(fallback);
      _ongoingDiscovery = null;
      return fallback;
    }
  }

  /// Pemanasan awal saat aplikasi pertama kali dibuka (di Splash / Login initState)
  static void warmup() {
    getActiveBaseUrl().ignore();
  }

  /// Reset cache ketika jaringan berubah atau request mengalami connection error
  static void resetCache() {
    _cachedWorkingUrl = null;
  }

  /// Cek apakah base URL bisa dijangkau dari perangkat saat ini
  static Future<bool> canConnect([String? customBaseUrl]) async {
    final normalized = _sanitizeBaseUrl(customBaseUrl);
    if (normalized != null) {
      return _isReachable(normalized);
    }
    final active = await getActiveBaseUrl();
    return _isReachable(active);
  }

  // Fallback sinkron untuk kompatibilitas
  static String get baseUrl => _cachedWorkingUrl ?? defaultBaseUrl;

  // ─── Endpoints Helper ──────────────────────────────────────────────────────
  static String endpoint(String path, [String? base]) {
    final root = base ?? baseUrl;
    final cleanRoot = root.endsWith('/')
        ? root.substring(0, root.length - 1)
        : root;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanRoot$cleanPath';
  }

  static String get health => endpoint('/health');
  static String get login => endpoint('/login');
  static String get register => endpoint('/register');
  static String get logout => endpoint('/logout');
  static String get me => endpoint('/user');

  // ─── Timeout ───────────────────────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
