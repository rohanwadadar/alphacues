import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/screener_models.dart';

/// A single result row card for the screener results table.
/// Displays: symbol, exchange badge, company name, price, day change %, market cap, P/E ratio.
class ScreenerResultCard extends StatelessWidget {
  const ScreenerResultCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ScreenerResultItem item;
  final VoidCallback? onTap;

  String _formatMarketCap(double cap) {
    if (cap >= 1e12) {
      return '\$${(cap / 1e12).toStringAsFixed(2)}T';
    } else if (cap >= 1e9) {
      return '\$${(cap / 1e9).toStringAsFixed(1)}B';
    } else if (cap >= 1e6) {
      return '\$${(cap / 1e6).toStringAsFixed(1)}M';
    }
    return '\$${cap.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = item.changePercent >= 0;
    final changeColor = isPositive ? AppColors.positive : AppColors.negative;
    final badgeBg = isPositive ? AppColors.positiveBackground : AppColors.negativeBackground;
    final changePrefix = isPositive ? '+' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: symbol + exchange tag | price
                Row(
                  children: [
                    Text(
                      item.symbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        item.exchange,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Row 2: company name | day change % pill
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$changePrefix${item.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Row 3: market cap | P/E | dividend yield (if set)
                Wrap(
                  spacing: 16,
                  children: [
                    Text(
                      'Cap: ${_formatMarketCap(item.marketCap)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'P/E: ${item.peRatio != null ? item.peRatio!.toStringAsFixed(1) : "N/A"}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.dividendYield != null && item.dividendYield! > 0)
                      Text(
                        'Div: ${item.dividendYield!.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
