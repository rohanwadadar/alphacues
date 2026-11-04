import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../onboarding/presentation/onboarding_guide_modal.dart';
import '../../settings/data/settings_provider.dart';
import '../../market/data/symbol_search_provider.dart';
import '../../screener/data/screener_providers.dart';
import '../data/dashboard_providers.dart';
import 'widgets/dashboard_formatters.dart';
// import 'widgets/market_treemap_widget.dart';
// import '../../social/presentation/social_copy_trading_widget.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/notification_bell.dart';
import 'widgets/portfolio_summary_widget.dart';
// import 'widgets/top_movers_widget.dart';
import 'widgets/watchlist_summary_widget.dart';
// import '../../news/presentation/widgets/market_news_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  StreamSubscription<NotificationNewPayload>? _notificationSub;
  List<String> _subscribedSymbols = const [];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final socket = ref.read(socketClientProvider);
    _quoteSub = socket.quoteUpdates.listen(_onQuoteUpdate);
    _notificationSub = socket.notifications.listen(_onNotificationNew);
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dashboardScreenActiveProvider.notifier).track();
        final settings = ref.read(settingsProvider);
        if (!settings.hasCompletedOnboarding) {
          OnboardingGuideModal.show(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    Widget contentBody = dashboardAsync.when(
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
    );

    return Scaffold(
      appBar: AppBar(
        title: const AlphaCuesFullLogo(),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [
          NotificationBell(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeScreen(
        child: contentBody,
      ),
    );
  }

  Future<void> _refreshDashboard() {
    return ref.read(dashboardProvider.notifier).refresh();
  }
}

class _DashboardSearchResults extends ConsumerWidget {
  const _DashboardSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(symbolSearchProvider(query));
    
    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
      error: (error, _) => Center(child: Text('Search failed: $error')),
      data: (results) {
        if (results.isEmpty) {
          return const Center(child: Text('No matching stocks found', style: TextStyle(color: Colors.black54)));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final stock = results[index];
            return GestureDetector(
              onTap: () {
                context.push(AppRoutes.symbolDetail(stock.symbol));
              },
              child: Card(
                color: Colors.grey[50],
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    child: Text(
                      stock.symbol[0], 
                      style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)
                    ),
                  ),
                  title: Text(
                    stock.symbol,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    stock.name,
                    style: TextStyle(color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(255, 114, 70, 192).withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Color.fromARGB(255, 114, 70, 192),
                      size: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

    // Single-column phone layout (Task 24): on screens â‰¤600dp the list fills
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
            // ── 1. Portfolio Summary (top of home page) ──────────────────
            PortfolioSummaryWidget(
              portfolio: snapshot?.portfolio,
              isStale: isStale,
              errorMessage: portfolioError,
              onRetry: onRetryPortfolio,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Watchlist Section (from 2nd page, placed below Portfolio) ──
            const WatchlistSummaryWidget(),
            const SizedBox(height: AppSpacing.lg),

            // ── Commented out for future release per request ──────────────
            // Strategy Quick-Access:
            // const _StrategyQuickAccess(),
            // const SizedBox(height: AppSpacing.lg),

            // Market Movers:
            // TopMoversWidget(
            //   movers: snapshot?.topMovers ?? const [],
            //   isStale: isStale,
            //   errorMessage: moversError,
            //   onRetry: onRetryMovers,
            // ),
            // const SizedBox(height: AppSpacing.lg),

            // Market Movers Treemap:
            // const MarketTreemapWidget(),
            // const SizedBox(height: AppSpacing.lg),

            // Social Copy Trading:
            // const SocialCopyTradingWidget(),
            // const SizedBox(height: AppSpacing.lg),

            // Market News:
            // const MarketNewsWidget(),
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

/// Strategy Quick-Access — horizontal card row of saved strategies.
/// Tapping any card navigates to the Strategy Builder tab.
class _StrategyQuickAccess extends ConsumerWidget {
  const _StrategyQuickAccess();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final savedStrategies = ref.watch(savedStrategiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Strategies',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => context.push(
                '${AppRoutes.strategy}?create=true',
                extra: true,
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ],
        ),
        const SizedBox(height: 8),
        savedStrategies.when(
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
          data: (strategies) {
            if (strategies.isEmpty) {
              return GestureDetector(
                onTap: () => context.go(AppRoutes.strategy),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(Icons.auto_graph_rounded, color: colorScheme.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Build your first strategy ?',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: strategies.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  if (i == strategies.length) {
                    return GestureDetector(
                      onTap: () => context.go(AppRoutes.strategy),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_rounded, color: colorScheme.primary, size: 28),
                          const SizedBox(height: 4),
                          Text('New', style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  }
                  final s = strategies[i];
                  return GestureDetector(
                    onTap: () => context.go(AppRoutes.strategy),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [colorScheme.primary.withOpacity(0.15), colorScheme.primary.withOpacity(0.05)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.auto_graph_rounded, color: colorScheme.primary, size: 20),
                        const Spacer(),
                        Text(s.name, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(s.filters.isEmpty ? 'All stocks' : 'Filtered', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
