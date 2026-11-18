import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

class GeocodingSuggestion {
  final String displayName;
  final String shortAddress;
  final double latitude;
  final double longitude;

  const GeocodingSuggestion({
    required this.displayName,
    required this.shortAddress,
    required this.latitude,
    required this.longitude,
  });
}

class ReverseGeocodeResult {
  final String? road;
  final String? houseNumber;
  final String? poi;
  final String? village;
  final String? cityDistrict;
  final String fullAddress;
  final String? matchedKecamatanNama;
  final int? matchedKecamatanId;
  final String rawDisplayName;

  const ReverseGeocodeResult({
    this.road,
    this.houseNumber,
    this.poi,
    this.village,
    this.cityDistrict,
    required this.fullAddress,
    this.matchedKecamatanNama,
    this.matchedKecamatanId,
    required this.rawDisplayName,
  });
}

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  // 31 Titik Pusat Kecamatan di Kabupaten Jember (Fallback akurasi spasial)
  static const Map<String, ({double lat, double lng})> jemberKecamatanCentroids = {
    'Ajung': (lat: -8.2258, lng: 113.6700),
    'Ambulu': (lat: -8.3496, lng: 113.6067),
    'Arjasa': (lat: -8.1158, lng: 113.7431),
    'Balung': (lat: -8.2719, lng: 113.5350),
    'Bangsalsari': (lat: -8.1969, lng: 113.5283),
    'Gumukmas': (lat: -8.3192, lng: 113.4072),
    'Jelbuk': (lat: -8.0772, lng: 113.7436),
    'Jenggawah': (lat: -8.2608, lng: 113.6558),
    'Jombang': (lat: -8.2567, lng: 113.3444),
    'Kalisat': (lat: -8.1258, lng: 113.8114),
    'Kaliwates': (lat: -8.1804, lng: 113.6826),
    'Kencong': (lat: -8.2792, lng: 113.3711),
    'Ledokombo': (lat: -8.1361, lng: 113.8822),
    'Mayang': (lat: -8.1906, lng: 113.7878),
    'Mumbulsari': (lat: -8.2619, lng: 113.7436),
    'Pakusari': (lat: -8.1714, lng: 113.7661),
    'Panti': (lat: -8.1067, lng: 113.6169),
    'Patrang': (lat: -8.1565, lng: 113.7058),
    'Puger': (lat: -8.3586, lng: 113.4739),
    'Rambipuji': (lat: -8.2032, lng: 113.6053),
    'Semboro': (lat: -8.2167, lng: 113.4350),
    'Silo': (lat: -8.2433, lng: 113.9142),
    'Sukorambi': (lat: -8.1472, lng: 113.6558),
    'Sukowono': (lat: -8.0667, lng: 113.8219),
    'Sumberbaru': (lat: -8.1417, lng: 113.3639),
    'Sumberjambe': (lat: -8.0967, lng: 113.9056),
    'Sumbersari': (lat: -8.1724, lng: 113.7175),
    'Tanggul': (lat: -8.1578, lng: 113.4544),
    'Tempurejo': (lat: -8.3267, lng: 113.7067),
    'Umbulsari': (lat: -8.2433, lng: 113.4867),
    'Wuluhan': (lat: -8.3308, lng: 113.5358),
  };

  /// Reverse geocoding dari titik GPS (latitude & longitude) menjadi nama jalan dan kecamatan
  /// menggunakan 3-tier fallback provider (Nominatim -> Photon Komoot -> BigDataCloud).
  static Future<ReverseGeocodeResult> reverseGeocode(
    double lat,
    double lng, {
    List<Map<String, dynamic>>? availableKecamatans,
  }) async {
    String? detectedRoad;
    String? detectedHouseNumber;
    String? detectedPoi;
    String? detectedVillage;
    String? detectedCityDistrict;
    String rawDisplayName = '';

    // ── 1. Provider Utama: OpenStreetMap Nominatim ──
    try {
      final nomUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=17&addressdetails=1&accept-language=id',
      );

      final response = await http.get(nomUrl, headers: {
        'User-Agent': 'Jeki-Infrast-App/1.0 (contact: info@jeki.id)',
        'Accept-Language': 'id-ID,id;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        rawDisplayName = data['display_name'] as String? ?? '';

        detectedRoad = address['road'] ??
            address['street'] ??
            address['residential'] ??
            address['pedestrian'] ??
            address['footway'] ??
            address['path'] ??
            address['service'] ??
            address['track'] ??
            address['cycleway'] ??
            address['living_street'] ??
            address['highway'];

        detectedHouseNumber = address['house_number'] ??
            address['street_number'] ??
            address['house_name'];

        final rawBldg = address['building'];
        final bldgName = (rawBldg is String &&
                rawBldg.toLowerCase() != 'yes' &&
                rawBldg.toLowerCase() != 'true' &&
                rawBldg.toLowerCase() != 'house')
            ? rawBldg
            : null;

        detectedPoi = address['amenity'] ??
            address['shop'] ??
            address['office'] ??
            address['tourism'] ??
            address['leisure'] ??
            bldgName ??
            (data['name'] is String && data['name'] != detectedRoad ? data['name'] : null);

        detectedVillage = address['suburb'] ??
            address['village'] ??
            address['neighbourhood'] ??
            address['hamlet'] ??
            address['quarter'];

        detectedCityDistrict = address['city_district'] ??
            address['subdistrict'] ??
            address['district'] ??
            address['county'];
      }
    } catch (_) {}

    // ── 2. Provider Kedua (Fallback Cepat): Photon Komoot ──
    if (detectedRoad == null || detectedRoad.trim().isEmpty) {
      try {
        final photonUrl = Uri.parse(
          'https://photon.komoot.io/reverse?lat=$lat&lon=$lng&lang=id',
        );
        final pResp = await http.get(photonUrl).timeout(const Duration(seconds: 3));
        if (pResp.statusCode == 200) {
          final pData = json.decode(pResp.body);
          final features = pData['features'] as List?;
          if (features != null && features.isNotEmpty) {
            final props = features[0]['properties'] as Map<String, dynamic>? ?? {};
            final street = props['street'] as String?;
            if (street != null && street.trim().isNotEmpty) {
              detectedRoad = street.trim();
            }
            detectedHouseNumber ??= props['housenumber']?.toString();
            if (detectedPoi == null && props['name'] != null && props['name'] != detectedRoad) {
              detectedPoi = props['name'] as String;
            }
            detectedVillage ??= props['district'] as String?;
            detectedCityDistrict ??= props['city'] as String?;
            if (rawDisplayName.isEmpty && props['name'] != null) {
              rawDisplayName = props['name'].toString();
            }
          }
        }
      } catch (_) {}
    }

    // ── 3. Provider Ketiga: BigDataCloud ──
    if (detectedRoad == null || detectedRoad.trim().isEmpty) {
      try {
        final bdcUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=id',
        );
        final bResp = await http.get(bdcUrl).timeout(const Duration(seconds: 3));
        if (bResp.statusCode == 200) {
          final bData = json.decode(bResp.body);
          final localityInfo = bData['localityInfo'] as Map<String, dynamic>? ?? {};
          final informative = localityInfo['informative'] as List? ?? [];
          for (final item in informative) {
            final name = item['name'] as String? ?? '';
            final lower = name.toLowerCase();
            if (lower.startsWith('jalan ') ||
                lower.startsWith('jl.') ||
                lower.startsWith('gang ') ||
                lower.startsWith('gg.') ||
                (item['description'] as String? ?? '').toLowerCase().contains('road')) {
              detectedRoad = name;
              break;
            }
          }
          detectedVillage ??= bData['locality'] as String?;
          if (detectedCityDistrict == null && bData['localityInfo']?['administrative'] != null) {
            final admin = bData['localityInfo']['administrative'] as List? ?? [];
            for (final a in admin) {
              final aName = (a['name'] as String? ?? '').toLowerCase();
              if (aName.contains('kecamatan') || a['adminLevel'] == 7) {
                detectedCityDistrict = a['name'];
                break;
              }
            }
          }
        }
      } catch (_) {}
    }

    // Ekstrak nomor rumah jika belum terpisah
    if (detectedHouseNumber == null && rawDisplayName.isNotEmpty) {
      final match = RegExp(r'^(?:No\.?\s*)?(\d+[\w\-/]*)\s*,').firstMatch(rawDisplayName);
      if (match != null) {
        detectedHouseNumber = match.group(1);
      }
    }

    // Format Jalan dan Nomor
    String fullAlamat = '';
    if (detectedRoad != null && detectedRoad.trim().isNotEmpty) {
      final formattedRoad = formatNamaJalan(detectedRoad);
      String streetWithNumber = formattedRoad;
      if (detectedHouseNumber != null && detectedHouseNumber.trim().isNotEmpty) {
        streetWithNumber = '$formattedRoad ${formatNomorRumah(detectedHouseNumber)}';
      }

      if (detectedVillage != null &&
          detectedVillage.trim().isNotEmpty &&
          !formattedRoad.toLowerCase().contains(detectedVillage.toLowerCase())) {
        fullAlamat = '$streetWithNumber, $detectedVillage';
      } else {
        fullAlamat = streetWithNumber;
      }
    } else if (rawDisplayName.isNotEmpty) {
      final parts = rawDisplayName
          .split(',')
          .map((p) => p.trim())
          .where((p) {
            final l = p.toLowerCase();
            return l.isNotEmpty &&
                l != 'indonesia' &&
                l != 'east java' &&
                l != 'jawa timur' &&
                l != 'jember' &&
                l != 'kabupaten jember' &&
                !RegExp(r'^\d{5}$').hasMatch(l);
          })
          .toList();

      if (parts.isNotEmpty) {
        if (parts.length >= 2 && RegExp(r'^\d+[\w\-/]*$').hasMatch(parts[0])) {
          fullAlamat = '${formatNamaJalan(parts[1])} ${formatNomorRumah(parts[0])}';
          if (parts.length > 2) {
            fullAlamat += ', ${parts[2]}';
          }
        } else {
          fullAlamat = parts.take(2).join(', ');
        }
      }
    }

    // Cocokkan nama kecamatan dengan referensi resmi
    final searchSource = '${detectedCityDistrict ?? ''} ${detectedVillage ?? ''} $rawDisplayName'.toLowerCase();
    String? matchedNama;
    int? matchedId;

    if (availableKecamatans != null && availableKecamatans.isNotEmpty) {
      for (final k in availableKecamatans) {
        final kNama = (k['nama'] as String).toLowerCase();
        if (searchSource.contains(kNama)) {
          matchedNama = k['nama'] as String;
          matchedId = k['id'] as int;
          break;
        }
      }
    }

    // Fallback jarak kecamatan terdekat jika belum cocok dari nama teks
    if (matchedNama == null) {
      String? closestNama;
      double minDistance = double.infinity;
      for (final entry in jemberKecamatanCentroids.entries) {
        final d = math.sqrt(
          math.pow(lat - entry.value.lat, 2) + math.pow(lng - entry.value.lng, 2),
        );
        if (d < minDistance) {
          minDistance = d;
          closestNama = entry.key;
        }
      }
      matchedNama = closestNama;
      if (availableKecamatans != null && matchedNama != null) {
        for (final k in availableKecamatans) {
          if ((k['nama'] as String).toLowerCase() == matchedNama.toLowerCase()) {
            matchedId = k['id'] as int;
            break;
          }
        }
      }
    }

    if (fullAlamat.isEmpty && matchedNama != null) {
      fullAlamat = 'Wilayah Kec. $matchedNama, Kab. Jember';
    }

    return ReverseGeocodeResult(
      road: detectedRoad,
      houseNumber: detectedHouseNumber,
      poi: detectedPoi,
      village: detectedVillage,
      cityDistrict: detectedCityDistrict,
      fullAddress: fullAlamat,
      matchedKecamatanNama: matchedNama,
      matchedKecamatanId: matchedId,
      rawDisplayName: rawDisplayName,
    );
  }

  /// Format standar penulisan nama jalan Indonesia
  static String formatNamaJalan(String raw) {
    var road = raw.trim();
    final lower = road.toLowerCase();

    if (lower.startsWith('jalan ')) {
      road = road.substring(6).trim();
    } else if (lower.startsWith('jl. ')) {
      road = road.substring(4).trim();
    } else if (lower.startsWith('jl ')) {
      road = road.substring(3).trim();
    }

    if (road.isEmpty) return 'Lokasi tidak dikenal';

    final roadLower = road.toLowerCase();
    if (!roadLower.startsWith('gang ') &&
        !roadLower.startsWith('gg.') &&
        !roadLower.startsWith('gg ') &&
        !roadLower.startsWith('lorong ') &&
        !roadLower.startsWith('blok ') &&
        !roadLower.startsWith('dusun ') &&
        !roadLower.startsWith('alun-alun') &&
        !roadLower.startsWith('kawasan')) {
      road = 'Jl. $road';
    }
    return road;
  }

  /// Format standar nomor rumah / bangunan
  static String formatNomorRumah(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return '';
    if (clean.toLowerCase().startsWith('no')) return clean;
    return 'No. $clean';
  }

  /// Search alamat berbasis geocoding untuk autocomplete jalan.
  static Future<List<GeocodingSuggestion>> searchAddress(
    String query, {
    double? nearLat,
    double? nearLng,
    int limit = 6,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 3) return const [];

    final params = <String, String>{
      'q': cleanQuery,
      'format': 'jsonv2',
      'addressdetails': '1',
      'accept-language': 'id',
      'countrycodes': 'id',
      'limit': limit.toString(),
    };

    if (nearLat != null && nearLng != null) {
      // Prioritaskan hasil di sekitar titik pengguna agar nama jalan lebih relevan.
      params['lat'] = nearLat.toString();
      params['lon'] = nearLng.toString();
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Jeki-Infrast-App/1.0 (contact: info@jeki.id)',
        'Accept-Language': 'id-ID,id;q=0.9,en;q=0.8',
      },
    ).timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) {
      return const [];
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];

    final result = <GeocodingSuggestion>[];

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;

      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      final displayName = item['display_name']?.toString().trim() ?? '';

      if (lat == null || lon == null || displayName.isEmpty) continue;

      final shortAddress = _buildShortAddress(item);

      result.add(
        GeocodingSuggestion(
          displayName: displayName,
          shortAddress: shortAddress,
          latitude: lat,
          longitude: lon,
        ),
      );
    }

    return result;
  }

  static String _buildShortAddress(Map<String, dynamic> item) {
    final address = item['address'];
    if (address is! Map<String, dynamic>) {
      return item['display_name']?.toString() ?? '';
    }

    final road = (address['road'] ?? address['street'] ?? address['residential'] ?? '')
        .toString()
        .trim();
    final number = (address['house_number'] ?? '').toString().trim();
    final suburb = (address['suburb'] ?? address['village'] ?? address['neighbourhood'] ?? '')
        .toString()
        .trim();
    final district = (address['city_district'] ?? address['county'] ?? '').toString().trim();
    final city = (address['city'] ?? address['town'] ?? address['municipality'] ?? '')
        .toString()
        .trim();

    final head = road.isEmpty
        ? ''
        : (number.isEmpty ? road : '$road No. $number');

    final parts = <String>[
      if (head.isNotEmpty) head,
      if (suburb.isNotEmpty) suburb,
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ];

    if (parts.isEmpty) {
      return item['display_name']?.toString() ?? '';
    }

    return parts.join(', ');
  }
}
