import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_error.dart';
import '../../../core/platform/connectivity_service.dart';
import 'screener_models.dart';
import 'screener_repository.dart';

export 'screener_models.dart';
export 'screener_repository.dart' show screenerRepositoryProvider;

// ---------------------------------------------------------------------------
// Screen state — owns all UI states for the Screener screen.
// Per the plan's loading/empty/error/degraded table:
//   Loading  → isLoading = true
//   Empty    → result != null && result.items.isEmpty
//   Error    → error != null (filters preserved)
//   Degraded → isOffline = true (last preset shown, fresh scan disabled)
//   Disabled → isFeatureDisabled = true
// ---------------------------------------------------------------------------
class ScreenerState {
  const ScreenerState({
    this.isLoading = false,
    this.error,
    this.isFeatureDisabled = false,
    this.isOffline = false,
    this.filters = const ScreenerFilter(),
    this.sortBy = 'marketCap',
    this.sortOrder = 'desc',
    this.result,
    this.lastSavedPreset,
  });

  final bool isLoading;
  final String? error;
  final bool isFeatureDisabled;

  /// True when connectivity is down — fresh scans are disabled in this state.
  final bool isOffline;

  /// Active filter form values — preserved on error, never cleared.
  final ScreenerFilter filters;

  /// Sort field — one of: marketCap | peRatio | price | changePercent | symbol
  final String sortBy;

  /// Sort order — one of: asc | desc
  final String sortOrder;

  /// Last successful scan result (null before first run).
  final ScreenerScanResult? result;

  /// Last saved strategy preset — shown in degraded/offline state.
  final ScreenerStrategy? lastSavedPreset;

  ScreenerState copyWith({
    bool? isLoading,
    String? error,
    bool? isFeatureDisabled,
    bool? isOffline,
    ScreenerFilter? filters,
    String? sortBy,
    String? sortOrder,
    ScreenerScanResult? result,
    ScreenerStrategy? lastSavedPreset,
    bool clearError = false,
  }) {
    return ScreenerState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isFeatureDisabled: isFeatureDisabled ?? this.isFeatureDisabled,
      isOffline: isOffline ?? this.isOffline,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      result: result ?? this.result,
      lastSavedPreset: lastSavedPreset ?? this.lastSavedPreset,
    );
  }
}

// ---------------------------------------------------------------------------
// Feature controller provider — owns ScreenerState + mutation flows
// Pattern mirrors WatchlistsNotifier / WatchlistFormNotifier from watchlist/.
// ---------------------------------------------------------------------------
class ScreenerNotifier extends StateNotifier<ScreenerState> {
  ScreenerNotifier(this._repository, this._connectivity)
      : super(const ScreenerState()) {
    // Run an initial scan on construction unless flag is disabled.
    final config = AppConfig.instance;
    if (config.enableScreener) {
      runScan();
    } else {
      state = state.copyWith(isFeatureDisabled: true);
    }
  }

  final ScreenerRepository _repository;
  final ConnectivityStatus _connectivity;

  // -------------------------------------------------------------------------
  // Run a fresh scan using current filters + sorting.
  // -------------------------------------------------------------------------
  Future<void> runScan() async {
    if (!_connectivity.isOnline) {
      state = state.copyWith(isOffline: true);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      isFeatureDisabled: false,
      isOffline: false,
    );

    try {
      final res = await _repository.runScan(
        filters: state.filters,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
        limit: 1000,
      );
      state = state.copyWith(isLoading: false, result: res);
    } on ApiException catch (e) {
      if (e.code == 'FEATURE_DISABLED') {
        state = state.copyWith(isLoading: false, isFeatureDisabled: true);
      } else if (e.code == 'SERVICE_UNAVAILABLE') {
        state = state.copyWith(isLoading: false, isOffline: true);
      } else {
        // Preserve filters — do NOT clear the form on error (plan requirement).
        state = state.copyWith(isLoading: false, error: e.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Update active filter form values and immediately re-scan.
  // -------------------------------------------------------------------------
  void setFilters(ScreenerFilter filters) {
    state = state.copyWith(filters: filters);
    runScan();
  }

  // -------------------------------------------------------------------------
  // Update sorting and re-scan.
  // -------------------------------------------------------------------------
  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    runScan();
  }

  // -------------------------------------------------------------------------
  // Reset filters to empty defaults and re-scan.
  // -------------------------------------------------------------------------
  void resetFilters() {
    state = state.copyWith(filters: const ScreenerFilter());
    runScan();
  }

  // -------------------------------------------------------------------------
  // Apply a saved strategy preset (load its filters + sorting).
  // -------------------------------------------------------------------------
  void applySavedStrategy(ScreenerStrategy strategy) {
    state = state.copyWith(
      filters: strategy.filters,
      sortBy: strategy.sortBy,
      sortOrder: strategy.sortOrder,
      lastSavedPreset: strategy,
    );
    runScan();
  }
}

final screenerNotifierProvider =
    StateNotifierProvider<ScreenerNotifier, ScreenerState>((ref) {
  final repo = ref.watch(screenerRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return ScreenerNotifier(repo, connectivity);
});

// ---------------------------------------------------------------------------
// Saved strategies list provider.
// Loads the paginated list; invalidated after create/delete mutations.
// ---------------------------------------------------------------------------
class SavedStrategiesNotifier extends AsyncNotifier<List<ScreenerStrategy>> {
  @override
  Future<List<ScreenerStrategy>> build() async {
    final repo = ref.watch(screenerRepositoryProvider);
    final result = await repo.listStrategies();
    return result.strategies;
  }

  Future<bool> saveStrategy({
    required String name,
    required ScreenerFilter filters,
    String sortBy = 'marketCap',
    String sortOrder = 'desc',
    String? description,
  }) async {
    try {
      await ref.read(screenerRepositoryProvider).createStrategy(
        name: name,
        filters: filters,
        sortBy: sortBy,
        sortOrder: sortOrder,
        description: description,
      );
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteStrategy(int strategyId) async {
    try {
      await ref.read(screenerRepositoryProvider).deleteStrategy(strategyId);
      ref.invalidateSelf();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final savedStrategiesProvider =
    AsyncNotifierProvider<SavedStrategiesNotifier, List<ScreenerStrategy>>(
      SavedStrategiesNotifier.new,
    );
