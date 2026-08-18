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
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../market/presentation/symbol_detail_screen.dart';
import '../../screener/data/screener_models.dart';
import '../../screener/data/screener_providers.dart';
import '../../screener/presentation/custom_screener_builder.dart';
import '../../screener/presentation/screener_filter_dialog.dart';
import '../../screener/presentation/screener_screen.dart';
import '../../screener/presentation/widgets/screener_result_card.dart';
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

            Widget pageBody = SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isOnline) const StaleBanner(),

                  // ── 1. WATCHLISTS SECTION ─────────────────────────────────────
                  watchlistsAsync.when(
                    loading: () => const _WatchlistsSkeleton(),
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

                      return Column(
                        children: watchlists.map((watchlist) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: _WatchlistRow(
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
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── 2. STOCK SCREENER SECTION ──────────────────────────────────
                  const _ScreenerSection(),
                ],
              ),
            );

            if (!isPhone) {
              pageBody = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: pageBody,
                ),
              );
            }

            return pageBody;
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
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Watchlist'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(watchlistRepositoryProvider).deleteWatchlist(watchlistId);
      ref.read(watchlistsProvider.notifier).refresh();
    }
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.star,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          watchlist.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${watchlist.symbolCount} ${watchlist.symbolCount == 1 ? 'symbol' : 'symbols'}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'rename') {
              onRename();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              enabled: mutationsEnabled,
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('Rename'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              enabled: mutationsEnabled,
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistsSkeleton extends StatelessWidget {
  const _WatchlistsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

// ── SCREENER SECTION BELOW WATCHLISTS ──────────────────────────────────────────
class _ScreenerSection extends ConsumerWidget {
  const _ScreenerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenerNotifierProvider);
    final notifier = ref.read(screenerNotifierProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final results = state.result?.items ?? [];

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Icon(Icons.tune_rounded, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Stock Screener',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded),
                  tooltip: 'Filter Options',
                  onPressed: () async {
                    final newFilter = await ScreenerFilterDialog.show(
                      context,
                      state.filters,
                    );
                    if (newFilter != null) {
                      notifier.setFilters(newFilter);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded),
                  tooltip: 'Full Screener View',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScreenerScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Preset Badges + Custom Builder Action
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: Icon(Icons.add_circle_outline_rounded, size: 16, color: colorScheme.primary),
                    label: Text(
                      'Custom Builder',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                    side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomScreenerBuilderScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Megacaps (\$200B+)',
                    icon: Icons.domain_rounded,
                    isSelected: state.filters.marketCapMin == 200e9,
                    onTap: () {
                      notifier.setFilters(const ScreenerFilter(marketCapMin: 200e9));
                    },
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Top Gainers (>+2%)',
                    icon: Icons.trending_up_rounded,
                    isSelected: state.filters.changePercentMin == 2.0,
                    onTap: () {
                      notifier.setFilters(const ScreenerFilter(changePercentMin: 2.0));
                    },
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Value (P/E < 25)',
                    icon: Icons.price_check_rounded,
                    isSelected: state.filters.peRatioMax == 25.0,
                    onTap: () {
                      notifier.setFilters(const ScreenerFilter(peRatioMax: 25.0));
                    },
                  ),
                  const SizedBox(width: 8),
                  _PresetChip(
                    label: 'Under \$100',
                    icon: Icons.sell_outlined,
                    isSelected: state.filters.priceMax == 100.0,
                    onTap: () {
                      notifier.setFilters(const ScreenerFilter(priceMax: 100.0));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading state
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 36, color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'No matching stocks found',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () => notifier.setFilters(const ScreenerFilter()),
                        child: const Text('Reset Filters'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Render Screener Results List
              Column(
                children: results.take(6).map((item) {
                  return ScreenerResultCard(
                    item: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SymbolDetailScreen(symbol: item.symbol),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      onSelected: (_) => onTap(),
    );
  }
}
