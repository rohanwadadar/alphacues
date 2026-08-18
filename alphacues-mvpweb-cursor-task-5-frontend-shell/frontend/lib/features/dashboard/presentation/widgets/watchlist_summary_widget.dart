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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.watchlistDetail(watchlist.watchlistId)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    watchlist.name,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${watchlist.symbolCount} symbols',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
