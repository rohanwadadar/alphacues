import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_scope.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../watchlist/data/watchlist_repository.dart'
    show ServiceUnavailableException;
import 'market_repository.dart';

export 'market_repository.dart';

/// Tracks the symbol detail screen currently visible for reconnect REST refresh.
class ActiveSymbolDetailNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void track(String symbol) => state = symbol.trim().toUpperCase();

  void untrack(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    if (state == normalized) {
      state = null;
    }
  }
}

final activeSymbolDetailProvider =
    NotifierProvider<ActiveSymbolDetailNotifier, String?>(
      ActiveSymbolDetailNotifier.new,
    );

Future<void> refreshActiveSymbolDetail(Ref ref) async {
  final symbol = ref.read(activeSymbolDetailProvider);
  if (symbol == null) {
    return;
  }
  ref.invalidate(symbolDetailProvider(symbol));
  await ref.read(symbolDetailProvider(symbol).future);
}

void _registerSymbolDetailUserScope() {
  if (!userScopedProviderKeys.contains(activeSymbolDetailProvider)) {
    userScopedProviderKeys.add(activeSymbolDetailProvider);
  }
}

class SymbolDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<SymbolDetailSnapshot, String> {
  SymbolDetailSnapshot? _cached;

  @override
  Future<SymbolDetailSnapshot> build(String symbol) async {
    _registerSymbolDetailUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final snapshot = await ref
          .read(marketRepositoryProvider)
          .getSymbolDetail(symbol);
      _cached = snapshot;
      return snapshot;
    } on ServiceUnavailableException {
      if (_cached != null) {
        return _cached!;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(marketRepositoryProvider).getSymbolDetail(arg),
    );
    if (state case AsyncData(:final value)) {
      _cached = value;
    }
  }

  void patchQuote(MarketQuote quote) {
    final current = state.asData?.value ?? _cached;
    if (current == null) {
      return;
    }
    final next = SymbolDetailSnapshot(
      quote: quote,
      fundamentals: current.fundamentals,
      fetchedAt: current.fetchedAt,
    );
    _cached = next;
    state = AsyncData(next);
  }
}

final symbolDetailProvider = AutoDisposeAsyncNotifierProviderFamily<
    SymbolDetailNotifier,
    SymbolDetailSnapshot,
    String>(SymbolDetailNotifier.new);
