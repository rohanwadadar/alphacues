import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_scope.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../watchlist/data/watchlist_repository.dart'
    show ServiceUnavailableException;
import 'dashboard_repository.dart';

export 'dashboard_repository.dart';

/// Tracks whether the dashboard screen is visible for reconnect REST refresh.
class DashboardScreenActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void track() => state = true;

  void untrack() => state = false;
}

final dashboardScreenActiveProvider =
    NotifierProvider<DashboardScreenActiveNotifier, bool>(
      DashboardScreenActiveNotifier.new,
    );

Future<void> refreshDashboardIfActive(Ref ref) async {
  if (!ref.read(dashboardScreenActiveProvider)) {
    return;
  }
  ref.invalidate(dashboardProvider);
  await ref.read(dashboardProvider.future);
}

void _registerDashboardUserScope() {
  if (!userScopedProviderKeys.contains(dashboardProvider)) {
    userScopedProviderKeys.add(dashboardProvider);
  }
  if (!userScopedProviderKeys.contains(dashboardScreenActiveProvider)) {
    userScopedProviderKeys.add(dashboardScreenActiveProvider);
  }
  if (!userScopedProviderKeys.contains(dashboardNotificationBadgeProvider)) {
    userScopedProviderKeys.add(dashboardNotificationBadgeProvider);
  }
}

class DashboardNotifier extends AsyncNotifier<DashboardSnapshot> {
  DashboardSnapshot? _cached;

  @override
  Future<DashboardSnapshot> build() async {
    _registerDashboardUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final snapshot = await _loadSnapshot();
      _cached = snapshot;
      ref.read(dashboardNotificationBadgeProvider.notifier).seed(
        snapshot.unreadNotificationCount,
      );
      return snapshot;
    } on ServiceUnavailableException {
      if (_cached != null) {
        return _cached!;
      }
      rethrow;
    }
  }

  Future<DashboardSnapshot> _loadSnapshot() async {
    final repository = ref.read(dashboardRepositoryProvider);
    final snapshot = await repository.getDashboard();
    if (snapshot.unreadNotificationCount > 0) {
      return snapshot;
    }

    try {
      final unread = await repository.getUnreadNotificationCount();
      return snapshot.copyWith(unreadNotificationCount: unread);
    } catch (_) {
      return snapshot;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final snapshot = await _loadSnapshot();
      _cached = snapshot;
      ref.read(dashboardNotificationBadgeProvider.notifier).seed(
        snapshot.unreadNotificationCount,
      );
      return snapshot;
    });
  }

  void patchMoverQuote({
    required String symbol,
    required double lastPrice,
    required double changePercent,
  }) {
    final current = state.asData?.value ?? _cached;
    if (current == null) {
      return;
    }

    final updatedMovers = current.topMovers.map((mover) {
      if (mover.symbol != symbol) {
        return mover;
      }
      return mover.copyWith(
        lastPrice: lastPrice,
        changePercent: changePercent,
      );
    }).toList();

    final next = current.copyWith(topMovers: updatedMovers);
    _cached = next;
    state = AsyncData(next);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSnapshot>(
      DashboardNotifier.new,
    );

class DashboardNotificationBadgeNotifier extends Notifier<int> {
  StreamSubscription<NotificationNewPayload>? _sub;

  @override
  int build() {
    final socket = ref.watch(socketClientProvider);
    _sub?.cancel();
    _sub = socket.notifications.listen((_) {
      increment();
    });
    ref.onDispose(() {
      _sub?.cancel();
    });
    return 0;
  }

  void seed(int count) {
    state = count;
  }

  void increment() {
    state = state + 1;
  }

  void decrement([int amount = 1]) {
    state = (state - amount).clamp(0, 999999);
  }

  void clear() {
    state = 0;
  }
}

final dashboardNotificationBadgeProvider =
    NotifierProvider<DashboardNotificationBadgeNotifier, int>(
      DashboardNotificationBadgeNotifier.new,
    );
