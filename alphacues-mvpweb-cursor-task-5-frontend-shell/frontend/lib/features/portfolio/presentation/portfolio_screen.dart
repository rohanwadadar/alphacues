import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../dashboard/presentation/widgets/dashboard_formatters.dart';
import '../data/portfolio_providers.dart';
import 'portfolio_event_form_dialog.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  List<String> _subscribedSymbols = const [];
  Set<String> _heldSymbols = const {};

  @override
  void initState() {
    super.initState();
    _quoteSub = ref
        .read(socketClientProvider)
        .quoteUpdates
        .listen(_onQuoteUpdate);
  }

  @override
  void deactivate() {
    _quoteSub?.cancel();
    _quoteSub = null;
    final symbols = List<String>.from(_subscribedSymbols);
    _subscribedSymbols = const [];
    try {
      final quoteManager = ref.read(quoteSubscriptionManagerProvider.notifier);
      final portfolioActive = ref.read(portfolioScreenActiveProvider.notifier);
      Future.microtask(() {
        try {
          if (symbols.isNotEmpty) {
            quoteManager.unsubscribeHidden(symbols);
          }
          portfolioActive.untrack();
        } catch (_) {}
      });
    } catch (_) {}
    super.deactivate();
  }

  @override
  void dispose() {
    _quoteSub?.cancel();
    super.dispose();
  }

  void _onQuoteUpdate(QuoteUpdatePayload payload) {
    if (!mounted || !_heldSymbols.contains(payload.symbol)) {
      return;
    }
    ref.invalidate(portfolioSummaryProvider);
  }

  void _syncSubscriptions(List<String> symbols) {
    if (_listEquals(symbols, _subscribedSymbols)) {
      return;
    }

    final manager = ref.read(quoteSubscriptionManagerProvider.notifier);
    final toRemove = _subscribedSymbols
        .where((s) => !symbols.contains(s))
        .toList();
    if (toRemove.isNotEmpty) {
      manager.unsubscribeHidden(toRemove);
    }
    if (symbols.isNotEmpty) {
      manager.subscribeVisible(symbols);
    }
    _subscribedSymbols = List<String>.from(symbols);
    _heldSymbols = symbols.toSet();
    ref.read(portfolioScreenActiveProvider.notifier).track();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _isAsOfStale(String asOf, bool socketConnected) {
    if (!socketConnected) {
      return true;
    }
    final parsed = DateTime.tryParse(asOf)?.toUtc();
    if (parsed == null) {
      return true;
    }
    return DateTime.now().toUtc().difference(parsed).inSeconds > 60;
  }

  Future<void> _deleteEvent(PortfolioEvent event) async {
    try {
      await ref.read(portfolioRepositoryProvider).deleteEvent(event.eventId);
      if (!mounted) {
        return;
      }
      ref.invalidate(portfolioSummaryProvider);
      ref.invalidate(portfolioTransactionsProvider);
    } on PortfolioValidationErrorException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(portfolioErrorMessage(error))));
    }
  }

  void _openAddDialog() {
    PortfolioEventFormDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketState = ref.watch(socketConnectionStateProvider);
    final socketConnected =
        socketState.connectionState == SocketConnectionState.connected;
    final transactionsNotifier = ref.read(
      portfolioTransactionsProvider.notifier,
    );
    final mutationsEnabled = isOnline;

    ref.listen(portfolioSummaryProvider, (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncSubscriptions(value.symbols);
      }
    });

    if (summaryAsync case AsyncData(:final value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncSubscriptions(value.symbols);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(portfolioScreenActiveProvider.notifier).track();
      }
    });

    final summary = summaryAsync.asData?.value;
    final showStaleBanner =
        !socketConnected ||
        socketState.awaitingRestRefresh ||
        (summary != null &&
            _isAsOfStale(summary.summary.asOf, socketConnected));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(AppLabels.portfolio),
        actions: [
          IconButton(
            onPressed: mutationsEnabled ? _openAddDialog : null,
            icon: const Icon(Icons.add),
            tooltip: 'Add transaction',
          ),
        ],
      ),
      floatingActionButton: mutationsEnabled
          ? FloatingActionButton(
              onPressed: _openAddDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeScreen(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth <= 600;
            Widget portfolioBody = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaleBanner(
                  message: 'Prices may be delayed',
                  visible: showStaleBanner,
                ),
                Expanded(
                  child: summaryAsync.when(
                loading: () => const _PortfolioSkeleton(),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () =>
                      ref.read(portfolioSummaryProvider.notifier).refresh(),
                ),
                data: (overview) {
                  return transactionsAsync.when(
                    loading: () => const _PortfolioSkeleton(),
                    error: (error, _) => ErrorState(
                      message: error.toString(),
                      onRetry: () => ref
                          .read(portfolioTransactionsProvider.notifier)
                          .refresh(),
                    ),
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return EmptyState(
                          icon: Icons.pie_chart_outline,
                          heading: 'No holdings yet',
                          body:
                              'Add your first BUY to start tracking your portfolio.',
                          actionLabel: mutationsEnabled
                              ? 'Add transaction'
                              : null,
                          onAction: mutationsEnabled ? _openAddDialog : null,
                        );
                      }

                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200) {
                            transactionsNotifier.loadMore();
                          }
                          return false;
                        },
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: _SummaryCard(
                                overview: overview,
                                isDegraded: !isOnline || showStaleBanner,
                              ),
                            ),
                            if (overview.positions.isNotEmpty) ...[
                              const SliverToBoxAdapter(
                                child: _SectionHeader(title: 'Holdings'),
                              ),
                              SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final position = overview.positions[index];
                                  return _PositionRow(position: position);
                                }, childCount: overview.positions.length),
                              ),
                            ],
                            const SliverToBoxAdapter(
                              child: _SectionHeader(title: 'Transactions'),
                            ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final event = transactions[index];
                                return _TransactionRow(
                                  event: event,
                                  mutationsEnabled: mutationsEnabled,
                                  onEdit: () => PortfolioEventFormDialog.show(
                                    context,
                                    event: event,
                                  ),
                                  onDelete: () => _deleteEvent(event),
                                );
                              }, childCount: transactions.length),
                            ),
                            if (transactionsNotifier.hasMore)
                              const SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );

        if (!isPhone) {
          portfolioBody = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: portfolioBody,
            ),
          );
        }

        return portfolioBody;
      },
    ),
  ),
);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.overview, required this.isDegraded});

  final PortfolioOverview overview;
  final bool isDegraded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = overview.summary;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricRow(
              label: 'Total value',
              value: formatPrice(summary.totalValue),
            ),
            _MetricRow(
              label: 'Total profit',
              value: formatSignedAmount(summary.totalProfit),
              valueColor: summary.totalProfit >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
            _MetricRow(
              label: 'Total return',
              value: formatPercent(summary.totalReturn),
              valueColor: summary.totalReturn >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
            _MetricRow(
              label: 'Day change',
              value: formatSignedAmount(summary.dayChange),
              valueColor: summary.dayChange >= 0
                  ? AppColors.positive
                  : AppColors.negative,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'As of ${formatAsOfTimestamp(summary.asOf)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isDegraded) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Showing last known values',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({required this.position});

  final PortfolioPosition position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppTheme.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(position.symbol, style: theme.textTheme.titleMedium),
                  Text(
                    '${position.volume} shares · cost ${formatPrice(position.totalPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatAsOfTimestamp(position.updatedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.event,
    required this.mutationsEnabled,
    required this.onEdit,
    required this.onDelete,
  });

  final PortfolioEvent event;
  final bool mutationsEnabled;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBuy = event.action == 'BUY';
    final chipColor = isBuy ? AppColors.positive : AppColors.negative;

    return Dismissible(
      key: ValueKey(event.eventId),
      direction: mutationsEnabled
          ? DismissDirection.horizontal
          : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (!mutationsEnabled) {
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          await onDelete();
        } else if (direction == DismissDirection.startToEnd) {
          onEdit();
        }
        return false;
      },
      background: Container(
        color: AppColors.negative,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.delete_outline, color: AppColors.onPrimary),
      ),
      secondaryBackground: Container(
        color: AppColors.primary,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: const Icon(Icons.edit_outlined, color: AppColors.onPrimary),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: mutationsEnabled ? onEdit : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppTheme.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isBuy
                          ? AppColors.positiveBackground
                          : AppColors.negativeBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                      color: chipColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.symbol, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '${event.volume} shares @ ${formatPrice(event.price)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      event.action,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: chipColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    formatAsOfTimestamp(event.timeStamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}

class _PortfolioSkeleton extends StatelessWidget {
  const _PortfolioSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        LoadingSkeleton(width: double.infinity, height: 160),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(width: double.infinity, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 20),
        SizedBox(height: AppSpacing.sm),
        LoadingSkeleton(width: double.infinity, height: 20),
      ],
    );
  }
}
