import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/features/dashboard/data/dashboard_providers.dart';
import 'package:frontend/features/watchlist/data/watchlist_providers.dart';
import 'package:frontend/features/notifications/data/notifications_notifier.dart';

import '../core/realtime/fake_realtime_socket.dart';

AuthSession testAuthSession({String userId = 'user-1'}) {
  return AuthSession(
    user: AuthUser(userId: userId, email: 'test@example.com'),
  );
}

class _FixedAuthSessionNotifier extends AuthSessionNotifier {
  _FixedAuthSessionNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> bootstrapSession() async {}
}

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _EmptyNotificationsNotifier extends NotificationsNotifier {
  @override
  Future<List<NotificationModel>> build() async => const [];
}

class _NoopQuoteSubscriptionManager extends QuoteSubscriptionManager {
  @override
  Set<String> build() => {};

  @override
  void subscribeVisible(List<String> symbols) {}

  @override
  void unsubscribeHidden(List<String> symbols) {}

  @override
  Future<void> resubscribeAll() async {}
}

class _FixtureWatchlistsNotifier extends WatchlistsNotifier {
  @override
  Future<List<Watchlist>> build() async {
    return const [];
  }
}

class _FixtureDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSnapshot> build() async {
    return DashboardSnapshot(
      topMovers: const [],
      unreadNotificationCount: 0,
      fetchedAt: DateTime.now().toUtc(),
    );
  }
}

Future<void> pumpTestApp(
  WidgetTester tester, {
  required AuthSession? session,
  required bool enableScreener,
  String initialLocation = '/dashboard',
}) async {
  AppConfig.resetForTest(enableScreener: enableScreener);

  final authState = session == null
      ? AuthState.unauthenticated
      : AuthState(status: AuthStatus.authenticated, session: session);

  final router = createAppRouter(
    isAuthenticated: authState.isAuthenticated,
    enableScreener: enableScreener,
  );

  final store = InMemorySecureTokenStore();
  final fakeSocket = FakeRealtimeSocket();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authSessionProvider.overrideWith(
          () => _FixedAuthSessionNotifier(authState),
        ),
        connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
        quoteSubscriptionManagerProvider.overrideWith(
          _NoopQuoteSubscriptionManager.new,
        ),
        watchlistsProvider.overrideWith(_FixtureWatchlistsNotifier.new),
        dashboardProvider.overrideWith(_FixtureDashboardNotifier.new),
        notificationsProvider.overrideWith(_EmptyNotificationsNotifier.new),
        secureTokenStoreProvider.overrideWithValue(store),
        socketClientProvider.overrideWith((ref) {
          return SocketClient(
            config: AppConfig.instance,
            tokenStore: store,
            connectionNotifier: ref.read(
              socketConnectionStateProvider.notifier,
            ),
            onConnected: () {},
            socketFactory: ({required url, required auth}) => fakeSocket,
            connectivity: null,
            watchConnectivity: false,
          );
        }),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  router.go(initialLocation);
  await tester.pump();
}
