import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/features/dashboard/data/dashboard_repository.dart';
import 'package:frontend/features/portfolio/data/portfolio_providers.dart';
import 'package:frontend/features/portfolio/presentation/portfolio_screen.dart';

import '../../core/realtime/fake_realtime_socket.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _EmptyTransactionsNotifier extends PortfolioTransactionsNotifier {
  @override
  Future<List<PortfolioEvent>> build() async => const [];
}

class _LoadedSummaryNotifier extends PortfolioSummaryNotifier {
  @override
  Future<PortfolioOverview> build() async {
    return PortfolioOverview(
      summary: PortfolioSummary(
        portfolioId: '1',
        totalValue: 0,
        availableBalance: 0,
        totalProfit: 0,
        totalReturn: 0,
        dayChange: 0,
        asOf: DateTime.now().toUtc().toIso8601String(),
      ),
      positions: const [],
    );
  }
}

class _ErrorThenSuccessPortfolioRepository extends PortfolioRepository {
  _ErrorThenSuccessPortfolioRepository() : super(Dio());

  int summaryCalls = 0;

  @override
  Future<PortfolioOverview> getPortfolioSummary() async {
    summaryCalls++;

    if (summaryCalls == 1) {
      throw Exception('Unable to load portfolio');
    }

    return PortfolioOverview(
      summary: PortfolioSummary(
        portfolioId: '1',
        totalValue: 0,
        availableBalance: 0,
        totalProfit: 0,
        totalReturn: 0,
        dayChange: 0,
        asOf: DateTime.now().toUtc().toIso8601String(),
      ),
      positions: const [],
    );
  }
}

class _NoopQuoteSubscriptionManager extends QuoteSubscriptionManager {
  @override
  Set<String> build() => {};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty state when there are no transactions', (
    tester,
  ) async {
    AppConfig.resetForTest();

    final fakeSocket = FakeRealtimeSocket();
    final store = InMemorySecureTokenStore();

    await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
          portfolioSummaryProvider.overrideWith(_LoadedSummaryNotifier.new),
          portfolioTransactionsProvider.overrideWith(
            _EmptyTransactionsNotifier.new,
          ),
          quoteSubscriptionManagerProvider.overrideWith(
            _NoopQuoteSubscriptionManager.new,
          ),
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
        ],
        child: const MaterialApp(home: PortfolioScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No holdings yet'), findsOneWidget);
    expect(find.text('Add transaction'), findsWidgets);
  });

  testWidgets('shows Retry on initial error and loads after retry', (
    tester,
  ) async {
    AppConfig.resetForTest();

    final fakeSocket = FakeRealtimeSocket();
    final store = InMemorySecureTokenStore();
    final repository = _ErrorThenSuccessPortfolioRepository();

    await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
          portfolioRepositoryProvider.overrideWithValue(repository),
          portfolioTransactionsProvider.overrideWith(
            _EmptyTransactionsNotifier.new,
          ),
          quoteSubscriptionManagerProvider.overrideWith(
            _NoopQuoteSubscriptionManager.new,
          ),
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
        ],
        child: const MaterialApp(home: PortfolioScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.summaryCalls, 1);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('Unable to load portfolio'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.summaryCalls, 2);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('No holdings yet'), findsOneWidget);
    expect(find.text('Add transaction'), findsWidgets);
  });
}
