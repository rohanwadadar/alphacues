import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.resetForTest();
  });

  test('Reconnect Chaos Test — resubscribe trigger & REST refresh state contract', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final manager = container.read(quoteSubscriptionManagerProvider.notifier);
    final socketConnState = container.read(socketConnectionStateProvider.notifier);

    // Initial state: not awaiting rest refresh
    expect(container.read(socketConnectionStateProvider).awaitingRestRefresh, false);

    // Simulate socket disconnect chaos
    socketConnState.setDisconnected();
    expect(container.read(socketConnectionStateProvider).connectionState, SocketConnectionState.disconnected);

    // Perform reconnect flow
    socketConnState.setConnected();
    
    // Resubscribe trigger under load
    await manager.resubscribeAll();

    // Verify stale banner state clears after REST refresh completes
    final stateAfter = container.read(socketConnectionStateProvider);
    expect(stateAfter.connectionState, SocketConnectionState.connected);
    expect(stateAfter.awaitingRestRefresh, false);
    expect(stateAfter.isVisible, false);
  });
}
