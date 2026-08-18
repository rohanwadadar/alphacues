import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_routes.dart';
import 'package:frontend/app/router/route_guards.dart';
import 'package:frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:frontend/features/screener/presentation/screener_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeRouteRedirect sends /screener to /dashboard when disabled', () {
    expect(
      computeRouteRedirect(
        matchedPath: AppRoutes.screener,
        fullPath: AppRoutes.screener,
        isAuthenticated: true,
        enableScreener: false,
      ),
      AppRoutes.dashboard,
    );
  });

  testWidgets(
    'navigating to /screener redirects when enable_screener is false',
    (tester) async {
      await pumpTestApp(
        tester,
        session: testAuthSession(),
        enableScreener: false,
        initialLocation: AppRoutes.screener,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(ScreenerScreen), findsNothing);
    },
  );

  testWidgets('screener tab absent from NavigationBar when disabled', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      session: testAuthSession(),
      enableScreener: false,
      initialLocation: AppRoutes.dashboard,
    );
    await tester.pumpAndSettle();

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.items.length, 4);
    expect(find.text(AppLabels.screener), findsNothing);
  });

  testWidgets('screener tab present when enable_screener is true', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      session: testAuthSession(),
      enableScreener: true,
      initialLocation: AppRoutes.dashboard,
    );
    await tester.pumpAndSettle();

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.items.length, 5);
    expect(find.text(AppLabels.screener), findsOneWidget);
  });
}
