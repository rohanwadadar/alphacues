import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/mobile_shell.dart';
import '../../features/notifications/data/notifications_notifier.dart';
import 'app_routes.dart';

/// Authenticated bottom navigation shell.
///
/// 4-tab layout:
///   0 → Home (Dashboard + Portfolio)
///   1 → Watchlist
///   2 → Strategy Builder
///   3 → Profile (Settings)
class AuthenticatedShell extends ConsumerWidget {
  const AuthenticatedShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static int selectedIndexForLocation(String location) {
    if (location.startsWith(AppRoutes.watchlists)) return 1;
    if (location.startsWith(AppRoutes.settings)) return 2;
    return 0; // dashboard / home
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsProvider);
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = selectedIndexForLocation(location);

    const navItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.home_filled, size: 24),
        label: AppLabels.dashboard,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_rounded, size: 24),
        label: AppLabels.strategy,
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_rounded, size: 24),
        label: AppLabels.settings,
      ),
    ];

    return MobileShell(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.3),
                blurRadius: 12.0,
                spreadRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withValues(alpha: 0.6),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              currentIndex: selectedIndex.clamp(0, navItems.length - 1),
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == selectedIndex,
                );
              },
              items: navItems,
            ),
          ),
        ),
      ),
    );
  }
}
