import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/features/watchlist/data/watchlist_providers.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _MockWatchlistRepository extends WatchlistRepository {
  _MockWatchlistRepository() : super(Dio());

  var addSymbolCalls = 0;
  var getWatchlistCalls = 0;

  @override
  Future<void> addSymbol(String watchlistId, String symbol, {double? quantity}) async {
    addSymbolCalls++;
  }

  @override
  Future<WatchlistDetail> getWatchlist(String watchlistId) async {
    getWatchlistCalls++;
    return WatchlistDetail(
      watchlistId: watchlistId,
      name: 'Tech',
      items: const [WatchlistItem(symbol: 'AAPL')],
    );
  }

  @override
  Future<WatchlistListResult> listWatchlists({
    String? cursor,
    int limit = 20,
  }) async {
    return const WatchlistListResult(
      watchlists: [
        Watchlist(watchlistId: '1', name: 'Tech', symbolCount: 1),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addSymbol invalidates watchlist detail only', () async {
    final repository = _MockWatchlistRepository();
    final container = ProviderContainer(
      overrides: [
        watchlistRepositoryProvider.overrideWithValue(repository),
        connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
      ],
    );
    addTearDown(container.dispose);

    await container.read(watchlistsProvider.future);
    final listBefore = container.read(watchlistsProvider);

    await container.read(watchlistDetailProvider('1').future);
    expect(repository.getWatchlistCalls, 1);

    await container.read(addSymbolProvider('1').notifier).addSymbol('TSLA');
    await container.read(watchlistDetailProvider('1').future);

    expect(repository.addSymbolCalls, 1);
    expect(repository.getWatchlistCalls, 2);

    final listAfter = container.read(watchlistsProvider);
    expect(listAfter, same(listBefore));
  });
}
