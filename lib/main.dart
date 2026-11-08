import 'package:flutter/material.dart';
import 'package:infrast/app.dart';
import 'package:infrast/core/services/notification_service.dart';
import 'package:infrast/features/masyarakat/data/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Firebase & Notification Service
  await NotificationService.initialize();
  
  // 2. Sync Token FCM ke Server (jika user sudah login)
  _syncFcmToken();

  runApp(const App());
}

Future<void> _syncFcmToken() async {
  final token = await NotificationService.getToken();
  if (token != null) {
    await UserService.updateFcmToken(token);
  }
}
