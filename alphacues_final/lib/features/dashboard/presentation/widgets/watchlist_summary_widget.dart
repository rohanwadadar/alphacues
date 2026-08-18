import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../watchlist/data/watchlist_providers.dart';
import 'dashboard_section_card.dart';

class WatchlistSummaryWidget extends ConsumerWidget {
  const WatchlistSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistsAsync = ref.watch(watchlistsProvider);

    return watchlistsAsync.when(
      loading: () => const DashboardSectionCard(
        title: 'Watchlists',
        child: Column(
          children: [
            Row(
              children: [
                LoadingSkeleton(width: 120, height: 18),
                Spacer(),
                LoadingSkeleton(width: 40, height: 18),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                LoadingSkeleton(width: 96, height: 18),
                Spacer(),
                LoadingSkeleton(width: 40, height: 18),
              ],
            ),
          ],
        ),
      ),
      error: (error, _) => DashboardSectionCard(
        title: 'Watchlists',
        errorMessage: error.toString(),
        onRetry: () => ref.read(watchlistsProvider.notifier).refresh(),
        child: const SizedBox.shrink(),
      ),
      data: (watchlists) {
        if (watchlists.isEmpty) {
          return DashboardSectionCard(
            title: 'Watchlists',
            child: EmptyState(
              icon: Icons.star_outline,
              heading: 'Create your first watchlist',
              body: 'Track the symbols you care about from your dashboard.',
              actionLabel: 'Create watchlist',
              onAction: () => context.go(AppRoutes.watchlists),
            ),
          );
        }

        return DashboardSectionCard(
          title: 'Watchlists',
          child: Column(
            children: [
              for (var i = 0; i < watchlists.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _WatchlistSummaryRow(watchlist: watchlists[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WatchlistSummaryRow extends StatelessWidget {
  const _WatchlistSummaryRow({required this.watchlist});

  final Watchlist watchlist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(AppRoutes.watchlistDetail(watchlist.watchlistId)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  child: Icon(Icons.star, size: 18, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        watchlist.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${watchlist.symbolCount} stocks tracked',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'View List',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
