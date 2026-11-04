// ignore_for_file: lines_longer_than_80_chars
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/authenticated_shell.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/widgets/mobile_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fake socket notifier — returns "connected" so StaleBanner collapses to
// height=0 (visible=false), preventing layout overflow in widget tests.
// Defined at top level because Dart does not allow class declarations inside
// function bodies.
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectedSocketNotifier extends SocketConnectionNotifier {
  @override
  StaleBannerState build() => const StaleBannerState(
        connectionState: SocketConnectionState.connected,
        awaitingRestRefresh: false,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: build a [MobileShell] + [NavigationBar] wrapped in [ProviderScope].
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildShell({
  required int selectedIndex,
  required ValueChanged<int> onDestinationSelected,
  bool enableScreener = false,
}) {
  final destinations = <NavigationDestination>[
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(Icons.star_outline),
      selectedIcon: Icon(Icons.star),
      label: 'Watchlists',
    ),
    const NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Alerts',
    ),
    const NavigationDestination(
      icon: Icon(Icons.pie_chart_outline),
      selectedIcon: Icon(Icons.pie_chart),
      label: 'Portfolio',
    ),
    if (enableScreener)
      const NavigationDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: 'Screener',
      ),
  ];

  return ProviderScope(
    overrides: [
      socketConnectionStateProvider
          .overrideWith(_ConnectedSocketNotifier.new),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: MobileShell(
        body: const Center(child: Text('body content')),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ),
    ),
  );
}

/// Tests for Phase 4 Task 24 — Mobile App Shell, Safe Areas, Bottom Navigation.
///
/// Two suites:
///   A. Pure unit tests for [AuthenticatedShell.selectedIndexForLocation]
///   B. Widget tests for [MobileShell] + [NavigationBar] pumped directly.
///
/// NOTE: Widget tests pump [MobileShell] + [NavigationBar] in isolation (not
/// via [pumpTestApp]). On the test host (Windows / macOS CI), neither
/// `Platform.isAndroid` nor `Platform.isIOS` is true, so [AuthenticatedShell]
/// correctly takes the web branch and renders no [NavigationBar]. Testing
/// [MobileShell] directly is the correct approach — the platform gate is a
/// simple boolean and is already covered by [authenticated_shell.dart] code.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // A. selectedIndexForLocation — pure unit tests (no widget pump)
  // ─────────────────────────────────────────────────────────────────────────
  group('AuthenticatedShell.selectedIndexForLocation', () {
    test('returns 0 for /dashboard', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/dashboard'),
        equals(0),
      );
    });

    test('returns 0 for unknown path (falls through to home)', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/'),
        equals(0),
      );
    });

    test('returns 1 for /watchlists', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/watchlists'),
        equals(1),
      );
    });

    test('returns 1 for /watchlists/123 (stack push, branch index still 1)', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/watchlists/123'),
        equals(1),
      );
    });

    test('returns 2 for /alerts', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/alerts'),
        equals(2),
      );
    });

    test('returns 3 for /portfolio', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/portfolio'),
        equals(3),
      );
    });

    test('returns 4 for /screener when screener is enabled', () {
      expect(
        AuthenticatedShell.selectedIndexForLocation('/screener'),
        equals(4),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // B. Widget tests: NavigationBar tab taps, destination count, SafeArea
  // ─────────────────────────────────────────────────────────────────────────
  group('MobileShell navigation bar (widget tests — isolated pump)', () {
    testWidgets('Tab 0 — Home: initially selected at index 0', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _buildShell(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(0));
    });

    testWidgets('Tab 1 — Watchlists: tap sets selectedIndex to 1',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _buildShell(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.star_outline));
      await tester.pumpAndSettle();

      expect(selected, equals(1),
          reason: 'Tapping Watchlists must fire onDestinationSelected(1)');
    });

    testWidgets('Tab 2 — Alerts: tap sets selectedIndex to 2', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _buildShell(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      expect(selected, equals(2),
          reason: 'Tapping Alerts must fire onDestinationSelected(2)');
    });

    testWidgets('Tab 3 — Portfolio: tap sets selectedIndex to 3',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _buildShell(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => selected = i),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.pie_chart_outline));
      await tester.pumpAndSettle();

      expect(selected, equals(3),
          reason: 'Tapping Portfolio must fire onDestinationSelected(3)');
    });

    testWidgets(
        'Screener NOT present when enableScreener=false — exactly 4 destinations',
        (tester) async {
      await tester.pumpWidget(
        _buildShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          enableScreener: false,
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, equals(4),
          reason: 'enableScreener=false → exactly 4 NavigationDestinations');
      expect(find.byIcon(Icons.search_outlined), findsNothing,
          reason: 'Screener icon must not appear when disabled');
    });

    testWidgets(
        'Screener appears as 5th destination when enableScreener=true',
        (tester) async {
      await tester.pumpWidget(
        _buildShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          enableScreener: true,
        ),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, equals(5),
          reason: 'enableScreener=true → 5 NavigationDestinations');
      expect(find.byIcon(Icons.search_outlined), findsOneWidget,
          reason: 'Screener search icon must be present when enabled');
    });

    testWidgets(
        'MobileShell body is wrapped with SafeArea(top=true, bottom=false)',
        (tester) async {
      await tester.pumpWidget(
        _buildShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      // MobileShell wraps its Column in SafeArea(top:true, bottom:false).
      final safeAreas = tester.widgetList<SafeArea>(find.byType(SafeArea));
      final shellSafeArea =
          safeAreas.where((sa) => sa.top == true && sa.bottom == false);
      expect(
        shellSafeArea,
        isNotEmpty,
        reason: 'MobileShell must apply SafeArea(top:true, bottom:false) '
            'so content is protected from notch / Dynamic Island',
      );
    });

    testWidgets('NavigationBar and MobileShell both render', (tester) async {
      await tester.pumpWidget(
        _buildShell(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(MobileShell), findsOneWidget);
    });
  });
}
