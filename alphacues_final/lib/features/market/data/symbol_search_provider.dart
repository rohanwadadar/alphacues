import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_repository.dart';

/// Ranks stock search results with exact prefix tiers:
/// 1. Exact symbol match (e.g. "a" -> "A", "aa" -> "AA", "aapl" -> "AAPL")
/// 2. Symbol prefix match (e.g. "a" -> "AA", "AAL", "AAP", "AAPL", "AMZN") sorted by length then symbol
/// 3. Company name prefix match (e.g. "Apple Inc." for "app")
/// 4. Word-boundary prefix match (words in company name starting with query)
/// 5. Substring symbol match
/// 6. Substring company name match
List<MarketSearchResult> rankSearchResults(
  List<MarketSearchResult> results,
  String query,
) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return results;

  final exactSymbol = <MarketSearchResult>[];
  final prefixSymbol = <MarketSearchResult>[];
  final prefixName = <MarketSearchResult>[];
  final wordStartName = <MarketSearchResult>[];
  final containsSymbol = <MarketSearchResult>[];
  final containsName = <MarketSearchResult>[];
  final other = <MarketSearchResult>[];

  final seen = <String>{};

  for (final item in results) {
    final sym = item.symbol.trim();
    if (sym.isEmpty || seen.contains(sym)) continue;
    seen.add(sym);

    final symLower = sym.toLowerCase();
    final nameLower = item.name.trim().toLowerCase();
    final words = nameLower.split(RegExp(r'\s+'));

    if (symLower == needle) {
      exactSymbol.add(item);
    } else if (symLower.startsWith(needle)) {
      prefixSymbol.add(item);
    } else if (nameLower.startsWith(needle)) {
      prefixName.add(item);
    } else if (words.any((w) => w.startsWith(needle))) {
      wordStartName.add(item);
    } else if (symLower.contains(needle)) {
      containsSymbol.add(item);
    } else if (nameLower.contains(needle)) {
      containsName.add(item);
    } else {
      other.add(item);
    }
  }

  // Sort prefix symbols by length ascending (e.g. "A", "AA", "AAL", "AAPL"), then alphabetically
  prefixSymbol.sort((a, b) {
    final lenCmp = a.symbol.length.compareTo(b.symbol.length);
    return lenCmp != 0 ? lenCmp : a.symbol.compareTo(b.symbol);
  });

  prefixName.sort((a, b) {
    final lenCmp = a.name.length.compareTo(b.name.length);
    return lenCmp != 0 ? lenCmp : a.name.compareTo(b.name);
  });

  wordStartName.sort((a, b) => a.name.compareTo(b.name));
  containsSymbol.sort((a, b) => a.symbol.compareTo(b.symbol));
  containsName.sort((a, b) => a.name.compareTo(b.name));

  return [
    ...exactSymbol,
    ...prefixSymbol,
    ...prefixName,
    ...wordStartName,
    ...containsSymbol,
    ...containsName,
    ...other,
  ];
}

/// Common stock search provider used across the app (Dashboard, Watchlist, Alerts, Portfolio).
final symbolSearchProvider = FutureProvider.autoDispose.family<List<MarketSearchResult>, String>((ref, query) async {
  final cleanQuery = query.trim();
  if (cleanQuery.isEmpty) return const [];
  
  var isCancelled = false;
  ref.onDispose(() => isCancelled = true);
  
  await Future.delayed(const Duration(milliseconds: 200));
  if (isCancelled) return const [];

  final repository = ref.watch(marketRepositoryProvider);
  final rawResults = await repository.searchSymbols(cleanQuery, limit: 25);
  return rankSearchResults(rawResults, cleanQuery);
});
