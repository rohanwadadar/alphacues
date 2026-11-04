import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../watchlist/data/watchlist_providers.dart';
import '../../../watchlist/presentation/watchlist_form_dialog.dart';

class WatchlistSummaryWidget extends ConsumerWidget {
  const WatchlistSummaryWidget({super.key});

  static Future<void> confirmDeleteWatchlist(
    BuildContext context,
    WidgetRef ref,
    String watchlistId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Text('Warning: Delete Watchlist'),
          ],
        ),
        content: Text(
          'Warning: Are you sure you want to delete "$name"? All stored stocks inside will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(watchlistRepositoryProvider)
            .deleteWatchlist(watchlistId);
        ref.invalidate(watchlistsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF673AB7),
              content: Text('Deleted watchlist "$name".'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.purple.shade900,
              content: Text('Failed to delete watchlist: $e'),
            ),
          );
        }
      }
    }
  }

  void _showAllWatchlistsModal(
    BuildContext context,
    List<Watchlist> watchlists,
  ) {
    final theme = Theme.of(context);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? watchlists
                : watchlists
                    .where((w) => w.name.toLowerCase().contains(query))
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // ── Drag Handle ──────────────────────────────────────────
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title & Add Action ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'Watchlist',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () {
                            Navigator.of(context).pop();
                            WatchlistFormDialog.show(
                              context,
                              mode: WatchlistFormMode.create,
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: 'Add new watchlist',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Search Input (for 50+ watchlists) ───────────────────
                  if (watchlists.length > 5)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search watchlists...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // ── Watchlists Scrollable List ───────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching watchlists found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = filtered[index];
                              return _WatchlistTile(
                                watchlist: item,
                                showActions: true,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push(
                                    AppRoutes.watchlistDetail(item.watchlistId),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final watchlistsAsync = ref.watch(watchlistsProvider);

    return watchlistsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LoadingSkeleton(width: 110, height: 22),
              const SizedBox(width: 8),
              const LoadingSkeleton(width: 28, height: 28),
              const Spacer(),
              const LoadingSkeleton(width: 60, height: 20),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watchlists',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
      ),
      data: (watchlists) {
        if (watchlists.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: EmptyState(
              icon: Icons.star_outline_rounded,
              heading: 'Create your first watchlist',
              body: 'Track symbols you care about right from your dashboard.',
              actionLabel: 'Create Watchlist',
              onAction: () => WatchlistFormDialog.show(
                context,
                mode: WatchlistFormMode.create,
              ),
            ),
          );
        }

        // Show top 3 watchlists on home page card
        final displayList = watchlists.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Minimalist Section Header ─────────────────────────────────
            Row(
              children: [
                Text(
                  'Watchlists',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),

                // ── (+) Add Watchlist Button ──────────────────────────────
                IconButton(
                  onPressed: () => WatchlistFormDialog.show(
                    context,
                    mode: WatchlistFormMode.create,
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  tooltip: 'Add Watchlist',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const Spacer(),

                // ── "See All" Popup Trigger ─────────────────────────────────
                TextButton(
                  onPressed: () => _showAllWatchlistsModal(context, watchlists),
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Single Minimalist Card Container ───────────────────────────
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < displayList.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    _WatchlistTile(
                      watchlist: displayList[i],
                      showActions: false,
                      onTap: () => context.push(
                        AppRoutes.watchlistDetail(displayList[i].watchlistId),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WatchlistTile extends ConsumerWidget {
  const _WatchlistTile({
    required this.watchlist,
    required this.onTap,
    this.showActions = false,
  });

  final Watchlist watchlist;
  final VoidCallback onTap;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
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
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${watchlist.symbolCount} ${watchlist.symbolCount == 1 ? 'stock' : 'stocks'} tracked',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Rename Pen & Delete Recycle Bin Icon Buttons (Shown only in "See All") ────
              if (showActions) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.85),
                  ),
                  tooltip: 'Rename Watchlist',
                  onPressed: () {
                    WatchlistFormDialog.show(
                      context,
                      mode: WatchlistFormMode.rename,
                      watchlistId: watchlist.watchlistId,
                      initialName: watchlist.name,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: theme.colorScheme.error.withValues(alpha: 0.85),
                  ),
                  tooltip: 'Delete Watchlist',
                  onPressed: () {
                    WatchlistSummaryWidget.confirmDeleteWatchlist(
                      context,
                      ref,
                      watchlist.watchlistId,
                      watchlist.name,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
