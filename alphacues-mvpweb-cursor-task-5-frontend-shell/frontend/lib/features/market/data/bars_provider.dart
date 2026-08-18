import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/socket_client.dart';
import 'market_repository.dart';

/// Selected chart range on the symbol detail screen.
final chartRangeProvider = StateProvider.autoDispose<String>((ref) => '1D');

typedef BarsQuery = ({String symbol, String range});

class BarsSnapshot {
  const BarsSnapshot({
    required this.bars,
    required this.fetchedAt,
  });

  final List<Bar> bars;
  final DateTime fetchedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BarsSnapshot &&
            fetchedAt == other.fetchedAt &&
            listEquals(bars, other.bars);
  }

  @override
  int get hashCode => Object.hash(fetchedAt, Object.hashAll(bars));
}

/// View-model for the chart section. [bars] uses deep equality so consumers
/// only rebuild when candle data actually changes.
@immutable
class BarsChartData {
  const BarsChartData._({
    required this.isLoading,
    required this.bars,
    required this.fetchedAt,
    required this.isStale,
    this.error,
  });

  factory BarsChartData.loading() {
    return const BarsChartData._(
      isLoading: true,
      bars: [],
      fetchedAt: null,
      isStale: false,
    );
  }

  factory BarsChartData.error(Object error) {
    return BarsChartData._(
      isLoading: false,
      bars: const [],
      fetchedAt: null,
      isStale: false,
      error: error,
    );
  }

  factory BarsChartData.ready({
    required List<Bar> bars,
    required DateTime fetchedAt,
    required bool isStale,
  }) {
    return BarsChartData._(
      isLoading: false,
      bars: bars,
      fetchedAt: fetchedAt,
      isStale: isStale,
    );
  }

  final bool isLoading;
  final List<Bar> bars;
  final DateTime? fetchedAt;
  final bool isStale;
  final Object? error;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BarsChartData &&
            isLoading == other.isLoading &&
            isStale == other.isStale &&
            fetchedAt == other.fetchedAt &&
            error == other.error &&
            listEquals(bars, other.bars);
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    isStale,
    fetchedAt,
    error,
    Object.hashAll(bars),
  );
}

class BarsNotifier extends AutoDisposeFamilyAsyncNotifier<BarsSnapshot, BarsQuery> {
  @override
  Future<BarsSnapshot> build(BarsQuery query) async {
    final bars = await ref
        .read(marketRepositoryProvider)
        .fetchBars(query.symbol, query.range);
    return BarsSnapshot(
      bars: bars,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final bars = await ref
          .read(marketRepositoryProvider)
          .fetchBars(arg.symbol, arg.range);
      return BarsSnapshot(
        bars: bars,
        fetchedAt: DateTime.now().toUtc(),
      );
    });
  }
}

final barsProvider =
    AutoDisposeAsyncNotifierProviderFamily<BarsNotifier, BarsSnapshot, BarsQuery>(
      BarsNotifier.new,
    );

bool _isBarsDataStale({
  required DateTime fetchedAt,
  required bool socketConnected,
}) {
  if (!socketConnected) {
    return true;
  }
  return DateTime.now().toUtc().difference(fetchedAt).inMinutes > 5;
}

/// Chart-facing provider that isolates bar list changes from live quote ticks.
final barsChartDataProvider = Provider.autoDispose.family<BarsChartData, BarsQuery>(
  (ref, query) {
    final barsSnapshot = ref.watch(
      barsProvider(query).select(
        (async) => switch (async) {
          AsyncData(:final value) => value,
          _ => null,
        },
      ),
    );
    final socketConnected = ref.watch(
      socketConnectionStateProvider.select(
        (state) => state.connectionState == SocketConnectionState.connected,
      ),
    );

    final async = ref.watch(barsProvider(query));

    if (async.isLoading && barsSnapshot == null) {
      return BarsChartData.loading();
    }

    if (async.hasError && barsSnapshot == null) {
      return BarsChartData.error(async.error!);
    }

    if (barsSnapshot != null) {
      return BarsChartData.ready(
        bars: barsSnapshot.bars,
        fetchedAt: barsSnapshot.fetchedAt,
        isStale: _isBarsDataStale(
          fetchedAt: barsSnapshot.fetchedAt,
          socketConnected: socketConnected,
        ),
      );
    }

    return BarsChartData.loading();
  },
);
