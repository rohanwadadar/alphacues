import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../market/data/symbol_detail_providers.dart';
import '../../market/data/symbol_search_provider.dart';
import '../../portfolio/data/portfolio_providers.dart';
import '../data/watchlist_providers.dart';

class WatchlistDetailScreen extends ConsumerStatefulWidget {
  const WatchlistDetailScreen({
    super.key,
    required this.watchlistId,
    this.autoEditSymbol,
  });

  final String watchlistId;
  final String? autoEditSymbol;

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
  bool _hasTriggeredAutoEdit = false;

  void _checkAutoEdit(WatchlistDetail detail) {
    if (widget.autoEditSymbol != null && !_hasTriggeredAutoEdit) {
      final target = detail.items
          .where((it) => it.symbol.toUpperCase() == widget.autoEditSymbol!.toUpperCase())
          .firstOrNull;
      if (target != null) {
        _hasTriggeredAutoEdit = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showEditStockDialog(target);
          }
        });
      }
    }
  }

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

    // Calculate total quantity if symbol is already in watchlist
    double finalQuantity = quantity ?? 1.0;
    final detailAsync = ref.read(watchlistDetailProvider(widget.watchlistId));
    if (detailAsync case AsyncData(:final value)) {
      for (final item in value.items) {
        if (item.symbol.toUpperCase() == raw) {
          finalQuantity = (item.quantity ?? 0.0) + (quantity ?? 1.0);
          break;
        }
      }
    }

    setState(() => _clientValidationError = null);
    ref.read(addSymbolProvider(widget.watchlistId).notifier).clearError();

    try {
      final repo = ref.read(watchlistRepositoryProvider);
      await repo.addSymbol(widget.watchlistId, raw, quantity: finalQuantity);
    } catch (e) {
      setState(() => _clientValidationError = 'Could not update symbol.');
      return;
    }

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

    // Invalidate providers so Watchlist UI instantly refreshes
    ref.invalidate(watchlistDetailProvider(widget.watchlistId));
    ref.invalidate(watchlistsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$raw added to watchlist'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── EDIT STOCK DIALOG (Quantity Add / Quantity Reduce / Delete Stock) ──────
  Future<void> _showEditStockDialog(WatchlistItem item) async {
    final theme = Theme.of(context);
    final currentQty = item.quantity ?? 1.0;
    final qtyController = TextEditingController();
    String editMode = 'add'; // 'add', 'reduce', 'delete'

    double livePrice = 0.0;
    try {
      final repository = ref.read(marketRepositoryProvider);
      final quote = await repository.getQuote(item.symbol);
      livePrice = quote.lastPrice;
    } catch (_) {
      livePrice = item.quote?.lastPrice ?? 0.0;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final inputQty = double.tryParse(qtyController.text.trim()) ?? 0.0;
            double calculatedQty = currentQty;
            if (editMode == 'add') {
              calculatedQty = currentQty + inputQty;
            } else if (editMode == 'reduce') {
              calculatedQty = (currentQty - inputQty).clamp(0.0, double.infinity);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit ${item.symbol}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Current: ${currentQty.toStringAsFixed(2)} shares',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (livePrice > 0)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Market Price:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '\$${livePrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    // ── Mode Selection Chips ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('+ Increase Qty'),
                            selected: editMode == 'add',
                            onSelected: (val) {
                              if (val) setDialogState(() => editMode = 'add');
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('− Reduce Qty'),
                            selected: editMode == 'reduce',
                            onSelected: (val) {
                              if (val) setDialogState(() => editMode = 'reduce');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: editMode == 'delete'
                                ? theme.colorScheme.onError
                                : theme.colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Remove Entire Stock',
                            style: TextStyle(
                              color: editMode == 'delete'
                                  ? theme.colorScheme.onError
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      selected: editMode == 'delete',
                      selectedColor: theme.colorScheme.error,
                      onSelected: (val) {
                        if (val) setDialogState(() => editMode = 'delete');
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Quantity Field (for Add / Reduce) ───────────────────
                    if (editMode != 'delete') ...[
                      TextField(
                        controller: qtyController,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: editMode == 'add'
                              ? 'Qty to Add'
                              : 'Qty to Reduce',
                          hintText: 'e.g. 2',
                          prefixIcon: Icon(
                            editMode == 'add'
                                ? Icons.add_circle_outline
                                : Icons.remove_circle_outline,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Updated Holdings:',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${calculatedQty.toStringAsFixed(2)} shares',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    editMode == 'delete' ? 'Remove Stock' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    if (editMode == 'delete') {
      try {
        final repo = ref.read(watchlistRepositoryProvider);
        await repo.removeSymbol(widget.watchlistId, item.symbol);

        ref.invalidate(watchlistDetailProvider(widget.watchlistId));
        ref.invalidate(watchlistsProvider);
        ref.invalidate(portfolioSummaryProvider);
        ref.invalidate(portfolioTransactionsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF673AB7),
              content: Text('Removed ${item.symbol} from watchlist'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.purple.shade900,
              content: Text('Action failed: $e'),
            ),
          );
        }
      }
      return;
    }

    final inputQty = double.tryParse(qtyController.text.trim()) ?? 0.0;
    if (inputQty <= 0) return;
    double newQty = currentQty;
    if (editMode == 'add') {
      newQty = currentQty + inputQty;
    } else if (editMode == 'reduce') {
      newQty = (currentQty - inputQty).clamp(0.0, double.infinity);
    }

    try {
      final repo = ref.read(watchlistRepositoryProvider);
      if (newQty <= 0) {
        await repo.removeSymbol(widget.watchlistId, item.symbol);
      } else {
        await repo.addSymbol(widget.watchlistId, item.symbol, quantity: newQty);
      }

      ref.invalidate(watchlistDetailProvider(widget.watchlistId));
      ref.invalidate(watchlistsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF673AB7),
            content: Text(
              newQty <= 0
                  ? 'Removed ${item.symbol} from watchlist'
                  : 'Updated ${item.symbol} quantity to ${newQty.toStringAsFixed(2)} shares',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.purple.shade900,
            content: Text('Action failed: $e'),
          ),
        );
      }
    }
  }

  Future<void> _confirmRemoveSymbol(WatchlistItem item) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 24),
            const SizedBox(width: 8),
            const Text('Remove Stock'),
          ],
        ),
        content: Text('Remove ${item.symbol} completely from this watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final repo = ref.read(watchlistRepositoryProvider);
      await repo.removeSymbol(widget.watchlistId, item.symbol);

      ref.invalidate(watchlistDetailProvider(widget.watchlistId));
      ref.invalidate(watchlistsProvider);
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF673AB7),
            content: Text('Removed ${item.symbol} from watchlist'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.purple.shade900,
            content: Text('Action failed: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(watchlistDetailProvider(widget.watchlistId));
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketConnected =
        ref.watch(socketConnectionStateProvider).connectionState ==
        SocketConnectionState.connected;
    final addInlineError = _addSymbolError();

    ref.listen(watchlistDetailProvider(widget.watchlistId), (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncSubscriptions(value);
        _checkAutoEdit(value);
      }
    });

    if (detailAsync case AsyncData(:final value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncSubscriptions(value);
          _checkAutoEdit(value);
        }
      });
    }

    final watchlistName = detailAsync.maybeWhen(
      data: (detail) => detail.name,
      orElse: () => 'Watchlist',
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: const [
          SizedBox(width: 8),
        ],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline) const StaleBanner(),

            // ── Watchlist Name Header (Below Back Button) ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  watchlistName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // ── Search & Add Stock Section (Below Watchlist Name) ───────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AddSymbolField(
                controller: _symbolController,
                errorText: addInlineError,
                enabled: isOnline,
                isLoading: ref
                    .watch(addSymbolProvider(widget.watchlistId))
                    .isLoading,
                onSubmit: _addSymbol,
              ),
            ),
            const SizedBox(height: 12),

            // ── Watchlist Stocks List (Below Search Section) ─────────────────
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
                      body:
                          'Search for a stock above to add it to this watchlist.',
                      icon: Icons.show_chart_rounded,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: detail.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = detail.items[index];
                      final quote = _effectiveQuote(item);
                      final stale = _isQuoteStale(quote, socketConnected);

                      return _ItemRow(
                        symbol: item.symbol,
                        quantity: item.quantity,
                        quote: quote,
                        isStale: stale || !isOnline,
                        onEdit: isOnline
                            ? () => _showEditStockDialog(item)
                            : null,
                        onDelete: isOnline
                            ? () => _confirmRemoveSymbol(item)
                            : null,
                      );
                    },
                  );
                },
              ),
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
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 64,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            LoadingSkeleton(width: 72, height: 20),
            Spacer(),
            LoadingSkeleton(width: 56, height: 20),
            SizedBox(width: AppSpacing.sm),
            LoadingSkeleton(width: 48, height: 20),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.symbol,
    this.quantity,
    this.quote,
    required this.isStale,
    this.onEdit,
    this.onDelete,
  });

  final String symbol;
  final double? quantity;
  final WatchlistQuote? quote;
  final bool isStale;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(symbolDetailProvider(symbol));

    // Use live quote if available from symbolDetailProvider
    final livePrice =
        detailAsync.valueOrNull?.quote.lastPrice ?? quote?.lastPrice ?? 0.0;
    final changeAmt =
        detailAsync.valueOrNull?.quote.changeAmount ?? quote?.changeAmount ?? 0.0;
    final changePct =
        detailAsync.valueOrNull?.quote.changePercent ?? quote?.changePercent ?? 0.0;

    final isPositive = changeAmt >= 0;
    // Green for profit / gain (isPositive), Red for loss
    final changeColor = isPositive ? AppColors.positive : AppColors.negative;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push(AppRoutes.symbolDetail(symbol)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Ticker Symbol & Quantity Badge ───────────────────────────
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        symbol,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (quantity != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${quantity!.toStringAsFixed(2)} qty',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                /* 
                // Commented out per request for potential future reuse:
                if (quantity != null && livePrice > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Val: \$${(quantity! * livePrice).toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                */

                // ── Live Price (Green for profit, Red for loss) & Percentage Change ──
                if (livePrice > 0) ...[
                  Text(
                    livePrice.toStringAsFixed(2),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: changeColor, // Colored GREEN for profit, RED for loss
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                // ── Edit Pen Button (Quantity Add / Remove) ──────────
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.85),
                      size: 20,
                    ),
                    tooltip: 'Edit quantity',
                  ),
                ],

                // ── Remove from Watchlist Button ────────────────────────
                if (onDelete != null) ...[
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    tooltip: 'Remove from Watchlist',
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

    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final repository = ref.read(marketRepositoryProvider);
        final results = await repository.searchSymbols(
          query.isEmpty ? 'A' : query,
          limit: 20,
        );
        if (mounted) {
          setState(() {
            _results = rankSearchResults(results, query);
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

    await widget.onSubmit(quantity: 1.0);
    widget.controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${stock.symbol} added to watchlist'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled && !widget.isLoading,
          textCapitalization: TextCapitalization.characters,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search stocks to add (e.g. AAPL)...',
            prefixIcon: const Icon(Icons.search_rounded),
            errorText: widget.errorText,
            filled: true,
            fillColor:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
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
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                ),
                shrinkWrap: true,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final stock = _results[index];
                  return ListTile(
                    dense: true,
                    onTap: () => _handleSelect(stock),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stock.exchange,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          onPressed: () => _handleSelect(stock),
                          tooltip: 'Add to Watchlist',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
