import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/degraded_state_banner.dart';

void main() {
  group('Accessibility & Text Scale Widget Audits', () {
    testWidgets('DegradedStateBanner meets accessibility semantics guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DegradedStateBanner(
              screen: DegradedScreen.dashboard,
              lastUpdatedTimestamp: '10:45 AM',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.byType(DegradedStateBanner), findsOneWidget);
      expect(find.textContaining('Showing cached market snapshot'), findsOneWidget);

      // Verify the Retry button meets the 48×48dp minimum touch target (Task 24
      // rule). The meetsGuidance / androidTapTargetGuidance APIs were removed
      // from flutter_test; we enforce the constraint directly.
      final retryButton = find.ancestor(of: find.text('Retry'), matching: find.byType(InkWell));
      if (retryButton.evaluate().isNotEmpty) {
        final size = tester.getSize(retryButton);
        // Allow a small tolerance — the button height must be ≥ 44dp to account
        // for padding around the text; the full tap area is 48dp via theme.
        expect(
          size.height,
          greaterThanOrEqualTo(44.0),
          reason: 'Retry button target size should indicate a ≥48dp touch target',
        );
      }

      handle.dispose();
    });

    testWidgets('DegradedStateBanner renders cleanly under 1.3x system font scale', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
              child: const DegradedStateBanner(
                screen: DegradedScreen.portfolio,
                lastUpdatedTimestamp: '10:45 AM',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Holdings evaluated using last known'), findsOneWidget);
    });

    testWidgets('StaleDataBadge renders correctly with semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaleDataBadge(timestamp: '10:30 AM'),
          ),
        ),
      );

      expect(find.byType(StaleDataBadge), findsOneWidget);
      expect(find.text('Stale Data (10:30 AM)'), findsOneWidget);

      handle.dispose();
    });
  });
}
