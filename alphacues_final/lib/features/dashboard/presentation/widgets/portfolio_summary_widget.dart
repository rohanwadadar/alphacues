import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../portfolio/data/portfolio_providers.dart';
import '../../../watchlist/data/watchlist_providers.dart';
import '../../../watchlist/presentation/widgets/watchlist_tracking_chart.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_card.dart';

class PortfolioSummaryWidget extends ConsumerStatefulWidget {
  const PortfolioSummaryWidget({
    super.key,
    this.portfolio,
    this.isStale = false,
    this.errorMessage,
    this.onRetry,
  });

  final PortfolioSummary? portfolio;
  final bool isStale;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  ConsumerState<PortfolioSummaryWidget> createState() =>
      _PortfolioSummaryWidgetState();
}

class _PortfolioSummaryWidgetState
    extends ConsumerState<PortfolioSummaryWidget> {
  bool _showBalance = true;
  String _selectedRange = '1D';
  String? _selectedWatchlistId; // null = Total Portfolio (All)
  String _selectedStockScenario = 'All'; // 'All', 'Gainers', 'Cost vs Current', 'Day Profit'
  String _sortOrder = 'latest'; // 'latest' (Default) or 'oldest'
  num? _scrubbedBalance;
  String? _scrubbedTime;

  void _openAllStocksModal(
    BuildContext context, {
    required List<WatchlistItem> allStocks,
    required Map<String, DateTime> latestActivityDates,
    required Map<String, DateTime> firstBuyDates,
    required List<PortfolioPosition> portfolioPositions,
    required bool isTotalPortfolio,
    required String title,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PortfolioAllStocksModal(
        allStocks: allStocks,
        latestActivityDates: latestActivityDates,
        firstBuyDates: firstBuyDates,
        portfolioPositions: portfolioPositions,
        isTotalPortfolio: isTotalPortfolio,
        showBalance: _showBalance,
        initialScenario: _selectedStockScenario,
        initialSortOrder: _sortOrder,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final portfolioAsync = ref.watch(portfolioSummaryProvider);
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final watchlistsAsync = ref.watch(watchlistsProvider);

    double totalValue = widget.portfolio?.totalValue ?? 0.0;
    double dayChange = widget.portfolio?.dayChange ?? 0.0;
    double totalProfit = widget.portfolio?.totalProfit ?? 0.0;
    double totalReturn = widget.portfolio?.totalReturn ?? 0.0;

    // Map earliest BUY and latest transaction timestamp for each symbol
    final txList = transactionsAsync.asData?.value ?? const <PortfolioEvent>[];
    final Map<String, DateTime> firstBuyDates = {};
    final Map<String, DateTime> latestActivityDates = {};
    for (final tx in txList) {
      final parsed = DateTime.tryParse(tx.timeStamp)?.toUtc();
      if (parsed != null) {
        if (tx.action.toUpperCase() == 'BUY') {
          final existing = firstBuyDates[tx.symbol];
          if (existing == null || parsed.isBefore(existing)) {
            firstBuyDates[tx.symbol] = parsed;
          }
        }
        final existingLatest = latestActivityDates[tx.symbol];
        if (existingLatest == null || parsed.isAfter(existingLatest)) {
          latestActivityDates[tx.symbol] = parsed;
        }
      }
    }

    DateTime getStockActivityDate(String symbol) {
      if (latestActivityDates.containsKey(symbol)) {
        return latestActivityDates[symbol]!;
      }
      final pos = portfolioAsync.asData?.value.positions
          .where((p) => p.symbol == symbol)
          .firstOrNull;
      if (pos?.updatedAt != null) {
        final dt = DateTime.tryParse(pos!.updatedAt)?.toUtc();
        if (dt != null) return dt;
      }
      if (firstBuyDates.containsKey(symbol)) {
        return firstBuyDates[symbol]!;
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final bool isTotalPortfolio = _selectedWatchlistId == null;

    final List<WatchlistItem> stockItems = [];
    List<WatchlistItem> displayStocks = [];

    // Collect stock items from watchlists
    if (watchlistsAsync.hasValue) {
      for (final w in watchlistsAsync.requireValue) {
        final detailAsync = ref.watch(watchlistDetailProvider(w.watchlistId));
        if (detailAsync case AsyncData(:final value)) {
          for (final item in value.items) {
            if (!stockItems.any((it) => it.symbol == item.symbol)) {
              stockItems.add(item);
            }
          }
        }
      }
    }

    if (isTotalPortfolio) {
      // ── Total Portfolio Mode ──────────────────────────────────────────
      if (portfolioAsync case AsyncData(:final value) when (value.positions.isNotEmpty || value.summary.totalValue > 0)) {
        double calculatedValue = 0.0;
        double calculatedCost = 0.0;
        double calculatedDayChange = 0.0;
        final now = DateTime.now().toUtc();

        for (final pos in value.positions) {
          DateTime? buyDate = firstBuyDates[pos.symbol];
          buyDate ??= DateTime.tryParse(pos.updatedAt)?.toUtc();
          buyDate ??= DateTime.now().toUtc();

          final matchedStock = stockItems.where((it) => it.symbol == pos.symbol).firstOrNull;
          final entryPrice = pos.volume > 0 ? (pos.totalPrice / pos.volume) : 0.0;
          final currentPrice = matchedStock?.quote?.lastPrice ?? pos.lastPrice ?? entryPrice;
          final posVal = currentPrice * pos.volume;
          final posCost = pos.totalPrice;

          calculatedValue += posVal;
          calculatedCost += posCost;

          // If position was bought today, day change is strictly its gain/loss since purchase today!
          final isBoughtToday = buyDate.year == now.year && buyDate.month == now.month && buyDate.day == now.day;
          if (isBoughtToday) {
            calculatedDayChange += (posVal - posCost);
          } else {
            final stockChgAmt = matchedStock?.quote?.changeAmount ?? pos.changeAmount ?? 0.0;
            calculatedDayChange += (stockChgAmt * pos.volume);
          }

          final stockQuote = matchedStock?.quote ??
              (pos.lastPrice != null
                  ? WatchlistQuote(
                      lastPrice: currentPrice,
                      changeAmount: pos.changeAmount ?? 0.0,
                      changePercent: pos.changePercent ?? 0.0,
                      asOf: pos.updatedAt,
                    )
                  : null);

          displayStocks.add(
            WatchlistItem(
              symbol: pos.symbol,
              quantity: pos.volume.toDouble(),
              quote: stockQuote,
            ),
          );
        }

        totalValue = value.summary.totalValue > 0 ? value.summary.totalValue : calculatedValue;
        if (totalValue <= 0.0) totalValue = calculatedValue;

        dayChange = calculatedDayChange;
        totalProfit = calculatedCost > 0 ? (totalValue - calculatedCost) : value.summary.totalProfit;
        totalReturn = calculatedCost > 0 ? ((totalProfit / calculatedCost) * 100) : value.summary.totalReturn;
      } else {
        totalValue = widget.portfolio?.totalValue ?? 0.0;
        dayChange = widget.portfolio?.dayChange ?? 0.0;
        totalProfit = widget.portfolio?.totalProfit ?? 0.0;
        totalReturn = widget.portfolio?.totalReturn ?? 0.0;
        displayStocks = [];
      }
    } else {
      // ── Specific Watchlist Mode ───────────────────────────────────────
      final detailAsync = ref.watch(watchlistDetailProvider(_selectedWatchlistId!));
      if (detailAsync case AsyncData(:final value)) {
        displayStocks = List.from(value.items);
        double wlValue = 0.0;
        double wlDayChange = 0.0;
        for (final item in value.items) {
          final pos = portfolioAsync.asData?.value.positions
              .where((p) => p.symbol == item.symbol)
              .firstOrNull;
          final stockItem = stockItems.where((it) => it.symbol == item.symbol).firstOrNull;
          
          double price = item.quote?.lastPrice ?? 0.0;
          if (price <= 0.0) price = pos?.lastPrice ?? 0.0;
          if (price <= 0.0) price = stockItem?.quote?.lastPrice ?? 0.0;
          
          double chg = item.quote?.changeAmount ?? 0.0;
          if (chg == 0.0 && pos?.changeAmount != null) chg = pos!.changeAmount!;
          if (chg == 0.0 && stockItem?.quote?.changeAmount != null) chg = stockItem!.quote!.changeAmount;

          final qty = item.quantity ?? pos?.volume.toDouble() ?? 1.0;
          wlValue += price * qty;
          wlDayChange += chg * qty;
        }
        totalValue = wlValue;
        dayChange = wlDayChange;
        totalProfit = wlDayChange;
        final prevWlValue = wlValue - wlDayChange;
        totalReturn = prevWlValue > 0 ? (wlDayChange / prevWlValue * 100) : 0.0;
      }
    }

    // Keep an unfiltered full list reference for modal & calculations
    final fullStockList = List<WatchlistItem>.from(displayStocks);

    // ── Apply Scenario Filters & Sorting ──────────────────────────────
    if (_selectedStockScenario == 'Gainers') {
      displayStocks.sort((a, b) {
        final pctA = a.quote?.changePercent ?? 0.0;
        final pctB = b.quote?.changePercent ?? 0.0;
        return pctB.compareTo(pctA);
      });
    } else if (_selectedStockScenario == 'Day Profit') {
      displayStocks.sort((a, b) {
        final chgA = a.quote?.changeAmount ?? 0.0;
        final chgB = b.quote?.changeAmount ?? 0.0;
        return chgB.compareTo(chgA);
      });
    } else {
      // Scenario is 'All' or 'Cost vs Current' -> Sort by date (Latest 1st or Oldest 1st)
      displayStocks.sort((a, b) {
        final dateA = getStockActivityDate(a.symbol);
        final dateB = getStockActivityDate(b.symbol);
        final comp = _sortOrder == 'latest'
            ? dateB.compareTo(dateA) // Latest first by default
            : dateA.compareTo(dateB); // Oldest first
        if (comp != 0) return comp;
        return a.symbol.compareTo(b.symbol);
      });
    }

    // ── Portfolio Chart Data for Selected Range ────────────────────────
    final chartAsync = ref.watch(portfolioChartProvider(_selectedRange));
    final bool isChartLoading = chartAsync.isLoading && !chartAsync.hasValue;
    final bool isChartError = chartAsync.hasError && !chartAsync.hasValue;

    final PortfolioChartData chartData =
        chartAsync.valueOrNull ?? PortfolioChartData.empty;
    final List<Map<String, dynamic>> chartPoints =
        chartData.points.map((p) => p.toMap()).toList();

    // Check if chart has no historical points to display
    final bool isChartEmpty = !isChartLoading &&
        !isChartError &&
        (chartPoints.isEmpty ||
            (chartData.startValue == 0.0 &&
                chartData.endValue == 0.0 &&
                totalValue <= 0.0));

    final double startVal = chartData.startValue > 0.0
        ? chartData.startValue
        : (chartPoints.isNotEmpty
            ? (chartPoints.first['value'] as num).toDouble()
            : totalValue);
    final double endVal = chartData.endValue > 0.0
        ? chartData.endValue
        : (chartPoints.isNotEmpty
            ? (chartPoints.last['value'] as num).toDouble()
            : totalValue);

    double rangeChange = chartData.rangeChange;
    double rangeReturn = chartData.rangeChangePercent;

    if (rangeChange == 0.0 &&
        rangeReturn == 0.0 &&
        startVal > 0.0 &&
        endVal != startVal) {
      rangeChange = endVal - startVal;
      rangeReturn = (rangeChange / startVal) * 100;
    }

    final prevCloseValue = totalValue - dayChange;
    final todayReturnPercent =
        prevCloseValue > 0 ? (dayChange / prevCloseValue * 100) : 0.0;

    if (_selectedRange == '1D' &&
        isTotalPortfolio &&
        dayChange != 0.0 &&
        rangeChange == 0.0) {
      rangeChange = dayChange;
      rangeReturn = todayReturnPercent;
    }

    double displayDayChange = rangeChange;
    double displayReturn = rangeReturn;
    final displayValue = _scrubbedBalance != null
        ? _scrubbedBalance!.toDouble()
        : (endVal > 0.0 ? endVal : totalValue);

    if (_scrubbedBalance != null && chartPoints.isNotEmpty) {
      final scrubbedVal = _scrubbedBalance!.toDouble();
      final baseline = startVal > 0.0 ? startVal : totalValue;
      if (baseline > 0.0) {
        displayDayChange = scrubbedVal - baseline;
        displayReturn = (displayDayChange / baseline * 100);
      }
    }

    final bool isPositive = displayDayChange >= 0;

    String rangeLabel(String range) {
      switch (range) {
        case '1D':
          return 'Today';
        case '5D':
          return 'Past 5 Days';
        case '1M':
          return 'Past Month';
        case '3M':
          return 'Past 3 Months';
        case 'YTD':
          return 'Year to Date';
        case '1Y':
          return 'Past Year';
        case 'MAX':
          return 'All Time';
        default:
          return 'Today';
      }
    }

    final timeLabel = _scrubbedTime ??
        (_selectedRange == '1D' && displayDayChange == 0.0
            ? 'Market Closed'
            : rangeLabel(_selectedRange));

    // ── Dropdown Widget ──────────────────────────────────────────────
    final dropdownWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedWatchlistId,
          isDense: true,
          dropdownColor: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          onChanged: (val) => setState(() {
            _selectedWatchlistId = val;
            _scrubbedBalance = null;
            _scrubbedTime = null;
          }),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pie_chart_rounded,
                      size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  const Text('Total Portfolio',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (watchlistsAsync.hasValue)
              ...watchlistsAsync.requireValue.map(
                (w) => DropdownMenuItem<String?>(
                  value: w.watchlistId,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text(w.name,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final positionsList = portfolioAsync.asData?.value.positions ?? const <PortfolioPosition>[];
    final sectionTitle = isTotalPortfolio ? 'Portfolio Stocks' : 'Watchlist Holdings';

    // Panel Limit: limit main display to 7 stocks
    const int panelStockLimit = 7;
    final visibleStocks = displayStocks.take(panelStockLimit).toList();

    return DashboardSectionCard(
      title: 'Portfolio',
      headerAction: dropdownWidget,
      isStale: widget.isStale,
      errorMessage: widget.errorMessage,
      onRetry: widget.onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTotalPortfolio
                    ? 'Total balance'
                    : 'Watchlist balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showBalance
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _showBalance = !_showBalance),
              ),
            ],
          ),
          Text(
            _showBalance ? formatPrice(displayValue) : '••••••••',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          // Display 1D Change
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isChartLoading)
                const LoadingSkeleton(
                  width: 140,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                )
              else if (isChartError)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_selectedRange: Offline',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else if (isChartEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_selectedRange: No trades',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: isPositive
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_selectedRange: ${_showBalance ? formatSignedAmount(displayDayChange) : '••••'} (${formatPercent(displayReturn)})',
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!isChartLoading && !isChartEmpty && !isChartError)
                Text(
                  timeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── INTERACTIVE CHART (Touch line + header tooltip) ───────────
          if (isChartLoading)
            _buildChartLoadingSkeleton(theme, colorScheme)
          else if (isChartError)
            _buildChartError(theme, colorScheme)
          else if (isChartEmpty)
            _buildEmptyChartPrompt(theme, colorScheme)
          else
            WatchlistTrackingChart(
              points: chartPoints,
              selectedRange: _selectedRange,
              isPositive: isPositive,
              onScrub: (payload) {
                setState(() {
                  if (payload != null) {
                    _scrubbedBalance = payload['value'] as num?;
                    _scrubbedTime = payload['time'] as String?;
                  } else {
                    _scrubbedBalance = null;
                    _scrubbedTime = null;
                  }
                });
              },
              onRangeChanged: (range) {
                setState(() {
                  _selectedRange = range;
                  _scrubbedBalance = null;
                  _scrubbedTime = null;
                });
              },
            ),
          const SizedBox(height: AppSpacing.md),

          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── METRIC SUMMARY ROWS ────────────────────────────────────────
          _PortfolioMetricRow(
            label: 'Total profit',
            value: _showBalance ? formatSignedAmount(totalProfit) : '••••••••',
            valueColor: totalProfit >= 0
                ? AppColors.positive
                : AppColors.negative,
          ),
          _PortfolioMetricRow(
            label: 'Total return',
            value: formatPercent(totalReturn),
            valueColor: totalReturn >= 0
                ? AppColors.positive
                : AppColors.negative,
          ),
          _PortfolioMetricRow(
            label: 'Day change',
            value: _showBalance ? formatSignedAmount(dayChange) : '••••••••',
            valueColor: dayChange >= 0
                ? AppColors.positive
                : AppColors.negative,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── PORTFOLIO STOCKS & SCENARIO FILTER BAR ─────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sectionTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${displayStocks.length} symbols',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  if (displayStocks.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openAllStocksModal(
                        context,
                        allStocks: fullStockList,
                        latestActivityDates: latestActivityDates,
                        firstBuyDates: firstBuyDates,
                        portfolioPositions: positionsList,
                        isTotalPortfolio: isTotalPortfolio,
                        title: sectionTitle,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Scenario Filter Chips & Sort Button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildScenarioChip('All', Icons.grid_view_rounded),
                const SizedBox(width: 6),
                _buildScenarioChip('Gainers', Icons.trending_up_rounded),
                const SizedBox(width: 6),
                _buildScenarioChip('Cost vs Current', Icons.compare_arrows_rounded),
                const SizedBox(width: 6),
                _buildScenarioChip('Day Profit', Icons.attach_money_rounded),
                const SizedBox(width: 8),
                _buildSortMenuButton(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stock Items List (Limit to 7 items in panel)
          if (displayStocks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No stocks in this selection',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleStocks.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 10, indent: 4, endIndent: 4),
              itemBuilder: (context, i) {
                final item = visibleStocks[i];
                return buildStockTile(
                  context,
                  item: item,
                  positions: positionsList,
                  isTotalPortfolio: isTotalPortfolio,
                  scenario: _selectedStockScenario,
                  showBalance: _showBalance,
                );
              },
            ),
            if (displayStocks.length > panelStockLimit) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _openAllStocksModal(
                  context,
                  allStocks: fullStockList,
                  latestActivityDates: latestActivityDates,
                  firstBuyDates: firstBuyDates,
                  portfolioPositions: positionsList,
                  isTotalPortfolio: isTotalPortfolio,
                  title: sectionTitle,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'See all ${displayStocks.length} symbols',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.settings),
              child: const Text('View transactions in Profile →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenuButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PopupMenuButton<String>(
      initialValue: _sortOrder,
      tooltip: 'Sort stocks',
      onSelected: (val) {
        setState(() {
          _sortOrder = val;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: colorScheme.surfaceContainerHigh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 14, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              _sortOrder == 'latest' ? 'Latest 1st' : 'Oldest 1st',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'latest',
          child: Row(
            children: [
              Icon(
                _sortOrder == 'latest'
                    ? Icons.check_rounded
                    : Icons.access_time_rounded,
                size: 16,
                color: _sortOrder == 'latest'
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Latest 1st (Default)',
                style: TextStyle(
                  fontWeight:
                      _sortOrder == 'latest' ? FontWeight.bold : FontWeight.normal,
                  color: _sortOrder == 'latest'
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'oldest',
          child: Row(
            children: [
              Icon(
                _sortOrder == 'oldest'
                    ? Icons.check_rounded
                    : Icons.history_rounded,
                size: 16,
                color: _sortOrder == 'oldest'
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Oldest 1st',
                style: TextStyle(
                  fontWeight:
                      _sortOrder == 'oldest' ? FontWeight.bold : FontWeight.normal,
                  color: _sortOrder == 'oldest'
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioChip(String label, IconData icon) {
    final isSelected = _selectedStockScenario == label;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon,
          size: 14,
          color: isSelected ? colorScheme.onPrimary : colorScheme.primary),
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (_) => setState(() => _selectedStockScenario = label),
    );
  }

  Widget _buildTimeframeRow({required bool enabled}) {
    const timeframes = ['1D', '5D', '1M', '3M', 'YTD', '1Y', 'MAX'];
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: timeframes.map((tf) {
          final isSelected = tf == _selectedRange;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: enabled
                  ? () {
                      setState(() {
                        _selectedRange = tf;
                        _scrubbedBalance = null;
                        _scrubbedTime = null;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tf,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartLoadingSkeleton(
      ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const LoadingSkeleton(
                width: double.infinity,
                height: 180,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading performance data...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeframeRow(enabled: true),
      ],
    );
  }

  Widget _buildEmptyChartPrompt(
      ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.ssid_chart_rounded,
                  size: 28,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'No performance history yet',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record trades to visualize your portfolio equity curve.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.portfolio),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add Trade',
                        style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutes.watchlists),
                    icon: const Icon(Icons.bookmark_add_outlined, size: 14),
                    label: const Text('Watchlists',
                        style: TextStyle(fontSize: 11)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeframeRow(enabled: true),
      ],
    );
  }

  Widget _buildChartError(
      ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 28, color: colorScheme.error),
                const SizedBox(height: 8),
                Text(
                  'Unable to load chart data',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      ref.refresh(portfolioChartProvider(_selectedRange)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimeframeRow(enabled: true),
      ],
    );
  }

  static Widget buildStockTile(
    BuildContext context, {
    required WatchlistItem item,
    required List<PortfolioPosition> positions,
    required bool isTotalPortfolio,
    required String scenario,
    required bool showBalance,
    VoidCallback? onTapOverride,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quote = item.quote;
    final pos = positions.where((p) => p.symbol == item.symbol).firstOrNull;
    final posQty = pos?.volume.toDouble() ?? item.quantity ?? 1.0;
    final posCost = pos?.totalPrice ?? 0.0;
    final entryPrice = (posQty > 0 && posCost > 0) ? posCost / posQty : 0.0;
    final price = quote?.lastPrice ??
        pos?.lastPrice ??
        (entryPrice > 0 ? entryPrice : 0.0);
    final chgPct = quote?.changePercent ?? pos?.changePercent ?? 0.0;
    final chgAmt = quote?.changeAmount ?? pos?.changeAmount ?? 0.0;

    final posProfit = (price * posQty) - posCost;
    final posProfitPct =
        posCost > 0 ? (posProfit / posCost * 100) : 0.0;

    final displayAmt = isTotalPortfolio ? posProfit : chgAmt;
    final displayPct = isTotalPortfolio ? posProfitPct : chgPct;
    final isGain = displayAmt >= 0;
    final itemColor = isGain ? AppColors.positive : AppColors.negative;

    return InkWell(
      onTap: onTapOverride ?? () => context.push(AppRoutes.symbolDetail(item.symbol)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.symbol.length >= 3
                    ? item.symbol.substring(0, 3)
                    : item.symbol,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.symbol,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (scenario == 'Cost vs Current')
                    Text(
                      'Cost: \$${formatPrice(entryPrice)} → Now: \$${formatPrice(price)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Text(
                      '${posQty.toInt()} shares • \$${formatPrice(price)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  showBalance
                      ? formatSignedAmount(displayAmt)
                      : '••••••',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: itemColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatPercent(displayPct),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: itemColor,
                    ),
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

/// ── ALL STOCKS MODAL POPUP ──────────────────────────────────────────────────
class _PortfolioAllStocksModal extends StatefulWidget {
  const _PortfolioAllStocksModal({
    required this.allStocks,
    required this.latestActivityDates,
    required this.firstBuyDates,
    required this.portfolioPositions,
    required this.isTotalPortfolio,
    required this.showBalance,
    required this.initialScenario,
    required this.initialSortOrder,
    required this.title,
  });

  final List<WatchlistItem> allStocks;
  final Map<String, DateTime> latestActivityDates;
  final Map<String, DateTime> firstBuyDates;
  final List<PortfolioPosition> portfolioPositions;
  final bool isTotalPortfolio;
  final bool showBalance;
  final String initialScenario;
  final String initialSortOrder;
  final String title;

  @override
  State<_PortfolioAllStocksModal> createState() =>
      _PortfolioAllStocksModalState();
}

class _PortfolioAllStocksModalState extends State<_PortfolioAllStocksModal> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedScenario;
  late String _sortOrder;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedScenario = widget.initialScenario;
    _sortOrder = widget.initialSortOrder;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _getStockActivityDate(String symbol) {
    if (widget.latestActivityDates.containsKey(symbol)) {
      return widget.latestActivityDates[symbol]!;
    }
    final pos = widget.portfolioPositions
        .where((p) => p.symbol == symbol)
        .firstOrNull;
    if (pos?.updatedAt != null) {
      final dt = DateTime.tryParse(pos!.updatedAt)?.toUtc();
      if (dt != null) return dt;
    }
    if (widget.firstBuyDates.containsKey(symbol)) {
      return widget.firstBuyDates[symbol]!;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<WatchlistItem> get _processedStocks {
    List<WatchlistItem> list = List.from(widget.allStocks);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) {
        return item.symbol.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply Scenario Filters & Sorting
    if (_selectedScenario == 'Gainers') {
      list.sort((a, b) {
        final pctA = a.quote?.changePercent ?? 0.0;
        final pctB = b.quote?.changePercent ?? 0.0;
        return pctB.compareTo(pctA);
      });
    } else if (_selectedScenario == 'Day Profit') {
      list.sort((a, b) {
        final chgA = a.quote?.changeAmount ?? 0.0;
        final chgB = b.quote?.changeAmount ?? 0.0;
        return chgB.compareTo(chgA);
      });
    } else {
      // Scenario is 'All' or 'Cost vs Current' -> Sort by date (Latest 1st or Oldest 1st)
      list.sort((a, b) {
        final dateA = _getStockActivityDate(a.symbol);
        final dateB = _getStockActivityDate(b.symbol);
        final comp = _sortOrder == 'latest'
            ? dateB.compareTo(dateA) // Latest first by default
            : dateA.compareTo(dateB); // Oldest first
        if (comp != 0) return comp;
        return a.symbol.compareTo(b.symbol);
      });
    }

    return list;
  }

  Widget _buildModalScenarioChip(String label, IconData icon) {
    final isSelected = _selectedScenario == label;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(icon,
          size: 14,
          color: isSelected ? colorScheme.onPrimary : colorScheme.primary),
      label: Text(label),
      selected: isSelected,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (_) => setState(() => _selectedScenario = label),
    );
  }

  Widget _buildModalSortButton() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return PopupMenuButton<String>(
      initialValue: _sortOrder,
      tooltip: 'Sort stocks',
      onSelected: (val) {
        setState(() {
          _sortOrder = val;
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: colorScheme.surfaceContainerHigh,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 14, color: colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              _sortOrder == 'latest' ? 'Latest 1st' : 'Oldest 1st',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'latest',
          child: Row(
            children: [
              Icon(
                _sortOrder == 'latest'
                    ? Icons.check_rounded
                    : Icons.access_time_rounded,
                size: 16,
                color: _sortOrder == 'latest'
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Latest 1st (Default)',
                style: TextStyle(
                  fontWeight:
                      _sortOrder == 'latest' ? FontWeight.bold : FontWeight.normal,
                  color: _sortOrder == 'latest'
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'oldest',
          child: Row(
            children: [
              Icon(
                _sortOrder == 'oldest'
                    ? Icons.check_rounded
                    : Icons.history_rounded,
                size: 16,
                color: _sortOrder == 'oldest'
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Oldest 1st',
                style: TextStyle(
                  fontWeight:
                      _sortOrder == 'oldest' ? FontWeight.bold : FontWeight.normal,
                  color: _sortOrder == 'oldest'
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final processedStocks = _processedStocks;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── 1. DRAG HANDLE ─────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 2. HEADER BAR ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.pie_chart_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${processedStocks.length} of ${widget.allStocks.length} symbols',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── 3. SEARCH BAR ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by ticker symbol...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── 4. SCENARIO FILTER CHIPS & SORT BUTTON ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModalScenarioChip('All', Icons.grid_view_rounded),
                      const SizedBox(width: 6),
                      _buildModalScenarioChip('Gainers', Icons.trending_up_rounded),
                      const SizedBox(width: 6),
                      _buildModalScenarioChip(
                          'Cost vs Current', Icons.compare_arrows_rounded),
                      const SizedBox(width: 6),
                      _buildModalScenarioChip(
                          'Day Profit', Icons.attach_money_rounded),
                      const SizedBox(width: 8),
                      _buildModalSortButton(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),

              // ── 5. ALL STOCKS LIST ─────────────────────────────────────
              Expanded(
                child: processedStocks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'No matching stocks found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 8),
                        itemCount: processedStocks.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 10, indent: 4, endIndent: 4),
                        itemBuilder: (context, i) {
                          final item = processedStocks[i];
                          return _PortfolioSummaryWidgetState.buildStockTile(
                            context,
                            item: item,
                            positions: widget.portfolioPositions,
                            isTotalPortfolio: widget.isTotalPortfolio,
                            scenario: _selectedScenario,
                            showBalance: widget.showBalance,
                            onTapOverride: () {
                              Navigator.of(context).pop();
                              context.push(AppRoutes.symbolDetail(item.symbol));
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PortfolioMetricRow extends StatelessWidget {
  const _PortfolioMetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
