import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/widgets/safe_screen.dart';
import '../data/screener_providers.dart';
import 'screener_filter_dialog.dart';
import 'widgets/screener_result_card.dart';

/// Strategy Builder Screen v1 (Backup of previous design)
class StrategyScreenV1 extends ConsumerStatefulWidget {
  const StrategyScreenV1({super.key});

  @override
  ConsumerState<StrategyScreenV1> createState() => _StrategyScreenV1State();
}

class _StrategyScreenV1State extends ConsumerState<StrategyScreenV1> {
  final _strategyNameController =
      TextEditingController(text: 'My Custom Strategy');

  ScreenerFilter _currentFilter = const ScreenerFilter();
  String _sortBy = 'marketCap';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runScan());
  }

  @override
  void dispose() {
    _strategyNameController.dispose();
    super.dispose();
  }

  void _runScan() {
    final notifier = ref.read(screenerNotifierProvider.notifier);
    notifier.setFilters(_currentFilter);
    notifier.setSorting(_sortBy, _sortOrder);
  }

  Future<void> _saveStrategy() async {
    final name = _strategyNameController.text.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a strategy name.')),
      );
      return;
    }
    final ok = await ref.read(savedStrategiesProvider.notifier).saveStrategy(
          name: name,
          filters: _currentFilter,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          description: 'Custom market scan strategy',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Strategy "$name" saved!' : 'Failed to save strategy.'),
        backgroundColor: ok ? const Color(0xFF673AB7) : Colors.purple.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openFilterDialog() async {
    final result = await ScreenerFilterDialog.show(
      context,
      _currentFilter,
    );
    if (result != null) {
      setState(() => _currentFilter = result);
      _runScan();
    }
  }

  void _applyPreset(ScreenerStrategy strategy) {
    setState(() {
      _currentFilter = strategy.filters;
      _sortBy = strategy.sortBy;
      _sortOrder = strategy.sortOrder;
      _strategyNameController.text = strategy.name;
    });
    ref.read(screenerNotifierProvider.notifier).applySavedStrategy(strategy);
    _runScan();
  }

  Future<void> _deleteStrategy(int strategyId) async {
    final ok = await ref.read(savedStrategiesProvider.notifier).deleteStrategy(strategyId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Strategy deleted.' : 'Failed to delete strategy.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteStrategy(ScreenerStrategy strategy) async {
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
          'Warning: Are you sure you want to delete strategy "${strategy.name}"?',
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
      await _deleteStrategy(strategy.strategyId);
    }
  }

  Future<void> _editStrategyFilter(ScreenerStrategy strategy) async {
    _applyPreset(strategy);
    final newFilter = await ScreenerFilterDialog.show(context, _currentFilter);
    if (newFilter != null) {
      setState(() => _currentFilter = newFilter);
      _runScan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated filter criteria for "${strategy.name}". Click Save to persist.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenerState = ref.watch(screenerNotifierProvider);
    final savedStrategiesAsync = ref.watch(savedStrategiesProvider);
    final results = screenerState.result?.items ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const AlphaCuesFullLogo(),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeScreen(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Title Header ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strategy Builder',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan live market data with custom criteria & saved presets',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── "Add a new strategy" Command Box ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_chart_rounded, size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Add a new strategy',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _strategyNameController,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Strategy Name',
                          hintText: 'e.g. High Growth Tech',
                          prefixIcon: const Icon(Icons.edit_note_rounded, size: 22),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: FilledButton.icon(
                              onPressed: _runScan,
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: const Text('Run Screener', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: OutlinedButton.icon(
                              onPressed: _openFilterDialog,
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: Text(
                                _currentFilter.isEmpty ? 'Add Filters' : 'Edit Filters',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Tooltip(
                            message: 'Save Strategy',
                            child: IconButton.filled(
                              onPressed: _saveStrategy,
                              icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Saved Strategies Section ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Saved Strategies',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    savedStrategiesAsync.when(
                      loading: () => const SizedBox(
                        height: 48,
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (strategies) {
                        if (strategies.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark_border_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No saved strategies yet. Save your custom filter rules above to reuse anytime.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
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
                              for (var i = 0; i < strategies.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: theme.dividerColor
                                        .withValues(alpha: 0.15),
                                  ),
                                _SavedStrategyItemTileV1(
                                  strategy: strategies[i],
                                  isSelected: _strategyNameController.text ==
                                      strategies[i].name,
                                  onTap: () => _applyPreset(strategies[i]),
                                  onEdit: () =>
                                      _editStrategyFilter(strategies[i]),
                                  onDelete: () =>
                                      _confirmDeleteStrategy(strategies[i]),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Active Filter Condition Chips ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ActiveConditionChipsV1(
                  filter: _currentFilter,
                  onClear: () {
                    setState(() => _currentFilter = const ScreenerFilter());
                    _runScan();
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Sort & Stock Results Header ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SortChipV1(
                      label: 'Mkt Cap',
                      value: 'marketCap',
                      sortBy: _sortBy,
                      onTap: () {
                        setState(() {
                          _sortBy = 'marketCap';
                          _sortOrder = 'desc';
                        });
                        _runScan();
                      },
                    ),
                    const SizedBox(width: 6),
                    _SortChipV1(
                      label: 'Change%',
                      value: 'changePercent',
                      sortBy: _sortBy,
                      onTap: () {
                        setState(() {
                          _sortBy = 'changePercent';
                          _sortOrder = 'desc';
                        });
                        _runScan();
                      },
                    ),
                    const SizedBox(width: 6),
                    _SortChipV1(
                      label: 'P/E',
                      value: 'peRatio',
                      sortBy: _sortBy,
                      onTap: () {
                        setState(() {
                          _sortBy = 'peRatio';
                          _sortOrder = 'asc';
                        });
                        _runScan();
                      },
                    ),
                    const Spacer(),
                    if (screenerState.result != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${results.length} stocks',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // ── Live Scan Results List ──────────────────────────────────────
            if (screenerState.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (screenerState.isOffline)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'You are offline.\nConnect to run a new scan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (screenerState.error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Scan failed: ${screenerState.error}\nAdjust filters and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                ),
              )
            else if (results.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No stocks match your conditions.\nAdjust filters to see results.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = results[i];
                      return ScreenerResultCard(
                        item: item,
                        onTap: () => context.push(AppRoutes.symbolDetail(item.symbol)),
                      );
                    },
                    childCount: results.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

class _SortChipV1 extends StatelessWidget {
  const _SortChipV1({
    required this.label,
    required this.value,
    required this.sortBy,
    required this.onTap,
  });
  final String label;
  final String value;
  final String sortBy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = sortBy == value;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ActiveConditionChipsV1 extends StatelessWidget {
  const _ActiveConditionChipsV1({
    required this.filter,
    required this.onClear,
  });
  final ScreenerFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chips = <String>[];

    if (filter.marketCapMin != null || filter.marketCapMax != null) {
      final min = filter.marketCapMin != null
          ? '\$${(filter.marketCapMin! / 1e9).toStringAsFixed(0)}B'
          : '';
      final max = filter.marketCapMax != null
          ? '\$${(filter.marketCapMax! / 1e9).toStringAsFixed(0)}B'
          : '∞';
      chips.add('MktCap: $min–$max');
    }
    if (filter.peRatioMin != null || filter.peRatioMax != null) {
      chips.add('P/E: ${filter.peRatioMin ?? ''}–${filter.peRatioMax ?? '∞'}');
    }
    if (filter.priceMin != null || filter.priceMax != null) {
      chips.add('Price: \$${filter.priceMin ?? '0'}–\$${filter.priceMax ?? '∞'}');
    }
    if (filter.changePercentMin != null || filter.changePercentMax != null) {
      chips.add('Chg: ${filter.changePercentMin ?? ''}%–${filter.changePercentMax ?? ''}%');
    }
    if (filter.exchange != null && filter.exchange!.isNotEmpty) {
      chips.add('Exchange: ${filter.exchange}');
    }

    if (chips.isEmpty) {
      return Text(
        'No conditions set — tap "Add Filters" to narrow results',
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: chips
                .map(
                  (c) => Chip(
                    label: Text(c, style: const TextStyle(fontSize: 11)),
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        ),
        InkWell(
          onTap: onClear,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedStrategyItemTileV1 extends StatelessWidget {
  const _SavedStrategyItemTileV1({
    required this.strategy,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ScreenerStrategy strategy;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.auto_graph_rounded,
                  size: 20,
                  color: colorScheme.primary,
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
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      filterSummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                tooltip: 'Edit Strategy',
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: colorScheme.error.withValues(alpha: 0.85),
                ),
                tooltip: 'Delete Strategy',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
