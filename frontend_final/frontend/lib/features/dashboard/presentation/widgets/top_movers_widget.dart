import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_card.dart';

class TopMoversWidget extends StatelessWidget {
  const TopMoversWidget({
    super.key,
    required this.movers,
    this.isStale = false,
    this.errorMessage,
    this.onRetry,
  });

  final List<MarketMover> movers;
  final bool isStale;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardSectionCard(
      title: 'Top Movers',
      isStale: isStale,
      errorMessage: errorMessage,
      onRetry: onRetry,
      child: movers.isEmpty
          ? Text(
              'No movers available right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < movers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MoverRow(mover: movers[i]),
                ],
              ],
            ),
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.mover});

  final MarketMover mover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = mover.changePercent >= 0;
    final changeColor = isPositive ? AppColors.positive : AppColors.negative;
    final badgeBg = isPositive ? AppColors.positiveBackground : AppColors.negativeBackground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.symbolDetail(mover.symbol)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    mover.symbol.substring(0, mover.symbol.length > 2 ? 2 : mover.symbol.length),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    mover.symbol,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  formatPrice(mover.lastPrice),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        formatPercent(mover.changePercent),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
