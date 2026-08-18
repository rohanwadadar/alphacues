import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_routes.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/core/widgets/loading_skeleton.dart';
import 'package:frontend/features/dashboard/data/dashboard_providers.dart';
import 'package:frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:frontend/features/watchlist/data/watchlist_providers.dart';

import '../../core/realtime/fake_realtime_socket.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _NoopQuoteSubscriptionManager extends QuoteSubscriptionManager {
  @override
  Set<String> build() => {};

  @override
  void subscribeVisible(List<String> symbols) {}

  @override
  void unsubscribeHidden(List<String> symbols) {}
}

class _LoadingDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSnapshot> build() async {
    final completer = Completer<DashboardSnapshot>();
    ref.onDispose(() {
      if (!completer.isCompleted) {
        completer.completeError(StateError('disposed'));
      }
    });
    return completer.future;
  }
}

class _ErrorDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSnapshot> build() async {
    throw Exception('Dashboard unavailable');
  }
}

DashboardSnapshot _fixtureSnapshot() {
  return DashboardSnapshot(
    topMovers: const [
      MarketMover(symbol: 'AAPL', lastPrice: 188.9, changePercent: 0.66),
      MarketMover(symbol: 'MSFT', lastPrice: 420.5, changePercent: -0.42),
    ],
    portfolio: const PortfolioSummary(
      portfolioId: '12',
      totalValue: 12500.5,
      availableBalance: 0,
      totalProfit: 500.5,
      totalReturn: 4.17,
      dayChange: -125.22,
      asOf: '2026-05-13T14:30:00Z',
    ),
    unreadNotificationCount: 2,
    fetchedAt: DateTime.utc(2026, 5, 13, 14, 30),
  );
}

class _DataDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardSnapshot> build() async => _fixtureSnapshot();
}

class _FixtureWatchlistsNotifier extends WatchlistsNotifier {
  @override
  Future<List<Watchlist>> build() async {
    return const [
      Watchlist(watchlistId: '1', name: 'Tech', symbolCount: 3),
    ];
  }
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required List<Override> overrides,
}) async {
  AppConfig.resetForTest();
  final fakeSocket = FakeRealtimeSocket();
  final store = InMemorySecureTokenStore();
  await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
        quoteSubscriptionManagerProvider.overrideWith(
          _NoopQuoteSubscriptionManager.new,
        ),
        watchlistsProvider.overrideWith(_FixtureWatchlistsNotifier.new),
        secureTokenStoreProvider.overrideWithValue(store),
        socketClientProvider.overrideWith((ref) {
          return SocketClient(
            config: ref.watch(appConfigProvider),
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
        ...overrides,
      ],
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard loading state shows skeleton', (tester) async {
    await _pumpDashboard(
      tester,
      overrides: [
        dashboardProvider.overrideWith(_LoadingDashboardNotifier.new),
      ],
    );

    await tester.pump();

    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.text('Top Movers'), findsNothing);
  });

  testWidgets('dashboard data state shows all summary sections', (tester) async {
    await _pumpDashboard(
      tester,
      overrides: [
        dashboardProvider.overrideWith(_DataDashboardNotifier.new),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Top Movers'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
    expect(find.text('Watchlists'), findsOneWidget);
    expect(find.text('Tech'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Total value'), findsOneWidget);
  });

  testWidgets('dashboard error state shows retry banner', (tester) async {
    await _pumpDashboard(
      tester,
      overrides: [
        dashboardProvider.overrideWith(_ErrorDashboardNotifier.new),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text(AppLabels.retry), findsWidgets);
    expect(find.textContaining('Dashboard unavailable'), findsWidgets);
  });
}
