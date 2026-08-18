import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/features/market/data/market_repository.dart';
import 'package:frontend/features/market/presentation/widgets/stock_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtureBars = [
    const Bar(
      timeStamp: '2026-05-13T14:30:00Z',
      openPrice: 188.12,
      highPrice: 189.02,
      lowPrice: 187.98,
      closePrice: 188.90,
      volume: 1823400,
    ),
    const Bar(
      timeStamp: '2026-05-13T15:00:00Z',
      openPrice: 188.90,
      highPrice: 190.10,
      lowPrice: 188.50,
      closePrice: 189.75,
      volume: 1450000,
    ),
  ];

  Future<void> pumpChart(
    WidgetTester tester, {
    required List<Bar> bars,
    bool isStale = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: StockChart(
            bars: bars,
            selectedRange: '1D',
            isStale: isStale,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders StockChart with fixture bars without error', (
    tester,
  ) async {
    await pumpChart(tester, bars: fixtureBars);

    expect(find.byType(StockChart), findsOneWidget);
    expect(find.text('No chart data available'), findsNothing);
  });

  testWidgets('shows zero-data state when bars is empty', (tester) async {
    await pumpChart(tester, bars: const []);

    expect(find.text('No chart data available'), findsOneWidget);
  });
}
