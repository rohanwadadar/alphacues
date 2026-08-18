import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../data/bars_provider.dart';
import '../data/symbol_detail_providers.dart';
import '../../dashboard/presentation/widgets/dashboard_formatters.dart';
import 'widgets/stock_chart.dart';
import 'widgets/timeframe_selector.dart';

class SymbolDetailScreen extends ConsumerStatefulWidget {
  const SymbolDetailScreen({super.key, required this.symbol});

  final String symbol;

  @override
  ConsumerState<SymbolDetailScreen> createState() => _SymbolDetailScreenState();
}

class _SymbolDetailScreenState extends ConsumerState<SymbolDetailScreen> {
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  MarketQuote? _liveQuote;

  @override
  void initState() {
    super.initState();
    _quoteSub = ref.read(socketClientProvider).quoteUpdates.listen(_onQuoteUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(activeSymbolDetailProvider.notifier).track(widget.symbol);
      }
    });
  }

  @override
  void deactivate() {
    _quoteSub?.cancel();
    _quoteSub = null;
    final symbol = widget.symbol.trim().toUpperCase();
    try {
      final quoteManager = ref.read(quoteSubscriptionManagerProvider.notifier);
      final activeSymbol = ref.read(activeSymbolDetailProvider.notifier);
      Future.microtask(() {
        try {
          quoteManager.unsubscribeHidden([symbol]);
          activeSymbol.untrack(symbol);
        } catch (_) {}
      });
    } catch (_) {}
    super.deactivate();
  }

  void _onQuoteUpdate(QuoteUpdatePayload payload) {
    if (!mounted) {
      return;
    }
    final normalized = widget.symbol.trim().toUpperCase();
    if (payload.symbol != normalized) {
      return;
    }

    setState(() {
      _liveQuote = MarketQuote(
        symbol: payload.symbol,
        lastPrice: payload.lastPrice,
        changeAmount: payload.changeAmount,
        changePercent: payload.changePercent,
        asOf: payload.asOf,
      );
    });
    ref.read(symbolDetailProvider(normalized).notifier).patchQuote(_liveQuote!);
  }

  void _syncQuoteSubscription() {
    final normalized = widget.symbol.trim().toUpperCase();
    if (!marketSymbolPattern.hasMatch(normalized)) {
      return;
    }
    ref
        .read(quoteSubscriptionManagerProvider.notifier)
        .subscribeVisible([normalized]);
  }

  bool _isQuoteStale(MarketQuote? quote, bool socketConnected) {
    if (!socketConnected) {
      return true;
    }
    if (quote == null) {
      return true;
    }
    final asOf = DateTime.tryParse(quote.asOf)?.toUtc();
    if (asOf == null) {
      return true;
    }
    return DateTime.now().toUtc().difference(asOf).inSeconds > 60;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = widget.symbol.trim().toUpperCase();
    if (!marketSymbolPattern.hasMatch(normalized)) {
      return Scaffold(
        appBar: AppBar(title: Text(normalized)),
        body: SafeScreen(
          child: ErrorState(
            message: 'Symbol not found',
            onRetry: () {},
          ),
        ),
      );
    }

    final detailAsync = ref.watch(symbolDetailProvider(normalized));
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketConnected =
        ref.watch(socketConnectionStateProvider).connectionState ==
        SocketConnectionState.connected;

    ref.listen(symbolDetailProvider(normalized), (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncQuoteSubscription();
        _liveQuote ??= value.quote;
      }
    });

    if (detailAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncQuoteSubscription();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(normalized)),
      body: SafeScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isOnline || !socketConnected) const StaleBanner(),
            Expanded(
              child: detailAsync.when(
                loading: () => const _SymbolDetailSkeleton(),
                error: (error, _) {
                  if (error is SymbolNotFoundException) {
                    return ErrorState(
                      message: error.message,
                      onRetry: () {},
                    );
                  }

                  return ErrorState(
                    message: 'Market data unavailable',
                    onRetry: () => ref
                        .read(symbolDetailProvider(normalized).notifier)
                        .refresh(),
                  );
                },
                data: (snapshot) {
                  final quote = _liveQuote ?? snapshot.quote;
                  final stale = _isQuoteStale(quote, socketConnected) || !isOnline;

                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      if (stale)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Text(
                            'Last updated ${formatAsOfTimestamp(quote.asOf)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                        ),
                      _QuoteSection(quote: quote),
                      const SizedBox(height: AppSpacing.lg),
                      _ChartSection(symbol: normalized),
                      const SizedBox(height: AppSpacing.lg),
                      _FundamentalsSection(
                        fundamentals: snapshot.fundamentals,
                      ),
                    ],
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

class _QuoteSection extends StatelessWidget {
  const _QuoteSection({required this.quote});

  final MarketQuote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor = quote.changeAmount >= 0
        ? AppColors.positive
        : AppColors.negative;

    return Card(
      color: AppColors.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatPrice(quote.lastPrice),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${formatSignedAmount(quote.changeAmount)} (${formatPercent(quote.changePercent)})',
              style: theme.textTheme.titleMedium?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'As of ${formatAsOfTimestamp(quote.asOf)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(chartRangeProvider);
    final query = (symbol: symbol, range: range);
    final chartData = ref.watch(barsChartDataProvider(query));

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TimeframeSelector(
            selectedRange: range,
            onRangeChanged: (nextRange) {
              ref.read(chartRangeProvider.notifier).state = nextRange;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          if (chartData.isLoading)
            Card(
              color: AppColors.surfaceAlt,
              child: SizedBox(
                height: 220,
                child: Center(
                  child: LoadingSkeleton(
                    width: MediaQuery.sizeOf(context).width - AppSpacing.md * 2,
                    height: 180,
                  ),
                ),
              ),
            )
          else if (chartData.error != null)
            Card(
              color: AppColors.surfaceAlt,
              child: SizedBox(
                height: 220,
                child: ErrorState(
                  message: 'Chart data unavailable',
                  onRetry: () =>
                      ref.read(barsProvider(query).notifier).refresh(),
                ),
              ),
            )
          else
            StockChart(
              bars: chartData.bars,
              selectedRange: range,
              isStale: chartData.isStale,
            ),
        ],
      ),
    );
  }
}

class _FundamentalsSection extends StatelessWidget {
  const _FundamentalsSection({required this.fundamentals});

  final MarketFundamentals fundamentals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = fundamentals.displayEntries;

    return Card(
      color: AppColors.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fundamentals',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (entries.isEmpty)
              Text(
                'No fundamentals available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              for (final entry in entries)
                if (entry.key == 'description') ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Company Overview',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value.toString(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _labelForField(entry.key),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _formatFieldValue(entry.key, entry.value),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ],
        ),
      ),
    );
  }

  String _labelForField(String key) {
    if (key.isEmpty) {
      return key;
    }
    final spaced = key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match[1]} ${match[2]}';
    });
    return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  String _formatFieldValue(String key, dynamic value) {
    if (value == null) return '-';
    if (key == 'marketCap' && value is num) {
      final cap = value.toDouble();
      if (cap >= 1e12) return '\$${(cap / 1e12).toStringAsFixed(2)}T';
      if (cap >= 1e9) return '\$${(cap / 1e9).toStringAsFixed(2)}B';
      if (cap >= 1e6) return '\$${(cap / 1e6).toStringAsFixed(2)}M';
      return '\$${cap.toStringAsFixed(0)}';
    }
    if (value is num) {
      final doubleVal = value.toDouble();
      if (key.toLowerCase().contains('percent') || key == 'dividendYield') {
        final pct = doubleVal < 1.0 ? doubleVal * 100 : doubleVal;
        return '${pct.toStringAsFixed(2)}%';
      }
      if (doubleVal > 1000000) {
        return '\$${(doubleVal / 1e6).toStringAsFixed(2)}M';
      }
      return doubleVal.toStringAsFixed(2);
    }
    return value.toString();
  }
}

class _SymbolDetailSkeleton extends StatelessWidget {
  const _SymbolDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        LoadingSkeleton(width: double.infinity, height: 96),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(width: double.infinity, height: 220),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(width: double.infinity, height: 160),
      ],
    );
  }
}
