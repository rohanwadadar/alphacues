import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_routes.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/widgets/error_state.dart';

void main() {
  testWidgets('displays message and fires onRetry on tap', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ErrorState(
            message: 'Something went wrong',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text(AppLabels.retry), findsOneWidget);

    await tester.tap(find.text(AppLabels.retry));
    await tester.pump();

    expect(retried, isTrue);
  });
}
