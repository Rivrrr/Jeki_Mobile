import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Inisialisasi Firebase lintas platform tanpa `flutterfire configure`.
///
/// Android/iOS memakai berkas native (`google-services.json` /
/// `GoogleService-Info.plist`) yang sudah ada di proyek, sedangkan web dan
/// desktop memakai nilai dari aset yang sama. Nilai di bawah bukan rahasia:
/// API key Firebase memang dirancang untuk disebar ke klien, dan keamanan
/// dijaga lewat Security Rules / App Check.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  // ── Nilai dari android/app/google-services.json (project jeki-a831d) ──
  static const String _projectId = 'jeki-a831d';
  static const String _projectNumber = '861019284438';
  static const String _storageBucket = 'jeki-a831d.firebasestorage.app';
  static const String _androidAppId = '1:861019284438:android:a5682bd89973a5fd223a77';

  /// Web API key proyek Firebase. Isi lewat
  /// `--dart-define=FIREBASE_WEB_API_KEY=...` dari Firebase Console
  /// (Project settings → Your apps → Web app → apiKey/config).
  static const String _webApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY', defaultValue: '');

  /// Web App ID. Isi lewat `--dart-define=FIREBASE_WEB_APP_ID=...`.
  static const String _webAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '');

  /// `messagingSenderId` = project number Firebase.
  static const String _messagingSenderId = _projectNumber;

  /// Opsi Firebase untuk platform yang butuh konfigurasi eksplisit.
  /// Mengembalikan `null` untuk Android/iOS (dipakai berkas native).
  static FirebaseOptions? optionsForCurrentPlatform() {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return null;
    }

    if (kIsWeb) {
      if (_webApiKey.isEmpty || _webAppId.isEmpty) return null;
      return const FirebaseOptions(
        apiKey: _webApiKey,
        appId: _webAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        authDomain: '$_projectId.firebaseapp.com',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return const FirebaseOptions(
        apiKey: _webApiKey,
        appId: _androidAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );
    }

    return null;
  }

  /// Inisialisasi aman: mengembalikan `false` (tanpa melempar) bila
  /// konfigurasi untuk platform ini belum tersedia, agar aplikasi tetap
  /// berjalan normal tanpa fitur push.
  static Future<bool> initialize() async {
    try {
      final options = optionsForCurrentPlatform();
      if (options == null) {
        // Android/iOS: pakai google-services.json / GoogleService-Info.plist.
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          await Firebase.initializeApp();
          return true;
        }
        debugPrint(
          'Firebase dilewati: konfigurasi untuk platform ini belum diisi '
          '(set FIREBASE_WEB_API_KEY & FIREBASE_WEB_APP_ID bila memakai web).',
        );
        return false;
      }

      await Firebase.initializeApp(options: options);
      return true;
    } catch (e) {
      debugPrint('Firebase Initialization Error: $e');
      return false;
    }
  }
}
