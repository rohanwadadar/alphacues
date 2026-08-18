import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_scope.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../alerts/data/alerts_providers.dart';
import 'notifications_repository.dart';

export 'notifications_repository.dart';

void _registerNotificationsUserScope() {
  if (!userScopedProviderKeys.contains(notificationsProvider)) {
    userScopedProviderKeys.add(notificationsProvider);
  }
}

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  List<NotificationModel>? _cached;
  String? _nextCursor;
  StreamSubscription<NotificationNewPayload>? _notificationSub;
  StreamSubscription<Map<String, dynamic>>? _alertTriggeredSub;

  String? get nextCursor => _nextCursor;

  bool get hasMore => _nextCursor != null;

  @override
  Future<List<NotificationModel>> build() async {
    _registerNotificationsUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      _wireSocketListeners();
      return _cached!;
    }

    try {
      final result = await ref
          .read(notificationsRepositoryProvider)
          .listNotifications();
      _cached = result.items;
      _nextCursor = result.nextCursor;
      _wireSocketListeners();
      return result.items;
    } on NotificationServiceUnavailableException {
      if (_cached != null) {
        _wireSocketListeners();
        return _cached!;
      }
      rethrow;
    }
  }

  void _wireSocketListeners() {
    _notificationSub?.cancel();
    _alertTriggeredSub?.cancel();

    final socket = ref.read(socketClientProvider);
    socket.emit(kSubscribeNotifications, null);

    _notificationSub = socket.notifications.listen((payload) {
      final newItem = NotificationModel.fromSocketPayload({
        'notificationId': payload.notificationId,
        'alertId': payload.alertId,
        'title': payload.title,
        'body': payload.body,
        'createdAt': payload.createdAt,
      });
      final current = state.asData?.value ?? _cached ?? const <NotificationModel>[];
      final next = [newItem, ...current];
      _cached = next;
      state = AsyncData(next);
    });

    _alertTriggeredSub = socket.alertTriggered.listen((_) {
      ref.invalidate(alertsProvider);
    });

    ref.onDispose(() {
      _notificationSub?.cancel();
      _alertTriggeredSub?.cancel();
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(notificationsRepositoryProvider)
          .listNotifications();
      _cached = result.items;
      _nextCursor = result.nextCursor;
      return result.items;
    });
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || state.isLoading) {
      return;
    }

    final cursor = _nextCursor;
    final current = state.asData?.value ?? _cached ?? const <NotificationModel>[];

    try {
      final result = await ref
          .read(notificationsRepositoryProvider)
          .listNotifications(cursor: cursor);
      _nextCursor = result.nextCursor;
      final merged = [...current, ...result.items];
      _cached = merged;
      state = AsyncData(merged);
    } catch (_) {
      // Keep existing items visible on pagination failure.
    }
  }

  Future<void> markRead(String notificationId) async {
    final current = state.asData?.value ?? _cached;
    if (current == null) {
      return;
    }

    final optimistic = current
        .map(
          (item) => item.notificationId == notificationId
              ? item.copyWith(isRead: true)
              : item,
        )
        .toList();
    _cached = optimistic;
    state = AsyncData(optimistic);

    try {
      await ref.read(notificationsRepositoryProvider).markRead(notificationId);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value ?? _cached;
    if (current == null) {
      return;
    }

    final optimistic = current.map((item) => item.copyWith(isRead: true)).toList();
    _cached = optimistic;
    state = AsyncData(optimistic);

    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
    } catch (_) {
      await refresh();
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
      NotificationsNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (items) => items.where((item) => !item.isRead).length,
    orElse: () => 0,
  );
});
