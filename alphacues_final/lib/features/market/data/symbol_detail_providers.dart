import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_scope.dart';
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

final Map<String, SymbolDetailSnapshot> _staticCacheMap = {};

class SymbolDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<SymbolDetailSnapshot, String> {

  @override
  Future<SymbolDetailSnapshot> build(String symbol) async {
    _registerSymbolDetailUserScope();
    final normalized = symbol.trim().toUpperCase();

    // Fast memory return
    final cached = _staticCacheMap[normalized];
    if (cached != null) {
      _refreshInBackground(normalized);
      return cached;
    }

    try {
      final snapshot = await ref
          .read(marketRepositoryProvider)
          .getSymbolDetail(normalized);
      _staticCacheMap[normalized] = snapshot;
      return snapshot;
    } on ServiceUnavailableException {
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  void _refreshInBackground(String symbol) async {
    try {
      final snapshot = await ref
          .read(marketRepositoryProvider)
          .getSymbolDetail(symbol);
      _staticCacheMap[symbol] = snapshot;
      state = AsyncData(snapshot);
    } catch (_) {}
  }

  Future<void> refresh() async {
    final normalized = arg.trim().toUpperCase();
    state = await AsyncValue.guard(
      () => ref.read(marketRepositoryProvider).getSymbolDetail(normalized),
    );
    if (state case AsyncData(:final value)) {
      _staticCacheMap[normalized] = value;
    }
  }

  void patchQuote(MarketQuote quote) {
    final normalized = arg.trim().toUpperCase();
    final current = state.asData?.value ?? _staticCacheMap[normalized];
    if (current == null) {
      return;
    }
    final next = SymbolDetailSnapshot(
      quote: quote,
      fundamentals: current.fundamentals,
      fetchedAt: current.fetchedAt,
    );
    _staticCacheMap[normalized] = next;
    state = AsyncData(next);
  }
}

final symbolDetailProvider = AutoDisposeAsyncNotifierProviderFamily<
    SymbolDetailNotifier,
    SymbolDetailSnapshot,
    String>(SymbolDetailNotifier.new);
