// Provider test: save/delete strategy lifecycle.
// Verifies:
//   1. Create a strategy → it appears in the strategies list.
//   2. Delete that strategy → it is removed from the list.
// Uses a fake repository that simulates in-memory CRUD without HTTP.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/features/screener/data/screener_providers.dart';
import 'package:frontend/features/screener/data/screener_repository.dart';

// ---------------------------------------------------------------------------
// In-memory fake repository
// ---------------------------------------------------------------------------

class _FakeScreenerRepository extends ScreenerRepository {
  _FakeScreenerRepository() : super(Dio());

  final List<ScreenerStrategy> _strategies = [];
  int _nextId = 1;

  @override
  Future<ScreenerStrategyListResult> listStrategies({
    String? cursor,
    int limit = 20,
  }) async {
    return ScreenerStrategyListResult(strategies: List.from(_strategies));
  }

  @override
  Future<ScreenerStrategy> createStrategy({
    required String name,
    required ScreenerFilter filters,
    String sortBy = 'marketCap',
    String sortOrder = 'desc',
    String? description,
  }) async {
    final strategy = ScreenerStrategy(
      strategyId: _nextId++,
      name: name,
      filters: filters,
      sortBy: sortBy,
      sortOrder: sortOrder,
      description: description,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    _strategies.add(strategy);
    return strategy;
  }

  @override
  Future<void> deleteStrategy(int strategyId) async {
    _strategies.removeWhere((s) => s.strategyId == strategyId);
  }

  @override
  Future<ScreenerScanResult> runScan({
    required ScreenerFilter filters,
    String sortBy = 'marketCap',
    String sortOrder = 'desc',
    int limit = 50,
  }) async {
    return const ScreenerScanResult(total: 0, limit: 50, items: []);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppConfig.resetForTest(enableScreener: true);
  });

  test('save strategy → appears in list; delete → removed from list', () async {
    final fakeRepo = _FakeScreenerRepository();

    final container = ProviderContainer(
      overrides: [screenerRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    // ── Initial list is empty ────────────────────────────────────────────────
    final initialList = await container.read(savedStrategiesProvider.future);
    expect(initialList, isEmpty);

    // ── Create a strategy ────────────────────────────────────────────────────
    final notifier = container.read(savedStrategiesProvider.notifier);
    final saved = await notifier.saveStrategy(
      name: 'Value Picks',
      filters: const ScreenerFilter(marketCapMin: 1e10, peRatioMax: 20),
    );
    expect(saved, isTrue);

    // Refresh to get updated list
    final afterCreate = await container.read(savedStrategiesProvider.future);
    expect(afterCreate.length, 1);
    expect(afterCreate.first.name, 'Value Picks');

    // ── Delete the strategy ──────────────────────────────────────────────────
    final strategyId = afterCreate.first.strategyId;
    final deleted = await notifier.deleteStrategy(strategyId);
    expect(deleted, isTrue);

    // List should now be empty
    final afterDelete = await container.read(savedStrategiesProvider.future);
    expect(afterDelete, isEmpty);
  });

  test('save multiple strategies then delete one — others remain', () async {
    final fakeRepo = _FakeScreenerRepository();
    final container = ProviderContainer(
      overrides: [screenerRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(savedStrategiesProvider.notifier);

    await notifier.saveStrategy(
      name: 'High Dividend',
      filters: const ScreenerFilter(dividendYieldMin: 3.0),
    );
    await notifier.saveStrategy(
      name: 'Large Cap Growth',
      filters: const ScreenerFilter(marketCapMin: 1e11),
    );

    final list = await container.read(savedStrategiesProvider.future);
    expect(list.length, 2);

    // Delete first strategy
    await notifier.deleteStrategy(list.first.strategyId);

    final afterDelete = await container.read(savedStrategiesProvider.future);
    expect(afterDelete.length, 1);
    expect(afterDelete.first.name, 'Large Cap Growth');
  });
}
