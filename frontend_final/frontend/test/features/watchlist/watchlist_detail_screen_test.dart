import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/features/watchlist/data/watchlist_repository.dart';
import 'package:frontend/features/watchlist/data/watchlist_providers.dart';
import 'package:frontend/features/watchlist/presentation/watchlist_detail_screen.dart';

import '../../core/realtime/fake_realtime_socket.dart';

class _DuplicateSymbolRepository extends WatchlistRepository {
  _DuplicateSymbolRepository() : super(Dio());

  @override
  Future<WatchlistDetail> getWatchlist(String watchlistId) async {
    return const WatchlistDetail(
      watchlistId: '1',
      name: 'Tech',
      items: [WatchlistItem(symbol: 'AAPL')],
    );
  }

  @override
  Future<void> addSymbol(String watchlistId, String symbol) async {
    throw const DuplicateSymbolException(
      'AAPL is already in this watchlist.',
    );
  }
}

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _NoopQuoteSubscriptionManager extends QuoteSubscriptionManager {
  @override
  Set<String> build() => {};
}

void main() {
  testWidgets('shows duplicate symbol inline error without navigating away', (
    tester,
  ) async {
    AppConfig.resetForTest();
    final fakeSocket = FakeRealtimeSocket();
    final store = InMemorySecureTokenStore();
    await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistRepositoryProvider.overrideWithValue(
            _DuplicateSymbolRepository(),
          ),
          connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
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
        child: const MaterialApp(
          home: WatchlistDetailScreen(watchlistId: '1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'AAPL');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('AAPL is already in this watchlist.'), findsOneWidget);
    expect(find.byType(WatchlistDetailScreen), findsOneWidget);
  });
}
