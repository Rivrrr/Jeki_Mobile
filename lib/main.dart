import 'package:flutter/material.dart';
import 'package:infrast/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Autentikasi kini menggunakan Laravel REST API + SharedPreferences.
  // Tidak ada inisialisasi Supabase di sini.
  runApp(const App());
}
