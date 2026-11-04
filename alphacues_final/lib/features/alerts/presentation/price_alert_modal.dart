import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/alerts_providers.dart';

class PriceAlertModal extends ConsumerStatefulWidget {
  const PriceAlertModal({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  final String symbol;
  final double currentPrice;

  static void show(BuildContext context, {required String symbol, required double currentPrice}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PriceAlertModal(symbol: symbol, currentPrice: currentPrice),
    );
  }

  @override
  ConsumerState<PriceAlertModal> createState() => _PriceAlertModalState();
}

class _PriceAlertModalState extends ConsumerState<PriceAlertModal> {
  late final TextEditingController _priceController;
  String _condition = 'ABOVE';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final targetDefault = widget.currentPrice > 0 ? widget.currentPrice * 1.05 : 100.0;
    _priceController = TextEditingController(text: targetDefault.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final purpleColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    final alertsAsync = ref.watch(alertsProvider);
    final alerts = alertsAsync.maybeWhen(
      data: (items) => items
          .where((a) => a.symbol.toUpperCase() == widget.symbol.toUpperCase())
          .toList(),
      orElse: () => const <AlertModel>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.notification_add_outlined, color: purpleColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Alert: ${widget.symbol}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.currentPrice > 0
                          ? 'Current Price: \$${widget.currentPrice.toStringAsFixed(2)}'
                          : 'Set your target trigger price',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.alerts);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('All Alerts', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Condition Selector
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'ABOVE',
                label: Text('Breaks Above'),
                icon: Icon(Icons.trending_up_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'BELOW',
                label: Text('Breaks Below'),
                icon: Icon(Icons.trending_down_rounded, size: 16),
              ),
            ],
            selected: {_condition},
            onSelectionChanged: (set) => setState(() => _condition = set.first),
          ),
          const SizedBox(height: AppSpacing.md),

          // Price Input
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Target Price (\$)',
              prefixText: '\$ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Submit Button
          FilledButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    final target = double.tryParse(_priceController.text.trim());
                    if (target == null || target <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid price greater than \$0.'),
                          backgroundColor: AppColors.negative,
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final router = GoRouter.of(context);
                    setState(() => _isSubmitting = true);
                    try {
                      await ref.read(alertsRepositoryProvider).createAlert(
                            symbol: widget.symbol.toUpperCase(),
                            condition: _condition,
                            target: target,
                            isActive: true,
                          );
                      ref.invalidate(alertsProvider);
                      ref.invalidate(alertHistoryProvider);
                      await ref.read(alertsProvider.notifier).refresh();
                      ref.read(alertHistoryProvider.notifier).refresh();

                      if (mounted) {
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Alert created: ${widget.symbol} $_condition \$${target.toStringAsFixed(2)}',
                            ),
                            backgroundColor: const Color(0xFF673AB7),
                            action: SnackBarAction(
                              label: 'View Alerts',
                              textColor: Colors.white,
                              onPressed: () => router.push(AppRoutes.alerts),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to save alert: $e'),
                            backgroundColor: AppColors.negative,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                      }
                    }
                  },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF673AB7),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Create Alert',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),

          // Active Alerts List for this Symbol
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Configured Alerts for ${widget.symbol}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${alerts.length} alert(s)',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...alerts.map(
              (alert) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: alert.triggered
                          ? AppColors.negative
                          : (alert.condition == 'ABOVE' ? AppColors.positive : AppColors.negative),
                      width: 1.5,
                    ),
                    color: (alert.condition == 'ABOVE'
                            ? AppColors.positive
                            : AppColors.negative)
                        .withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Icon(
                      alert.condition == 'ABOVE'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: alert.condition == 'ABOVE' ? AppColors.positive : AppColors.negative,
                      size: 16,
                    ),
                  ),
                ),
                title: Text(
                  '${alert.condition == 'ABOVE' ? 'Above' : 'Below'} \$${alert.target.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Text(
                  alert.triggered
                      ? 'Triggered'
                      : (alert.isActive ? 'Active' : 'Disabled'),
                  style: TextStyle(
                    fontSize: 11,
                    color: alert.triggered ? AppColors.negative : colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete alert',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref.read(alertsRepositoryProvider).deleteAlert(alert.alertId);
                      ref.invalidate(alertsProvider);
                      ref.invalidate(alertHistoryProvider);
                      await ref.read(alertsProvider.notifier).refresh();
                      ref.read(alertHistoryProvider.notifier).refresh();
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete: $e'),
                            backgroundColor: AppColors.negative,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
