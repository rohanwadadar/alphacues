import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/safe_screen.dart';
import '../data/dashboard_providers.dart';
import 'widgets/dashboard_formatters.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/notification_bell.dart';
import 'widgets/portfolio_summary_widget.dart';
import 'widgets/top_movers_widget.dart';
import 'widgets/watchlist_summary_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  StreamSubscription<NotificationNewPayload>? _notificationSub;
  List<String> _subscribedSymbols = const [];

  @override
  void initState() {
    super.initState();
    final socket = ref.read(socketClientProvider);
    _quoteSub = socket.quoteUpdates.listen(_onQuoteUpdate);
    _notificationSub = socket.notifications.listen(_onNotificationNew);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dashboardScreenActiveProvider.notifier).track();
      }
    });
  }

  @override
  void deactivate() {
    _quoteSub?.cancel();
    _quoteSub = null;
    _notificationSub?.cancel();
    _notificationSub = null;
    final symbols = List<String>.from(_subscribedSymbols);
    _subscribedSymbols = const [];
    try {
      final quoteManager = ref.read(quoteSubscriptionManagerProvider.notifier);
      final dashboardActive = ref.read(dashboardScreenActiveProvider.notifier);
      Future.microtask(() {
        try {
          if (symbols.isNotEmpty) {
            quoteManager.unsubscribeHidden(symbols);
          }
          dashboardActive.untrack();
        } catch (_) {}
      });
    } catch (_) {}
    super.deactivate();
  }

  void _onQuoteUpdate(QuoteUpdatePayload payload) {
    if (!mounted) {
      return;
    }
    ref.read(dashboardProvider.notifier).patchMoverQuote(
      symbol: payload.symbol,
      lastPrice: payload.lastPrice,
      changePercent: payload.changePercent,
    );
  }

  void _onNotificationNew(NotificationNewPayload payload) {
    if (!mounted) {
      return;
    }
    ref.read(dashboardNotificationBadgeProvider.notifier).increment();
  }

  void _syncMoverSubscriptions(DashboardSnapshot snapshot) {
    final symbols = snapshot.moverSymbols;
    if (_listEquals(symbols, _subscribedSymbols)) {
      return;
    }

    final manager = ref.read(quoteSubscriptionManagerProvider.notifier);
    final toRemove = _subscribedSymbols
        .where((symbol) => !symbols.contains(symbol))
        .toList();
    if (toRemove.isNotEmpty) {
      manager.unsubscribeHidden(toRemove);
    }
    if (symbols.isNotEmpty) {
      manager.subscribeVisible(symbols);
    }
    _subscribedSymbols = List<String>.from(symbols);
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

  bool _isSnapshotStale(DashboardSnapshot snapshot, bool socketConnected) {
    if (!socketConnected) {
      return true;
    }
    return DateTime.now().toUtc().difference(snapshot.fetchedAt).inSeconds > 60;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketConnected =
        ref.watch(socketConnectionStateProvider).connectionState ==
        SocketConnectionState.connected;

    ref.listen(dashboardProvider, (previous, next) {
      if (next case AsyncData(:final value)) {
        _syncMoverSubscriptions(value);
      }
    });

    if (dashboardAsync case AsyncData(:final value)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _syncMoverSubscriptions(value);
        }
      });
    }

    final cachedSnapshot = dashboardAsync.asData?.value;
    final isStale = cachedSnapshot != null &&
        (!isOnline || _isSnapshotStale(cachedSnapshot, socketConnected));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLabels.dashboard),
        actions: const [NotificationBell()],
      ),
      body: SafeScreen(
        child: dashboardAsync.when(
          loading: () => const DashboardSkeleton(),
          error: (error, _) {
            final errorMessage = error.toString();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RetryBanner(
                  message: errorMessage,
                  onRetry: _refreshDashboard,
                ),
                Expanded(
                  child: _DashboardContent(
                    snapshot: cachedSnapshot,
                    isStale: cachedSnapshot != null,
                    staleTimestamp: cachedSnapshot?.fetchedAt,
                    moversError: cachedSnapshot == null ? errorMessage : null,
                    portfolioError: cachedSnapshot == null ? errorMessage : null,
                    onRetryMovers: _refreshDashboard,
                    onRetryPortfolio: _refreshDashboard,
                  ),
                ),
              ],
            );
          },
          data: (snapshot) => _DashboardContent(
            snapshot: snapshot,
            isStale: isStale,
            staleTimestamp: snapshot.fetchedAt,
            onRetryMovers: _refreshDashboard,
            onRetryPortfolio: _refreshDashboard,
          ),
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() {
    return ref.read(dashboardProvider.notifier).refresh();
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.snapshot,
    required this.isStale,
    this.staleTimestamp,
    this.moversError,
    this.portfolioError,
    this.onRetryMovers,
    this.onRetryPortfolio,
  });

  final DashboardSnapshot? snapshot;
  final bool isStale;
  final DateTime? staleTimestamp;
  final String? moversError;
  final String? portfolioError;
  final VoidCallback? onRetryMovers;
  final VoidCallback? onRetryPortfolio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Single-column phone layout (Task 24): on screens ≤600dp the list fills
    // edge-to-edge. On wider devices (tablet/web) content is max 600dp wide.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth <= 600;
        Widget content = ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (isStale && staleTimestamp != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Last updated ${formatAsOfTimestamp(staleTimestamp!.toIso8601String())}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ),
            TopMoversWidget(
              movers: snapshot?.topMovers ?? const [],
              isStale: isStale,
              errorMessage: moversError,
              onRetry: onRetryMovers,
            ),
            const SizedBox(height: AppSpacing.lg),
            const WatchlistSummaryWidget(),
            const SizedBox(height: AppSpacing.lg),
            PortfolioSummaryWidget(
              portfolio: snapshot?.portfolio,
              isStale: isStale,
              errorMessage: portfolioError,
              onRetry: onRetryPortfolio,
            ),
          ],
        );

        if (!isPhone) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: content,
            ),
          );
        }

        return content;
      },
    );
  }
}

class _RetryBanner extends StatelessWidget {
  const _RetryBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.negativeBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.negative,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(AppLabels.retry),
            ),
          ],
        ),
      ),
    );
  }
}
