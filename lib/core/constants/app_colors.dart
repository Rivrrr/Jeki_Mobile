import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFD3F92);
  static const Color primaryDark = Color(0xFFB50060);
  static const Color primaryLight = Color(0xFFDC2079);
  static const Color accentPink = Color(0xFFFFF0F5);

  static const Color background = Color(0xFFF8F9FD);
  static const Color cardSurface = Colors.white;
  
  static const Color textPrimary = Color(0xFF1E2432);
  static const Color textSecondary = Color(0xFF757F95);
  static const Color textMuted = Color(0xFF9EA6BA);
  static const Color border = Color(0xFFE0E5ED);

  // Legacy / Additional
  static const Color success = Color(0xFF1DBF73);
  static const Color warning = Color(0xFFFFB84D);
  static const Color error = Color(0xFFE53935);

  // Status Indicators
  static const Color statusPending = Color(0xFFFD3F92);
  static const Color statusPendingBg = Color(0xFFFFF0F5);
  static const Color statusProcessing = Color(0xFFFF9800);
  static const Color statusProcessingBg = Color(0xFFFFF3E0);
  static const Color statusVerification = Color(0xFF2196F3);
  static const Color statusVerificationBg = Color(0xFFE3F2FD);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCompletedBg = Color(0xFFE8F5E9);

  // Gradient as in Figma (Stops: 0% #B50060, 60% #FD3F92, 100% #DC2079)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.6, 1.0],
    colors: [
      Color(0xFFB50060),
      Color(0xFFFD3F92),
      Color(0xFFDC2079),
    ],
  );
}
