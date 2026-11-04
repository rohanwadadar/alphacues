import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_scope.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/socket_events.dart';
import '../../watchlist/data/watchlist_repository.dart'
    show ServiceUnavailableException;
import 'portfolio_repository.dart';

export 'portfolio_repository.dart';

/// Tracks whether the portfolio screen is visible for reconnect REST refresh.
class PortfolioScreenActiveNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void track() => state = true;

  void untrack() => state = false;
}

final portfolioScreenActiveProvider =
    NotifierProvider<PortfolioScreenActiveNotifier, bool>(
      PortfolioScreenActiveNotifier.new,
    );

Future<void> refreshPortfolioIfActive(Ref ref) async {
  if (!ref.read(portfolioScreenActiveProvider)) {
    return;
  }
  ref.invalidate(portfolioSummaryProvider);
  ref.invalidate(portfolioTransactionsProvider);
  await Future.wait([
    ref.read(portfolioSummaryProvider.future),
    ref.read(portfolioTransactionsProvider.future),
  ]);
}

void _registerPortfolioUserScope() {
  if (!userScopedProviderKeys.contains(portfolioSummaryProvider)) {
    userScopedProviderKeys.add(portfolioSummaryProvider);
  }
  if (!userScopedProviderKeys.contains(portfolioTransactionsProvider)) {
    userScopedProviderKeys.add(portfolioTransactionsProvider);
  }
  if (!userScopedProviderKeys.contains(portfolioHistoryProvider)) {
    userScopedProviderKeys.add(portfolioHistoryProvider);
  }
  if (!userScopedProviderKeys.contains(portfolioScreenActiveProvider)) {
    userScopedProviderKeys.add(portfolioScreenActiveProvider);
  }
}

class PortfolioSummaryNotifier extends AsyncNotifier<PortfolioOverview> {
  PortfolioOverview? _cached;

  @override
  Future<PortfolioOverview> build() async {
    _registerPortfolioUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final overview = await ref
          .read(portfolioRepositoryProvider)
          .getPortfolioSummary();
      _cached = overview;
      return overview;
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
      final overview = await ref
          .read(portfolioRepositoryProvider)
          .getPortfolioSummary();
      _cached = overview;
      return overview;
    });
  }

  void patchQuote(QuoteUpdatePayload quote) {
    final current = state.asData?.value ?? _cached;
    if (current == null) return;

    var matched = false;
    var valueDelta = 0.0;
    var dayChangeDelta = 0.0;
    final positions = current.positions.map((position) {
      if (position.symbol != quote.symbol) return position;
      matched = true;
      if (position.lastPrice != null) {
        valueDelta += (quote.lastPrice - position.lastPrice!) * position.volume;
      }
      if (position.changeAmount != null) {
        dayChangeDelta +=
            (quote.changeAmount - position.changeAmount!) * position.volume;
      }
      return position.copyWith(
        lastPrice: quote.lastPrice,
        changeAmount: quote.changeAmount,
        changePercent: quote.changePercent,
      );
    }).toList(growable: false);

    if (!matched) return;

    final summary = current.summary;
    final totalValue = summary.totalValue + valueDelta;
    final totalProfit = summary.totalProfit + valueDelta;
    final costBasis = positions.fold<double>(
      0,
      (total, position) => total + position.totalPrice,
    );
    final updated = PortfolioOverview(
      summary: summary.copyWith(
        totalValue: totalValue,
        totalProfit: totalProfit,
        totalReturn: costBasis > 0 ? totalProfit / costBasis * 100 : summary.totalReturn,
        dayChange: summary.dayChange + dayChangeDelta,
        asOf: quote.asOf,
      ),
      positions: positions,
    );
    _cached = updated;
    state = AsyncData(updated);
  }
}

final portfolioSummaryProvider =
    AsyncNotifierProvider<PortfolioSummaryNotifier, PortfolioOverview>(
      PortfolioSummaryNotifier.new,
    );

class PortfolioTransactionsNotifier
    extends AsyncNotifier<List<PortfolioEvent>> {
  List<PortfolioEvent>? _cached;
  String? _nextCursor;

  String? get nextCursor => _nextCursor;

  bool get hasMore => _nextCursor != null;

  @override
  Future<List<PortfolioEvent>> build() async {
    _registerPortfolioUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final result = await ref
          .read(portfolioRepositoryProvider)
          .getPortfolioTransactions();
      _cached = result.items;
      _nextCursor = result.nextCursor;
      return result.items;
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
          .read(portfolioRepositoryProvider)
          .getPortfolioTransactions();
      _cached = result.items;
      _nextCursor = result.nextCursor;
      return result.items;
    });
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || state.isLoading) {
      return;
    }

    final cursor = _nextCursor;
    final current = state.asData?.value ?? _cached ?? const <PortfolioEvent>[];

    try {
      final result = await ref
          .read(portfolioRepositoryProvider)
          .getPortfolioTransactions(cursor: cursor);
      _nextCursor = result.nextCursor;
      final merged = [...current, ...result.items];
      _cached = merged;
      state = AsyncData(merged);
    } catch (_) {
      // Keep existing items visible on pagination failure.
    }
  }
}

final portfolioTransactionsProvider =
    AsyncNotifierProvider<PortfolioTransactionsNotifier, List<PortfolioEvent>>(
      PortfolioTransactionsNotifier.new,
    );

class PortfolioHistoryNotifier extends AsyncNotifier<List<PortfolioSnapshot>> {
  List<PortfolioSnapshot>? _cached;

  @override
  Future<List<PortfolioSnapshot>> build() async {
    _registerPortfolioUserScope();
    final connectivity = ref.watch(connectivityServiceProvider);
    if (!connectivity.isOnline && _cached != null) {
      return _cached!;
    }

    try {
      final history = await ref
          .read(portfolioRepositoryProvider)
          .getPortfolioHistory();
      _cached = history;
      return history;
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
      final history = await ref
          .read(portfolioRepositoryProvider)
          .getPortfolioHistory();
      _cached = history;
      return history;
    });
  }
}

final portfolioHistoryProvider =
    AsyncNotifierProvider<PortfolioHistoryNotifier, List<PortfolioSnapshot>>(
      PortfolioHistoryNotifier.new,
    );

class PortfolioEventFormState {
  const PortfolioEventFormState({
    this.symbolError,
    this.actionError,
    this.volumeError,
    this.priceError,
    this.dateError,
    this.isSubmitting = false,
  });

  final String? symbolError;
  final String? actionError;
  final String? volumeError;
  final String? priceError;
  final String? dateError;
  final bool isSubmitting;

  PortfolioEventFormState copyWith({
    String? symbolError,
    String? actionError,
    String? volumeError,
    String? priceError,
    String? dateError,
    bool? isSubmitting,
    bool clearErrors = false,
  }) {
    return PortfolioEventFormState(
      symbolError: clearErrors ? null : symbolError ?? this.symbolError,
      actionError: clearErrors ? null : actionError ?? this.actionError,
      volumeError: clearErrors ? null : volumeError ?? this.volumeError,
      priceError: clearErrors ? null : priceError ?? this.priceError,
      dateError: clearErrors ? null : dateError ?? this.dateError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class PortfolioEventFormNotifier extends Notifier<PortfolioEventFormState> {
  @override
  PortfolioEventFormState build() => const PortfolioEventFormState();

  bool validate({
    required String symbol,
    required String action,
    required String volumeText,
    required String priceText,
    required DateTime date,
  }) {
    String? symbolError;
    String? volumeError;
    String? priceError;
    String? dateError;

    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) {
      symbolError = 'Symbol is required';
    } else if (!portfolioSymbolPattern.hasMatch(normalized)) {
      symbolError = 'Enter a valid ticker (e.g. AAPL)';
    }

    final volume = int.tryParse(volumeText.trim());
    if (volume == null || volume <= 0) {
      volumeError = 'Quantity must be a positive integer';
    }

    final price = double.tryParse(priceText.trim());
    if (price == null || price <= 0) {
      priceError = 'Price must be greater than zero';
    }

    if (!isPortfolioEventDateToday(date)) {
      dateError = 'Date must be today.';
    }

    if (action != 'BUY' && action != 'SELL') {
      // Guard against invalid enum values in UI state.
    }

    state = PortfolioEventFormState(
      symbolError: symbolError,
      volumeError: volumeError,
      priceError: priceError,
      dateError: dateError,
    );

    return symbolError == null &&
        volumeError == null &&
        priceError == null &&
        dateError == null;
  }

  Future<bool> submitCreate({
    required String symbol,
    required String action,
    required int volume,
    required double price,
    required String timeStamp,
    required String idempotencyKey,
  }) async {
    state = state.copyWith(clearErrors: true, isSubmitting: true);
    try {
      await ref
          .read(portfolioRepositoryProvider)
          .createEvent(
            symbol: symbol,
            action: action,
            volume: volume,
            price: price,
            timeStamp: timeStamp,
            idempotencyKey: idempotencyKey,
          );
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
      state = const PortfolioEventFormState();
      return true;
    } on PortfolioValidationErrorException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        symbolError: error.details['symbol']?.toString(),
        volumeError: error.details['volume']?.toString(),
        priceError: error.details['price']?.toString(),
        dateError: error.details['time_stamp']?.toString(),
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  Future<bool> submitUpdate({
    required String eventId,
    required String symbol,
    required String action,
    required int volume,
    required double price,
    required String timeStamp,
  }) async {
    state = state.copyWith(clearErrors: true, isSubmitting: true);
    try {
      await ref
          .read(portfolioRepositoryProvider)
          .updateEvent(
            eventId,
            symbol: symbol,
            action: action,
            volume: volume,
            price: price,
            timeStamp: timeStamp,
          );
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
      state = const PortfolioEventFormState();
      return true;
    } on PortfolioValidationErrorException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        symbolError: error.details['symbol']?.toString(),
        volumeError: error.details['volume']?.toString(),
        priceError: error.details['price']?.toString(),
        dateError: error.details['time_stamp']?.toString(),
      );
      rethrow;
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  void reset() {
    state = const PortfolioEventFormState();
  }
}

final portfolioEventFormProvider =
    NotifierProvider<PortfolioEventFormNotifier, PortfolioEventFormState>(
      PortfolioEventFormNotifier.new,
    );
