import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../data/alerts_provider.dart';

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
  AlertCondition _condition = AlertCondition.above;

  @override
  void initState() {
    super.initState();
    final targetDefault = widget.currentPrice * 1.05;
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
    final alerts = ref.watch(priceAlertsProvider).where((a) => a.symbol == widget.symbol).toList();

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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_alert_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Alert for ${widget.symbol}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current Price: \$${widget.currentPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Condition Selector
          SegmentedButton<AlertCondition>(
            segments: const [
              ButtonSegment(
                value: AlertCondition.above,
                label: Text('Breaks Above'),
                icon: Icon(Icons.trending_up_rounded, size: 16),
              ),
              ButtonSegment(
                value: AlertCondition.below,
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
            onPressed: () {
              final target = double.tryParse(_priceController.text);
              if (target != null && target > 0) {
                ref.read(priceAlertsProvider.notifier).addAlert(
                      symbol: widget.symbol,
                      targetPrice: target,
                      condition: _condition,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alert set for ${widget.symbol} at \$${target.toStringAsFixed(2)}'),
                    backgroundColor: AppColors.positive,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Create Alert', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Active Alerts List for this Symbol
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Active Alerts for ${widget.symbol}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...alerts.map(
              (alert) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  alert.condition == AlertCondition.above
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: alert.condition == AlertCondition.above ? AppColors.positive : AppColors.negative,
                  size: 20,
                ),
                title: Text(
                  '${alert.condition == AlertCondition.above ? 'Above' : 'Below'} \$${alert.targetPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(alert.isTriggered ? 'Triggered!' : 'Active'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => ref.read(priceAlertsProvider.notifier).removeAlert(alert.id),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
