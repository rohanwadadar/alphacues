import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'market_repository.dart';

/// Provider for the current search query string.
final stockSearchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced search results provider.
/// Automatically re-fetches whenever the search query changes.
final stockSearchResultsProvider =
    FutureProvider.autoDispose<List<SearchStockResult>>((ref) async {
  final query = ref.watch(stockSearchQueryProvider);

  if (query.trim().isEmpty) {
    return const [];
  }

  // Debounce: wait 300ms before firing the request.
  // If the query changes during this window, the previous
  // provider is disposed and a fresh one is created.
  final completer = Completer<void>();
  final timer = Timer(const Duration(milliseconds: 300), () {
    if (!completer.isCompleted) completer.complete();
  });
  ref.onDispose(timer.cancel);
  await completer.future;

  final repo = ref.read(marketRepositoryProvider);
  return repo.searchStocks(query, limit: 20);
});
