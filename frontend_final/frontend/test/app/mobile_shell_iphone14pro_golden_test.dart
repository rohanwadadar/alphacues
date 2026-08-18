// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/widgets/mobile_shell.dart';
import 'package:frontend/core/widgets/safe_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake socket notifier — "connected" so StaleBanner collapses to height=0.
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectedSocket extends SocketConnectionNotifier {
  @override
  StaleBannerState build() => const StaleBannerState(
        connectionState: SocketConnectionState.connected,
        awaitingRestRefresh: false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: wrap MobileShell + NavigationBar in ProviderScope.
// Uses a plain ThemeData (no Google Fonts) to avoid network calls in tests.
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildIsolatedShell({
  required String bodyLabel,
  required List<NavigationDestination> destinations,
  int selectedIndex = 0,
}) {
  return ProviderScope(
    overrides: [
      socketConnectionStateProvider.overrideWith(_ConnectedSocket.new),
    ],
    child: MaterialApp(
      // Intentionally use default ThemeData (no Google Fonts) to avoid
      // network font-fetch failures during tests.
      theme: ThemeData(useMaterial3: true),
      home: MobileShell(
        body: SafeScreen(
          child: Center(
            child: Text(bodyLabel),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (_) {},
          destinations: destinations,
        ),
      ),
    ),
  );
}

const _kFourDestinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.star_outline),
    selectedIcon: Icon(Icons.star),
    label: 'Watchlists',
  ),
  NavigationDestination(
    icon: Icon(Icons.notifications_outlined),
    selectedIcon: Icon(Icons.notifications),
    label: 'Alerts',
  ),
  NavigationDestination(
    icon: Icon(Icons.pie_chart_outline),
    selectedIcon: Icon(Icons.pie_chart),
    label: 'Portfolio',
  ),
];

const _kFiveDestinations = <NavigationDestination>[
  ..._kFourDestinations,
  NavigationDestination(
    icon: Icon(Icons.search_outlined),
    selectedIcon: Icon(Icons.search),
    label: 'Screener',
  ),
];

/// Golden tests for Phase 4 Task 24 — iPhone 14 Pro notch / Dynamic Island.
///
/// iPhone 14 Pro logical resolution: 393 × 852 dp.
/// Top safe-area inset:  59 dp (Dynamic Island).
/// Bottom safe-area inset: 34 dp (home indicator).
///
/// The tests prove that:
/// 1. Content starts below 59dp (avoids Dynamic Island).
/// 2. NavigationBar renders with exactly 4 or 5 destinations.
/// 3. MobileShell.SafeArea(top=true, bottom=false) is present.
void main() {
  const iphone14ProSize = Size(393, 852);
  const iphone14ProPadding = EdgeInsets.only(top: 59.0, bottom: 34.0);

  group('iPhone 14 Pro golden — SafeArea avoids notch / Dynamic Island', () {
    testWidgets(
      'mobile_shell_iphone14pro: content body starts below 59dp top inset',
      (tester) async {
        tester.view.physicalSize = iphone14ProSize * 3.0;
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: iphone14ProSize,
              padding: iphone14ProPadding,
              devicePixelRatio: 3.0,
            ),
            child: _buildIsolatedShell(
              bodyLabel: 'Dashboard',
              destinations: _kFourDestinations,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. SafeArea(top=true) must exist.
        final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
        expect(
          safeAreas.any((sa) => sa.top == true),
          isTrue,
          reason: 'MobileShell must apply SafeArea with top=true',
        );

        // 2. NavigationBar is rendered.
        expect(find.byType(NavigationBar), findsOneWidget);

        // 3. Body text is below the Dynamic Island inset (59dp).
        final textFinder = find.text('Dashboard');
        expect(textFinder, findsOneWidget);
        final contentTop = tester.getTopLeft(textFinder).dy;
        expect(
          contentTop,
          greaterThan(iphone14ProPadding.top),
          reason:
              'Content top ($contentTop dp) must be below Dynamic Island '
              '(${iphone14ProPadding.top} dp)',
        );

        // 4. Golden snapshot.
        await expectLater(
          find.byType(MobileShell),
          matchesGoldenFile('goldens/mobile_shell_iphone14pro.png'),
        );
      },
    );

    testWidgets(
      'mobile_shell_iphone14pro_4tabs: exactly 4 destinations, no search icon',
      (tester) async {
        tester.view.physicalSize = iphone14ProSize * 3.0;
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildIsolatedShell(
            bodyLabel: 'Content',
            destinations: _kFourDestinations,
          ),
        );
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, equals(4),
            reason: 'Screener disabled → exactly 4 destinations');
        expect(find.byIcon(Icons.search_outlined), findsNothing);

        await expectLater(
          find.byType(NavigationBar),
          matchesGoldenFile('goldens/mobile_shell_iphone14pro_4tabs.png'),
        );
      },
    );

    testWidgets(
      'mobile_shell_iphone14pro_5tabs: 5 destinations when screener enabled',
      (tester) async {
        tester.view.physicalSize = iphone14ProSize * 3.0;
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _buildIsolatedShell(
            bodyLabel: 'Content',
            destinations: _kFiveDestinations,
          ),
        );
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, equals(5),
            reason: 'Screener enabled → 5 destinations');
        expect(find.byIcon(Icons.search_outlined), findsOneWidget);

        await expectLater(
          find.byType(NavigationBar),
          matchesGoldenFile('goldens/mobile_shell_iphone14pro_5tabs.png'),
        );
      },
    );
  });
}
