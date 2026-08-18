// Widget test: empty results state ("No matches" after a completed run with
// zero results). Verifies the Empty state UI renders correctly and does not
// show a blank screen.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/platform/connectivity_service.dart';
import 'package:frontend/features/screener/data/screener_providers.dart';
import 'package:frontend/features/screener/data/screener_repository.dart';
import 'package:frontend/features/screener/presentation/screener_screen.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _OnlineConnectivity extends ConnectivityService {
  @override
  ConnectivityStatus build() => const ConnectivityStatus(isOnline: true);
}

/// Repository that returns zero items (empty scan result).
class _EmptyResultRepository extends ScreenerRepository {
  _EmptyResultRepository() : super(Dio());

  @override
  Future<ScreenerScanResult> runScan({
    required ScreenerFilter filters,
    String sortBy = 'marketCap',
    String sortOrder = 'desc',
    int limit = 50,
  }) async {
    return const ScreenerScanResult(total: 0, limit: 50, items: []);
  }

  @override
  Future<ScreenerStrategyListResult> listStrategies({
    String? cursor,
    int limit = 20,
  }) async {
    return const ScreenerStrategyListResult(strategies: []);
  }
}

// ---------------------------------------------------------------------------
// Test
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.resetForTest(enableScreener: true);
  });

  testWidgets('shows "No matches" after a completed run with zero results',
      (tester) async {
    final repo = _EmptyResultRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityServiceProvider.overrideWith(_OnlineConnectivity.new),
          screenerRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: ScreenerScreen()),
      ),
    );

    // Allow the initial runScan() to complete.
    await tester.pumpAndSettle();

    // The Empty state must show "No matches" — never a blank screen.
    expect(find.text('No matches'), findsOneWidget);

    // Must also offer a way to reset filters.
    expect(find.text('Reset Filters'), findsOneWidget);

    // Must NOT show an error or loading indicator.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });
}
