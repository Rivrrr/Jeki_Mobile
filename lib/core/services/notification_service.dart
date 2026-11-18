import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:infrast/core/services/firebase_bootstrap.dart';
import 'package:infrast/routes/app_routes.dart';

/// Service untuk menangani Notifikasi Push menggunakan Firebase Cloud Messaging (FCM).
/// Mengelola pendaftaran token, pendengaran pesan masuk, dan integrasi notifikasi.
class NotificationService {
  NotificationService._();

  // Global Key untuk navigasi tanpa Context (dibutuhkan untuk notifikasi background)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Nama channel Android. HARUS sama dengan `android.notification.channel_id`
  /// yang dikirim backend (`FCMService`), jika tidak suara/prioritas hilang.
  static const String androidChannelId = 'jeki_notifications';
  static const String androidChannelName = 'Notifikasi JEKI';
  static const String androidChannelDescription =
      'Pemberitahuan status laporan dan tugas pekerjaan';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// `true` bila Firebase berhasil diinisialisasi di platform ini.
  static bool _ready = false;
  static bool get isReady => _ready;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    androidChannelId,
    androidChannelName,
    description: androidChannelDescription,
    importance: Importance.max,
    playSound: true,
  );

  /// Inisialisasi Firebase, channel Android, dan setup listener notifikasi.
  static Future<void> initialize() async {
    try {
      final ok = await FirebaseBootstrap.initialize();
      if (!ok) {
        debugPrint('Notifikasi push nonaktif: Firebase belum siap.');
        return;
      }
      _ready = true;

      // Channel harus dibuat lebih dulu, kalau tidak notifikasi Android 8+
      // tetap tampil tetapi tanpa suara dan tanpa heads-up.
      await _initLocalNotifications();

      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted permission for notifications');
      }

      // Listener tetap dipasang walau izin belum diberikan: bila pengguna
      // mengizinkan belakangan (halaman Pengaturan), push langsung tertangani.
      _setupListeners();
    } catch (e) {
      debugPrint('Firebase Initialization Error: $e');
    }
  }

  /// Buat channel Android + daftarkan handler foreground.
  static Future<void> _initLocalNotifications() async {
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    try {
      await _local.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          final id = int.tryParse(payload);
          if (id != null) {
            navigatorKey.currentState?.pushNamed(
              AppRoutes.laporanDetail,
              arguments: id,
            );
          }
        },
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    } catch (e) {
      debugPrint('Gagal menyiapkan channel notifikasi lokal: $e');
    }
  }

  /// Tampilkan notifikasi sebagai heads-up banner di Android saat app aktif.
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Notifikasi JEKI';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';
    final laporanId = message.data['laporan_id']?.toString();

    try {
      await _local.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannelId,
            androidChannelName,
            channelDescription: androidChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        payload: laporanId,
      );
    } catch (e) {
      debugPrint('Gagal menampilkan notifikasi foreground: $e');
    }
  }

  /// ScaffoldMessenger global supaya pesan foreground bisa ditampilkan dari
  /// mana pun tanpa BuildContext (listener FCM hidup di luar widget tree).
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void _setupListeners() {
      // Foreground Messages — push tidak dirender OS saat app aktif, jadi
      // banner heads-up ditampilkan lewat notification channel yang sama
      // dengan channel backend agar suara & prioritas konsisten.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Foreground Message: ${message.notification?.title}');

        final title = message.notification?.title ?? message.data['title'];
        final body = message.notification?.body ?? message.data['body'];
        if (title == null && body == null) return;

        await _showForegroundNotification(message);

        // Snackbar tetap dipakai sebagai umpan balik in-app (mis. saat izin
        // notifikasi belum diberikan sehingga banner tidak muncul).
        final messenger = messengerKey.currentState;
        if (messenger == null) return;

        messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1F2937),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (body != null)
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
            action: SnackBarAction(
              label: 'Lihat',
              textColor: Colors.white,
              onPressed: () => _handleNavigation(message),
            ),
          ),
        );
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

  /// Periksa apakah izin notifikasi sudah diberikan pengguna.
  ///
  /// Mengembalikan `false` bila Firebase belum siap atau terjadi error, agar
  /// halaman pengaturan menampilkan tombol "Izinkan Akses".
  static Future<bool> getPermissionStatus() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('Error reading notification permission: $e');
      return false;
    }
  }

  /// Minta izin notifikasi ke pengguna. Mengembalikan `true` bila diizinkan.
  static Future<bool> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) _setupListeners();
      return granted;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }
}
