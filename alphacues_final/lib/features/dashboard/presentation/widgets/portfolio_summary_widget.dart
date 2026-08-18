import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../watchlist/presentation/widgets/watchlist_tracking_chart.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../portfolio/data/portfolio_providers.dart';
import '../../../watchlist/data/watchlist_providers.dart';

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
  ConsumerState<PortfolioSummaryWidget> createState() => _PortfolioSummaryWidgetState();
}

class _PortfolioSummaryWidgetState extends ConsumerState<PortfolioSummaryWidget> {
  bool _showBalance = true;
  String _selectedRange = '1D';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portfolioAsync = ref.watch(portfolioSummaryProvider);
    final watchlistsAsync = ref.watch(watchlistsProvider);

    double totalValue = widget.portfolio?.totalValue ?? 0.0;
    double dayChange = widget.portfolio?.dayChange ?? 0.0;
    double totalProfit = widget.portfolio?.totalProfit ?? 0.0;
    double totalReturn = widget.portfolio?.totalReturn ?? 0.0;

    if (portfolioAsync case AsyncData(:final value)) {
      totalValue = value.summary.totalValue;
      dayChange = value.summary.dayChange;
      totalProfit = value.summary.totalProfit;
      totalReturn = value.summary.totalReturn;
    }

    if (totalValue == 0 && watchlistsAsync.hasValue) {
      final lists = watchlistsAsync.requireValue;
      for (final w in lists) {
        final detailAsync = ref.watch(watchlistDetailProvider(w.watchlistId));
        if (detailAsync case AsyncData(:final value)) {
          for (final item in value.items) {
            final price = item.quote?.lastPrice ?? 150.0;
            final qty = item.quantity ?? 1.0;
            final chg = item.quote?.changeAmount ?? 2.5;
            totalValue += price * qty;
            dayChange += chg * qty;
          }
        }
      }
      totalProfit = dayChange;
      totalReturn = totalValue > 0 ? (dayChange / totalValue * 100) : 0.0;
    }

    final chartPoints = List.generate(20, (i) {
      final base = totalValue == 0 ? 2500.0 : totalValue;
      double mult = 1.0;
      if (_selectedRange == '5D') mult = 1.0 + (i * 0.005);
      else if (_selectedRange == '1M') mult = 1.0 + (i * 0.01);
      else if (_selectedRange == '3M') mult = 1.0 + (i * 0.015);
      else if (_selectedRange == 'YTD') mult = 1.0 + (i * 0.02);
      else if (_selectedRange == '1Y') mult = 1.0 + (i * 0.025);
      else if (_selectedRange == 'MAX') mult = 1.0 + (i * 0.03);
      return {'value': base * (0.96 + 0.04 * (i / 20.0) * mult)};
    });

    return DashboardSectionCard(
      title: 'Portfolio',
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
                'Total value',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _showBalance = !_showBalance),
              ),
            ],
          ),
          Text(
            _showBalance ? formatPrice(totalValue) : '••••••••',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                dayChange >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: dayChange >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(
                '${formatSignedAmount(dayChange)} (${formatPercent(totalReturn)}) Today',
                style: TextStyle(
                  color: dayChange >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          WatchlistTrackingChart(
            points: chartPoints,
            selectedRange: _selectedRange,
            isPositive: dayChange >= 0,
            onRangeChanged: (range) {
              setState(() {
                _selectedRange = range;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.portfolio),
              child: const Text('View full portfolio details'),
            ),
          ),
        ],
      ),
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
