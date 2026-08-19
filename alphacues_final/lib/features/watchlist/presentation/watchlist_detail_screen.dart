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
import '../../market/data/market_repository.dart';
import '../../market/data/symbol_detail_providers.dart';
import '../../market/data/symbol_search_provider.dart';
import '../../portfolio/data/portfolio_providers.dart';
import '../data/watchlist_providers.dart';
import 'watchlist_form_dialog.dart';
import 'widgets/watchlist_tracking_chart.dart';

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
  String _selectedChartRange = '1D';

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

  Future<void> _addSymbol({double? quantity}) async {
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

    // Verify symbol exists via market repository
    setState(() => _clientValidationError = null);
    try {
      final repository = ref.read(marketRepositoryProvider);
      await repository.getQuote(raw);
    } catch (_) {
      // Fallback check via search
      try {
        final repository = ref.read(marketRepositoryProvider);
        final results = await repository.searchSymbols(raw);
        if (results.isEmpty) {
          setState(() => _clientValidationError = 'Symbol not found in market.');
          return;
        }
      } catch (_) {
        setState(() => _clientValidationError = 'Failed to verify symbol.');
        return;
      }
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

    await ref.read(addSymbolProvider(widget.watchlistId).notifier).addSymbol(raw, quantity: quantity);

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

    // Invalidate providers so Watchlist UI and Portfolio instantly refresh!
    ref.invalidate(watchlistDetailProvider(widget.watchlistId));
    ref.invalidate(watchlistsProvider);
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

                      return _ItemRow(
                        symbol: item.symbol,
                        quantity: item.quantity,
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

typedef _SymbolRow = _ItemRow;

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.symbol,
    this.quantity,
    this.quote,
    required this.isStale,
    this.onRemove,
  });

  final String symbol;
  final double? quantity;
  final WatchlistQuote? quote;
  final bool isStale;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(symbolDetailProvider(symbol));
    
    // Use live quote if available from symbolDetailProvider
    final livePrice = detailAsync.valueOrNull?.quote.lastPrice ?? quote?.lastPrice ?? 0.0;
    final changeAmt = detailAsync.valueOrNull?.quote.changeAmount ?? quote?.changeAmount ?? 0.0;
    final changePct = detailAsync.valueOrNull?.quote.changePercent ?? quote?.changePercent ?? 0.0;

    final changeColor = changeAmt >= 0 ? AppColors.positive : AppColors.negative;

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
                      Row(
                        children: [
                          Text(symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          if (quantity != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${quantity!.toStringAsFixed(2)} qty',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (quantity != null && livePrice > 0)
                        Text(
                          'Val: \$${(quantity! * livePrice).toStringAsFixed(2)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (livePrice > 0) ...[
                  Text(
                    livePrice.toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${changeAmt >= 0 ? '+' : ''}${changeAmt.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
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

class _AddSymbolField extends ConsumerStatefulWidget {
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
  final Future<void> Function({double? quantity}) onSubmit;

  @override
  ConsumerState<_AddSymbolField> createState() => _AddSymbolFieldState();
}

class _AddSymbolFieldState extends ConsumerState<_AddSymbolField> {
  List<MarketSearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    final query = value.trim();

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final repository = ref.read(marketRepositoryProvider);
        final results = await repository.searchSymbols(query.isEmpty ? 'A' : query);
        if (mounted) {
          setState(() {
            _results = results;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _results = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _handleSelect(MarketSearchResult stock) async {
    widget.controller.text = stock.symbol;
    setState(() {
      _results = [];
    });

    // Fetch live quote for unit price calculation
    double livePrice = 150.0;
    try {
      final repository = ref.read(marketRepositoryProvider);
      final quote = await repository.getQuote(stock.symbol);
      livePrice = quote.lastPrice;
    } catch (_) {}

    final quantityController = TextEditingController(text: '1');
    final double? quantity = await showDialog<double>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final qtyVal = double.tryParse(quantityController.text.trim()) ?? 0.0;
            final totalCost = qtyVal * livePrice;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      stock.symbol.isNotEmpty ? stock.symbol[0] : '?',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buy ${stock.symbol}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(stock.name, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Market Price:', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('\$${livePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: quantityController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Quantity (shares)',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Estimated Cost:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '\$${totalCost.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final val = double.tryParse(quantityController.text.trim());
                    Navigator.of(context).pop(val ?? 0.0);
                  },
                  child: const Text('Confirm Buy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (quantity != null && quantity > 0) {
      widget.controller.text = stock.symbol;
      await widget.onSubmit(quantity: quantity);
      widget.controller.clear();
      if (mounted) {
        TradeAnimationOverlay.show(
          context,
          type: TradeType.buy,
          symbol: stock.symbol,
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_results.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                    itemBuilder: (context, index) {
                      final stock = _results[index];
                      return ListTile(
                        dense: true,
                        onTap: () => _handleSelect(stock),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            stock.symbol.isNotEmpty ? stock.symbol[0] : '?',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          stock.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          stock.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                stock.exchange,
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            IconButton(
                              icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 22),
                              onPressed: () => _handleSelect(stock),
                              tooltip: 'Buy',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            TextField(
              controller: widget.controller,
              enabled: widget.enabled && !widget.isLoading,
              textCapitalization: TextCapitalization.characters,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search stocks to buy (e.g. AAPL)...',
                prefixIcon: const Icon(Icons.search_rounded),
                errorText: widget.errorText,
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                ),
                suffixIcon: _isSearching || widget.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : widget.controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              widget.controller.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
