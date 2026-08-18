import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/realtime/socket_events.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/features/alerts/data/alerts_providers.dart';
import 'package:frontend/features/notifications/data/notifications_notifier.dart';

import '../../core/realtime/fake_realtime_socket.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _MockNotificationsRepository extends NotificationsRepository {
  _MockNotificationsRepository() : super(Dio());

  @override
  Future<({List<NotificationModel> items, String? nextCursor})> listNotifications({
    String? cursor,
    int limit = 20,
  }) async {
    return (items: const <NotificationModel>[], nextCursor: null);
  }
}

class _MockAlertsRepository extends AlertsRepository {
  _MockAlertsRepository() : super(Dio());

  @override
  Future<List<AlertModel>> listAlerts() async => const [];
}

class _CountingAlertsNotifier extends AlertsNotifier {
  _CountingAlertsNotifier(this.onBuild);

  final VoidCallback onBuild;

  @override
  Future<List<AlertModel>> build() async {
    onBuild();
    return const [];
  }
}

class _NoopQuoteSubscriptionManager extends QuoteSubscriptionManager {
  @override
  Set<String> build() => {};

  @override
  Future<void> resubscribeAll() async {}
}

ProviderContainer _createContainer({
  required FakeRealtimeSocket fakeSocket,
  required InMemorySecureTokenStore store,
  List<Override> overrides = const [],
}) {
  return ProviderContainer(
    overrides: [
      connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
      notificationsRepositoryProvider.overrideWithValue(
        _MockNotificationsRepository(),
      ),
      alertsRepositoryProvider.overrideWithValue(_MockAlertsRepository()),
      secureTokenStoreProvider.overrideWithValue(store),
      quoteSubscriptionManagerProvider.overrideWith(
        _NoopQuoteSubscriptionManager.new,
      ),
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
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.resetForTest(socketBaseUrl: 'https://api.test.com');
  });

  test('notification_new prepends unread notification at index 0', () async {
    final fakeSocket = FakeRealtimeSocket();
    final store = InMemorySecureTokenStore();
    await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');

    final container = _createContainer(fakeSocket: fakeSocket, store: store);
    addTearDown(container.dispose);

    await container.read(notificationsProvider.future);
    await container.read(socketClientProvider).connect();

    fakeSocket.simulateEvent(
      kNotificationNew,
      {
        'notificationId': '456',
        'alertId': '123',
        'title': 'AAPL crossed above 190.00',
        'body': 'Your AAPL ABOVE alert was triggered.',
        'createdAt': '2026-05-13T14:30:02Z',
      },
    );
    await Future<void>.delayed(Duration.zero);

    final items = container.read(notificationsProvider).value!;
    expect(items.length, 1);
    expect(items.first.notificationId, '456');
    expect(items.first.isRead, isFalse);
    expect(items.first.title, 'AAPL crossed above 190.00');
  });

  test('alert_triggered invalidates alertsProvider', () async {
    final fakeSocket = FakeRealtimeSocket();
    final store = InMemorySecureTokenStore();
    await store.writeTokens(accessToken: 'token', refreshToken: 'refresh');

    var alertsBuildCount = 0;
    final container = _createContainer(
      fakeSocket: fakeSocket,
      store: store,
      overrides: [
        alertsProvider.overrideWith(
          () => _CountingAlertsNotifier(() => alertsBuildCount++),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(notificationsProvider.future);
    await container.read(socketClientProvider).connect();
    final buildsBefore = alertsBuildCount;

    fakeSocket.simulateEvent(kAlertTriggered, {'alertId': '123'});
    await Future<void>.delayed(Duration.zero);
    await container.read(alertsProvider.future);

    expect(alertsBuildCount, greaterThan(buildsBefore));
  });
}
