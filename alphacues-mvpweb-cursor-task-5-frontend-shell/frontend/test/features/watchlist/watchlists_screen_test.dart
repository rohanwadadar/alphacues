import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/features/watchlist/data/watchlist_providers.dart';
import 'package:frontend/features/watchlist/presentation/watchlists_screen.dart';

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

class _EmptyWatchlistsNotifier extends WatchlistsNotifier {
  @override
  Future<List<Watchlist>> build() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty state when there are no watchlists', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
          watchlistsProvider.overrideWith(_EmptyWatchlistsNotifier.new),
        ],
        child: const MaterialApp(home: WatchlistsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No watchlists yet'), findsOneWidget);
  });
}
