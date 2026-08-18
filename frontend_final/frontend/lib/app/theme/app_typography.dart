import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Text styles for Alpha Cues. All text styling must use [AppTypography] themes.
abstract final class AppTypography {
  static TextTheme get light => _buildTextTheme(
    primary: AppColors.onBackground,
    muted: AppColors.onSurfaceVariant,
  );

  static TextTheme get dark => _buildTextTheme(
    primary: AppColors.darkOnBackground,
    muted: AppColors.darkOnSurfaceVariant,
  );

  /// Default light text theme (backward compatible).
  static TextTheme get textTheme => light;

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color muted,
  }) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      Color? color,
      double? height,
      double? letterSpacing,
    }) {
      return GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? primary,
      );
    }

    return TextTheme(
      displayLarge: style(size: 57, weight: FontWeight.w400, height: 1.12),
      displayMedium: style(size: 45, weight: FontWeight.w400, height: 1.16),
      displaySmall: style(size: 36, weight: FontWeight.w400, height: 1.22),
      headlineLarge: style(size: 32, weight: FontWeight.w600, height: 1.25),
      headlineMedium: style(size: 28, weight: FontWeight.w600, height: 1.3),
      headlineSmall: style(size: 24, weight: FontWeight.w600, height: 1.35),
      titleLarge: style(size: 22, weight: FontWeight.w500, height: 1.35),
      titleMedium: style(size: 16, weight: FontWeight.w500, height: 1.4),
      titleSmall: style(size: 14, weight: FontWeight.w500, height: 1.4),
      bodyLarge: style(size: 16, weight: FontWeight.w400, height: 1.5),
      bodyMedium: style(size: 14, weight: FontWeight.w400, height: 1.5),
      bodySmall: style(
        size: 12,
        weight: FontWeight.w400,
        height: 1.45,
        color: muted,
      ),
      labelLarge: style(
        size: 14,
        weight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
      ),
      labelMedium: style(
        size: 12,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.5,
        color: muted,
      ),
      labelSmall: style(
        size: 11,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.5,
        color: muted,
      ),
    );
  }
}
