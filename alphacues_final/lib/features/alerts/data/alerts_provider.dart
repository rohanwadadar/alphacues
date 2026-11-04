import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AlertCondition { above, below, percentChange }

class PriceAlert {
  const PriceAlert({
    required this.id,
    required this.symbol,
    required this.targetPrice,
    required this.condition,
    required this.createdAt,
    this.isTriggered = false,
  });

  final String id;
  final String symbol;
  final double targetPrice;
  final AlertCondition condition;
  final DateTime createdAt;
  final bool isTriggered;

  PriceAlert copyWith({
    String? id,
    String? symbol,
    double? targetPrice,
    AlertCondition? condition,
    DateTime? createdAt,
    bool? isTriggered,
  }) {
    return PriceAlert(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      targetPrice: targetPrice ?? this.targetPrice,
      condition: condition ?? this.condition,
      createdAt: createdAt ?? this.createdAt,
      isTriggered: isTriggered ?? this.isTriggered,
    );
  }
}

class PriceAlertsNotifier extends StateNotifier<List<PriceAlert>> {
  PriceAlertsNotifier() : super(const []);

  void addAlert({
    required String symbol,
    required double targetPrice,
    required AlertCondition condition,
  }) {
    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: symbol.toUpperCase(),
      targetPrice: targetPrice,
      condition: condition,
      createdAt: DateTime.now(),
    );
    state = [alert, ...state];
  }

  void removeAlert(String id) {
    state = state.where((a) => a.id != id).toList();
  }

  void checkTriggers(String symbol, double currentPrice) {
    bool updated = false;
    final nextState = state.map((alert) {
      if (alert.symbol == symbol && !alert.isTriggered) {
        if ((alert.condition == AlertCondition.above && currentPrice >= alert.targetPrice) ||
            (alert.condition == AlertCondition.below && currentPrice <= alert.targetPrice)) {
          updated = true;
          return alert.copyWith(isTriggered: true);
        }
      }
      return alert;
    }).toList();

    if (updated) {
      state = nextState;
    }
  }
}

final priceAlertsProvider =
    StateNotifierProvider<PriceAlertsNotifier, List<PriceAlert>>((ref) {
  return PriceAlertsNotifier();
});
