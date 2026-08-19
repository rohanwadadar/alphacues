import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/widgets/safe_screen.dart';
import '../data/screener_providers.dart';
import 'screener_filter_dialog.dart';
import 'widgets/saved_strategies_bar.dart';
import 'widgets/screener_loading_skeleton.dart';
import 'widgets/screener_result_card.dart';

/// Screener screen — route: /screener (private, gated by enable_screener).
///
/// Five states per the plan's loading/empty/error/degraded table:
///   Loading   → filter placeholder + table skeleton
///   Empty     → "No matches" after a completed run with zero results
///   Error     → error message + Retry; filters are NOT cleared
///   Degraded  → last saved preset shown, fresh scan disabled
///   Disabled  → enable_screener=false; shows unavailable state
class ScreenerScreen extends ConsumerWidget {
  const ScreenerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(screenerNotifierProvider);
    final notifier = ref.read(screenerNotifierProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const AlphaCuesFullLogo(),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Filter button — badge dot when filters are active
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.filter_list),
                if (!state.filters.isEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filter',
            onPressed: (state.isFeatureDisabled || state.isOffline)
                ? null
                : () async {
                    final newFilter = await ScreenerFilterDialog.show(
                      context,
                      state.filters,
                    );
                    if (newFilter != null) {
                      notifier.setFilters(newFilter);
                    }
                  },
          ),
          // Save strategy button
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save Strategy',
            onPressed: (state.isFeatureDisabled || state.isOffline)
                ? null
                : () => _showSaveStrategyDialog(context, ref, state),
          ),
        ],
      ),
      body: SafeScreen(
        child: Column(
          children: [
            // Saved strategy chips (hidden in disabled state)
            if (!state.isFeatureDisabled) const SavedStrategiesBar(),

            // Sort header (hidden in loading / disabled / offline without result)
            if (!state.isLoading &&
                !state.isFeatureDisabled &&
                state.result != null)
              _SortHeader(state: state, notifier: notifier),

            if (!state.isLoading &&
                !state.isFeatureDisabled &&
                state.result != null)
              const Divider(height: 1),

            // Main body
            Expanded(
              child: _buildBody(context, ref, state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ScreenerState state,
    ScreenerNotifier notifier,
  ) {
    // ── Loading state ────────────────────────────────────────────────────────
    if (state.isLoading) {
      return const ScreenerLoadingSkeleton();
    }

    // ── Feature-disabled state ───────────────────────────────────────────────
    if (state.isFeatureDisabled) {
      return const _FeatureDisabledBody();
    }

    // ── Offline / degraded state ─────────────────────────────────────────────
    if (state.isOffline) {
      return _DegradedBody(
        lastPreset: state.lastSavedPreset,
        onRetry: notifier.runScan,
      );
    }

    // ── Error state — filters preserved ─────────────────────────────────────
    if (state.error != null) {
      return _ErrorBody(
        message: state.error!,
        onRetry: notifier.runScan,
      );
    }

    // ── Empty state — zero results after a completed run ────────────────────
    final items = state.result?.items ?? [];
    if (items.isEmpty && state.result != null) {
      return _EmptyResultsBody(onReset: notifier.resetFilters);
    }

    // ── Initial state (no scan yet) ──────────────────────────────────────────
    if (state.result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Run the screener to find matching stocks.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Screener'),
              onPressed: notifier.runScan,
            ),
          ],
        ),
      );
    }

    // ── Data state — results list ────────────────────────────────────────────
    return RefreshIndicator(
      onRefresh: notifier.runScan,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ScreenerResultCard(
            item: item,
            onTap: () => context.push('/symbols/${item.symbol}'),
          );
        },
      ),
    );
  }

  void _showSaveStrategyDialog(
    BuildContext context,
    WidgetRef ref,
    ScreenerState state,
  ) {
    final nameController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save Screener Strategy'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Strategy Name',
            hintText: 'e.g. Value Tech Stocks',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogContext).pop();
              final ok = await ref
                  .read(savedStrategiesProvider.notifier)
                  .saveStrategy(
                    name: name,
                    filters: state.filters,
                    sortBy: state.sortBy,
                    sortOrder: state.sortOrder,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok ? 'Strategy saved!' : 'Failed to save strategy.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort header bar
// ─────────────────────────────────────────────────────────────────────────────
class _SortHeader extends StatelessWidget {
  const _SortHeader({required this.state, required this.notifier});

  final ScreenerState state;
  final ScreenerNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${state.result?.total ?? 0} Results',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Text('Sort: ', style: TextStyle(fontSize: 12)),
          DropdownButton<String>(
            value: state.sortBy,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 'marketCap', child: Text('Market Cap')),
              DropdownMenuItem(value: 'peRatio', child: Text('P/E Ratio')),
              DropdownMenuItem(value: 'price', child: Text('Price')),
              DropdownMenuItem(
                value: 'changePercent',
                child: Text('Day Change %'),
              ),
              DropdownMenuItem(value: 'symbol', child: Text('Symbol')),
            ],
            onChanged: (val) {
              if (val != null) notifier.setSorting(val, state.sortOrder);
            },
          ),
          IconButton(
            icon: Icon(
              state.sortOrder == 'desc'
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              size: 18,
            ),
            tooltip: state.sortOrder == 'desc' ? 'Descending' : 'Ascending',
            onPressed: () {
              final newOrder = state.sortOrder == 'desc' ? 'asc' : 'desc';
              notifier.setSorting(state.sortBy, newOrder);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — "No matches" after a completed run with zero results
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyResultsBody extends StatelessWidget {
  const _EmptyResultsBody({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No matches',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No stocks match your current filter criteria.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state — message + Retry action; filters are preserved (plan rule)
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Degraded / offline state — show last saved preset, disable fresh scans
// ─────────────────────────────────────────────────────────────────────────────
class _DegradedBody extends StatelessWidget {
  const _DegradedBody({this.lastPreset, required this.onRetry});

  final ScreenerStrategy? lastPreset;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'You appear to be offline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fresh scans are disabled. Connect to the internet to run a new screen.',
              textAlign: TextAlign.center,
            ),
            if (lastPreset != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Last preset: ${lastPreset!.name}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature-disabled state — enable_screener=false hit directly via URL
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureDisabledBody extends StatelessWidget {
  const _FeatureDisabledBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Screener Unavailable',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The stock screener is not available on your plan.\n'
              'Contact your administrator if you believe this is an error.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
