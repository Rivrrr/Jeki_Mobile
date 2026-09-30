import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFF06292);
  static const Color accentPink = Color(0xFFFCE4EC);

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
  static const Color statusPending = Color(0xFFE91E63);
  static const Color statusPendingBg = Color(0xFFFCE4EC);
  static const Color statusProcessing = Color(0xFFFF9800);
  static const Color statusProcessingBg = Color(0xFFFFF3E0);
  static const Color statusVerification = Color(0xFF2196F3);
  static const Color statusVerificationBg = Color(0xFFE3F2FD);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCompletedBg = Color(0xFFE8F5E9);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD81B60), Color(0xFFEC407A)],
  );
}
