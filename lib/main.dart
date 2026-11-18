import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:infrast/app.dart';
import 'package:infrast/core/services/notification_service.dart';
import 'package:infrast/features/masyarakat/data/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0a. Inisialisasi data locale intl. Tanpa ini, DateFormat(..., 'id_ID')
  // melempar LocaleDataException dan halaman yang memformat tanggal
  // (mis. Tanggal Lahir di Edit Profil) gagal dirender.
  await initializeDateFormatting('id_ID', null);

  // 0. Muat konfigurasi `.env` (API_BASE_URL). Dibungkus try/catch agar
  // aplikasi tetap jalan dengan deteksi otomatis bila berkas tidak ada.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('Konfigurasi .env tidak ditemukan, memakai deteksi otomatis.');
  }

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
