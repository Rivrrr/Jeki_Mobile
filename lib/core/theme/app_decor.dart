import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';

class AppDecor {
  AppDecor._();

  /// Card putih, radius besar, shadow lembut tint primary.
  static BoxDecoration card({double radius = 24}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      );
}