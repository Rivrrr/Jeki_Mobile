import 'dart:convert';

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

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';

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
