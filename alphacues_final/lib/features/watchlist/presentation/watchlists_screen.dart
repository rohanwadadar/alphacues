import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../dashboard/data/dashboard_providers.dart';
import '../../dashboard/presentation/widgets/market_treemap_widget.dart';
import '../../dashboard/presentation/widgets/notification_bell.dart';
import '../../dashboard/presentation/widgets/stock_search_bar_widget.dart';
import '../../dashboard/presentation/widgets/strategy_quick_access_widget.dart';
import '../../dashboard/presentation/widgets/top_movers_widget.dart';
import '../../news/presentation/widgets/market_news_widget.dart';

class WatchlistsScreen extends ConsumerWidget {
  const WatchlistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final dashboardAsync = ref.watch(dashboardProvider);

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
      floatingActionButton: null,
      body: SafeScreen(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth <= 600;

            Widget pageBody = SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isOnline) const StaleBanner(),

                  // ── 1. SEARCH BAR (AT TOP OF 2ND PAGE) ───────────────────────
                  const StockSearchBarWidget(),
                  const SizedBox(height: AppSpacing.md),

                  // ── 2. STRATEGY SECTION (BELOW SEARCH BAR) ───────────────────
                  const StrategyQuickAccessWidget(),
                  const SizedBox(height: AppSpacing.lg),

                  // ── 3. TOP MOVERS SECTION ─────────────────────────────────────
                  dashboardAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (snapshot) => TopMoversWidget(
                      movers: snapshot.topMovers,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── 4. SECTOR TREEMAP ─────────────────────────────────────────
                  const MarketTreemapWidget(),

                  const SizedBox(height: AppSpacing.lg),

                  // ── 5. MARKET NEWS ────────────────────────────────────────────
                  const MarketNewsWidget(),

                  const SizedBox(height: 80),
                ],
              ),
            );

            if (!isPhone) {
              pageBody = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: pageBody,
                ),
              );
            }

            return pageBody;
          },
        ),
      ),
    );
  }
}
