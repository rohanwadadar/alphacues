import 'package:go_router/go_router.dart';

/// Public routes that do not require authentication.
const unauthenticatedRoutes = <String>{'/login', '/verify-otp'};

/// Routes that require an active session.
const authenticatedRoutes = <String>{
  '/dashboard',
  '/watchlists',
  '/alerts',
  '/portfolio',
  '/screener',
  '/settings',
};

bool isAuthenticatedRoute(String path) {
  if (authenticatedRoutes.contains(path)) {
    return true;
  }
  if (path.startsWith('/watchlists/')) {
    return true;
  }
  if (path.startsWith('/symbols/')) {
    return true;
  }
  return false;
}

bool isUnauthenticatedRoute(String path) {
  return unauthenticatedRoutes.contains(path);
}

/// Pure redirect logic for tests and [GoRouter.redirect].
String? computeRouteRedirect({
  required String matchedPath,
  required String fullPath,
  required bool isAuthenticated,
  required bool enableScreener,
  bool isLoading = false,
}) {
  final path = matchedPath.isEmpty ? fullPath : matchedPath;

  if (isLoading) {
    return null;
  }

  if (!enableScreener && (path == '/screener' || fullPath == '/screener')) {
    return isAuthenticated ? '/dashboard' : '/login';
  }

  if (isAuthenticated && isUnauthenticatedRoute(path)) {
    return '/dashboard';
  }

  if (!isAuthenticated && isAuthenticatedRoute(path)) {
    return '/login';
  }

  if (path == '/') {
    return isAuthenticated ? '/dashboard' : '/login';
  }

  return null;
}

/// [GoRouter] redirect callback wired to session and feature flags.
String? routeGuardRedirect(
  GoRouterState state, {
  required bool isAuthenticated,
  required bool enableScreener,
  bool isLoading = false,
}) {
  return computeRouteRedirect(
    matchedPath: state.matchedLocation,
    fullPath: state.uri.path,
    isAuthenticated: isAuthenticated,
    enableScreener: enableScreener,
    isLoading: isLoading,
  );
}
