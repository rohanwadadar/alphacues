import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/realtime/socket_events.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/core/widgets/stale_banner.dart';
import 'package:frontend/features/watchlist/data/watchlist_providers.dart';

import '../../features/auth/mock_http_adapter.dart';
import 'fake_realtime_socket.dart';

void main() {
  testWidgets(
    'disconnect → reconnect → REST refresh keeps banner until response resolves',
    (tester) async {
      AppConfig.resetForTest();
      final fake = FakeRealtimeSocket();
      final store = InMemorySecureTokenStore();
      await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

      final completer = Completer<void>();
      final adapter = MockHttpAdapter(
        responses: [
          MockResponse(
            body: {
              'success': true,
              'data': {
                'watchlistId': 'wl-1',
                'name': 'Tech',
                'symbols': ['AAPL'],
              },
              'error': null,
              'meta': {'requestId': 'r1', 'apiVersion': '1'},
            },
            beforeRespond: completer.future,
          ),
        ],
      );

      final dio = Dio(BaseOptions(baseUrl: AppConfig.instance.apiBaseUrl));
      dio.httpClientAdapter = adapter;

      var resubscribeOnConnect = false;
      Future<void>? pendingRefresh;
      late ProviderContainer container;
      container = ProviderContainer(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(store),
          dioProvider.overrideWithValue(dio),
          socketClientProvider.overrideWith((ref) {
            return SocketClient(
              config: AppConfig.instance,
              tokenStore: store,
              connectionNotifier: ref.read(
                socketConnectionStateProvider.notifier,
              ),
              onConnected: () {
                if (!resubscribeOnConnect) {
                  return;
                }
                pendingRefresh = container
                    .read(quoteSubscriptionManagerProvider.notifier)
                    .resubscribeAll();
              },
              socketFactory: ({required url, required auth}) => fake,
              connectivity: null,
              watchConnectivity: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      container.read(quoteSubscriptionManagerProvider.notifier).state = {
        'AAPL',
      };

      final client = container.read(socketClientProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: StaleBanner()),
          ),
        ),
      );

      await client.connect();
      await tester.pump();
      expect(find.text(StaleBanner.reconnectingText), findsNothing);

      resubscribeOnConnect = true;
      container.read(activeWatchlistIdsProvider.notifier).track('wl-1');

      fake.disconnect();
      await tester.pump();
      expect(find.text(StaleBanner.reconnectingText), findsOneWidget);

      fake.connect();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        adapter.requests.where((r) => r.path == '/api/v1/watchlist/wl-1').length,
        1,
      );
      expect(find.text(StaleBanner.reconnectingText), findsOneWidget);
      expect(
        container.read(socketConnectionStateProvider).awaitingRestRefresh,
        isTrue,
      );

      expect(pendingRefresh, isNotNull);
      completer.complete();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (!container.read(socketConnectionStateProvider).awaitingRestRefresh) {
          break;
        }
      }
      expect(find.text(StaleBanner.reconnectingText), findsNothing);

      expect(
        fake.emitted.where((e) => e.$1 == kSubscribeQuotes).length,
        greaterThanOrEqualTo(1),
      );
      expect(
        fake.emitted.any((e) => e.$1 == kSubscribeNotifications),
        isTrue,
      );
    },
  );
}
