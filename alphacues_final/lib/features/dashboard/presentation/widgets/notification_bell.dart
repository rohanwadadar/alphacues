import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_theme.dart';
import '../../data/dashboard_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(dashboardNotificationBadgeProvider);

    return IconButton(
      onPressed: () => context.go(AppRoutes.alerts),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
      tooltip: 'Alerts',
      constraints: const BoxConstraints(
        minWidth: AppTheme.minTouchTarget,
        minHeight: AppTheme.minTouchTarget,
      ),
    );
  }
}
