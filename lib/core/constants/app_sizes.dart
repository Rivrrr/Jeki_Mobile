import 'package:flutter/material.dart';

class AppSizes {
  static const double paddingXS = 8;
  static const double paddingSM = 12;
  static const double paddingMD = 16;
  static const double paddingLG = 20;
  static const double paddingXL = 24;

  static const double radiusSM = 12;
  static const double radiusMD = 16;
  static const double radiusLG = 20;
  static const double radiusXL = 28;

  static const double iconSM = 18;
  static const double iconMD = 24;
  static const double iconLG = 32;

  static const double buttonHeight = 52;
  static const double cardElevation = 4;

  static const double designWidth = 390;
  static const double designHeight = 844;

  static double responsiveWidth(BuildContext context, double value) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= 0) return value;
    return value * (width / designWidth);
  }

  static double responsiveHeight(BuildContext context, double value) {
    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) return value;
    return value * (height / designHeight);
  }

  static double responsiveSpacing(BuildContext context, double value) {
    return responsiveWidth(context, value);
  }

  static double getHorizontalPadding(BuildContext context) {
    return responsiveSpacing(context, paddingXL);
  }

  static double headerHeight(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return (height * 0.34).clamp(220, 320).toDouble();
  }
}
