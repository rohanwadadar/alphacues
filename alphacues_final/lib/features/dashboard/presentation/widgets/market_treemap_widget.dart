import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class MarketSector {
  const MarketSector({
    required this.name,
    required this.changePercent,
    required this.weight,
    required this.topSymbols,
    required this.icon,
  });

  final String name;
  final double changePercent;
  final double weight;
  final List<String> topSymbols;
  final IconData icon;
}

const kMarketSectors = [
  MarketSector(
    name: 'Technology',
    changePercent: 2.45,
    weight: 0.30,
    topSymbols: ['AAPL', 'NVDA', 'MSFT', 'AVGO'],
    icon: Icons.memory_rounded,
  ),
  MarketSector(
    name: 'Communication',
    changePercent: 1.82,
    weight: 0.16,
    topSymbols: ['GOOGL', 'META', 'NFLX'],
    icon: Icons.cell_tower_rounded,
  ),
  MarketSector(
    name: 'Consumer',
    changePercent: 1.15,
    weight: 0.18,
    topSymbols: ['AMZN', 'TSLA', 'HD'],
    icon: Icons.shopping_bag_outlined,
  ),
  MarketSector(
    name: 'Financials',
    changePercent: -0.45,
    weight: 0.14,
    topSymbols: ['JPM', 'BAC', 'V', 'MA'],
    icon: Icons.account_balance_rounded,
  ),
  MarketSector(
    name: 'Healthcare',
    changePercent: -0.85,
    weight: 0.12,
    topSymbols: ['LLY', 'UNH', 'JNJ'],
    icon: Icons.health_and_safety_rounded,
  ),
  MarketSector(
    name: 'Energy',
    changePercent: 3.12,
    weight: 0.10,
    topSymbols: ['XOM', 'CVX'],
    icon: Icons.bolt_rounded,
  ),
];

class MarketTreemapWidget extends StatelessWidget {
  const MarketTreemapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.grid_view_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Market Sector Treemap',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'S&P 500 Heatmap',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Sector Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.25,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: kMarketSectors.length,
              itemBuilder: (context, index) {
                final sector = kMarketSectors[index];
                final isPositive = sector.changePercent >= 0;
                final tileColor = isPositive ? AppColors.positive : AppColors.negative;

                return InkWell(
                  onTap: () {
                    if (sector.topSymbols.isNotEmpty) {
                      context.push(AppRoutes.symbolDetail(sector.topSymbols.first));
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tileColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: tileColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(sector.icon, size: 16, color: tileColor),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: tileColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${isPositive ? '+' : ''}${sector.changePercent.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: tileColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sector.name,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              sector.topSymbols.join(', '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
