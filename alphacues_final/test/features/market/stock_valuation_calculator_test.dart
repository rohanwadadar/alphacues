import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/market/presentation/widgets/stock_valuation_calculator.dart';

void main() {
  testWidgets('does not invent a stock price when market data is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StockValuationCalculator(symbol: 'AAPL', currentPrice: 0),
        ),
      ),
    );

    expect(
      find.text('Valuation is unavailable until a market price is available.'),
      findsOneWidget,
    );
    expect(find.textContaining('\$150'), findsNothing);
  });
}