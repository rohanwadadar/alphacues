import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../screener/data/screener_providers.dart';

/// Strategy Quick-Access — horizontal card row of saved strategies.
/// Tapping "See All" opens a modal bottom sheet displaying all strategies in a popup
/// (matching Watchlist architecture), complete with search, edit, delete, and add actions.
class StrategyQuickAccessWidget extends ConsumerWidget {
  const StrategyQuickAccessWidget({super.key});

  static Future<void> confirmDeleteStrategy(
    BuildContext context,
    WidgetRef ref,
    int strategyId,
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
            Text('Warning: Delete Strategy'),
          ],
        ),
        content: Text(
          'Warning: Are you sure you want to delete strategy "$name"?',
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
      final ok = await ref
          .read(savedStrategiesProvider.notifier)
          .deleteStrategy(strategyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                ok ? const Color(0xFF673AB7) : Colors.purple.shade900,
            content: Text(
              ok ? 'Deleted strategy "$name".' : 'Failed to delete strategy.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAllStrategiesModal(
    BuildContext context,
    WidgetRef ref,
    List<ScreenerStrategy> strategies,
  ) {
    final theme = Theme.of(context);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? strategies
                : strategies
                    .where((s) => s.name.toLowerCase().contains(query))
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
                          'Strategies',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          onPressed: () {
                            Navigator.of(modalContext).pop();
                            context.push(
                              '${AppRoutes.strategy}?create=true',
                              extra: true,
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          tooltip: 'Build New Strategy',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Search Input ─────────────────────────────────────────
                  if (strategies.length > 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search strategies...',
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

                  // ── Strategies Scrollable List ────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching strategies found',
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
                              return _StrategyTile(
                                strategy: item,
                                showActions: true,
                                onTap: () {
                                  Navigator.of(modalContext).pop();
                                  ref
                                      .read(screenerNotifierProvider.notifier)
                                      .applySavedStrategy(item);
                                  context.push(AppRoutes.strategy);
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
    final colorScheme = theme.colorScheme;
    final savedStrategies = ref.watch(savedStrategiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Strategies',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => context.push(
                    '${AppRoutes.strategy}?create=true',
                    extra: true,
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
                  tooltip: 'Add Strategy',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                final list = savedStrategies.valueOrNull ?? [];
                _showAllStrategiesModal(context, ref, list);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if ((savedStrategies.valueOrNull?.length ?? 0) > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${savedStrategies.valueOrNull!.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        savedStrategies.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (strategies) {
            if (strategies.isEmpty) {
              return GestureDetector(
                onTap: () => context.push(
                  '${AppRoutes.strategy}?create=true',
                  extra: true,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_graph_rounded,
                          color: colorScheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Build your first strategy →',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: strategies.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  if (i == strategies.length) {
                    return GestureDetector(
                      onTap: () => context.push(AppRoutes.strategy),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'New',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final s = strategies[i];
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(screenerNotifierProvider.notifier)
                          .applySavedStrategy(s);
                      context.push(AppRoutes.strategy);
                    },
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.15),
                            colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.auto_graph_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const Spacer(),
                          Text(
                            s.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.filters.isEmpty ? 'All stocks' : 'Filtered',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StrategyTile extends ConsumerWidget {
  const _StrategyTile({
    required this.strategy,
    required this.onTap,
    this.showActions = false,
  });

  final ScreenerStrategy strategy;
  final VoidCallback onTap;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    String filterSummary = 'All stocks';
    if (!strategy.filters.isEmpty) {
      final parts = <String>[];
      if (strategy.filters.marketCapMin != null ||
          strategy.filters.marketCapMax != null) {
        parts.add('Market Cap');
      }
      if (strategy.filters.peRatioMin != null ||
          strategy.filters.peRatioMax != null) {
        parts.add('P/E');
      }
      if (strategy.filters.priceMin != null ||
          strategy.filters.priceMax != null) {
        parts.add('Price');
      }
      if (strategy.filters.changePercentMin != null ||
          strategy.filters.changePercentMax != null) {
        parts.add('Change %');
      }
      if (strategy.filters.exchange != null &&
          strategy.filters.exchange!.isNotEmpty) {
        parts.add(strategy.filters.exchange!);
      }
      filterSummary = parts.isEmpty ? 'Custom Criteria' : parts.join(' • ');
    }

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
                  Icons.auto_graph_rounded,
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
                      strategy.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filterSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Rename/Edit Pen & Delete Recycle Bin Icon Buttons (Shown in "See All") ────
              if (showActions) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.85),
                  ),
                  tooltip: 'Edit Strategy',
                  onPressed: () {
                    ref
                        .read(screenerNotifierProvider.notifier)
                        .applySavedStrategy(strategy);
                    Navigator.of(context).pop();
                    context.push(
                      '${AppRoutes.strategy}?edit=true',
                      extra: true,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: theme.colorScheme.error.withValues(alpha: 0.85),
                  ),
                  tooltip: 'Delete Strategy',
                  onPressed: () {
                    StrategyQuickAccessWidget.confirmDeleteStrategy(
                      context,
                      ref,
                      strategy.strategyId,
                      strategy.name,
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

