import 'package:infrast/core/services/api_client.dart';

/// Service untuk mengelola data user dan pengaturan akun.
class UserService {
  UserService._();

  /// Update token FCM pengguna ke server.
  /// Token ini digunakan oleh backend untuk mengirim push notification ke perangkat ini.
  static Future<Map<String, dynamic>> updateFcmToken(String token) async {
    return await ApiClient.post('/user/update-fcm-token', body: {
      'fcm_token': token,
    });
  }
}
