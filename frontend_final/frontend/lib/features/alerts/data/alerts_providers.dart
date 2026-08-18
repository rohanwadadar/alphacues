import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_scope.dart';
import '../../../core/platform/connectivity_service.dart';
import 'alerts_repository.dart';

export 'alerts_repository.dart';

void _registerAlertsUserScope() {
  if (!userScopedProviderKeys.contains(alertsProvider)) {
    userScopedProviderKeys.add(alertsProvider);
  }
  if (!userScopedProviderKeys.contains(alertHistoryProvider)) {
    userScopedProviderKeys.add(alertHistoryProvider);
  }
}

class AlertsNotifier extends AsyncNotifier<List<AlertModel>> {
  List<AlertModel>? _cached;

  @override
  Future<List<AlertModel>> build() async {
    _registerAlertsUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final alerts = await ref.read(alertsRepositoryProvider).listAlerts();
      _cached = alerts;
      return alerts;
    } on AlertServiceUnavailableException {
      if (_cached != null) {
        return _cached!;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final alerts = await ref.read(alertsRepositoryProvider).listAlerts();
      _cached = alerts;
      return alerts;
    });
  }

  void patchTriggered(String alertId) {
    final current = state.asData?.value ?? _cached;
    if (current == null) {
      return;
    }
    final updated = current
        .map(
          (alert) => alert.alertId == alertId
              ? alert.copyWith(triggered: true)
              : alert,
        )
        .toList();
    _cached = updated;
    state = AsyncData(updated);
  }
}

final alertsProvider =
    AsyncNotifierProvider<AlertsNotifier, List<AlertModel>>(
      AlertsNotifier.new,
    );

class AlertHistoryNotifier extends AsyncNotifier<List<AlertModel>> {
  List<AlertModel>? _cached;

  @override
  Future<List<AlertModel>> build() async {
    _registerAlertsUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final history = await ref.read(alertsRepositoryProvider).getAlertHistory();
      _cached = history;
      return history;
    } on AlertServiceUnavailableException {
      if (_cached != null) {
        return _cached!;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final history = await ref.read(alertsRepositoryProvider).getAlertHistory();
      _cached = history;
      return history;
    });
  }
}

final alertHistoryProvider =
    AsyncNotifierProvider<AlertHistoryNotifier, List<AlertModel>>(
      AlertHistoryNotifier.new,
    );

class AlertDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String alertId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(alertsRepositoryProvider).deleteAlert(alertId);
      ref.invalidate(alertsProvider);
    });
  }
}

final alertDeleteProvider =
    AsyncNotifierProvider<AlertDeleteNotifier, void>(
      AlertDeleteNotifier.new,
    );

class AlertToggleNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> toggleActive(AlertModel alert, bool isActive) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(alertsRepositoryProvider).updateAlert(
        alert.alertId,
        symbol: alert.symbol,
        condition: alert.condition,
        target: alert.target,
        isActive: isActive,
        cooldownSeconds: alert.cooldownSeconds,
      );
      ref.invalidate(alertsProvider);
    });
  }
}

final alertToggleProvider =
    AsyncNotifierProvider<AlertToggleNotifier, void>(
      AlertToggleNotifier.new,
    );
