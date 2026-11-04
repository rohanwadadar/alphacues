import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../notifications/presentation/notifications_panel.dart';
import '../../data/dashboard_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(dashboardNotificationBadgeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purpleColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Tooltip(
      message: 'Notifications',
      child: IconButton(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const NotificationsPanel(),
          );
        },
        icon: Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(
            unreadCount > 99 ? '99+' : '$unreadCount',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.negative,
          child: Icon(
            Icons.notifications_rounded,
            size: 24,
            color: purpleColor,
          ),
        ),
      ),
    );
  }
}
