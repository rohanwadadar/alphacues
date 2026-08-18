import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_session_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/presentation/not_found_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/verify_otp_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/market/presentation/symbol_detail_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import '../../features/screener/presentation/screener_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/watchlist/presentation/watchlist_detail_screen.dart';
import '../../features/watchlist/presentation/watchlists_screen.dart';
import 'app_routes.dart';
import 'authenticated_shell.dart';
import 'route_guards.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Notifies GoRouter when auth state changes so it re-runs redirects
/// without recreating the router instance.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(authSessionProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

List<RouteBase> _buildRoutes(bool enableScreener) {
  final branches = <StatefulShellBranch>[
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          name: 'dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.watchlists,
          name: 'watchlists',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: WatchlistsScreen()),
          routes: [
            GoRoute(
              path: ':watchlistId',
              name: 'watchlistDetail',
              parentNavigatorKey: _rootNavigatorKey,
              pageBuilder: (context, state) => NoTransitionPage(
                child: WatchlistDetailScreen(
                  watchlistId: state.pathParameters['watchlistId'] ?? '',
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: AppRoutes.portfolio,
          name: 'portfolio',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PortfolioScreen()),
        ),
      ],
    ),
    if (enableScreener)
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.screener,
            name: 'screener',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ScreenerScreen()),
          ),
        ],
      ),
  ];

  return <RouteBase>[
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.verifyOtp,
      name: 'verifyOtp',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: VerifyOtpScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AuthenticatedShell(navigationShell: navigationShell),
      branches: branches,
    ),
    GoRoute(
      path: AppRoutes.alerts,
      name: 'alerts',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: AlertsScreen()),
    ),
    GoRoute(
      path: '/symbols/:symbol',
      name: 'symbolDetail',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => NoTransitionPage(
        child: SymbolDetailScreen(symbol: state.pathParameters['symbol'] ?? ''),
      ),
    ),
    if (!enableScreener)
      GoRoute(
        path: AppRoutes.screener,
        redirect: (context, state) {
          // screener disabled — always redirect away
          return '/dashboard';
        },
      ),
  ];
}

/// Kept for unit tests that call createAppRouter directly.
GoRouter createAppRouter({
  required bool isAuthenticated,
  required bool enableScreener,
  bool isLoading = false,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    redirect: (context, state) => routeGuardRedirect(
      state,
      isAuthenticated: isAuthenticated,
      enableScreener: enableScreener,
      isLoading: isLoading,
    ),
    routes: _buildRoutes(enableScreener),
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final config = AppConfig.instance;

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: _AuthNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authSessionProvider);
      return routeGuardRedirect(
        state,
        isAuthenticated: authState.isAuthenticated,
        enableScreener: config.enableScreener,
        isLoading: authState.isLoading,
      );
    },
    routes: _buildRoutes(config.enableScreener),
    errorBuilder: (context, state) => const NotFoundScreen(),
  );

  return router;
});