import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class TopTrader {
  const TopTrader({
    required this.name,
    required this.handle,
    required this.returnYtd,
    required this.winRate,
    required this.followers,
    required this.topHoldings,
    required this.avatarAccent,
  });

  final String name;
  final String handle;
  final double returnYtd;
  final int winRate;
  final String followers;
  final List<String> topHoldings;
  final Color avatarAccent;
}

const kTopTraders = [
  TopTrader(
    name: 'Alex Rivers',
    handle: '@arivers_alpha',
    returnYtd: 142.8,
    winRate: 88,
    followers: '14.2k',
    topHoldings: ['NVDA', 'GOOGL', 'AAPL'],
    avatarAccent: Color(0xFF7C3AED),
  ),
  TopTrader(
    name: 'Sarah Chen',
    handle: '@schen_quant',
    returnYtd: 98.4,
    winRate: 84,
    followers: '9.8k',
    topHoldings: ['TSLA', 'AMZN', 'META'],
    avatarAccent: Color(0xFF2563EB),
  ),
  TopTrader(
    name: 'Marcus Vance',
    handle: '@mvance_macro',
    returnYtd: 84.2,
    winRate: 79,
    followers: '7.1k',
    topHoldings: ['AMD', 'MSFT', 'INTC'],
    avatarAccent: Color(0xFF10B981),
  ),
];

class SocialCopyTradingWidget extends StatelessWidget {
  const SocialCopyTradingWidget({super.key});

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
                    Icon(Icons.workspace_premium_rounded, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Copy Trading & Leaderboard',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verified Returns',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Top Traders List
            ...kTopTraders.map(
              (trader) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: trader.avatarAccent.withValues(alpha: 0.2),
                      child: Text(
                        trader.name[0],
                        style: TextStyle(color: trader.avatarAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                trader.name,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded, size: 14, color: colorScheme.primary),
                            ],
                          ),
                          Text(
                            '${trader.handle} • ${trader.followers} copiers',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: trader.topHoldings.map((sym) {
                              return GestureDetector(
                                onTap: () => context.push(AppRoutes.symbolDetail(sym)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    sym,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '+${trader.returnYtd.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.positive,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${trader.winRate}% Win Rate',
                          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        FilledButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied ${trader.name}\'s strategy into Virtual Portfolio!'),
                                backgroundColor: const Color(0xFF673AB7),
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
