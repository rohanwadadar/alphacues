import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Online/offline connectivity status for offline UX.
class ConnectivityStatus {
  const ConnectivityStatus({required this.isOnline});

  final bool isOnline;
}

/// Watches device network connectivity via [connectivity_plus].
class ConnectivityService extends Notifier<ConnectivityStatus> {
  @override
  ConnectivityStatus build() {
    final connectivity = Connectivity();
    final sub = connectivity.onConnectivityChanged.listen(_onChanged);
    ref.onDispose(sub.cancel);
    unawaited(_loadInitial(connectivity));
    return const ConnectivityStatus(isOnline: true);
  }

  Future<void> _loadInitial(Connectivity connectivity) async {
    final results = await connectivity.checkConnectivity();
    _onChanged(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (state.isOnline != online) {
      state = ConnectivityStatus(isOnline: online);
    }
  }
}

final connectivityServiceProvider =
    NotifierProvider<ConnectivityService, ConnectivityStatus>(
      ConnectivityService.new,
    );
