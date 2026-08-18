/// Canonical route path constants for deep links and navigation.
abstract final class AppRoutes {
  static const login = '/login';
  static const verifyOtp = '/verify-otp';
  static const dashboard = '/dashboard';
  static const watchlists = '/watchlists';
  static const alerts = '/alerts';
  static const portfolio = '/portfolio';
  static const screener = '/screener';
  static const settings = '/settings';

  static String watchlistDetail(String id) => '/watchlists/$id';
  static String symbolDetail(String symbol) => '/symbols/$symbol';
}

/// Bottom navigation labels.
abstract final class AppLabels {
  static const dashboard = 'Dashboard';
  static const watchlists = 'Watchlists';
  static const alerts = 'Alerts';
  static const portfolio = 'Portfolio';
  static const screener = 'Screener';
  static const settings = 'Settings';
  static const login = 'Login';
  static const verifyOtp = 'Verify OTP';
  static const notFound = 'Not Found';
  static const retry = 'Retry';
}
