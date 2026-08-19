import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_formatters.dart';
import 'dashboard_section_card.dart';

class TopMoversWidget extends StatefulWidget {
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
  State<TopMoversWidget> createState() => _TopMoversWidgetState();
}

class _TopMoversWidgetState extends State<TopMoversWidget> {
  String _filter = 'GAINERS';

  static const _fallbackMovers = [
    MarketMover(symbol: 'NVDA', lastPrice: 128.50, changePercent: 5.07),
    MarketMover(symbol: 'META', lastPrice: 475.20, changePercent: 2.68),
    MarketMover(symbol: 'AMD', lastPrice: 162.30, changePercent: 2.59),
    MarketMover(symbol: 'GOOGL', lastPrice: 343.37, changePercent: 1.01),
    MarketMover(symbol: 'AMZN', lastPrice: 185.40, changePercent: 1.53),
    MarketMover(symbol: 'AAPL', lastPrice: 188.90, changePercent: 0.66),
    MarketMover(symbol: 'MSFT', lastPrice: 415.50, changePercent: -0.50),
    MarketMover(symbol: 'NFLX', lastPrice: 640.10, changePercent: -1.31),
    MarketMover(symbol: 'TSLA', lastPrice: 178.25, changePercent: -2.59),
    MarketMover(symbol: 'INTC', lastPrice: 30.75, changePercent: -3.76),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allMovers = widget.movers.isNotEmpty ? widget.movers : _fallbackMovers;

    final displayedMovers = allMovers.where((m) {
      if (_filter == 'GAINERS') return m.changePercent >= 0;
      if (_filter == 'LOSERS') return m.changePercent < 0;
      return true;
    }).toList();

    return DashboardSectionCard(
      title: 'Market Movers',
      isStale: widget.isStale,
      errorMessage: widget.errorMessage,
      onRetry: widget.onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilterChip(
                label: const Text('Top Gainers'),
                selected: _filter == 'GAINERS',
                selectedColor: const Color(0xFF22C55E).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _filter == 'GAINERS' ? const Color(0xFF15803D) : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _filter = 'GAINERS'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Top Losers'),
                selected: _filter == 'LOSERS',
                selectedColor: const Color(0xFFEF4444).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _filter == 'LOSERS' ? const Color(0xFFB91C1C) : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) => setState(() => _filter = 'LOSERS'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('All'),
                selected: _filter == 'ALL',
                labelStyle: const TextStyle(fontSize: 12),
                onSelected: (_) => setState(() => _filter = 'ALL'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (displayedMovers.isEmpty)
            Text(
              'No market movers available right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < displayedMovers.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MoverRow(mover: displayedMovers[i]),
                ],
              ],
            ),
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
