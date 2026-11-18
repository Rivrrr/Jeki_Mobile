import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/constants/app_sizes.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/login_screen.dart';
import 'package:infrast/features/masyarakat/presentation/pages/main_navigation_page.dart';
import 'package:infrast/features/pelaksana/presentation/main_pelaksana_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Pemanasan auto-discovery base URL di background
    ApiConstants.warmup();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final loggedIn = await AuthService.isLoggedIn;
      if (!mounted)  return;

      Widget nextScreen;
      if (loggedIn) {
        // Baca role dari storage untuk routing yang tepat
        final role = await AuthService.getRole();
        nextScreen = (role == 'pelaksana')
            ? const MainPelaksanaPage()
            : const MainNavigation();
      } else {
        nextScreen = const LoginScreen();
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Background Watermark
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: AppSizes.responsiveWidth(context, 300),
                height: AppSizes.responsiveHeight(context, 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSizes.getHorizontalPadding(context)),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    
                    // Center Content
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with Pulse
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ScaleTransition(
                                scale: _pulseAnimation,
                                child: Container(
                                  width: AppSizes.responsiveWidth(context, 120),
                                  height: AppSizes.responsiveWidth(context, 120),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              Container(
                                width: AppSizes.responsiveWidth(context, 80),
                                height: AppSizes.responsiveWidth(context, 80),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                    AppSizes.responsiveWidth(context, 16),
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo_jk.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.responsiveSpacing(context, 24)),
                          
                          // Title & Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Jeki',
                                style: TextStyle(
                                  fontSize: AppSizes.responsiveWidth(context, 32),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: AppSizes.responsiveSpacing(context, 8)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Jember',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppSizes.responsiveWidth(context, 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSizes.responsiveSpacing(context, 8)),
                          
                          // Tagline
                          Text(
                            '"Lapor Infrastruktur, Wujudkan Jember Lebih Baik"',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: AppSizes.responsiveWidth(context, 13),
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Bottom Content
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.responsiveHeight(context, 30)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BouncingDotsLoader(),
                          SizedBox(height: AppSizes.responsiveSpacing(context, 20)),
                          
                          // Footer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: AppSizes.responsiveWidth(context, 14),
                              ),
                              SizedBox(width: AppSizes.responsiveSpacing(context, 6)),
                              Text(
                                'Pemerintah Daerah — DISKOMINFO',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: AppSizes.responsiveWidth(context, 11),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widget for Bouncing Dots
class BouncingDotsLoader extends StatefulWidget {
  const BouncingDotsLoader({super.key});

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Pemanasan auto-discovery base URL di background
    ApiConstants.warmup();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offset = (index * 0.5) - (_controller.value * 2 * math.pi);
        final double y = -10 * (0.5 * (1 + math.sin(offset)));
        
        return Transform.translate(
          offset: Offset(0, y),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => _buildDot(index)),
    );
  }
}

