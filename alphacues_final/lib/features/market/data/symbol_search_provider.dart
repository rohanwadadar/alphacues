import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_repository.dart';

final symbolSearchProvider = FutureProvider.autoDispose.family<List<MarketSearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  
  // Basic debounce implementation within FutureProvider.
  // Delaying execution by 300ms. If the provider is disposed (because query changed),
  // it cancels this work.
  var isCancelled = false;
  ref.onDispose(() => isCancelled = true);
  
  await Future.delayed(const Duration(milliseconds: 300));
  if (isCancelled) return const [];

  final repository = ref.watch(marketRepositoryProvider);
  return repository.searchSymbols(query);
});
