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
import '../../alerts/presentation/price_alert_modal.dart';
import '../data/symbol_detail_providers.dart';
import '../../dashboard/presentation/widgets/dashboard_formatters.dart';
import 'widgets/stock_chart.dart';
import 'widgets/stock_valuation_calculator.dart';
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
  Bar? _scrubbedBar;

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

    final currentPrice = detailAsync.valueOrNull?.quote.lastPrice ?? 150.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(normalized),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded),
            tooltip: 'Set Price Alert',
            onPressed: () {
              PriceAlertModal.show(
                context,
                symbol: normalized,
                currentPrice: currentPrice,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                      _QuoteSection(
                        symbol: normalized,
                        quote: quote,
                        scrubbedBar: _scrubbedBar,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ChartSection(
                        symbol: normalized,
                        onScrub: (bar) => setState(() => _scrubbedBar = bar),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FundamentalsSection(
                        fundamentals: snapshot.fundamentals,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      StockValuationCalculator(
                        symbol: normalized,
                        currentPrice: quote.lastPrice,
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

const _kRangeLabels = {
  '1D': 'Past Day',
  '1W': 'Past 1 Week',
  '1M': 'Past 1 Month',
  '3M': 'Past 3 Months',
  '6M': 'Past 6 Months',
  '1Y': 'Past 1 Year',
  '5Y': 'Past 5 Years',
  'MAX': 'All Time',
};

class _QuoteSection extends ConsumerWidget {
  const _QuoteSection({
    required this.symbol,
    required this.quote,
    required this.scrubbedBar,
  });

  final String symbol;
  final MarketQuote quote;
  final Bar? scrubbedBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final range = ref.watch(chartRangeProvider);
    final chartData = ref.watch(barsChartDataProvider((symbol: symbol, range: range)));

    double displayPrice = quote.lastPrice;
    double priceChange = quote.changeAmount;
    double percentChange = quote.changePercent;
    String subLabel = 'As of ${formatAsOfTimestamp(quote.asOf)}';

    final bars = chartData.bars;

    if (scrubbedBar != null) {
      displayPrice = scrubbedBar!.closePrice;
      if (bars.isNotEmpty) {
        final startPrice = bars.first.closePrice;
        priceChange = scrubbedBar!.closePrice - startPrice;
        percentChange = startPrice > 0 ? (priceChange / startPrice) * 100 : 0.0;
      }
      subLabel = _formatScrubDate(scrubbedBar!.timeStamp);
    } else if (range != '1D' && bars.length >= 2) {
      final firstPrice = bars.first.closePrice;
      priceChange = quote.lastPrice - firstPrice;
      percentChange = firstPrice > 0 ? (priceChange / firstPrice) * 100 : 0.0;
      final rangeText = _kRangeLabels[range] ?? range;
      subLabel = rangeText;
    } else {
      subLabel = 'Past Day';
    }

    final changeColor = priceChange >= 0 ? AppColors.positive : AppColors.negative;

    return Card(
      color: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatPrice(displayPrice),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  '${formatSignedAmount(priceChange)} (${formatPercent(percentChange)})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '• $subLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatScrubDate(String timestamp) {
    final dt = DateTime.tryParse(timestamp)?.toLocal();
    if (dt == null) return timestamp;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final month = _monthName(dt.month);
    return '$month ${dt.day}, ${dt.year} $hour:$minute $ampm';
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({
    required this.symbol,
    this.onScrub,
  });

  final String symbol;
  final ValueChanged<Bar?>? onScrub;

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
              onScrub: onScrub,
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
    final colorScheme = theme.colorScheme;
    final entries = fundamentals.displayEntries;

    final descriptionEntry = entries.where((e) => e.key.toLowerCase() == 'description').firstOrNull;
    final metricEntries = entries.where((e) => e.key.toLowerCase() != 'description').toList();

    return Card(
      color: AppColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats_rounded, size: 20, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Fundamentals & Key Metrics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (metricEntries.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: metricEntries.length,
                itemBuilder: (context, index) {
                  final entry = metricEntries[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _labelForField(entry.key),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatFieldValue(entry.key, entry.value),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (descriptionEntry != null) ...[
              if (metricEntries.isNotEmpty) const SizedBox(height: AppSpacing.md),
              Text(
                'Company Overview',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descriptionEntry.value.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
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
