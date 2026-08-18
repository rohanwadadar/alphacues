import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_routes.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/dashboard/presentation/dashboard_screen.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigating to /dashboard without session redirects to /login', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      session: null,
      enableScreener: false,
      initialLocation: AppRoutes.dashboard,
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });
}
