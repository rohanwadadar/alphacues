import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_card.dart';

class PortfolioSummaryWidget extends StatefulWidget {
  const PortfolioSummaryWidget({
    super.key,
    required this.portfolio,
    this.isStale = false,
    this.errorMessage,
    this.onRetry,
  });

  final PortfolioSummary? portfolio;
  final bool isStale;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<PortfolioSummaryWidget> createState() => _PortfolioSummaryWidgetState();
}

class _PortfolioSummaryWidgetState extends State<PortfolioSummaryWidget> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final portfolio = widget.portfolio;

    return DashboardSectionCard(
      title: 'Portfolio',
      isStale: widget.isStale,
      errorMessage: widget.errorMessage,
      onRetry: widget.onRetry,
      child: portfolio == null
          ? Text(
              'Portfolio summary unavailable.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
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
                  _showBalance ? formatPrice(portfolio.totalValue) : '••••••••',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                _PortfolioMetricRow(
                  label: 'Available balance',
                  value: _showBalance ? formatPrice(portfolio.availableBalance) : '••••••••',
                ),
                _PortfolioMetricRow(
                  label: 'Total profit',
                  value: _showBalance ? formatSignedAmount(portfolio.totalProfit) : '••••••••',
                  valueColor: portfolio.totalProfit >= 0
                      ? AppColors.positive
                      : AppColors.negative,
                ),
                _PortfolioMetricRow(
                  label: 'Total return',
                  value: formatPercent(portfolio.totalReturn),
                  valueColor: portfolio.totalReturn >= 0
                      ? AppColors.positive
                      : AppColors.negative,
                ),
                _PortfolioMetricRow(
                  label: 'Day change',
                  value: _showBalance ? formatSignedAmount(portfolio.dayChange) : '••••••••',
                  valueColor: portfolio.dayChange >= 0
                      ? AppColors.positive
                      : AppColors.negative,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'As of ${formatAsOfTimestamp(portfolio.asOf)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.portfolio),
                    child: const Text('View portfolio'),
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
