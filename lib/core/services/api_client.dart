import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/services/storage_service.dart';

/// HTTP Client terpusat untuk berkomunikasi dengan backend Laravel.
/// Sepenuhnya kompatibel dengan Flutter Web, Android, iOS, dan Desktop (tanpa dependensi dart:io).
class ApiClient {
  ApiClient._();

  // ─── Resolve URL ───────────────────────────────────────────────────────────
  static Future<String> resolveUrl(String pathOrUrl) async {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final base = await ApiConstants.getActiveBaseUrl();
    return ApiConstants.endpoint(pathOrUrl, base);
  }

  // ─── Headers ───────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept':       'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ─── Response Parser ───────────────────────────────────────────────────────
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      return {
        'success':       isSuccess,
        'statusCode':    response.statusCode,
        'data':          isSuccess ? body : null,
        'message':       body['message'] ?? (isSuccess ? 'Berhasil' : 'Terjadi kesalahan pada server.'),
        'role_mismatch': body['role_mismatch'] == true,
        'user_role':     body['user_role'],
        'expected_role': body['expected_role'],
        'errors':        body['errors'],
        'raw_body':      body,
      };
    } catch (_) {
      return {
        'success':        false,
        'statusCode':     response.statusCode,
        'data':           null,
        'message':        'Format respons tidak valid dari server (Status ${response.statusCode}).',
        'isNetworkError': false,
      };
    }
  }

  // ─── GET ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String pathOrUrl, {
    bool requiresAuth = true,
  }) async {
    final finalUrl = await resolveUrl(pathOrUrl);
    try {
      final headers  = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http
          .get(Uri.parse(finalUrl), headers: headers)
          .timeout(ApiConstants.receiveTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      return _timeoutError(finalUrl);
    } catch (e) {
      return _networkOrUnknownError(e, finalUrl);
    }
  }

  // ─── POST ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String pathOrUrl, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final finalUrl = await resolveUrl(pathOrUrl);
    try {
      final headers  = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http
          .post(
            Uri.parse(finalUrl),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.receiveTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      return _timeoutError(finalUrl);
    } catch (e) {
      return _networkOrUnknownError(e, finalUrl);
    }
  }

  // ─── PUT ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String pathOrUrl, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final finalUrl = await resolveUrl(pathOrUrl);
    try {
      final headers  = await _buildHeaders(requiresAuth: requiresAuth);
      final response = await http
          .put(
            Uri.parse(finalUrl),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.receiveTimeout);
      return _parseResponse(response);
    } on TimeoutException {
      return _timeoutError(finalUrl);
    } catch (e) {
      return _networkOrUnknownError(e, finalUrl);
    }
  }

  // ─── POST Multipart (for file/bytes uploads) ────────────────────────────────
  static Future<Map<String, dynamic>> postMultipart(
    String pathOrUrl, {
    required Map<String, String> fields,
    List<({String fieldName, Uint8List bytes, String fileName})>? files,
    bool requiresAuth = true,
  }) async {
    final finalUrl = await resolveUrl(pathOrUrl);
    try {
      final token = requiresAuth ? await StorageService.getToken() : null;

      final request = http.MultipartRequest('POST', Uri.parse(finalUrl));
      request.headers['Accept'] = 'application/json';
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      if (files != null) {
        for (final f in files) {
          request.files.add(http.MultipartFile.fromBytes(
            f.fieldName,
            f.bytes,
            filename: f.fileName,
          ));
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      return _parseResponse(response);
    } on TimeoutException {
      return _timeoutError(finalUrl);
    } catch (e) {
      return _networkOrUnknownError(e, finalUrl);
    }
  }

  // ─── Error Helpers ─────────────────────────────────────────────────────────
  static Map<String, dynamic> _timeoutError(String url) => {
        'success':        false,
        'statusCode':     408,
        'isTimeout':      true,
        'isNetworkError': true,
        'url':            url,
        'data':           null,
        'message':        'Waktu koneksi ke server habis (Timeout) saat menghubungi $url. Pastikan server backend aktif dan IP sudah sesuai.',
      };

  static Map<String, dynamic> _networkOrUnknownError(Object e, String url) {
    final errStr = e.toString().toLowerCase();
    final isConnErr = errStr.contains('socket') || 
                      errStr.contains('clientexception') || 
                      errStr.contains('connection refused') ||
                      errStr.contains('failed to fetch') ||
                      errStr.contains('xmlhttprequest');

    return {
      'success':        false,
      'statusCode':     0,
      'isNetworkError': isConnErr,
      'url':            url,
      'data':           null,
      'message': isConnErr
          ? 'Tidak dapat terhubung ke server Laravel ($url). Pastikan server backend aktif (php artisan serve).'
          : 'Terjadi kendala koneksi: ${e.toString()}',
    };
  }
}
