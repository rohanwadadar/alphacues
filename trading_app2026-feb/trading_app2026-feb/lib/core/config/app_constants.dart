// ============================================================
//  app_constants.dart  —  App-wide non-API constants
// ============================================================
//  Colour token, spacing, typography scale, and named
//  durations used across all widgets.  Import this instead
//  of hard-coding magic numbers inside widgets.
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary        = Color(0xFF7061F3);
  static const Color primaryLight   = Color(0xFFEBE9FD);
  static const Color primaryDark    = Color(0xFF4F3FD4);

  // Status
  static const Color success        = Color(0xFF00B899);
  static const Color successLight   = Color(0xFFE6F9F6);
  static const Color warning        = Color(0xFFFF8C42);
  static const Color warningLight   = Color(0xFFFFF0E6);
  static const Color danger         = Color(0xFFFF4D4D);
  static const Color dangerLight    = Color(0xFFFFECEC);

  // Market direction
  static const Color bullish        = Color(0xFF2ECC71);
  static const Color bearish        = Color(0xFFE74C3C);

  // Neutral
  static const Color background     = Color(0xFFF8F8FC);
  static const Color surface        = Colors.white;
  static const Color border         = Color(0xFFEEEEEE);
  static const Color textPrimary    = Color(0xFF0D0D0D);
  static const Color textSecondary  = Color(0xFF6B7280);
  static const Color textHint       = Color(0xFFB0B7C3);
}

class AppSpacing {
  AppSpacing._();
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double lg   = 16;
  static const double xl   = 20;
  static const double xxl  = 24;
  static const double xxxl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double pill = 100;
}

class AppDurations {
  AppDurations._();
  static const Duration fast    = Duration(milliseconds: 150);
  static const Duration normal  = Duration(milliseconds: 300);
  static const Duration slow    = Duration(milliseconds: 500);
  static const Duration splash  = Duration(milliseconds: 1200);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.bold,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.normal,
    color: AppColors.textPrimary, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.normal,
    color: AppColors.textSecondary, height: 1.4,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  static const TextStyle chip = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
  );
}
