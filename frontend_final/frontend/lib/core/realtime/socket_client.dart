import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import 'quote_subscription_manager.dart';
import 'socket_events.dart';

typedef RealtimeEventHandler = void Function(dynamic data);

/// Socket connection lifecycle states.
enum SocketConnectionState {
  connected,
  connecting,
  disconnected,
  reconnecting,
}

/// Whether the stale connection banner should be visible.
class StaleBannerState {
  const StaleBannerState({
    required this.connectionState,
    required this.awaitingRestRefresh,
  });

  final SocketConnectionState connectionState;
  final bool awaitingRestRefresh;

  bool get isVisible =>
      connectionState != SocketConnectionState.connected ||
      awaitingRestRefresh;

  /// Amber while reconnecting; red when fully disconnected.
  bool get isAmber =>
      connectionState == SocketConnectionState.reconnecting ||
      (connectionState == SocketConnectionState.connected &&
          awaitingRestRefresh);

  bool get isRed => connectionState == SocketConnectionState.disconnected;
}

/// Tracks socket connection state and post-reconnect REST refresh gating.
class SocketConnectionNotifier extends Notifier<StaleBannerState> {
  @override
  StaleBannerState build() {
    return const StaleBannerState(
      connectionState: SocketConnectionState.disconnected,
      awaitingRestRefresh: false,
    );
  }

  SocketConnectionState get connectionState => state.connectionState;

  bool get isConnected =>
      state.connectionState == SocketConnectionState.connected;

  bool get awaitingRestRefresh => state.awaitingRestRefresh;

  void setConnecting() {
    state = StaleBannerState(
      connectionState: SocketConnectionState.connecting,
      awaitingRestRefresh: state.awaitingRestRefresh,
    );
  }

  void setConnected({bool clearRestRefresh = false}) {
    state = StaleBannerState(
      connectionState: SocketConnectionState.connected,
      awaitingRestRefresh: clearRestRefresh ? false : state.awaitingRestRefresh,
    );
  }

  void setDisconnected() {
    state = const StaleBannerState(
      connectionState: SocketConnectionState.disconnected,
      awaitingRestRefresh: false,
    );
  }

  void setReconnecting() {
    state = StaleBannerState(
      connectionState: SocketConnectionState.reconnecting,
      awaitingRestRefresh: state.awaitingRestRefresh,
    );
  }

  void syncFromServer(String status) {
    final mapped = _mapServerStatus(status);
    if (mapped == null) {
      return;
    }
    state = StaleBannerState(
      connectionState: mapped,
      awaitingRestRefresh: state.awaitingRestRefresh,
    );
  }

  void setAwaitingRestRefresh(bool value) {
    if (state.awaitingRestRefresh == value) {
      return;
    }
    state = StaleBannerState(
      connectionState: state.connectionState,
      awaitingRestRefresh: value,
    );
  }

  void completeRestRefresh() {
    state = StaleBannerState(
      connectionState: state.connectionState,
      awaitingRestRefresh: false,
    );
  }

  static SocketConnectionState? _mapServerStatus(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
        return SocketConnectionState.connected;
      case 'connecting':
        return SocketConnectionState.connecting;
      case 'disconnected':
        return SocketConnectionState.disconnected;
      case 'reconnecting':
        return SocketConnectionState.reconnecting;
      default:
        return null;
    }
  }
}

final socketConnectionStateProvider =
    NotifierProvider<SocketConnectionNotifier, StaleBannerState>(
      SocketConnectionNotifier.new,
    );

/// Computes exponential reconnection delay capped at [reconnectionDelayMax].
@visibleForTesting
int reconnectionDelayForAttempt({
  required int attempt,
  int reconnectionDelay = 1000,
  int reconnectionDelayMax = 30000,
}) {
  final delay = reconnectionDelay * (1 << (attempt - 1).clamp(0, 30));
  return delay.clamp(reconnectionDelay, reconnectionDelayMax);
}

/// Abstraction over socket_io_client for tests.
abstract class RealtimeSocket {
  bool? get connected;
  int? get reconnectionDelay;
  int? get reconnectionDelayMax;

  void connect();
  void disconnect();
  void dispose();
  void emit(String event, dynamic data);
  void on(String event, RealtimeEventHandler handler);
  void off(String event);
}

typedef SocketFactory =
    RealtimeSocket Function({
      required String url,
      required Map<String, dynamic> auth,
    });

/// Wraps socket_io_client with auth, lifecycle, and event routing.
class SocketClient {
  SocketClient({
    required AppConfig config,
    required SecureTokenStore tokenStore,
    required SocketConnectionNotifier connectionNotifier,
    required void Function() onConnected,
    SocketFactory? socketFactory,
    Connectivity? connectivity,
    bool watchConnectivity = true,
  }) : _config = config,
       _tokenStore = tokenStore,
       _connectionNotifier = connectionNotifier,
       _onConnected = onConnected,
       _socketFactory = socketFactory ?? _defaultSocketFactory,
       _connectivity = connectivity ?? Connectivity(),
       _watchConnectivity = watchConnectivity && connectivity != null;

  static const reconnectionDelayMs = 1000;
  static const reconnectionDelayMaxMs = 30000;
  static const reconnectionAttempts = 10;

  final AppConfig _config;
  final SecureTokenStore _tokenStore;
  final SocketConnectionNotifier _connectionNotifier;
  final void Function() _onConnected;
  final SocketFactory _socketFactory;
  final Connectivity _connectivity;
  final bool _watchConnectivity;

  RealtimeSocket? _socket;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  final _quoteUpdates = StreamController<QuoteUpdatePayload>.broadcast();
  final _notifications = StreamController<NotificationNewPayload>.broadcast();
  final _alertTriggered = StreamController<Map<String, dynamic>>.broadcast();

  Stream<QuoteUpdatePayload> get quoteUpdates => _quoteUpdates.stream;

  Stream<NotificationNewPayload> get notifications => _notifications.stream;

  Stream<Map<String, dynamic>> get alertTriggered => _alertTriggered.stream;
  bool get isConnected => _connectionNotifier.isConnected;

  /// Thin wrapper around socket.emit.
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  /// Called by [SocketLifecycleBridge] when the app returns to foreground.
  void handleAppResumed() {
    // TODO: On app resume, reconnect and re-subscribe from scratch.
    // Do not assume a persistent background WebSocket on mobile.
    if (_connectionNotifier.connectionState ==
        SocketConnectionState.disconnected) {
      unawaited(connect());
    }
  }

  Future<void> connect() async {
    if (_connectionNotifier.connectionState ==
        SocketConnectionState.connecting) {
      return;
    }

    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    _connectionNotifier.setConnecting();
    _ensureConnectivityWatch();

    _socket?.dispose();
    _socket = _socketFactory(
      url: '${_config.socketBaseUrl}/stream',
      auth: {'token': accessToken},
    );
    _wireSocketHandlers(_socket!);
    _socket!.connect();
  }

  void disconnect() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionNotifier.setDisconnected();
  }

  void dispose() {
    disconnect();
    unawaited(_quoteUpdates.close());
    unawaited(_notifications.close());
    unawaited(_alertTriggered.close());
  }

  void _ensureConnectivityWatch() {
    if (!_watchConnectivity) {
      return;
    }
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork &&
          _connectionNotifier.connectionState ==
              SocketConnectionState.disconnected) {
        unawaited(connect());
      }
    });
  }

  void _wireSocketHandlers(RealtimeSocket socket) {
    socket.on('connect', (_) {
      _connectionNotifier.setConnected();
      socket.emit(kResumeSession, null);
      _onConnected();
    });

    socket.on('disconnect', (_) {
      _connectionNotifier.setDisconnected();
    });

    socket.on('reconnect_attempt', (_) {
      _connectionNotifier.setReconnecting();
    });

    socket.on('connect_error', (error) {
      developer.log('Socket connect_error: $error', name: 'SocketClient');
    });

    socket.on(kQuoteUpdate, (data) {
      if (data is! Map) {
        return;
      }
      try {
        final payload = QuoteUpdatePayload.fromJson(
          Map<String, dynamic>.from(data),
        );
        _quoteUpdates.add(payload);
      } catch (error, stack) {
        developer.log(
          'Failed to parse quote_update',
          name: 'SocketClient',
          error: error,
          stackTrace: stack,
        );
      }
    });

    socket.on(kNotificationNew, (data) {
      if (data is! Map) {
        return;
      }
      try {
        final payload = NotificationNewPayload.fromJson(
          Map<String, dynamic>.from(data),
        );
        _notifications.add(payload);
      } catch (error, stack) {
        developer.log(
          'Failed to parse notification_new',
          name: 'SocketClient',
          error: error,
          stackTrace: stack,
        );
      }
    });

    socket.on(kAlertTriggered, (data) {
      if (data is Map) {
        _alertTriggered.add(Map<String, dynamic>.from(data));
      }
    });
    socket.on(kConnectionState, (data) {
      if (data is Map && data['status'] is String) {
        _connectionNotifier.syncFromServer(data['status'] as String);
      }
    });

    socket.on(kSocketError, (error) {
      developer.log('Socket error event: $error', name: 'SocketClient');
    });
  }

  static RealtimeSocket _defaultSocketFactory({
    required String url,
    required Map<String, dynamic> auth,
  }) {
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(reconnectionAttempts)
          .setReconnectionDelay(reconnectionDelayMs)
          .setReconnectionDelayMax(reconnectionDelayMaxMs)
          .setAuth(auth)
          .build(),
    );
    return IoRealtimeSocket(socket);
  }
}

class IoRealtimeSocket implements RealtimeSocket {
  IoRealtimeSocket(this._socket);

  final dynamic _socket;

  @override
  bool? get connected => _socket.connected as bool?;

  @override
  int? get reconnectionDelay => _socket.io.options['reconnectionDelay'] as int?;

  @override
  int? get reconnectionDelayMax =>
      _socket.io.options['reconnectionDelayMax'] as int?;

  @override
  void connect() => _socket.connect();

  @override
  void disconnect() => _socket.disconnect();

  @override
  void dispose() => _socket.dispose();

  @override
  void emit(String event, dynamic data) => _socket.emit(event, data);

  @override
  void on(String event, RealtimeEventHandler handler) =>
      _socket.on(event, handler);

  @override
  void off(String event) => _socket.off(event);
}

/// Riverpod provider #6 — realtime socket client.
final socketClientProvider = Provider<SocketClient>((ref) {
  final client = SocketClient(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(secureTokenStoreProvider),
    connectionNotifier: ref.read(socketConnectionStateProvider.notifier),
    onConnected: () {
      ref.read(quoteSubscriptionManagerProvider.notifier).resubscribeAll();
    },
  );
  ref.onDispose(client.dispose);
  return client;
});

/// Registers app lifecycle hooks for the socket client.
class SocketLifecycleBridge extends ConsumerStatefulWidget {
  const SocketLifecycleBridge({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SocketLifecycleBridge> createState() =>
      _SocketLifecycleBridgeState();
}

class _SocketLifecycleBridgeState extends ConsumerState<SocketLifecycleBridge> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(socketClientProvider).handleAppResumed();
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
