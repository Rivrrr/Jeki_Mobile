import 'package:flutter/material.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/auth/presentation/screens/register_screen.dart';
import 'package:infrast/features/main_navigation/presentation/screens/main_navigation.dart';
import 'package:infrast/features/pelaksana/presentation/screens/pelaksana_home_page.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_list_screen.dart';
import 'package:infrast/features/splash/presentation/screens/splash_screen.dart';
import 'package:infrast/presentation/pages/notifikasi/notifikasi_page.dart';
import 'package:infrast/presentation/pages/onboarding/onboarding_page.dart';
import 'package:infrast/presentation/pages/peta/peta_page.dart';
import 'package:infrast/presentation/pages/profil/profil_page.dart';

class AppRoutes {
  static const String splash           = '/';
  static const String onboarding       = '/onboarding';
  static const String login            = '/login';
  static const String register         = '/register';
  static const String home             = '/home';
  static const String laporan          = '/laporan';
  static const String peta             = '/peta';
  static const String notifikasi       = '/notifikasi';
  static const String profil           = '/profil';
  // Pelaksana routes
  static const String pelaksanaHome    = '/pelaksana/home';
  static const String pelaksanaTugas   = '/pelaksana/tugas';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainNavigation());
      case peta:
        return MaterialPageRoute(builder: (_) => const PetaPage());
      case notifikasi:
        return MaterialPageRoute(builder: (_) => const NotifikasiPage());
      case profil:
        return MaterialPageRoute(builder: (_) => const ProfilPage());
      // Pelaksana
      case pelaksanaHome:
        return MaterialPageRoute(builder: (_) => const PelaksanaHomePage());
      case pelaksanaTugas:
        return MaterialPageRoute(builder: (_) => const TugasListScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Halaman tidak ditemukan')),
          ),
        );
    }
  }
}
