import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_routes.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/dashboard/presentation/dashboard_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'navigating to /login with active session redirects to /dashboard',
    (tester) async {
      await pumpTestApp(
        tester,
        session: testAuthSession(),
        enableScreener: false,
        initialLocation: AppRoutes.login,
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    },
  );
}
