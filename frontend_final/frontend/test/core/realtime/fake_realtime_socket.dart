import 'package:frontend/core/realtime/socket_client.dart';

typedef RealtimeEventHandler = void Function(dynamic data);

class FakeRealtimeSocket implements RealtimeSocket {
  FakeRealtimeSocket({
    this.reconnectionDelay = SocketClient.reconnectionDelayMs,
    this.reconnectionDelayMax = SocketClient.reconnectionDelayMaxMs,
  });

  final Map<String, List<RealtimeEventHandler>> _handlers = {};
  final List<(String event, dynamic data)> emitted = [];

  @override
  bool? connected;
  @override
  int? reconnectionDelay;
  @override
  int? reconnectionDelayMax;

  FakeRealtimeSocket initDelays({
    required int reconnectionDelay,
    required int reconnectionDelayMax,
  }) {
    this.reconnectionDelay = reconnectionDelay;
    this.reconnectionDelayMax = reconnectionDelayMax;
    return this;
  }

  @override
  void connect() {
    connected = true;
    simulateEvent('connect', null);
  }

  @override
  void disconnect() {
    connected = false;
    simulateEvent('disconnect', null);
  }

  void simulateReconnectAttempt() {
    simulateEvent('reconnect_attempt', null);
  }

  void simulateConnectError(Object error) {
    simulateEvent('connect_error', error);
  }

  void simulateEvent(String event, dynamic data) {
    final handlers = [...?_handlers[event]];
    for (final handler in handlers) {
      handler(data);
    }
  }

  @override
  void dispose() {
    connected = null;
    _handlers.clear();
  }

  @override
  void emit(String event, dynamic data) {
    emitted.add((event, data));
  }

  @override
  void on(String event, RealtimeEventHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  @override
  void off(String event) {
    _handlers.remove(event);
  }
}
