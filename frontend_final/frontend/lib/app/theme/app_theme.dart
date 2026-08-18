import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material 3 theme for Alpha Cues.
abstract final class AppTheme {
  static const double minTouchTarget = 48;

  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    scaffoldBackground: AppColors.background,
    textTheme: AppTypography.light,
    appBarBackground: AppColors.surface,
    appBarForeground: AppColors.onSurface,
    navBarBackground: AppColors.surface,
    navIndicator: AppColors.primaryContainer,
    navSelectedColor: AppColors.primaryText,
    navUnselectedIcon: AppColors.onSurfaceVariant,
    buttonBackground: AppColors.primary,
    buttonForeground: AppColors.onPrimary,
    textButtonColor: AppColors.primaryText,
    inputFill: AppColors.surfaceAlt,
    cardColor: AppColors.surface,
    dividerColor: AppColors.outline,
    overlayStyle: SystemUiOverlayStyle.dark,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    scaffoldBackground: AppColors.darkBackground,
    textTheme: AppTypography.dark,
    appBarBackground: AppColors.darkSurface,
    appBarForeground: AppColors.darkOnSurface,
    navBarBackground: AppColors.darkSurface,
    navIndicator: AppColors.darkPrimaryContainer,
    navSelectedColor: AppColors.darkPrimary,
    navUnselectedIcon: AppColors.darkOnSurfaceVariant,
    buttonBackground: AppColors.darkPrimary,
    buttonForeground: AppColors.darkBackground,
    textButtonColor: AppColors.darkPrimary,
    inputFill: AppColors.darkSurfaceAlt,
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkOutline,
    overlayStyle: SystemUiOverlayStyle.light,
  );

  static ColorScheme get _lightColorScheme {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );
  }

  static ColorScheme get _darkColorScheme {
    return ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkBackground,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required TextTheme textTheme,
    required Color appBarBackground,
    required Color appBarForeground,
    required Color navBarBackground,
    required Color navIndicator,
    required Color navSelectedColor,
    required Color navUnselectedIcon,
    required Color buttonBackground,
    required Color buttonForeground,
    required Color textButtonColor,
    required Color inputFill,
    required Color cardColor,
    required Color dividerColor,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: overlayStyle,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBackground,
        indicatorColor: navIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelMedium?.copyWith(color: navSelectedColor);
          }
          return textTheme.labelMedium;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: navSelectedColor);
          }
          return IconThemeData(color: navUnselectedIcon);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          backgroundColor: buttonBackground,
          foregroundColor: buttonForeground,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: textButtonColor,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: textButtonColor,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: textButtonColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: buttonBackground, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(color: dividerColor),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: dividerColor),
        ),
      ),
    );
  }
}
