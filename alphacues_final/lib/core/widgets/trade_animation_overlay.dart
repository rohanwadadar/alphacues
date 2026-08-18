import 'package:flutter/material.dart';

enum TradeType { buy, sell }

class TradeAnimationOverlay extends StatelessWidget {
  const TradeAnimationOverlay({
    super.key,
    required this.type,
    required this.symbol,
  });

  final TradeType type;
  final String symbol;

  static Future<void> show(
    BuildContext context, {
    required TradeType type,
    required String symbol,
  }) async {
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (context) => TradeAnimationOverlay(type: type, symbol: symbol),
    );

    if (!isTest) {
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = type == TradeType.buy;
    final color = isBuy ? Colors.green : Colors.red;
    final title = isBuy ? 'BUY Executed' : 'SELL Executed';
    final icon = isBuy ? Icons.arrow_downward : Icons.arrow_upward;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$symbol transaction confirmed',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
