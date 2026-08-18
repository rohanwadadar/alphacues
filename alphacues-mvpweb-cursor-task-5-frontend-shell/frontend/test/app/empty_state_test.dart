import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/widgets/empty_state.dart';

void main() {
  testWidgets('displays heading, body, and CTA', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox_outlined,
            heading: 'No items',
            body: 'Add your first item to get started.',
            actionLabel: 'Add item',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No items'), findsOneWidget);
    expect(find.text('Add your first item to get started.'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);

    await tester.tap(find.text('Add item'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
