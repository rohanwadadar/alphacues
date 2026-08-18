import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/user_scope.dart';
import '../../features/dashboard/data/dashboard_providers.dart';
import '../../features/market/data/symbol_detail_providers.dart';
import '../../features/portfolio/data/portfolio_providers.dart';
import '../../features/watchlist/data/watchlist_providers.dart';
import 'socket_client.dart';
import 'socket_events.dart';

const _subscriptionCap = 50;

/// Manages active quote symbol subscriptions over the realtime socket.
class QuoteSubscriptionManager extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _registerQuoteSubscriptionUserScope();
    return {};
  }

  SocketClient get _socketClient => ref.read(socketClientProvider);

  /// Subscribes to newly visible symbols (diff against current set).
  void subscribeVisible(List<String> symbols) {
    final capped = _capSymbols(symbols);
    final current = state;
    final newSymbols = capped.where((s) => !current.contains(s)).toList();
    if (newSymbols.isEmpty) {
      return;
    }

    _socketClient.emit(kSubscribeQuotes, {'symbols': newSymbols});
    state = {...current, ...newSymbols};
  }

  /// Unsubscribes from symbols that left the viewport.
  void unsubscribeHidden(List<String> symbols) {
    if (symbols.isEmpty) {
      return;
    }

    final leaving = symbols.where((s) => state.contains(s)).toList();
    if (leaving.isEmpty) {
      return;
    }

    _socketClient.emit(kUnsubscribeQuotes, {'symbols': leaving});
    final next = {...state}..removeAll(leaving);
    state = next;
  }

  /// Re-establishes subscriptions after reconnect and refreshes watchlists via REST.
  Future<void> resubscribeAll() async {
    final symbols = state.toList();
    if (symbols.isNotEmpty) {
      _socketClient.emit(kSubscribeQuotes, {'symbols': symbols});
    }
    _socketClient.emit(kSubscribeNotifications, null);

    ref.read(socketConnectionStateProvider.notifier).setAwaitingRestRefresh(
      true,
    );

    try {
      await Future.wait([
        refreshTrackedWatchlists(ref),
        refreshDashboardIfActive(ref),
        refreshActiveSymbolDetail(ref),
        refreshPortfolioIfActive(ref),
      ]);
    } finally {
      ref.read(socketConnectionStateProvider.notifier).completeRestRefresh();
    }
  }

  List<String> _capSymbols(List<String> symbols) {
    if (symbols.length <= _subscriptionCap) {
      return symbols;
    }
    developer.log(
      'Quote subscription capped at $_subscriptionCap symbols '
      '(requested ${symbols.length})',
      name: 'QuoteSubscriptionManager',
    );
    return symbols.take(_subscriptionCap).toList();
  }
}

final quoteSubscriptionManagerProvider =
    NotifierProvider<QuoteSubscriptionManager, Set<String>>(
      QuoteSubscriptionManager.new,
    );

void _registerQuoteSubscriptionUserScope() {
  if (!userScopedProviderKeys.contains(quoteSubscriptionManagerProvider)) {
    userScopedProviderKeys.add(quoteSubscriptionManagerProvider);
  }
  if (!userScopedProviderKeys.contains(activeWatchlistIdsProvider)) {
    userScopedProviderKeys.add(activeWatchlistIdsProvider);
  }
}
