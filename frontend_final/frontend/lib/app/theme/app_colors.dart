import 'package:flutter/material.dart';

/// Alpha Cues design system colors. All [Color] values used in the app
/// must come from this file.
abstract final class AppColors {
  // Brand — primary for buttons/filled surfaces; primaryText for text/icons on light bg
  static const Color primary = Color(0xFF7061F3);
  static const Color primaryText = Color(0xFF5A4FD4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE8E4FD);
  static const Color onPrimaryContainer = Color(0xFF2D2866);

  // Finance semantics (shared across light and dark themes)
  static const Color positive = Color(0xFF16A34A);
  static const Color onPositive = Color(0xFFFFFFFF);
  static const Color negative = Color(0xFFDC2626);
  static const Color onNegative = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFD97706);
  static const Color neutral = Color(0xFF6B7280);
  static const Color positiveBackground = Color(0xFFDCFCE7);
  static const Color negativeBackground = Color(0xFFFEE2E2);

  // Light surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color surfaceAlt = Color(0xFFF8F9FA);
  static const Color onSurfaceVariant = Color(0xFF5C5C7A);
  static const Color surfaceContainerHighest = Color(0xFFE8E8EF);
  static const Color outline = Color(0xFFE8E8EF);
  static const Color outlineVariant = Color(0xFFD4D4DE);

  // Dark surfaces
  static const Color darkPrimary = Color(0xFF9D8DF7);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkBackground = Color(0xFF12121F);
  static const Color darkOnSurface = Color(0xFFE8E8EF);
  static const Color darkOnBackground = Color(0xFFE8E8EF);
  static const Color darkSurfaceAlt = Color(0xFF2A2A3D);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkSurfaceContainerHighest = Color(0xFF2D2D3A);
  static const Color darkOutline = Color(0xFF3A3A4E);
  static const Color darkOutlineVariant = Color(0xFF4A4A5E);
  static const Color darkPrimaryContainer = Color(0xFF3D3566);
  static const Color darkOnPrimaryContainer = Color(0xFFE8E4FD);

  // Semantic (general)
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  /// @deprecated Prefer [positive].
  static const Color success = positive;

  /// @deprecated Prefer [positive].
  static const Color uptrend = positive;

  /// @deprecated Prefer [negative].
  static const Color downtrend = negative;

  // Inverse / scrim
  static const Color inverseSurface = Color(0xFF2D2D3A);
  static const Color onInverseSurface = Color(0xFFF5F5F7);
  static const Color scrim = Color(0x66000000);

  // Skeleton shimmer
  static const Color skeletonBase = Color(0xFFE8E8EF);
  static const Color skeletonHighlight = Color(0xFFF5F5F7);
  static const Color darkSkeletonBase = Color(0xFF2D2D3A);
  static const Color darkSkeletonHighlight = Color(0xFF3A3A4E);
}
