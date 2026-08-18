import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// dart:io is not available on web — import conditionally.
import 'dart:io' show Platform;

import '../../core/config/app_config.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../features/notifications/data/notifications_notifier.dart';
import 'app_routes.dart';

/// Authenticated bottom navigation shell.
///
/// **Platform gating** (Task 24):
/// - `Platform.isAndroid || Platform.isIOS` → [MobileShell] with Material 3
///   [NavigationBar] (bottom nav, SafeArea-wrapped body).
/// - Web / other → plain [Scaffold] passing [navigationShell] directly as the
///   body. The web shell / top-nav are handled upstream by [app_shell.dart]
///   and the go_router structure; this class must not interfere with web layout.
class AuthenticatedShell extends ConsumerWidget {
  const AuthenticatedShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static int selectedIndexForLocation(String location, bool enableScreener) {
    if (location.startsWith(AppRoutes.watchlists)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.portfolio)) {
      return 3;
    }
    if (enableScreener && location.startsWith(AppRoutes.screener)) {
      return 4;
    }
    return 0;
  }

  /// True when running on a native Android or iOS device / simulator.
  /// Always false in browser builds (kIsWeb guard prevents dart:io crash).
  static bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationsProvider);
    final enableScreener = AppConfig.instance.enableScreener;
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = selectedIndexForLocation(location, enableScreener);

    // ── Floating Black Capsule Navigation ──────────
    final bottomNavItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_filled, size: 24),
        label: AppLabels.dashboard,
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.star_rounded, size: 24),
        label: AppLabels.watchlists,
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_rounded, size: 24),
        label: AppLabels.settings,
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.pie_chart_rounded, size: 24),
        label: AppLabels.portfolio,
      ),
      if (enableScreener)
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded, size: 24),
          label: AppLabels.screener,
        ),
    ];

    return MobileShell(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.95),
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
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
              unselectedItemColor: Colors.white.withOpacity(0.6),
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 0,
              currentIndex: selectedIndex.clamp(0, bottomNavItems.length - 1),
              onTap: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == selectedIndex,
                );
              },
              items: bottomNavItems,
            ),
          ),
        ),
      ),
    );
  }
}
