import 'dart:async';
import 'dart:io' show Platform, NetworkInterface, InternetAddressType;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:infrast/core/services/storage_service.dart';

enum ApiRuntime { desktop, emulator, physical }

/// URL backend Laravel dengan deteksi otomatis:
/// laptop/desktop, Android/iOS emulator, dan HP fisik.
class ApiConstants {
  ApiConstants._();

  static const int _apiPort = 8000;
  static const String _apiPath = '/api';

  static String? _cachedWorkingUrl;
  static Completer<String>? _ongoingDiscovery;
  static ApiRuntime? _runtimeCache;

  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String userNetworkTitle = 'Tidak Dapat Terhubung';
  static const String userNetworkMessage =
      'Layanan JEKI sedang tidak bisa dijangkau. Periksa koneksi internet Anda, lalu coba masuk kembali.';
  static const List<String> userNetworkSteps = [
    'Pastikan HP atau perangkat Anda terhubung ke internet.',
    'Jika memakai Wi-Fi, pastikan sinyalnya stabil.',
    'Tunggu beberapa saat, lalu tekan Masuk lagi.',
  ];

  static Future<ApiRuntime> detectRuntime() async {
    if (_runtimeCache != null) return _runtimeCache!;

    if (kIsWeb) {
      _runtimeCache = ApiRuntime.desktop;
      return _runtimeCache!;
    }

    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        _runtimeCache = ApiRuntime.desktop;
        return _runtimeCache!;
      }

      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _runtimeCache =
            info.isPhysicalDevice ? ApiRuntime.physical : ApiRuntime.emulator;
        return _runtimeCache!;
      }
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _runtimeCache =
            info.isPhysicalDevice ? ApiRuntime.physical : ApiRuntime.emulator;
        return _runtimeCache!;
      }
    } catch (_) {}

    _runtimeCache = ApiRuntime.desktop;
    return _runtimeCache!;
  }

  static String _urlForHost(String host) => 'http://$host:$_apiPort$_apiPath';

  static List<String> get candidateUrls {
    final env = _sanitizeBaseUrl(_envBaseUrl);
    if (kIsWeb) {
      return _dedupe([
        if (env != null) env,
        _urlForHost('127.0.0.1'),
        _urlForHost('localhost'),
      ]);
    }

    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return _dedupe([
          if (env != null) env,
          _urlForHost('127.0.0.1'),
          _urlForHost('localhost'),
        ]);
      }
    } catch (_) {}

    return _dedupe([
      if (env != null) env,
      _urlForHost('127.0.0.1'),
    ]);
  }

  static String get defaultBaseUrl => candidateUrls.first;

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
      if (seen.add(u)) result.add(u);
    }
    return result;
  }

  static bool _isEmulatorHost(String url) {
    return url.contains('10.0.2.2') || url.contains('10.0.3.2');
  }

  static bool _isLoopbackHost(String url) {
    return url.contains('127.0.0.1') || url.contains('localhost');
  }

  static bool _isCompatibleSavedUrl(String url, ApiRuntime runtime) {
    switch (runtime) {
      case ApiRuntime.desktop:
        return _isLoopbackHost(url) || !_isEmulatorHost(url);
      case ApiRuntime.emulator:
        return _isEmulatorHost(url) || _isLoopbackHost(url);
      case ApiRuntime.physical:
        return !_isEmulatorHost(url);
    }
  }

  static Future<bool> _isReachable(
    String baseUrl, {
    int timeoutMs = 1200,
  }) async {
    try {
      final healthUri = Uri.parse(endpoint('/health', baseUrl));
      final res = await http
          .get(healthUri)
          .timeout(Duration(milliseconds: timeoutMs));
      if (res.statusCode > 0 && res.statusCode < 500) return true;
    } catch (_) {
      try {
        final secUri = Uri.parse(endpoint('/kecamatan', baseUrl));
        final res = await http
            .get(secUri)
            .timeout(Duration(milliseconds: timeoutMs));
        if (res.statusCode > 0 && res.statusCode < 500) return true;
      } catch (_) {}
    }
    return false;
  }

  static bool _isPrivateLanIp(String ip) {
    if (ip.startsWith('192.168.')) return true;
    if (ip.startsWith('10.')) {
      if (ip.startsWith('10.0.2.') || ip.startsWith('10.0.3.')) return false;
      return true;
    }
    final parts = ip.split('.');
    if (parts.length == 4 && parts[0] == '172') {
      final second = int.tryParse(parts[1]) ?? 0;
      return second >= 16 && second <= 31;
    }
    return false;
  }

  /// Alamat IPv4 HP fisik di jaringan lokal (Wi-Fi / hotspot).
  static Future<List<String>> _localLanIpv4s() async {
    if (kIsWeb) return const [];
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      final list = <String>[];
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (_isPrivateLanIp(ip) && !list.contains(ip)) {
            list.add(ip);
          }
        }
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Cari laptop/server di subnet yang sama dengan HP.
  static Future<List<String>> _physicalDeviceCandidates() async {
    final env = _sanitizeBaseUrl(_envBaseUrl);
    final deviceIps = await _localLanIpv4s();
    final urls = <String>[
      if (env != null && _isCompatibleSavedUrl(env, ApiRuntime.physical)) env,
      // USB debugging: adb reverse tcp:8000 tcp:8000
      _urlForHost('127.0.0.1'),
    ];

    const priorityHosts = <int>[
      1, 2, 3, 10, 11, 12, 13, 14, 15, 20, 21, 22, 23, 24, 25, 50, 100, 101, 110, 111, 254,
    ];

    for (final deviceIp in deviceIps) {
      final parts = deviceIp.split('.');
      if (parts.length != 4) continue;
      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
      final ownOctet = int.tryParse(parts[3]) ?? -1;

      for (final host in priorityHosts) {
        if (host == ownOctet) continue;
        urls.add(_urlForHost('$subnet.$host'));
      }

      for (var host = 1; host <= 254; host++) {
        if (host == ownOctet || priorityHosts.contains(host)) continue;
        urls.add(_urlForHost('$subnet.$host'));
      }
    }

    return _dedupe(urls);
  }

  static Future<List<String>> _candidatesFor(ApiRuntime runtime) async {
    final env = _sanitizeBaseUrl(_envBaseUrl);
    switch (runtime) {
      case ApiRuntime.desktop:
        return _dedupe([
          if (env != null) env,
          _urlForHost('127.0.0.1'),
          _urlForHost('localhost'),
        ]);
      case ApiRuntime.emulator:
        return _dedupe([
          if (env != null && _isCompatibleSavedUrl(env, runtime)) env,
          _urlForHost('10.0.2.2'),
          _urlForHost('10.0.3.2'),
          _urlForHost('127.0.0.1'),
        ]);
      case ApiRuntime.physical:
        return _physicalDeviceCandidates();
    }
  }

  static Future<String?> _findFirstWorkingUrl(List<String> candidates) async {
    if (candidates.isEmpty) return null;

    const batchSize = 50; // Increased batch size for faster discovery on physical devices
    for (var i = 0; i < candidates.length; i += batchSize) {
      final end = (i + batchSize < candidates.length)
          ? i + batchSize
          : candidates.length;
      final batch = candidates.sublist(i, end);
      final found = await _probeBatch(batch);
      if (found != null) return found;
    }
    return null;
  }

  static Future<String?> _probeBatch(List<String> candidates) {
    if (candidates.isEmpty) return Future.value(null);

    final completer = Completer<String?>();
    var pending = candidates.length;

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

  static Future<String> getActiveBaseUrl() async {
    if (_cachedWorkingUrl != null) return _cachedWorkingUrl!;

    if (_ongoingDiscovery != null) {
      return _ongoingDiscovery!.future;
    }

    final completer = Completer<String>();
    _ongoingDiscovery = completer;

    try {
      final runtime = await detectRuntime();

      final savedUrl = _sanitizeBaseUrl(await StorageService.getBaseUrl());
      if (savedUrl != null && _isCompatibleSavedUrl(savedUrl, runtime)) {
        final ok = await _isReachable(savedUrl, timeoutMs: 1500);
        if (ok) {
          _cachedWorkingUrl = savedUrl;
          completer.complete(savedUrl);
          _ongoingDiscovery = null;
          return savedUrl;
        }
        await StorageService.clearBaseUrl();
      } else if (savedUrl != null) {
        await StorageService.clearBaseUrl();
      }

      final candidates = await _candidatesFor(runtime);
      final working = await _findFirstWorkingUrl(candidates);
      if (working != null) {
        _cachedWorkingUrl = working;
        StorageService.saveBaseUrl(working).ignore();
        completer.complete(working);
        _ongoingDiscovery = null;
        return working;
      }

      final fallback = candidates.isNotEmpty ? candidates.first : defaultBaseUrl;
      completer.complete(fallback);
      _ongoingDiscovery = null;
      return fallback;
    } catch (_) {
      final fallback = defaultBaseUrl;
      completer.complete(fallback);
      _ongoingDiscovery = null;
      return fallback;
    }
  }

  static void warmup() {
    getActiveBaseUrl().ignore();
  }

  static void resetCache() {
    _cachedWorkingUrl = null;
  }

  static Future<bool> canConnect([String? customBaseUrl]) async {
    final normalized = _sanitizeBaseUrl(customBaseUrl);
    if (normalized != null) {
      return _isReachable(normalized);
    }
    resetCache();
    final active = await getActiveBaseUrl();
    return _isReachable(active);
  }

  static String get baseUrl => _cachedWorkingUrl ?? defaultBaseUrl;

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
  static String get changePassword => endpoint('/change-password');

  static const Duration connectTimeout = Duration(seconds: 12);
  static const Duration receiveTimeout = Duration(seconds: 12);
}
