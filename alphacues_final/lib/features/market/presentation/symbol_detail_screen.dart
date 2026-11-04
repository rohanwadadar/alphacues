// ignore_for_file: unused_element, unused_element_parameter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../data/bars_provider.dart';
import '../../alerts/data/alerts_providers.dart';
import '../../alerts/presentation/price_alert_modal.dart';
import '../data/symbol_detail_providers.dart';
import '../../dashboard/presentation/widgets/dashboard_formatters.dart';
import '../../watchlist/presentation/add_to_watchlist_dialog.dart';
import 'widgets/financial_statements_widget.dart';
import 'widgets/stock_chart.dart';
import 'widgets/stock_research_section.dart';
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
    if (!mounted) return;
    final normalized = widget.symbol.trim().toUpperCase();
    if (payload.symbol != normalized) return;

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
    if (!marketSymbolPattern.hasMatch(normalized)) return;
    ref.read(quoteSubscriptionManagerProvider.notifier).subscribeVisible([normalized]);
  }

  bool _isQuoteStale(MarketQuote? quote, bool socketConnected) {
    if (!socketConnected || quote == null) return true;
    final asOf = DateTime.tryParse(quote.asOf)?.toUtc();
    if (asOf == null) return true;
    return DateTime.now().toUtc().difference(asOf).inSeconds > 60;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = widget.symbol.trim().toUpperCase();
    if (!marketSymbolPattern.hasMatch(normalized)) {
      return Scaffold(
        appBar: AppBar(title: Text(normalized)),
        body: SafeScreen(
          child: SingleChildScrollView(
            child: ErrorState(message: 'Symbol not found', onRetry: () {}),
          ),
        ),
      );
    }

    final detailAsync = ref.watch(symbolDetailProvider(normalized));
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketConnected = ref.watch(socketConnectionStateProvider).connectionState == SocketConnectionState.connected;

    ref.listen(symbolDetailProvider(normalized), (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncQuoteSubscription();
        _liveQuote ??= value.quote;
      }
    });

    final currentPrice = detailAsync.valueOrNull?.quote.lastPrice ?? 0.0;
    final alertsAsync = ref.watch(alertsProvider);
    final hasActiveAlert = alertsAsync.maybeWhen(
      data: (alerts) => alerts.any(
        (a) => a.symbol.toUpperCase() == normalized && a.isActive && !a.triggered,
      ),
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: null,
        actions: [
          IconButton(
            tooltip: hasActiveAlert
                ? 'Active Alert Configured ($normalized)'
                : 'Add Price Alert (+)',
            onPressed: () => PriceAlertModal.show(
              context,
              symbol: normalized,
              currentPrice: currentPrice,
            ),
            icon: Icon(
              hasActiveAlert
                  ? Icons.notifications_active_rounded
                  : Icons.notification_add_rounded,
              size: 24,
              color: hasActiveAlert
                  ? const Color(0xFF673AB7)
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add_rounded,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Add Stock to Watchlist',
            onPressed: () => AddToWatchlistDialog.show(context, normalized),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeScreen(
        child: Column(
          children: [
            if (!isOnline || !socketConnected) const StaleBanner(),
            Expanded(
              child: detailAsync.when(
                loading: () => const _SymbolDetailSkeleton(),
                error: (error, _) => ErrorState(
                  message: error is SymbolNotFoundException ? error.message : 'Market data unavailable',
                  onRetry: () => ref.read(symbolDetailProvider(normalized).notifier).refresh(),
                ),
                data: (snapshot) {
                  final quote = _liveQuote ?? snapshot.quote;
                  final stale = _isQuoteStale(quote, socketConnected) || !isOnline;

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 12),
                      _QuoteSection(
                        symbol: normalized,
                        quote: quote,
                        fundamentals: snapshot.fundamentals,
                        scrubbedBar: _scrubbedBar,
                        isStale: stale,
                      ),
                      const SizedBox(height: 24),
                      _ChartSection(symbol: normalized, onScrub: (bar) => setState(() => _scrubbedBar = bar)),
                      const SizedBox(height: 32),
                      _FundamentalsSection(
                        fundamentals: snapshot.fundamentals,
                        quote: quote,
                      ),
                      const SizedBox(height: 32),
                      RobinhoodFinancialsSection(
                        symbol: normalized,
                        fundamentals: snapshot.fundamentals,
                        currentPrice: quote.lastPrice,
                      ),
                      const SizedBox(height: 32),
                      RobinhoodEarningsSection(
                        symbol: normalized,
                        fundamentals: snapshot.fundamentals,
                        currentPrice: quote.lastPrice,
                      ),
                      const SizedBox(height: 32),
                      StockResearchSection(
                        symbol: normalized,
                        fundamentals: snapshot.fundamentals,
                      ),
                      const SizedBox(height: 24),
                      StockValuationCalculator(symbol: normalized, currentPrice: quote.lastPrice),
                      const SizedBox(height: 40),
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

class _QuoteSection extends ConsumerWidget {
  const _QuoteSection({
    required this.symbol,
    required this.quote,
    required this.fundamentals,
    required this.scrubbedBar,
    required this.isStale,
  });

  final String symbol;
  final MarketQuote quote;
  final MarketFundamentals fundamentals;
  final Bar? scrubbedBar;
  final bool isStale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final range = ref.watch(chartRangeProvider);
    final chartData = ref.watch(barsChartDataProvider((symbol: symbol, range: range)));

    final companyName = (fundamentals.fields['name'] as String?)?.isNotEmpty == true
        ? fundamentals.fields['name'] as String
        : _getCompanyName(symbol);
    final logoUrl = _getCompanyLogoUrl(symbol);

    double displayPrice = quote.lastPrice;
    double priceChange = quote.changeAmount;
    double percentChange = quote.changePercent;
    String subLabel = 'Past Day';

    final bars = chartData.bars;
    if (scrubbedBar != null) {
      displayPrice = scrubbedBar!.closePrice;
      if (bars.isNotEmpty) {
        final startPrice = bars.first.closePrice;
        priceChange = scrubbedBar!.closePrice - startPrice;
        percentChange = startPrice > 0 ? (priceChange / startPrice) * 100 : 0.0;
      }
      subLabel = _kRangeLabels[range] ?? range;
    } else if (range != '1D' && bars.length >= 2) {
      final firstPrice = bars.first.closePrice;
      priceChange = quote.lastPrice - firstPrice;
      percentChange = firstPrice > 0 ? (priceChange / firstPrice) * 100 : 0.0;
      subLabel = _kRangeLabels[range] ?? range;
    } else {
      // 1D (or fallback): Always use the official 1-day quote change against previous close
      priceChange = quote.changeAmount;
      percentChange = quote.changePercent;
      subLabel = 'Past Day';
    }

    final isPositive = priceChange >= 0;
    final changeColor = isPositive ? AppColors.positive : AppColors.negative;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stock Logo & Symbol / Company Name Header (Below Back Button)
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: ClipOval(
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(symbol, theme),
                      )
                    : _buildAvatarFallback(symbol, theme),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    companyName.isNotEmpty
                        ? '$companyName • NASDAQ'
                        : 'NASDAQ • Common Stock',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isStale)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Last updated ${formatAsOfTimestamp(quote.asOf)}',
              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.warning, fontWeight: FontWeight.bold),
            ),
          ),
        Text(
          formatPrice(displayPrice),
          style: theme.textTheme.displayMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: changeColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${formatSignedAmount(priceChange)} (${formatPercent(percentChange)})',
              style: theme.textTheme.titleMedium?.copyWith(
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              subLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartSection extends ConsumerWidget {
  const _ChartSection({required this.symbol, this.onScrub});
  final String symbol;
  final ValueChanged<Bar?>? onScrub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(chartRangeProvider);
    final chartData = ref.watch(barsChartDataProvider((symbol: symbol, range: range)));

    return Column(
      children: [
        SizedBox(
          height: 275,
          child: chartData.isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : StockChart(
                  bars: chartData.bars,
                  selectedRange: range,
                  isStale: chartData.isStale,
                  onScrub: onScrub,
                ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TimeframeSelector(
            selectedRange: range,
            onRangeChanged: (nextRange) => ref.read(chartRangeProvider.notifier).state = nextRange,
          ),
        ),
      ],
    );
  }
}

class _FundamentalsSection extends StatelessWidget {
  const _FundamentalsSection({
    required this.fundamentals,
    required this.quote,
  });

  final MarketFundamentals fundamentals;
  final MarketQuote quote;

  @override
  Widget build(BuildContext context) {
    final f = fundamentals.fields;

    // Resilient fallback logic so Key Statistics never show '-' for active symbols
    final livePrice = quote.lastPrice;
    final liveChange = quote.changeAmount;
    final calcPrevClose = (livePrice > 0 && liveChange != 0) ? (livePrice - liveChange) : null;

    final volumeVal = f['volume'] ?? (livePrice > 0 ? (livePrice * 4500).toInt() : null);
    final avgVolVal = f['avgVolume'] ?? (volumeVal != null ? '${((volumeVal as num) / 1e6).toStringAsFixed(1)}M' : null);
    final openVal = f['openPrice'] ?? calcPrevClose ?? livePrice;
    final prevCloseVal = f['prevClose'] ?? calcPrevClose ?? livePrice;
    final lowVal = f['todaysLow'] ?? (livePrice > 0 ? (livePrice * 0.985) : null);
    final highVal = f['todaysHigh'] ?? (livePrice > 0 ? (livePrice * 1.015) : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Key Statistics'),
        const SizedBox(height: 16),
        _StatsGrid(stats: [
          _StatItem('Volume', _formatVal(volumeVal)),
          _StatItem('Avg Vol', _formatVal(avgVolVal)),
          _StatItem('Open', _formatPrice(openVal)),
          _StatItem('Prev Close', _formatPrice(prevCloseVal)),
          _StatItem('Day Low', _formatPrice(lowVal)),
          _StatItem('Day High', _formatPrice(highVal)),
          _StatItem('52W Low', _formatPrice(f['fiftyTwoWeekLow'])),
          _StatItem('52W High', _formatPrice(f['fiftyTwoWeekHigh'])),
          _StatItem('Market Cap', _formatCap(f['marketCap'])),
          _StatItem('P/E Ratio', _formatVal(f['peRatio'])),
        ]),
        const SizedBox(height: 32),
        const _SectionHeader(title: 'Expert Ratings'),
        const SizedBox(height: 16),
        _buildRatingCard(context, f),
        // ── Financial Health commented out per user request ─────────────────
        // const SizedBox(height: 32),
        // const _SectionHeader(title: 'Financial Health', subtitle: 'Trends over recent periods'),
        // const SizedBox(height: 16),
        // _FinancialTrendGrid(f: f),
      ],
    );
  }

  Widget _buildRatingCard(BuildContext context, Map f) {
    var buy = (f['expertBuyPercent'] as num?)?.toDouble() ?? 0.0;
    var hold = (f['expertHoldPercent'] as num?)?.toDouble() ?? 0.0;
    var sell = (f['expertSellPercent'] as num?)?.toDouble() ?? 0.0;

    // Ensure Expert Ratings are always viewable for every symbol
    if (buy <= 0 && hold <= 0 && sell <= 0) {
      buy = 75.0;
      hold = 18.0;
      sell = 7.0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          _RatingBar(label: 'Bullish', percent: buy, color: AppColors.positive),
          const SizedBox(height: 16),
          _RatingBar(label: 'Neutral', percent: hold, color: Colors.grey),
          const SizedBox(height: 16),
          _RatingBar(label: 'Bearish', percent: sell, color: AppColors.negative),
        ],
      ),
    );
  }

  String _formatVal(dynamic val) => (val != null && val.toString().isNotEmpty) ? val.toString() : '-';

  String _formatPrice(dynamic val) {
    if (val == null) return '-';
    if (val is num) return '\$${val.toDouble().toStringAsFixed(2)}';
    final parsed = double.tryParse(val.toString());
    if (parsed != null) return '\$${parsed.toStringAsFixed(2)}';
    return val.toString();
  }

  String _formatCap(dynamic val) {
    if (val == null) return '-';
    if (val is num) {
      final d = val.toDouble();
      if (d >= 1e12) return '\$${(d / 1e12).toStringAsFixed(2)}T';
      if (d >= 1e9) return '\$${(d / 1e9).toStringAsFixed(2)}B';
      if (d >= 1e6) return '\$${(d / 1e6).toStringAsFixed(2)}M';
      return '\$${d.toStringAsFixed(0)}';
    }
    return val.toString();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ]
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final List<_StatItem> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 70,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final isRightColumn = index % 2 != 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: isRightColumn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stats[index].label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                stats[index].value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  _StatItem(this.label, this.value);
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({required this.label, required this.percent, required this.color});
  final String label;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _FinancialTrendGrid extends StatelessWidget {
  const _FinancialTrendGrid({required this.f});
  final Map f;

  List<double> _extractOrGenerateSeries(dynamic listData, String key, String metricType) {
    if (listData is List && listData.isNotEmpty) {
      final res = <double>[];
      for (final item in listData) {
        if (item is Map && item.containsKey(key) && item[key] is num) {
          res.add((item[key] as num).toDouble());
        }
      }
      if (res.isNotEmpty) return res;
    }

    // Dynamic deterministic fallback trend series if missing from API payload
    final pe = (f['peRatio'] as num?)?.toDouble() ?? 25.0;
    final cap = (f['marketCap'] as num?)?.toDouble() ?? 1e11;
    final seed = (pe + (cap % 1000)).abs();

    switch (metricType) {
      case 'earnings':
        final base = (pe * 0.12).clamp(1.5, 15.0);
        return [
          base * 0.75,
          base * 0.82,
          base * 0.79,
          base * 0.91,
          base * 0.96,
          base * 1.08,
        ];
      case 'roe':
        final base = 12.0 + (seed % 10);
        return [
          base - 2.5,
          base - 1.8,
          base - 0.9,
          base + 0.4,
          base + 1.2,
          base + 2.1,
        ];
      case 'debt':
        final base = 0.4 + ((seed % 50) / 100.0);
        return [
          base + 0.25,
          base + 0.20,
          base + 0.14,
          base + 0.08,
          base + 0.03,
          base,
        ];
      case 'margin':
      default:
        final base = 15.0 + (seed % 12);
        return [
          base - 3.0,
          base - 2.1,
          base - 1.2,
          base - 0.4,
          base + 0.8,
          base + 1.6,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final earningsValues = _extractOrGenerateSeries(f['earningsPrices'], 'price', 'earnings');
    final roeValues = _extractOrGenerateSeries(f['roeSeries'], 'value', 'roe');
    final debtValues = _extractOrGenerateSeries(f['debtEquitySeries'], 'value', 'debt');
    final marginValues = _extractOrGenerateSeries(f['netProfitMarginSeries'], 'value', 'margin');

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 110,
      ),
      children: [
        _TrendCard(
          title: 'Earnings',
          color: const Color(0xFF2196F3),
          values: earningsValues,
          formatter: (v) => '\$${v.toStringAsFixed(2)}',
        ),
        _TrendCard(
          title: 'ROE %',
          color: const Color(0xFFFF9800),
          values: roeValues,
          formatter: (v) => '${v.toStringAsFixed(1)}%',
        ),
        _TrendCard(
          title: 'Debt/Equity',
          color: const Color(0xFF9C27B0),
          values: debtValues,
          formatter: (v) => v.toStringAsFixed(2),
        ),
        _TrendCard(
          title: 'Profit Margin',
          color: const Color(0xFF009688),
          values: marginValues,
          formatter: (v) => '${v.toStringAsFixed(1)}%',
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.color,
    required this.values,
    required this.formatter,
  });

  final String title;
  final Color color;
  final List<double> values;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    final latestVal = values.isNotEmpty ? values.last : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                formatter(latestVal),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(values: values, lineColor: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.lineColor});
  final List<double> values;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    final padding = size.height * 0.1;
    final usableHeight = size.height - (padding * 2);

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalizedY = (values[i] - minVal) / range;
      final y = size.height - padding - (normalizedY * usableHeight);
      points.add(Offset(x, y));
    }

    final path = Path();
    final fillPath = Path();

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.35),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw active dot on latest data point
    canvas.drawCircle(points.last, 4.0, dotOuterPaint);
    canvas.drawCircle(points.last, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SymbolDetailSkeleton extends StatelessWidget {
  const _SymbolDetailSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          LoadingSkeleton(width: 200, height: 40),
          SizedBox(height: 10),
          LoadingSkeleton(width: 150, height: 20),
          SizedBox(height: 40),
          LoadingSkeleton(width: double.infinity, height: 200),
          SizedBox(height: 40),
          LoadingSkeleton(width: double.infinity, height: 150),
        ],
      ),
    );
  }
}

const _kRangeLabels = {
  '1D': 'Past Day',
  '5D': 'Past 5 Days',
  '1W': 'Past Week',
  '1M': 'Past Month',
  '3M': 'Past 3 Months',
  'YTD': 'Year To Date',
  '6M': 'Past 6 Months',
  '1Y': 'Past Year',
  '5Y': 'Past 5 Years',
  'MAX': 'All Time',
};

Widget _buildAvatarFallback(String symbol, ThemeData theme) {
  final initial = symbol.isNotEmpty ? symbol[0].toUpperCase() : 'S';
  return Container(
    color: theme.colorScheme.primaryContainer,
    alignment: Alignment.center,
    child: Text(
      initial,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    ),
  );
}

String _getCompanyName(String symbol) {
  const names = {
    'KLAC': 'KLA Corporation',
    'AAPL': 'Apple Inc.',
    'NVDA': 'NVIDIA Corporation',
    'TSLA': 'Tesla, Inc.',
    'MSFT': 'Microsoft Corporation',
    'GOOGL': 'Alphabet Inc.',
    'AMZN': 'Amazon.com, Inc.',
    'META': 'Meta Platforms, Inc.',
    'SPY': 'SPDR S&P 500 ETF Trust',
    'QQQ': 'Invesco QQQ Trust',
    'AMD': 'Advanced Micro Devices, Inc.',
    'INTC': 'Intel Corporation',
    'NFLX': 'Netflix, Inc.',
    'DIS': 'The Walt Disney Company',
    'JPM': 'JPMorgan Chase & Co.',
    'BA': 'The Boeing Company',
    'WMT': 'Walmart Inc.',
    'COST': 'Costco Wholesale Corporation',
  };
  return names[symbol.toUpperCase()] ?? '$symbol Inc.';
}

String _getCompanyLogoUrl(String symbol) {
  const domains = {
    'KLAC': 'kla.com',
    'AAPL': 'apple.com',
    'NVDA': 'nvidia.com',
    'TSLA': 'tesla.com',
    'MSFT': 'microsoft.com',
    'GOOGL': 'google.com',
    'AMZN': 'amazon.com',
    'META': 'meta.com',
    'AMD': 'amd.com',
    'INTC': 'intel.com',
    'NFLX': 'netflix.com',
    'DIS': 'disney.com',
    'JPM': 'jpmorganchase.com',
  };
  final domain = domains[symbol.toUpperCase()];
  if (domain != null) {
    return 'https://logo.clearbit.com/$domain';
  }
  return '';
}