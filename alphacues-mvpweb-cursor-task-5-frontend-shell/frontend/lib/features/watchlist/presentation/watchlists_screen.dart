import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../data/watchlist_providers.dart';
import 'watchlist_form_dialog.dart';

class WatchlistsScreen extends ConsumerWidget {
  const WatchlistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistsAsync = ref.watch(watchlistsProvider);
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final mutationsEnabled = isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLabels.watchlists),
        actions: [
          IconButton(
            onPressed: mutationsEnabled
                ? () => WatchlistFormDialog.show(
                    context,
                    mode: WatchlistFormMode.create,
                  )
                : null,
            icon: const Icon(Icons.add),
            tooltip: 'Create watchlist',
          ),
        ],
      ),
      floatingActionButton: mutationsEnabled
          ? FloatingActionButton(
              onPressed: () => WatchlistFormDialog.show(
                context,
                mode: WatchlistFormMode.create,
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeScreen(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth <= 600;
            Widget listBody = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isOnline) const StaleBanner(),
                Expanded(
                  child: watchlistsAsync.when(
                    loading: () => _WatchlistsSkeleton(),
                    error: (error, _) => ErrorState(
                      message: error.toString(),
                      onRetry: () =>
                          ref.read(watchlistsProvider.notifier).refresh(),
                    ),
                    data: (watchlists) {
                      if (watchlists.isEmpty) {
                        return EmptyState(
                          icon: Icons.star_outline,
                          heading: 'No watchlists yet',
                          body: 'Create a watchlist to track the symbols you care about.',
                          actionLabel: mutationsEnabled ? 'Create watchlist' : null,
                          onAction: mutationsEnabled
                              ? () => WatchlistFormDialog.show(
                                    context,
                                    mode: WatchlistFormMode.create,
                                  )
                              : null,
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        itemCount: watchlists.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final watchlist = watchlists[index];
                          return _WatchlistRow(
                            watchlist: watchlist,
                            mutationsEnabled: mutationsEnabled,
                            onTap: () => context.go(
                              AppRoutes.watchlistDetail(watchlist.watchlistId),
                            ),
                            onRename: () => WatchlistFormDialog.show(
                              context,
                              mode: WatchlistFormMode.rename,
                              watchlistId: watchlist.watchlistId,
                              initialName: watchlist.name,
                            ),
                            onDelete: () => _confirmDeleteWatchlist(
                              context,
                              ref,
                              watchlist.watchlistId,
                              watchlist.name,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );

            if (!isPhone) {
              listBody = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: listBody,
                ),
              );
            }

            return listBody;
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteWatchlist(
    BuildContext context,
    WidgetRef ref,
    String watchlistId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete watchlist?'),
        content: Text('Remove "$name" and all of its symbols?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(watchlistDeleteProvider.notifier).delete(watchlistId);
  }
}

class _WatchlistsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const Row(
        children: [
          Expanded(
            child: LoadingSkeleton(width: double.infinity, height: 20),
          ),
          SizedBox(width: AppSpacing.md),
          LoadingSkeleton(width: 40, height: 20),
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({
    required this.watchlist,
    required this.mutationsEnabled,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final Watchlist watchlist;
  final bool mutationsEnabled;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        '${watchlist.symbolCount} symbol${watchlist.symbolCount == 1 ? '' : 's'}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
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
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: onTap,
            onLongPress: mutationsEnabled ? () => _showActions(context) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (mutationsEnabled)
                      IconButton(
                        onPressed: () => _showActions(context),
                        icon: const Icon(Icons.more_vert),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(context).pop();
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
