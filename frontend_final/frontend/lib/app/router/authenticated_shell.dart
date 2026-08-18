import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// dart:io is not available on web — import conditionally.
import 'dart:io' show Platform;

import '../../app/theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../core/widgets/mobile_shell.dart';
import '../../features/market/presentation/stock_search_delegate.dart';
import '../../features/market/presentation/symbol_detail_screen.dart';
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
    if (location.startsWith(AppRoutes.alerts)) {
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
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    // ── Material 3 NavigationBar bottom nav for all platforms ─────────────────

    // ── Mobile path: Material 3 NavigationBar bottom nav ─────────────────────
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: AppLabels.dashboard,
      ),
      const NavigationDestination(
        icon: Icon(Icons.star_outline),
        selectedIcon: Icon(Icons.star),
        label: AppLabels.watchlists,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.notifications_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: const Icon(Icons.notifications),
        ),
        label: AppLabels.alerts,
      ),
      const NavigationDestination(
        icon: Icon(Icons.pie_chart_outline),
        selectedIcon: Icon(Icons.pie_chart),
        label: AppLabels.portfolio,
      ),
      // Screener is NOT a primary tab when disabled — only shown as optional
      // 5th destination when enable_screener=true (plan Task 24 constraint).
      if (enableScreener)
        const NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: AppLabels.screener,
        ),
    ];

    return MobileShell(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showSearch(
            context: context,
            delegate: StockSearchDelegate(),
          ).then((symbol) {
            if (symbol != null && symbol.isNotEmpty && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SymbolDetailScreen(symbol: symbol),
                ),
              );
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.search, color: Colors.white),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, destinations.length - 1),
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == selectedIndex,
          );
        },
        destinations: destinations,
      ),
    );
  }
}
