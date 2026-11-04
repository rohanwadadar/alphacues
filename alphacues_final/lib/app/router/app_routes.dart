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
  static const strategy = '/strategy';
  static const newUserKyc = '/new-user-kyc';

  static String watchlistDetail(String id) => '/watchlists/$id';
  static String symbolDetail(String symbol) => '/symbols/$symbol';
}

/// Bottom navigation labels.
abstract final class AppLabels {
  static const dashboard = 'Home';
  static const watchlists = 'Watchlist';
  static const alerts = 'Alerts';
  static const portfolio = 'Portfolio';
  static const screener = 'Screener';
  static const settings = 'Profile';
  static const strategy = 'Strategy';
  static const login = 'Login';
  static const verifyOtp = 'Verify OTP';
  static const notFound = 'Not Found';
  static const retry = 'Retry';
}
