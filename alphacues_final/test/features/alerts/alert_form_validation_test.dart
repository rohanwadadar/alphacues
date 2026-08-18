import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/alerts/data/alerts_providers.dart';
import 'package:frontend/features/alerts/data/alerts_repository.dart';
import 'package:frontend/features/alerts/presentation/alert_form_dialog.dart';

class _MockAlertsRepository extends AlertsRepository {
  _MockAlertsRepository({this.onCreate}) : super(Dio());

  Object? Function(Map<String, dynamic> body)? onCreate;

  @override
  Future<AlertModel> createAlert({
    required String symbol,
    required String condition,
    required double target,
    bool isActive = true,
    int cooldownSeconds = 0,
    List<String> notificationChannel = const ['IN_APP'],
  }) async {
    if (onCreate != null) {
      final result = onCreate!({
        'symbol': symbol,
        'condition': condition,
        'target': target,
        'isActive': isActive,
        'cooldownSeconds': cooldownSeconds,
        'notificationChannel': notificationChannel,
      });
      if (result is Exception) {
        throw result;
      }
      if (result is AlertModel) {
        return result;
      }
    }
    return AlertModel(
      alertId: '1',
      userId: '1',
      symbol: symbol,
      condition: condition,
      target: target,
      isActive: isActive,
      triggered: false,
      cooldownSeconds: cooldownSeconds,
      createdAt: '2026-05-13T14:30:02Z',
    );
  }

  @override
  Future<AlertModel> updateAlert(
    String alertId, {
    required String symbol,
    required String condition,
    required double target,
    bool isActive = true,
    int cooldownSeconds = 0,
    List<String> notificationChannel = const ['IN_APP'],
  }) async {
    return AlertModel(
      alertId: alertId,
      userId: '1',
      symbol: symbol,
      condition: condition,
      target: target,
      isActive: isActive,
      triggered: false,
      cooldownSeconds: cooldownSeconds,
      createdAt: '2026-05-13T14:30:02Z',
    );
  }
}

Future<void> _pumpAlertForm(
  WidgetTester tester, {
  AlertsRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          alertsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: AlertFormDialog())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty symbol field on submit shows required error', (
    tester,
  ) async {
    await _pumpAlertForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Symbol is required'), findsOneWidget);
  });

  testWidgets('invalid symbol shows ticker validation error', (tester) async {
    await _pumpAlertForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'aapl!');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid ticker (e.g. AAPL)'), findsOneWidget);
  });

  testWidgets('blank target shows positive price error', (tester) async {
    await _pumpAlertForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'AAPL');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a positive price target'), findsOneWidget);
  });

  testWidgets('valid inputs submit without inline errors', (tester) async {
    final repository = _MockAlertsRepository();
    await _pumpAlertForm(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField).first, 'AAPL');
    await tester.enterText(find.byType(TextFormField).at(1), '190');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(find.text('Symbol is required'), findsNothing);
    expect(find.text('Enter a valid ticker (e.g. AAPL)'), findsNothing);
    expect(find.text('Enter a positive price target'), findsNothing);
  });

  testWidgets('backend validation error details are displayed', (tester) async {
    final repository = _MockAlertsRepository(
      onCreate: (_) => const AlertValidationErrorException(
        'Validation failed',
        details: {'symbol': 'Symbol is not tradable'},
      ),
    );
    await _pumpAlertForm(tester, repository: repository);

    await tester.enterText(find.byType(TextFormField).first, 'AAPL');
    await tester.enterText(find.byType(TextFormField).at(1), '190');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Symbol is not tradable'), findsOneWidget);
  });
}
