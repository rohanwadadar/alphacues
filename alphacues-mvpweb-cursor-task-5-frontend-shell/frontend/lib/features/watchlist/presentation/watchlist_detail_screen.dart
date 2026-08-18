import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../../core/widgets/trade_animation_overlay.dart';
import '../../portfolio/data/portfolio_providers.dart';
import '../data/watchlist_providers.dart';
import 'watchlist_form_dialog.dart';

const Map<String, String> _kStockSuggestions = {
  'AAPL': 'Apple Inc.',
  'MSFT': 'Microsoft Corporation',
  'GOOGL': 'Alphabet Inc. Class A',
  'TSLA': 'Tesla, Inc.',
  'NVDA': 'NVIDIA Corporation',
  'AMZN': 'Amazon.com, Inc.',
};

class WatchlistDetailScreen extends ConsumerStatefulWidget {
  const WatchlistDetailScreen({super.key, required this.watchlistId});

  final String watchlistId;

  @override
  ConsumerState<WatchlistDetailScreen> createState() =>
      _WatchlistDetailScreenState();
}

class _WatchlistDetailScreenState
    extends ConsumerState<WatchlistDetailScreen> {
  final TextEditingController _symbolController = TextEditingController();
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  final Map<String, WatchlistQuote> _liveQuotes = {};
  List<String> _subscribedSymbols = const [];
  String? _clientValidationError;

  @override
  void initState() {
    super.initState();
    _quoteSub = ref.read(socketClientProvider).quoteUpdates.listen(_onQuoteUpdate);
  }

  @override
  void deactivate() {
    _quoteSub?.cancel();
    _quoteSub = null;
    final symbols = List<String>.from(_subscribedSymbols);
    _subscribedSymbols = const [];
    try {
      final quoteManager = ref.read(quoteSubscriptionManagerProvider.notifier);
      final activeNotifier = ref.read(activeWatchlistIdsProvider.notifier);
      final id = widget.watchlistId;
      Future.microtask(() {
        try {
          if (symbols.isNotEmpty) {
            quoteManager.unsubscribeHidden(symbols);
          }
          activeNotifier.untrack(id);
        } catch (_) {}
      });
    } catch (_) {}
    super.deactivate();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  void _onQuoteUpdate(QuoteUpdatePayload payload) {
    if (!mounted) {
      return;
    }
    setState(() {
      _liveQuotes[payload.symbol] = WatchlistQuote(
        lastPrice: payload.lastPrice,
        changeAmount: payload.changeAmount,
        changePercent: payload.changePercent,
        asOf: payload.asOf,
      );
    });
  }

  void _syncSubscriptions(WatchlistDetail detail) {
    final newSymbols = detail.symbols;
    if (_symbolsEqual(_subscribedSymbols, newSymbols)) {
      return;
    }

    final quoteManager = ref.read(quoteSubscriptionManagerProvider.notifier);
    ref.read(activeWatchlistIdsProvider.notifier).track(widget.watchlistId);

    if (_subscribedSymbols.isNotEmpty) {
      quoteManager.unsubscribeHidden(_subscribedSymbols);
    }

    _subscribedSymbols = List.unmodifiable(newSymbols);
    if (newSymbols.isNotEmpty) {
      quoteManager.subscribeVisible(newSymbols);
    }

    for (final item in detail.items) {
      if (item.quote != null && !_liveQuotes.containsKey(item.symbol)) {
        _liveQuotes[item.symbol] = item.quote!;
      }
    }
  }

  static bool _symbolsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  WatchlistQuote? _effectiveQuote(WatchlistItem item) {
    return _liveQuotes[item.symbol] ?? item.quote;
  }

  bool _isQuoteStale(WatchlistQuote? quote, bool socketConnected) {
    if (quote == null) {
      return true;
    }
    if (!socketConnected) {
      return true;
    }
    try {
      final parsed = DateTime.parse(quote.asOf).toUtc();
      final diff = DateTime.now().toUtc().difference(parsed);
      return diff.inSeconds > 30;
    } catch (_) {
      return true;
    }
  }

  String? _addSymbolError() {
    if (_clientValidationError != null) {
      return _clientValidationError;
    }
    final addState = ref.watch(addSymbolProvider(widget.watchlistId));
    if (addState.hasError) {
      final error = addState.error;
      if (error is DuplicateSymbolException) {
        return error.message;
      }
      if (error is ValidationErrorException) {
        return error.message;
      }
      return 'Could not add symbol.';
    }
    return null;
  }

  Future<void> _addSymbol() async {
    final raw = _symbolController.text.trim().toUpperCase();
    if (raw.isEmpty) {
      setState(() => _clientValidationError = 'Enter a symbol.');
      return;
    }
    if (!watchlistSymbolPattern.hasMatch(raw)) {
      setState(
        () => _clientValidationError =
            'Use an uppercase ticker like AAPL or BRK.B.',
      );
      return;
    }

    // Check duplicate entry
    final detailAsync = ref.read(watchlistDetailProvider(widget.watchlistId));
    if (detailAsync case AsyncData(:final value)) {
      if (value.items.any((item) => item.symbol.toUpperCase() == raw)) {
        setState(
          () => _clientValidationError =
              '$raw is already in this watchlist.',
        );
        return;
      }
    }

    setState(() => _clientValidationError = null);
    ref.read(addSymbolProvider(widget.watchlistId).notifier).clearError();

    await ref.read(addSymbolProvider(widget.watchlistId).notifier).addSymbol(raw);

    if (!mounted) {
      return;
    }

    final addState = ref.read(addSymbolProvider(widget.watchlistId));
    if (addState.hasError) {
      setState(() {});
      return;
    }

    _symbolController.clear();
    FocusScope.of(context).unfocus();

    // Trigger Realtime Portfolio Invalidation & Animated Trade Experience
    ref.invalidate(portfolioSummaryProvider);
    ref.invalidate(portfolioTransactionsProvider);
    await TradeAnimationOverlay.show(context, type: TradeType.buy, symbol: raw);
  }

  Future<void> _confirmDeleteWatchlist(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete watchlist?'),
        content: Text('Remove "$name" and all of its symbols?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref.read(watchlistDeleteProvider.notifier).delete(widget.watchlistId);
    if (mounted) {
      context.go(AppRoutes.watchlists);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(watchlistDetailProvider(widget.watchlistId));
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketConnected =
        ref.watch(socketConnectionStateProvider).connectionState ==
        SocketConnectionState.connected;
    final addInlineError = _addSymbolError();

    ref.listen(watchlistDetailProvider(widget.watchlistId), (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncSubscriptions(value);
      }
    });

    if (detailAsync case AsyncData(:final value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncSubscriptions(value);
        }
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: detailAsync.maybeWhen(
          data: (detail) => Text(detail.name),
          orElse: () => const Text('Watchlist'),
        ),
        actions: [
          IconButton(
            onPressed: isOnline && detailAsync.hasValue
                ? () {
                    final detail = detailAsync.requireValue;
                    WatchlistFormDialog.show(
                      context,
                      mode: WatchlistFormMode.rename,
                      watchlistId: detail.watchlistId,
                      initialName: detail.name,
                    );
                  }
                : null,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Rename watchlist',
          ),
          IconButton(
            onPressed: isOnline && detailAsync.hasValue
                ? () => _confirmDeleteWatchlist(detailAsync.requireValue.name)
                : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete watchlist',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const StaleBanner(),
            Expanded(
              child: detailAsync.when(
                loading: () => const _DetailSkeleton(),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.refresh(
                    watchlistDetailProvider(widget.watchlistId),
                  ),
                ),
                data: (detail) {
                  if (detail.items.isEmpty) {
                    return const EmptyState(
                      heading: 'No symbols yet',
                      body: 'Add a stock symbol below to track live prices.',
                      icon: Icons.show_chart,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: detail.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = detail.items[index];
                      final quote = _effectiveQuote(item);
                      final stale = _isQuoteStale(quote, socketConnected);

                      return _SymbolRow(
                        symbol: item.symbol,
                        quote: quote,
                        isStale: stale || !isOnline,
                        onRemove: isOnline
                            ? () async {
                                await ref
                                    .read(
                                      removeSymbolProvider(widget.watchlistId)
                                          .notifier,
                                    )
                                    .removeSymbol(item.symbol);
                                ref.invalidate(portfolioSummaryProvider);
                                ref.invalidate(portfolioTransactionsProvider);
                                if (context.mounted) {
                                  TradeAnimationOverlay.show(
                                    context,
                                    type: TradeType.sell,
                                    symbol: item.symbol,
                                  );
                                }
                              }
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
            _AddSymbolField(
              controller: _symbolController,
              errorText: addInlineError,
              enabled: isOnline,
              isLoading: ref
                  .watch(addSymbolProvider(widget.watchlistId))
                  .isLoading,
              onSubmit: _addSymbol,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const Row(
        children: [
          LoadingSkeleton(width: 72, height: 20),
          Spacer(),
          LoadingSkeleton(width: 56, height: 20),
          SizedBox(width: AppSpacing.sm),
          LoadingSkeleton(width: 48, height: 20),
        ],
      ),
    );
  }
}

class _SymbolRow extends StatelessWidget {
  const _SymbolRow({
    required this.symbol,
    required this.quote,
    required this.isStale,
    required this.onRemove,
  });

  final String symbol;
  final WatchlistQuote? quote;
  final bool isStale;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor = quote == null
        ? theme.colorScheme.onSurfaceVariant
        : quote!.changeAmount >= 0
        ? AppColors.positive
        : AppColors.negative;

    return Dismissible(
      key: ValueKey(symbol),
      direction: onRemove == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onRemove?.call();
        return false;
      },
      background: Container(
        color: AppColors.negative,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: const Icon(Icons.delete_outline, color: AppColors.onNegative),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.symbolDetail(symbol)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(symbol, style: theme.textTheme.titleMedium),
                      if (_kStockSuggestions.containsKey(symbol))
                        Text(
                          _kStockSuggestions[symbol]!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (isStale)
                        Text(
                          'Stale',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                if (quote != null) ...[
                  Text(
                    quote!.lastPrice.toStringAsFixed(2),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${quote!.changeAmount >= 0 ? '+' : ''}${quote!.changeAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: changeColor,
                        ),
                      ),
                      Text(
                        '${quote!.changePercent >= 0 ? '+' : ''}${quote!.changePercent.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: changeColor,
                        ),
                      ),
                    ],
                  ),
                ],
                if (onRemove != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddSymbolField extends StatelessWidget {
  const _AddSymbolField({
    required this.controller,
    required this.errorText,
    required this.enabled,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      final query = textEditingValue.text.toUpperCase();
                      return _kStockSuggestions.entries
                          .where((e) =>
                              e.key.contains(query) ||
                              e.value.toUpperCase().contains(query))
                          .map((e) => e.key);
                    },
                    onSelected: (String selection) {
                      controller.text = selection;
                      onSubmit();
                    },
                    fieldViewBuilder:
                        (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                      fieldTextEditingController.addListener(() {
                        controller.text = fieldTextEditingController.text;
                      });
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: focusNode,
                        enabled: enabled && !isLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Search Stocks',
                          hintText: 'Search stock ticker or name (e.g. AAPL)',
                          errorText: errorText,
                        ),
                        onSubmitted: (_) => onSubmit(),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          child: SizedBox(
                            width: 300,
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                final name = _kStockSuggestions[option] ?? '';
                                return ListTile(
                                  title: Text(option, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(name),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: AppTheme.minTouchTarget,
                  width: AppTheme.minTouchTarget,
                  child: IconButton.filled(
                    onPressed: enabled && !isLoading ? onSubmit : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: AppSpacing.lg,
                            height: AppSpacing.lg,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
