import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../portfolio/data/portfolio_providers.dart';
import 'watchlist_repository.dart';

export 'watchlist_repository.dart';

/// Tracks active watchlist ids that should be refreshed after reconnect.
class ActiveWatchlistIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void track(String watchlistId) {
    state = {...state, watchlistId};
  }

  void untrack(String watchlistId) {
    final next = {...state}..remove(watchlistId);
    state = next;
  }
}

final activeWatchlistIdsProvider =
    NotifierProvider<ActiveWatchlistIdsNotifier, Set<String>>(
      ActiveWatchlistIdsNotifier.new,
    );

/// Refreshes all tracked watchlist detail providers after reconnect.
Future<void> refreshTrackedWatchlists(Ref ref) async {
  final ids = ref.read(activeWatchlistIdsProvider);
  if (ids.isEmpty) {
    return;
  }

  await Future.wait(
    ids.map((id) => ref.refresh(watchlistDetailProvider(id).future)),
  );
}

class WatchlistsNotifier extends AsyncNotifier<List<Watchlist>> {
  List<Watchlist>? _cached;

  @override
  Future<List<Watchlist>> build() async {
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final repo = ref.read(watchlistRepositoryProvider);
      final result = await repo.listWatchlists();
      var list = result.watchlists;
      if (list.isEmpty && connectivity.isOnline) {
        try {
          final seeded = await repo.createWatchlist('Tech Picks');
          for (final sym in ['AAPL', 'MSFT', 'GOOGL', 'TSLA']) {
            await repo.addSymbol(seeded.watchlistId, sym);
          }
          final reList = await repo.listWatchlists();
          list = reList.watchlists;
        } catch (_) {}
      }
      _cached = list;
      return list;
    } on ServiceUnavailableException {
      if (_cached != null) {
        return _cached!;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(watchlistRepositoryProvider)
          .listWatchlists();
      _cached = result.watchlists;
      return result.watchlists;
    });
  }
}

final watchlistsProvider =
    AsyncNotifierProvider<WatchlistsNotifier, List<Watchlist>>(
      WatchlistsNotifier.new,
    );

class WatchlistDetailNotifier extends AutoDisposeFamilyAsyncNotifier<
    WatchlistDetail,
    String> {
  @override
  Future<WatchlistDetail> build(String watchlistId) async {
    return ref.read(watchlistRepositoryProvider).getWatchlist(watchlistId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(watchlistRepositoryProvider).getWatchlist(arg),
    );
  }
}

final watchlistDetailProvider = AutoDisposeAsyncNotifierProviderFamily<
    WatchlistDetailNotifier,
    WatchlistDetail,
    String>(WatchlistDetailNotifier.new);

class WatchlistFormNotifier extends AsyncNotifier<void> {
  String? _inlineError;

  String? get inlineError => _inlineError;

  @override
  Future<void> build() async {}

  Future<void> create(String name) async {
    _inlineError = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(watchlistRepositoryProvider).createWatchlist(name.trim());
      ref.invalidate(watchlistsProvider);
    });
    if (state.hasError) {
      _inlineError = _messageFromError(state.error);
    }
  }

  Future<void> rename({
    required String watchlistId,
    required String name,
  }) async {
    _inlineError = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(watchlistRepositoryProvider)
          .renameWatchlist(watchlistId, name.trim());
      ref.invalidate(watchlistsProvider);
    });
    if (state.hasError) {
      _inlineError = _messageFromError(state.error);
    }
  }

  void clearError() {
    _inlineError = null;
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }

  String _messageFromError(Object? error) {
    if (error is ValidationErrorException) {
      return error.message;
    }
    if (error is RateLimitedException) {
      return error.message;
    }
    if (error is ApiException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}

final watchlistFormProvider =
    AsyncNotifierProvider<WatchlistFormNotifier, void>(
      WatchlistFormNotifier.new,
    );

class WatchlistDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String watchlistId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(watchlistRepositoryProvider).deleteWatchlist(watchlistId);
      ref.invalidate(watchlistsProvider);
    });
  }
}

final watchlistDeleteProvider =
    AsyncNotifierProvider<WatchlistDeleteNotifier, void>(
      WatchlistDeleteNotifier.new,
    );

class AddSymbolNotifier extends AutoDisposeFamilyAsyncNotifier<void, String> {
  String? _inlineError;

  String? get inlineError => _inlineError;

  @override
  Future<void> build(String watchlistId) async {}

  Future<void> addSymbol(String symbol, {double? quantity}) async {
    _inlineError = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(watchlistRepositoryProvider)
          .addSymbol(arg, symbol.trim().toUpperCase(), quantity: quantity);
      ref.invalidate(watchlistDetailProvider(arg));
      ref.invalidate(watchlistsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
    });
    if (state.hasError) {
      _inlineError = _messageFromError(state.error);
    }
  }

  void clearError() {
    _inlineError = null;
    if (state.hasError) {
      state = const AsyncData(null);
    }
  }

  String _messageFromError(Object? error) {
    if (error is DuplicateSymbolException) {
      return error.message;
    }
    if (error is ValidationErrorException) {
      return error.message;
    }
    if (error is RateLimitedException) {
      return error.message;
    }
    if (error is ApiException) {
      return error.message;
    }
    return 'Could not add symbol. Please try again.';
  }
}

final addSymbolProvider = AutoDisposeAsyncNotifierProviderFamily<
    AddSymbolNotifier,
    void,
    String>(AddSymbolNotifier.new);

class RemoveSymbolNotifier extends AutoDisposeFamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String watchlistId) async {}

  Future<void> removeSymbol(String symbol) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(watchlistRepositoryProvider)
          .removeSymbol(arg, symbol);
      ref.invalidate(watchlistDetailProvider(arg));
      ref.invalidate(watchlistsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
    });
  }
}

final removeSymbolProvider = AutoDisposeAsyncNotifierProviderFamily<
    RemoveSymbolNotifier,
    void,
    String>(RemoveSymbolNotifier.new);
