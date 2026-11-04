import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/utils/us_market_time.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../market/presentation/symbol_detail_screen.dart';
import '../data/notifications_notifier.dart';

class NotificationsPanel extends ConsumerStatefulWidget {
  const NotificationsPanel({super.key});

  @override
  ConsumerState<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<NotificationsPanel> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<String> _categories = const [
    'All',
    'Unread',
    'Price Alerts',
    'Strategy Scans',
    'Market News',
    'System',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> all) {
    return all.where((n) {
      if (_selectedCategory == 'Unread' && n.isRead) {
        return false;
      }
      if (_selectedCategory != 'All' && _selectedCategory != 'Unread' && n.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final titleMatch = n.title.toLowerCase().contains(q);
        final bodyMatch = n.body.toLowerCase().contains(q);
        final symbolMatch = n.extractedSymbol?.toLowerCase().contains(q) ?? false;
        if (!titleMatch && !bodyMatch && !symbolMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, sheetController) {
        return SafeScreen(
          child: Material(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Notifications',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Manage Price Alerts',
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.alerts);
                        },
                        icon: Icon(
                          Icons.notification_add_rounded,
                          size: 24,
                          color: theme.brightness == Brightness.dark
                              ? AppColors.darkPrimary
                              : AppColors.primary,
                        ),
                      ),
                      TextButton(
                        onPressed: isOnline &&
                                notificationsAsync.maybeWhen(
                                  data: (items) => items.any((item) => !item.isRead),
                                  orElse: () => false,
                                )
                            ? () => notifier.markAllRead()
                            : null,
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by alert, ticker (\$NVDA), keyword...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                // Category Filter Chips
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),

                if (!isOnline)
                  const StaleBanner(
                    message: "You're offline. Showing cached notifications.",
                    visible: true,
                  ),

                Expanded(
                  child: notificationsAsync.when(
                    loading: () => _NotificationsSkeleton(controller: sheetController),
                    error: (error, _) => ListView(
                      controller: sheetController,
                      children: [
                        ErrorState(
                          message: error.toString(),
                          onRetry: () => notifier.refresh(),
                        ),
                      ],
                    ),
                    data: (notifications) {
                      final filteredList = _filterNotifications(notifications);

                      if (notifications.isEmpty) {
                        return ListView(
                          controller: sheetController,
                          children: const [
                            EmptyState(
                              icon: Icons.notifications_none_outlined,
                              heading: "You're all caught up",
                              body: 'New alert notifications will appear here.',
                            ),
                          ],
                        );
                      }

                      if (filteredList.isEmpty) {
                        return ListView(
                          controller: sheetController,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_alt_off_rounded, size: 48, color: colorScheme.outline),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'No notifications found',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Try adjusting your search query or selected filter category.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Reset All Filters'),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _selectedCategory = 'All';
                                        _searchQuery = '';
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          // Showing count header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${filteredList.length} of ${notifications.length} notifications',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedCategory != 'All' || _searchQuery.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() {
                                        _selectedCategory = 'All';
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Text(
                                      'Clear Filter',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              controller: sheetController,
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final notification = filteredList[index];
                                return _NotificationRow(
                                  notification: notification,
                                  onTap: () {
                                    if (isOnline) {
                                      notifier.markRead(notification.notificationId);
                                    }
                                    final sym = notification.extractedSymbol;
                                    if (sym != null && sym.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SymbolDetailScreen(symbol: sym),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Price Alerts':
        return Colors.blue;
      case 'Strategy Scans':
        return Colors.purple;
      case 'Market News':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = _formatDate(notification.createdAt);
    final catColor = _getCategoryColor(notification.category);
    final symbol = notification.extractedSymbol;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      color: notification.isRead
          ? Colors.transparent
          : AppColors.primaryContainer.withValues(alpha: 0.35),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                notification.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: catColor,
                                ),
                              ),
                            ),
                            if (symbol != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '\$$symbol',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              formattedDate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final raw = DateTime.parse(iso);
      final date = toUsEastern(raw);
      final now = toUsEastern(DateTime.now().toUtc());
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ET';
    } catch (_) {
      return iso;
    }
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeleton(width: double.infinity, height: 16),
          SizedBox(height: AppSpacing.sm),
          LoadingSkeleton(width: double.infinity, height: 14),
        ],
      ),
    );
  }
}

