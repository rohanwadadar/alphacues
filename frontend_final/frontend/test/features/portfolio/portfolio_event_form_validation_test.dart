import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/portfolio/data/portfolio_providers.dart';

///import 'package:frontend/features/portfolio/data/portfolio_repository.dart';
import 'package:frontend/features/portfolio/presentation/portfolio_event_form_dialog.dart';

class _RecordingPortfolioRepository extends PortfolioRepository {
  _RecordingPortfolioRepository({this.onCreate}) : super(Dio());

  Object? Function({
    required Map<String, dynamic> body,
    required Map<String, dynamic> headers,
  })?
  onCreate;

  var createCalls = 0;

  @override
  Future<String> createEvent({
    required String symbol,
    required String action,
    required int volume,
    required double price,
    required String timeStamp,
    required String idempotencyKey,
  }) async {
    createCalls++;
    final body = {
      'symbol': symbol,
      'action': action,
      'volume': volume,
      'price': price,
      'time_stamp': timeStamp,
    };
    final headers = {'Idempotency-Key': idempotencyKey};
    if (onCreate != null) {
      final result = onCreate!(body: body, headers: headers);
      if (result is Exception) {
        throw result;
      }
      if (result is String) {
        return result;
      }
    }
    return 'evt-1';
  }
}

Future<void> _pumpPortfolioForm(
  WidgetTester tester, {
  PortfolioRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          portfolioRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: PortfolioEventFormDialog()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _symbolField => find.byType(TextFormField).at(0);
Finder get _quantityField => find.byType(TextFormField).at(1);
Finder get _priceField => find.byType(TextFormField).at(2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('blank symbol shows inline error without HTTP call', (
    tester,
  ) async {
    final repository = _RecordingPortfolioRepository();
    await _pumpPortfolioForm(tester, repository: repository);

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Symbol is required'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('volume zero shows inline error without HTTP call', (
    tester,
  ) async {
    final repository = _RecordingPortfolioRepository();
    await _pumpPortfolioForm(tester, repository: repository);

    await tester.enterText(_symbolField, 'AAPL');
    await tester.enterText(_quantityField, '0');
    await tester.enterText(_priceField, '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Quantity must be a positive integer'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('price zero shows inline error without HTTP call', (
    tester,
  ) async {
    final repository = _RecordingPortfolioRepository();
    await _pumpPortfolioForm(tester, repository: repository);

    await tester.enterText(_symbolField, 'AAPL');
    await tester.enterText(_quantityField, '5');
    await tester.enterText(_priceField, '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Price must be greater than zero'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  test('non-today date shows inline error without HTTP call', () {
    final repository = _RecordingPortfolioRepository();
    final container = ProviderContainer(
      overrides: [portfolioRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(portfolioEventFormProvider.notifier);
    final invalidDates = [
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 1)),
    ];

    for (final invalidDate in invalidDates) {
      expect(
        notifier.validate(
          symbol: 'AAPL',
          action: 'BUY',
          volumeText: '5',
          priceText: '10',
          date: invalidDate,
        ),
        isFalse,
      );

      expect(
        container.read(portfolioEventFormProvider).dateError,
        'Date must be today.',
      );
    }

    expect(repository.createCalls, 0);
  });

  testWidgets('valid BUY form posts once with body and idempotency header', (
    tester,
  ) async {
    Map<String, dynamic>? capturedBody;
    Map<String, dynamic>? capturedHeaders;

    final repository = _RecordingPortfolioRepository(
      onCreate: ({required body, required headers}) {
        capturedBody = body;
        capturedHeaders = headers;
        return 'evt-create-1';
      },
    );
    await _pumpPortfolioForm(tester, repository: repository);

    await tester.enterText(_symbolField, 'AAPL');
    await tester.enterText(_quantityField, '10');
    await tester.enterText(_priceField, '188.9');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(capturedBody?['symbol'], 'AAPL');
    expect(capturedBody?['action'], 'BUY');
    expect(capturedBody?['volume'], 10);
    expect(capturedBody?['price'], 188.9);
    expect(capturedBody?['time_stamp'], isA<String>());

    final parsed = DateTime.parse(
      capturedBody!['time_stamp'] as String,
    ).toLocal();
    final today = DateTime.now();
    expect(parsed.year, today.year);
    expect(parsed.month, today.month);
    expect(parsed.day, today.day);

    expect(capturedHeaders?['Idempotency-Key'], isNotEmpty);
  });

  testWidgets('server validation message is shown in snackbar', (tester) async {
    final repository = _RecordingPortfolioRepository(
      onCreate: ({required body, required headers}) {
        return const PortfolioValidationErrorException(
          'Event is outside the editable window.',
        );
      },
    );
    await _pumpPortfolioForm(tester, repository: repository);

    await tester.enterText(_symbolField, 'AAPL');
    await tester.enterText(_quantityField, '10');
    await tester.enterText(_priceField, '188.9');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    expect(find.text('Event is outside the editable window.'), findsOneWidget);
    expect(find.byType(PortfolioEventFormDialog), findsOneWidget);
  });
}
