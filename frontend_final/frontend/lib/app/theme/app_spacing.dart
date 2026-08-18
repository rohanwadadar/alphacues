/// Spacing tokens on an 8px grid.
abstract final class AppSpacing {
  AppSpacing._();

  /// Tight gaps inside components.
  static const double xs = 4.0;

  /// Padding inside chips, small gaps.
  static const double sm = 8.0;

  /// Standard screen padding.
  static const double md = 16.0;

  /// Section spacing.
  static const double lg = 24.0;

  /// Large section gaps.
  static const double xl = 32.0;

  /// Hero spacing.
  static const double xxl = 48.0;
}

/// Border radius tokens.
abstract final class AppRadius {
  AppRadius._();

  /// Small chips.
  static const double sm = 4.0;

  /// Cards, buttons.
  static const double md = 8.0;

  /// Bottom sheets.
  static const double lg = 12.0;

  /// Modals.
  static const double xl = 16.0;

  /// Pills, tags.
  static const double full = 999.0;
}
