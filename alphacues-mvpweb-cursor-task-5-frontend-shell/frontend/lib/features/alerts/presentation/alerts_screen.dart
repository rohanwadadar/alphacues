import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../notifications/data/notifications_notifier.dart';
import '../../notifications/presentation/notifications_panel.dart';
import '../data/alerts_providers.dart';
import 'alert_form_dialog.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openNotificationsPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const NotificationsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(notificationsProvider);
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketDown = ref.watch(
      socketConnectionStateProvider.select(
        (state) => state.connectionState != SocketConnectionState.connected,
      ),
    );
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final mutationsEnabled = isOnline;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(AppLabels.alerts),
        actions: [
          IconButton(
            onPressed: _openNotificationsPanel,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      floatingActionButton: mutationsEnabled && _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => AlertFormDialog.show(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeScreen(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth <= 600;
            Widget bodyContent = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (socketDown)
                  const StaleBanner(
                    message: 'Live updates paused',
                    visible: true,
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AlertsList(
                        isHistory: false,
                        emptyHeading: 'No alerts yet',
                        showActiveControls: true,
                        mutationsEnabled: mutationsEnabled,
                      ),
                      _AlertsList(
                        isHistory: true,
                        emptyHeading: 'No alert history yet',
                        showActiveControls: false,
                        mutationsEnabled: false,
                      ),
                    ],
                  ),
                ),
              ],
            );

            if (!isPhone) {
              bodyContent = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: bodyContent,
                ),
              );
            }

            return bodyContent;
          },
        ),
      ),
    );
  }
}

class _AlertsList extends ConsumerWidget {
  const _AlertsList({
    required this.isHistory,
    required this.emptyHeading,
    required this.showActiveControls,
    required this.mutationsEnabled,
  });

  final bool isHistory;
  final String emptyHeading;
  final bool showActiveControls;
  final bool mutationsEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(
      isHistory ? alertHistoryProvider : alertsProvider,
    );

    return alertsAsync.when(
      loading: () => const _AlertsSkeleton(),
      error: (error, _) => ErrorState(
        message: error.toString(),
        onRetry: () {
          if (isHistory) {
            ref.read(alertHistoryProvider.notifier).refresh();
          } else {
            ref.read(alertsProvider.notifier).refresh();
          }
        },
      ),
      data: (alerts) {
        if (alerts.isEmpty) {
          return EmptyState(
            icon: Icons.notifications_outlined,
            heading: emptyHeading,
            body: showActiveControls
                ? 'Create a price alert to get notified when a symbol moves.'
                : 'Triggered alerts will appear here.',
            actionLabel: showActiveControls && mutationsEnabled
                ? 'Create alert'
                : null,
            onAction: showActiveControls && mutationsEnabled
                ? () => AlertFormDialog.show(context)
                : null,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: alerts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _AlertRow(
              alert: alert,
              showActiveControls: showActiveControls,
              mutationsEnabled: mutationsEnabled,
              onTap: showActiveControls && mutationsEnabled
                  ? () => AlertFormDialog.show(context, alert: alert)
                  : null,
              onDelete: showActiveControls && mutationsEnabled
                  ? () => _confirmDelete(context, ref, alert)
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AlertModel alert,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete alert?'),
        content: Text(
          'Remove ${alert.symbol} ${alert.condition} alert at ${alert.target}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    ///await ref.read(alertDeleteProvider.notifier).delete(alert.alertId);
    try {
        await ref.read(alertDeleteProvider.notifier).delete(alert.alertId);

        if (!context.mounted) {
          return;
        }

        ref.read(alertsProvider.notifier).refresh();
        ref.read(alertHistoryProvider.notifier).refresh();
      } catch (error) {
        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete alert: $error')),
        );
      }
  }
}

class _AlertRow extends ConsumerWidget {
  const _AlertRow({
    required this.alert,
    required this.showActiveControls,
    required this.mutationsEnabled,
    this.onTap,
    this.onDelete,
  });

  final AlertModel alert;
  final bool showActiveControls;
  final bool mutationsEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  String get _conditionLabel {
    switch (alert.condition) {
      case 'ABOVE':
        return 'Above';
      case 'BELOW':
        return 'Below';
      case 'PERCENT_CHANGE':
        return '% Change';
      default:
        return alert.condition;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitle =
        '$_conditionLabel ${alert.target.toStringAsFixed(2)}'
        '${alert.triggered ? ' · Triggered' : ''}';

    return Dismissible(
      key: ValueKey(alert.alertId),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        onDelete?.call();
        return false;
      },
      background: Container(
        color: AppColors.negative,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.delete_outline, color: AppColors.onPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: theme.colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: alert.triggered
                              ? AppColors.negativeBackground
                              : AppColors.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          alert.triggered
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_outlined,
                          color: alert.triggered ? AppColors.negative : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.symbol,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showActiveControls)
                        Switch(
                          value: alert.isActive,
                          onChanged: mutationsEnabled
                              ? (value) => ref
                                    .read(alertToggleProvider.notifier)
                                    .toggleActive(alert, value)
                              : null,
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: mutationsEnabled ? onDelete : null,
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete alert',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertsSkeleton extends StatelessWidget {
  const _AlertsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const Row(
        children: [
          Expanded(
            child: LoadingSkeleton(width: double.infinity, height: 20),
          ),
          SizedBox(width: AppSpacing.md),
          LoadingSkeleton(width: 48, height: 28),
        ],
      ),
    );
  }
}
