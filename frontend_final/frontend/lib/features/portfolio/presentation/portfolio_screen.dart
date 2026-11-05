import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/utils/us_market_time.dart';
import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../dashboard/presentation/widgets/dashboard_formatters.dart';
import '../../market/data/bars_provider.dart';
import '../../market/data/market_repository.dart' show Bar;
import '../../watchlist/data/watchlist_providers.dart';
import '../../watchlist/presentation/widgets/watchlist_tracking_chart.dart';
import '../data/portfolio_providers.dart';
import 'portfolio_event_form_dialog.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  List<String> _subscribedSymbols = const [];
  Set<String> _heldSymbols = const {};

  @override
  void initState() {
    super.initState();
    _quoteSub = ref
        .read(socketClientProvider)
        .quoteUpdates
        .listen(_onQuoteUpdate);
  }

  @override
  void deactivate() {
    _quoteSub?.cancel();
    _quoteSub = null;
    final symbols = List<String>.from(_subscribedSymbols);
    _subscribedSymbols = const [];
    try {
      final quoteManager = ref.read(quoteSubscriptionManagerProvider.notifier);
      final portfolioActive = ref.read(portfolioScreenActiveProvider.notifier);
      Future.microtask(() {
        try {
          if (symbols.isNotEmpty) {
            quoteManager.unsubscribeHidden(symbols);
          }
          portfolioActive.untrack();
        } catch (_) {}
      });
    } catch (_) {}
    super.deactivate();
  }

  @override
  void dispose() {
    _quoteSub?.cancel();
    super.dispose();
  }

  void _onQuoteUpdate(QuoteUpdatePayload payload) {
    if (!mounted || !_heldSymbols.contains(payload.symbol)) {
      return;
    }
    ref.read(portfolioSummaryProvider.notifier).patchQuote(payload);
  }

  void _syncSubscriptions(List<String> symbols) {
    if (_listEquals(symbols, _subscribedSymbols)) {
      return;
    }

    final manager = ref.read(quoteSubscriptionManagerProvider.notifier);
    final toRemove = _subscribedSymbols
        .where((s) => !symbols.contains(s))
        .toList();
    if (toRemove.isNotEmpty) {
      manager.unsubscribeHidden(toRemove);
    }
    if (symbols.isNotEmpty) {
      manager.subscribeVisible(symbols);
    }
    _subscribedSymbols = List<String>.from(symbols);
    _heldSymbols = symbols.toSet();
    ref.read(portfolioScreenActiveProvider.notifier).track();
  }

  bool _listEquals(List<String> a, List<String> b) {
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

  bool _isAsOfStale(String asOf, bool socketConnected) {
    if (!socketConnected) {
      return true;
    }
    final parsed = DateTime.tryParse(asOf)?.toUtc();
    if (parsed == null) {
      return true;
    }
    return DateTime.now().toUtc().difference(parsed).inSeconds > 60;
  }

  Future<void> _deleteEvent(PortfolioEvent event) async {
    try {
      await ref.read(portfolioRepositoryProvider).deleteEvent(event.eventId);
      if (!mounted) {
        return;
      }
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
    } on PortfolioValidationErrorException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF673AB7),
          content: Text(error.message),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF673AB7),
          content: Text(portfolioErrorMessage(error)),
        ),
      );
    }
  }

  void _openAddDialog() {
    PortfolioEventFormDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketState = ref.watch(socketConnectionStateProvider);
    final socketConnected =
        socketState.connectionState == SocketConnectionState.connected;
    final transactionsNotifier = ref.read(
      portfolioTransactionsProvider.notifier,
    );
    final mutationsEnabled = isOnline;

    ref.listen(portfolioSummaryProvider, (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncSubscriptions(value.symbols);
      }
    });

    if (summaryAsync case AsyncData(:final value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncSubscriptions(value.symbols);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(portfolioScreenActiveProvider.notifier).track();
      }
    });

    final summary = summaryAsync.asData?.value;
    final showStaleBanner =
        !socketConnected ||
        socketState.awaitingRestRefresh ||
        (summary != null &&
            _isAsOfStale(summary.summary.asOf, socketConnected));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const AlphaCuesFullLogo(),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: null,
      body: SafeScreen(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth <= 600;
            Widget portfolioBody = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaleBanner(
                  message: 'Prices may be delayed',
                  visible: showStaleBanner,
                ),
                Expanded(
                  child: summaryAsync.when(
                loading: () => const _PortfolioSkeleton(),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(portfolioSummaryProvider.notifier).refresh(),
                ),
                data: (overview) {
                  return transactionsAsync.when(
                    loading: () => const _PortfolioSkeleton(),
                    error: (error, _) => ErrorState(
                      message: error.toString(),
                      onRetry: () => ref
                          .read(portfolioTransactionsProvider.notifier)
                          .refresh(),
                    ),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return ListView(
                          children: [
                            _SummaryCard(
                              overview: overview,
                              isDegraded: !isOnline || showStaleBanner,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: EmptyState(
                                icon: Icons.pie_chart_outline,
                                heading: 'Portfolio is Clear',
                                body:
                                    'Your portfolio is completely empty (\$0.00). Tap below to add your first transaction.',
                                actionLabel: mutationsEnabled
                                    ? 'Add transaction'
                                    : null,
                                onAction: mutationsEnabled ? _openAddDialog : null,
                              ),
                            ),
                          ],
                        );
                      }

                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200) {
                            transactionsNotifier.loadMore();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _SummaryCard(
                                overview: overview,
                                isDegraded: !isOnline || showStaleBanner,
                              ),
                            ),
                            if (overview.positions.isNotEmpty) ...[
                              const SliverToBoxAdapter(
                                child: _SectionHeader(title: 'Holdings'),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final position = overview.positions[index];
                                  return _PositionRow(position: position);
                                }, childCount: overview.positions.length),
                              ),
                            ],
                            const SliverToBoxAdapter(
                              child: _SectionHeader(title: 'Transactions'),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final event = transactions[index];
                                return _TransactionRow(
                                  event: event,
                                  mutationsEnabled: mutationsEnabled,
                                  onEdit: () => PortfolioEventFormDialog.show(
                                    context,
                                    event: event,
                                  ),
                                  onDelete: () => _deleteEvent(event),
                                );
                              }, childCount: transactions.length),
                            ),
                            if (transactionsNotifier.hasMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );

        if (!isPhone) {
          portfolioBody = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: portfolioBody,
            ),
          );
        }

        return portfolioBody;
      },
    ),
  ),
);
  }
}

class _SummaryCard extends ConsumerStatefulWidget {
  const _SummaryCard({required this.overview, required this.isDegraded});

  final PortfolioOverview overview;
  final bool isDegraded;

  @override
  ConsumerState<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends ConsumerState<_SummaryCard> {
  String _selectedRange = '1D';
  String? _selectedWatchlistId;
  Map<String, dynamic>? _scrubbedPoint;

  String _formatBarTimestamp(String isoStamp, String range) {
    return formatUsMarketTimestamp(isoStamp, range: range);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.overview.summary;
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final watchlistsAsync = ref.watch(watchlistsProvider);

    double displayTotalValue = summary.totalValue;
    double displayDayChange = summary.dayChange;
    double displayTotalProfit = summary.totalProfit;
    double displayReturnPct = summary.totalReturn;

    // Map earliest BUY transaction timestamp for each symbol
    final txList = transactionsAsync.asData?.value ?? const <PortfolioEvent>[];
    final Map<String, DateTime> firstBuyDates = {};
    for (final tx in txList) {
      if (tx.action.toUpperCase() == 'BUY') {
        final parsed = DateTime.tryParse(tx.timeStamp)?.toUtc();
        if (parsed != null) {
          final existing = firstBuyDates[tx.symbol];
          if (existing == null || parsed.isBefore(existing)) {
            firstBuyDates[tx.symbol] = parsed;
          }
        }
      }
    }

    final List<({String symbol, double quantity, DateTime? buyDate, double costBasis, double entryPrice})> chartHoldings = [];

    if (_selectedWatchlistId == null) {
      if (widget.overview.positions.isNotEmpty || summary.totalValue > 0) {
        double calculatedVal = 0.0;
        double calculatedCost = 0.0;
        double calculatedDayChg = 0.0;
        final now = DateTime.now().toUtc();

        for (final pos in widget.overview.positions) {
          DateTime? buyDate = firstBuyDates[pos.symbol];
          buyDate ??= DateTime.tryParse(pos.updatedAt)?.toUtc();
          buyDate ??= DateTime.now().toUtc();

          final livePrice = pos.lastPrice ?? (pos.volume > 0 ? pos.totalPrice / pos.volume : 0.0);
          final posVal = livePrice * pos.volume;
          final posCost = pos.totalPrice;
          final entryPrice = pos.volume > 0 ? (pos.totalPrice / pos.volume) : livePrice;
          calculatedVal += posVal;
          calculatedCost += posCost;

          chartHoldings.add((
            symbol: pos.symbol,
            quantity: pos.volume.toDouble(),
            buyDate: buyDate,
            costBasis: posCost,
            entryPrice: entryPrice,
          ));

          final isBoughtToday = buyDate.year == now.year && buyDate.month == now.month && buyDate.day == now.day;
          if (isBoughtToday) {
            calculatedDayChg += (posVal - pos.totalPrice);
          } else {
            calculatedDayChg += ((pos.changeAmount ?? 0.0) * pos.volume);
          }
        }

        displayTotalValue = summary.totalValue > 0 ? summary.totalValue : calculatedVal;
        if (displayTotalValue <= 0.0) {
          displayTotalValue = calculatedVal;
        }

        displayTotalProfit = summary.totalProfit != 0.0
            ? summary.totalProfit
            : (calculatedCost > 0.0 ? (displayTotalValue - calculatedCost) : 0.0);

        final allBoughtToday = chartHoldings.isNotEmpty &&
            chartHoldings.every((h) =>
                h.buyDate != null &&
                h.buyDate!.year == now.year &&
                h.buyDate!.month == now.month &&
                h.buyDate!.day == now.day);
        if (allBoughtToday) {
          displayDayChange = calculatedDayChg;
        } else {
          displayDayChange = summary.dayChange != 0.0 ? summary.dayChange : calculatedDayChg;
        }
      } else {
        displayTotalValue = summary.totalValue;
        displayDayChange = summary.dayChange;
        displayTotalProfit = summary.totalProfit;
        displayReturnPct = summary.totalReturn;
      }
    } else {
      final detailAsync = ref.watch(watchlistDetailProvider(_selectedWatchlistId!));
      if (detailAsync case AsyncData(:final value)) {
        double wlValue = 0.0;
        double wlDayChange = 0.0;
        for (final item in value.items) {
          final pos = widget.overview.positions.where((p) => p.symbol == item.symbol).firstOrNull;
          final price = item.quote?.lastPrice ?? (pos?.lastPrice ?? 0.0);
          final chg = item.quote?.changeAmount ?? (pos?.changeAmount ?? 0.0);
          final qty = item.quantity ?? (pos?.volume.toDouble() ?? 1.0);
          wlValue += price * qty;
          wlDayChange += chg * qty;

          final buyDate = firstBuyDates[item.symbol] ??
              DateTime.tryParse(pos?.updatedAt ?? '')?.toUtc();
          final itemCost = pos != null && pos.totalPrice > 0 ? pos.totalPrice : (price * qty);
          final itemEntryPrice = pos != null && pos.volume > 0 ? (pos.totalPrice / pos.volume) : price;
          chartHoldings.add((
            symbol: item.symbol,
            quantity: qty,
            buyDate: buyDate,
            costBasis: itemCost,
            entryPrice: itemEntryPrice,
          ));
        }

        displayTotalValue = wlValue;
        displayDayChange = wlDayChange;
        displayTotalProfit = wlDayChange;
        final prevWlVal = wlValue - wlDayChange;
        displayReturnPct = prevWlVal > 0 ? (wlDayChange / prevWlVal * 100) : 0.0;
      }
    }

    final prevClose = displayTotalValue - displayDayChange;
    final todayReturnPercent = prevClose > 0 ? (displayDayChange / prevClose * 100) : 0.0;

    // Build dynamic multi-stock historical equity curve
    final List<Map<String, dynamic>> chartPoints = [];
    if (chartHoldings.isEmpty || displayTotalValue <= 0.0) {
      chartPoints.addAll(List.generate(20, (_) => {'value': 0.0, 'time': ''}));
    } else {
      final Map<String, List<Bar>> symbolBarsMap = {};
      for (final h in chartHoldings) {
        final barsAsync = ref.watch(barsProvider((symbol: h.symbol, range: _selectedRange)));
        if (barsAsync case AsyncData(:final value) when value.bars.isNotEmpty) {
          symbolBarsMap[h.symbol] = value.bars;
        }
      }

      if (symbolBarsMap.isEmpty) {
        chartPoints.addAll(List.generate(20, (_) => {'value': displayTotalValue, 'time': 'Market Closed'}));
      } else {
        final Set<String> allTimeStamps = {};
        for (final bars in symbolBarsMap.values) {
          for (final b in bars) {
            allTimeStamps.add(b.timeStamp);
          }
        }

        final sortedTimeStamps = allTimeStamps.toList()..sort();
        if (sortedTimeStamps.isEmpty) {
          chartPoints.addAll(List.generate(20, (_) => {'value': displayTotalValue, 'time': 'Market Closed'}));
        } else {
          for (final timeStr in sortedTimeStamps) {
            final barTime = DateTime.tryParse(timeStr)?.toUtc();
            double pointTotal = 0.0;

            for (final h in chartHoldings) {
              final isBeforeAcquisition = (barTime != null && h.buyDate != null && barTime.isBefore(h.buyDate!));
              if (isBeforeAcquisition) {
                // Before acquisition, position value was its initial cost basis (flat baseline before purchase)
                pointTotal += h.costBasis;
              } else {
                final bars = symbolBarsMap[h.symbol];
                double close = h.entryPrice;
                if (bars != null && bars.isNotEmpty) {
                  close = bars.first.closePrice;
                  for (final b in bars) {
                    if (b.timeStamp.compareTo(timeStr) <= 0) {
                      close = b.closePrice;
                    } else {
                      break;
                    }
                  }
                }
                if (close <= 0.0) close = h.entryPrice;
                pointTotal += (close * h.quantity);
              }
            }

            chartPoints.add({
              'value': pointTotal,
              'time': _formatBarTimestamp(timeStr, _selectedRange),
            });
          }
        }
      }
    }

    // Flatline at displayTotalValue when market closed or all points are zero
    final hasNonZero = chartPoints.any((pt) => (pt['value'] as num) > 0.0);
    if (!hasNonZero && displayTotalValue > 0.0) {
      chartPoints.clear();
      chartPoints.addAll(List.generate(20, (_) => {'value': displayTotalValue, 'time': 'Market Closed'}));
    }

    // Range-based return calculation
    double rangeChange = displayDayChange;
    double rangeReturnPct = todayReturnPercent;

    if (_selectedRange == 'MAX' && _selectedWatchlistId == null && displayTotalProfit != 0.0) {
      rangeChange = displayTotalProfit;
      rangeReturnPct = displayReturnPct;
    } else if (chartPoints.isNotEmpty && _selectedRange != '1D') {
      final startVal = (chartPoints.first['value'] as num).toDouble();
      final endVal = (chartPoints.last['value'] as num).toDouble();
      if (startVal > 0.0 && endVal > 0.0) {
        rangeChange = endVal - startVal;
        rangeReturnPct = (rangeChange / startVal) * 100;
      }
    }

    double finalDisplayDayChange = _selectedRange == '1D' ? displayDayChange : rangeChange;
    double finalDisplayReturnPct = _selectedRange == '1D' ? todayReturnPercent : rangeReturnPct;

    if (_scrubbedPoint != null && chartPoints.isNotEmpty) {
      final val = (_scrubbedPoint!['value'] as num).toDouble();
      displayTotalValue = val;
      if (_selectedRange == '1D') {
        final baseline = prevClose > 0 ? prevClose : displayTotalValue;
        finalDisplayDayChange = val - baseline;
        finalDisplayReturnPct = baseline > 0 ? (finalDisplayDayChange / baseline * 100) : 0.0;
      } else {
        final startVal = (chartPoints.first['value'] as num).toDouble();
        if (startVal > 0.0) {
          finalDisplayDayChange = val - startVal;
          finalDisplayReturnPct = (finalDisplayDayChange / startVal * 100);
        }
      }
    }

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Watchlist Portfolio Selector Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Portfolio Tracking',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: DropdownButton<String?>(
                      value: _selectedWatchlistId,
                      borderRadius: BorderRadius.circular(16),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pie_chart_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              const Text('Total Portfolio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
                                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text(w.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedWatchlistId = value;
                          _scrubbedPoint = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Total Portfolio Balance Value
            Text(
              formatPrice(displayTotalValue),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),

            // Daily Change Pill
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                // Daily Change Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (finalDisplayDayChange >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        finalDisplayDayChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: finalDisplayDayChange >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_selectedRange: ${formatSignedAmount(finalDisplayDayChange)} (${formatPercent(finalDisplayReturnPct)})',
                        style: TextStyle(
                          color: finalDisplayDayChange >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bezier Performance Curve Line Chart
            WatchlistTrackingChart(
              points: chartPoints,
              selectedRange: _selectedRange,
              isPositive: displayDayChange >= 0,
              onRangeChanged: (range) {
                setState(() {
                  _selectedRange = range;
                });
              },
              onScrub: (point) {
                setState(() {
                  _scrubbedPoint = point;
                });
              },
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Portfolio Metric Rows
            _MetricRow(
              label: 'Total profit',
              value: formatSignedAmount(displayTotalProfit),
              valueColor: displayTotalProfit >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
            _MetricRow(
              label: 'Total return',
              value: formatPercent(displayReturnPct),
              valueColor: displayReturnPct >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
            _MetricRow(
              label: 'Day change',
              value: formatSignedAmount(displayDayChange),
              valueColor: displayDayChange >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'As of ${formatAsOfTimestamp(summary.asOf)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.isDegraded) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Showing last known values',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.valueColor});

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(position.symbol, style: theme.textTheme.titleMedium),
                  Text(
                    '${position.volume} shares · cost ${formatPrice(position.totalPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (position.lastPrice != null) ...[
                  Text(
                    formatPrice(position.lastPrice! * position.volume),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatSignedAmount(
                      (position.lastPrice! * position.volume) -
                          position.totalPrice,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          ((position.lastPrice! * position.volume) >=
                                  position.totalPrice)
                              ? AppColors.positive
                              : AppColors.negative,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else ...[
                  Text(
                    formatAsOfTimestamp(position.updatedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.event,
    required this.mutationsEnabled,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioEvent event;
  final bool mutationsEnabled;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuy = event.action == 'BUY';
    final chipColor = isBuy ? AppColors.positive : AppColors.negative;

    return Dismissible(
      key: ValueKey(event.eventId),
      direction: mutationsEnabled
          ? DismissDirection.horizontal
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (!mutationsEnabled) {
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          await onDelete();
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
        }
        return false;
      },
      background: Container(
        color: AppColors.negative,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.delete_outline, color: AppColors.onPrimary),
      ),
      secondaryBackground: Container(
        color: AppColors.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.edit_outlined, color: AppColors.onPrimary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: mutationsEnabled ? onEdit : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTheme.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isBuy
                          ? AppColors.positiveBackground
                          : AppColors.negativeBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: chipColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${event.volume} ${event.volume == 1 ? "share" : "shares"} @ \$${formatPrice(event.price)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (event.watchlistName != null && event.watchlistName!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              isBuy ? 'Added to: ${event.watchlistName}' : 'Removed from: ${event.watchlistName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: chipColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          isBuy ? 'ADD TO WATCHLIST' : 'REMOVE FROM WATCHLIST',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: chipColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isBuy
                            ? 'Date of Add: ${formatEventDate(event.timeStamp)}'
                            : 'Date of Removed: ${formatEventDate(event.timeStamp)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                      Text(
                        formatAsOfTimestamp(event.timeStamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioSkeleton extends StatelessWidget {
  const _PortfolioSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        LoadingSkeleton(width: double.infinity, height: 160),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(width: double.infinity, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 20),
      ],
    );
  }
}
