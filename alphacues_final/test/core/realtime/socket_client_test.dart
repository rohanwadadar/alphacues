import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/realtime/socket_events.dart';
import 'package:frontend/core/storage/secure_token_store.dart';

import 'fake_realtime_socket.dart';

void main() {
  setUp(() {
    AppConfig.resetForTest(socketBaseUrl: 'https://api.test.com');
  });

  group('reconnectionDelayForAttempt', () {
    test('uses the socket backoff and caps at 3 s', () {
      expect(
        reconnectionDelayForAttempt(attempt: 1),
        SocketClient.reconnectionDelayMs,
      );
      expect(reconnectionDelayForAttempt(attempt: 2), 1000);
      expect(reconnectionDelayForAttempt(attempt: 3), 2000);
      expect(reconnectionDelayForAttempt(attempt: 4), 3000);
      expect(reconnectionDelayForAttempt(attempt: 5), 3000);
      expect(reconnectionDelayForAttempt(attempt: 6), 3000);
      expect(reconnectionDelayForAttempt(attempt: 10), 3000);
      expect(
        reconnectionDelayForAttempt(attempt: 99),
        SocketClient.reconnectionDelayMaxMs,
      );
    });
  });

  group('SocketClient reconnect', () {
    test('simulated disconnect drives reconnecting then disconnected states', () async {
      final fake = FakeRealtimeSocket();
      final store = InMemorySecureTokenStore();
      await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');

      final container = ProviderContainer(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(store),
          socketClientProvider.overrideWith((ref) {
            return SocketClient(
              config: AppConfig.instance,
              tokenStore: store,
              connectionNotifier: ref.read(
                socketConnectionStateProvider.notifier,
              ),
              onConnected: () {},
              socketFactory: ({required url, required auth}) => fake,
              connectivity: null,
              watchConnectivity: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(socketClientProvider);
      final connectionNotifier = container.read(
        socketConnectionStateProvider.notifier,
      );

      await client.connect();
      expect(connectionNotifier.isConnected, isTrue);

      fake.simulateReconnectAttempt();
      expect(
        container.read(socketConnectionStateProvider).connectionState,
        SocketConnectionState.reconnecting,
      );

      fake.disconnect();
      expect(
        container.read(socketConnectionStateProvider).connectionState,
        SocketConnectionState.disconnected,
      );
    });

    test('on connect after reconnect, resubscribeAll is called exactly once', () async {
      final fake = FakeRealtimeSocket();
      final store = InMemorySecureTokenStore();
      await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');

      var resubscribeCount = 0;
      late ProviderContainer container;
      container = ProviderContainer(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(store),
          socketClientProvider.overrideWith((ref) {
            return SocketClient(
              config: AppConfig.instance,
              tokenStore: store,
              connectionNotifier: ref.read(
                socketConnectionStateProvider.notifier,
              ),
              onConnected: () {
                resubscribeCount++;
                unawaited(
                  container
                      .read(quoteSubscriptionManagerProvider.notifier)
                      .resubscribeAll(),
                );
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
        'MSFT',
        'GOOGL',
      };

      final client = container.read(socketClientProvider);
      await client.connect();
      await Future<void>.delayed(Duration.zero);
      expect(resubscribeCount, 1);
      expect(
        fake.emitted.where((e) => e.$1 == kSubscribeQuotes).length,
        greaterThanOrEqualTo(1),
      );
      expect(
        fake.emitted.any((e) => e.$1 == kSubscribeNotifications),
        isTrue,
      );

      fake.disconnect();
      fake.connect();
      await Future<void>.delayed(Duration.zero);
      expect(resubscribeCount, 2);
    });

    test('app resume replaces a socket that still reports connected', () async {
      final sockets = <FakeRealtimeSocket>[];
      final store = InMemorySecureTokenStore();
      await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');

      final container = ProviderContainer(
        overrides: [
          secureTokenStoreProvider.overrideWithValue(store),
          socketClientProvider.overrideWith((ref) {
            return SocketClient(
              config: AppConfig.instance,
              tokenStore: store,
              connectionNotifier: ref.read(
                socketConnectionStateProvider.notifier,
              ),
              onConnected: () {},
              socketFactory: ({required url, required auth}) {
                final socket = FakeRealtimeSocket();
                sockets.add(socket);
                return socket;
              },
              connectivity: null,
              watchConnectivity: false,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      final client = container.read(socketClientProvider);
      await client.connect();
      expect(sockets, hasLength(1));
      expect(sockets.single.connected, isTrue);

      await client.handleAppResumed();

      expect(sockets, hasLength(2));
      expect(sockets.first.connected, isNull);
      expect(sockets.last.connected, isTrue);
      expect(client.isConnected, isTrue);
    });
  });
}
