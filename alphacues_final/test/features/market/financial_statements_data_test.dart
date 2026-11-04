import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/market/data/market_repository.dart';
import 'package:frontend/features/market/presentation/widgets/financial_statements_widget.dart';

void main() {
  testWidgets('missing fundamentals render unavailable states, not sample charts', (
    tester,
  ) async {
    const fundamentals = MarketFundamentals(symbol: 'XYZ', fields: {});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              RobinhoodFinancialsSection(
                symbol: 'XYZ',
                fundamentals: fundamentals,
                currentPrice: 0,
              ),
              RobinhoodEarningsSection(
                symbol: 'XYZ',
                fundamentals: fundamentals,
                currentPrice: 0,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('data is currently unavailable'), findsNWidgets(2));
    expect(find.textContaining('FY 2025'), findsNothing);
    expect(find.textContaining('Q3 FY26'), findsNothing);
  });
}
