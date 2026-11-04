import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../watchlist/presentation/add_to_watchlist_dialog.dart';
import '../../data/screener_models.dart';

/// A single result row card for the screener results table.
/// Displays: symbol, company full name (small size), exchange badge, price, day change %, market cap, volume, P/E ratio, and add button.
class ScreenerResultCard extends StatelessWidget {
  const ScreenerResultCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ScreenerResultItem item;
  final VoidCallback? onTap;

  String _formatMarketCap(double? cap) {
    if (cap == null) return 'N/A';
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
    final colorScheme = theme.colorScheme;
    final isPositive = item.changePercent >= 0;
    final changeColor = isPositive ? AppColors.positive : AppColors.negative;
    final badgeBg = isPositive
        ? AppColors.positiveBackground
        : AppColors.negativeBackground;
    final changePrefix = isPositive ? '+' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                // ── Row 1: Symbol + Tag + Name (Left) | Price + Change % (Mid-Right) | Add Button (+) (Far Right) ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Symbol + Tag + Company Full Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.symbol,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              if (item.exchange != null) Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer
                                      .withValues(alpha: 0.6),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  item.exchange!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.name.isEmpty ? item.symbol : item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11.5,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Mid-Right Column: Price (top) + Day Change % Pill (directly underneath price)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            '$changePrefix${item.changePercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // Far Right: Isolated Add Button (+) with clean purple theme
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: IconButton(
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                        ),
                        tooltip: 'Add Stock to Watchlist',
                        onPressed: () => AddToWatchlistDialog.show(
                          context,
                          item.symbol,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 8),

                // ── Market cap and valuation when supplied by the provider ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cap: ${_formatMarketCap(item.marketCap)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'P/E: ${item.peRatio != null ? item.peRatio!.toStringAsFixed(1) : "N/A"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
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

