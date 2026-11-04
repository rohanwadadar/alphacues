import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/screener_providers.dart';

/// Horizontal scrollable chip list for saved strategies.
/// Tap to apply strategy filters + re-run scan.
/// Long-press to delete with confirmation dialog.
class SavedStrategiesBar extends ConsumerWidget {
  const SavedStrategiesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategiesAsync = ref.watch(savedStrategiesProvider);

    return strategiesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (strategies) {
        if (strategies.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: strategies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final strategy = strategies[index];
              return GestureDetector(
                onLongPress: () => _confirmDelete(context, ref, strategy),
                child: ActionChip(
                  avatar: const Icon(Icons.flash_on, size: 16),
                  label: Text(strategy.name),
                  tooltip: 'Tap to apply • Long-press to delete',
                  onPressed: () {
                    ref
                        .read(screenerNotifierProvider.notifier)
                        .applySavedStrategy(strategy);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ScreenerStrategy strategy,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete strategy?'),
        content: Text('Remove "${strategy.name}" from saved strategies?'),
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
    if ((confirmed ?? false) && context.mounted) {
      final ok = await ref
          .read(savedStrategiesProvider.notifier)
          .deleteStrategy(strategy.strategyId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF673AB7),
            content: Text(
              ok
                  ? '"${strategy.name}" deleted.'
                  : 'Failed to delete strategy.',
            ),
          ),
        );
      }
    }
  }
}
