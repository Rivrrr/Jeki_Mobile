import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:infrast/routes/app_routes.dart';

/// Service untuk menangani Notifikasi Push menggunakan Firebase Cloud Messaging (FCM).
/// Mengelola pendaftaran token, pendengaran pesan masuk, dan integrasi notifikasi.
class NotificationService {
  NotificationService._();

  // Global Key untuk navigasi tanpa Context (dibutuhkan untuk notifikasi background)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Inisialisasi Firebase dan setup listener notifikasi.
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
        _setupListeners();
      }
    } catch (e) {
      debugPrint('Firebase Initialization Error: $e');
    }
  }

  static void _setupListeners() {
    // 1. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground Message: ${message.notification?.title}');
    });

    // 2. Background/Terminated Messages (User klik notifikasi)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });

    // 3. Handle if app is opened from terminated state via notification
    _handleInitialMessage();
  }

  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }
  }

  static void _handleNavigation(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('laporan_id')) {
      final laporanId = int.tryParse(data['laporan_id'].toString());
      if (laporanId != null) {
        debugPrint('Navigating to Laporan Detail: $laporanId');
        navigatorKey.currentState?.pushNamed(
          AppRoutes.laporanDetail, 
          arguments: laporanId,
        );
      }
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
      return null;
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }
}
