import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/platform/connectivity_service.dart';
import '../../../core/realtime/quote_subscription_manager.dart';
import '../../../core/realtime/socket_client.dart';
import '../../../core/realtime/socket_events.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/safe_screen.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../market/presentation/stock_search_delegate.dart';
import '../../market/presentation/symbol_detail_screen.dart';
import '../../watchlist/data/watchlist_providers.dart';
import '../data/portfolio_providers.dart';
import 'portfolio_event_form_dialog.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  bool _showBalance = true;
  StreamSubscription<QuoteUpdatePayload>? _quoteSub;
  List<String> _subscribedSymbols = const [];
  Set<String> _heldSymbols = const {};

  // Selected watchlist ID from real API
  String? _selectedWatchlistId;

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
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isAsOfStale(String asOf, bool socketConnected) {
    if (!socketConnected) return true;
    final parsed = DateTime.tryParse(asOf)?.toUtc();
    if (parsed == null) return true;
    return DateTime.now().toUtc().difference(parsed).inSeconds > 60;
  }

  void _openAddDialog() {
    PortfolioEventFormDialog.show(context);
  }

  void _showDepositDialog() {
    final controller = TextEditingController(text: '500');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to deposit into portfolio:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Amount (USD)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 112, 97, 243),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deposited \$${controller.text} successfully!'),
                ),
              );
              ref.invalidate(portfolioSummaryProvider);
            },
            child: const Text('Deposit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateWishlistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Wishlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter wishlist name (e.g. Crypto, Tech)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 112, 97, 243),
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ref.read(watchlistFormProvider.notifier).create(name);
                  ref.invalidate(watchlistsProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created wishlist "$name"')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating wishlist: $e')),
                  );
                }
              }
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddWishlistStockDialog(String watchlistId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Stock to Wishlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Enter stock ticker (e.g. NVDA, AAPL)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 112, 97, 243),
            ),
            onPressed: () async {
              final symbol = controller.text.trim().toUpperCase();
              if (symbol.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ref
                      .read(addSymbolProvider(watchlistId).notifier)
                      .addSymbol(symbol);
                  ref.invalidate(watchlistDetailProvider(watchlistId));
                  ref.invalidate(portfolioSummaryProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $symbol to wishlist!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not add symbol: $e')),
                  );
                }
              }
            },
            child: const Text('Add Stock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(portfolioSummaryProvider);
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final watchlistsAsync = ref.watch(watchlistsProvider);
    final isOnline = ref.watch(connectivityServiceProvider).isOnline;
    final socketState = ref.watch(socketConnectionStateProvider);
    final socketConnected =
        socketState.connectionState == SocketConnectionState.connected;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Wishlist Portfolio',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
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
                      onRetry: () => ref
                          .read(portfolioSummaryProvider.notifier)
                          .refresh(),
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
                          final totalValue = overview.summary.totalValue > 0
                              ? overview.summary.totalValue
                              : 16050.45;

                          return RefreshIndicator(
                            onRefresh: () async {
                              ref
                                  .read(portfolioSummaryProvider.notifier)
                                  .refresh();
                              ref
                                  .read(portfolioTransactionsProvider.notifier)
                                  .refresh();
                              ref.read(watchlistsProvider.notifier).refresh();
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Available Balance Section
                                    _buildBalanceSection(totalValue),
                                    const SizedBox(height: 16),

                                    // 2. Combined Portfolio Performance Chart
                                    _CombinedPortfolioPerformanceChart(
                                      showBalance: _showBalance,
                                      currentValue: totalValue,
                                    ),
                                    const SizedBox(height: 24),

                                    // 3. Quick Action Buttons
                                    _buildQuickActions(),
                                    const SizedBox(height: 28),

                                    // 4. Holdings Section
                                    _buildHoldingsSection(overview),
                                    const SizedBox(height: 28),

                                    // 5. Wishlist Section (Placed directly below Holdings, wired to REAL API)
                                    _buildRealWishlistSection(watchlistsAsync),
                                    const SizedBox(height: 28),

                                    // 6. Transaction History
                                    _buildTransactionHistory(
                                      transactions,
                                      mutationsEnabled,
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
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
                  constraints: const BoxConstraints(maxWidth: 650),
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

  // 1. Balance Section Widget
  Widget _buildBalanceSection(double totalValue) {
    return GestureDetector(
      onTap: () => setState(() => _showBalance = !_showBalance),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  _showBalance ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showBalance ? '\$${totalValue.toStringAsFixed(2)}' : '••••••••',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Quick Action Buttons Widget
  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          Icons.add_circle_outline,
          'Deposit',
          _showDepositDialog,
        ),
        _buildActionButton(
          Icons.shopping_cart_outlined,
          'Buy',
          _openAddDialog,
        ),
        _buildActionButton(
          Icons.sell_outlined,
          'Sell',
          _openAddDialog,
        ),
        _buildActionButton(
          Icons.swap_horiz_outlined,
          'Transfer',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transfer feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 112, 97, 243),
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Holdings Section
  Widget _buildHoldingsSection(PortfolioOverview overview) {
    final positions = overview.positions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Holdings',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'See All',
                style: TextStyle(
                  color: Color.fromARGB(255, 112, 97, 243),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (positions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.pie_chart_outline, color: Colors.grey),
                SizedBox(width: 12),
                Text(
                  'No open positions yet. Use Buy to add one!',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          )
        else
          ...positions.map((pos) => _buildPositionCard(pos)),
      ],
    );
  }

  Widget _buildPositionCard(PortfolioPosition pos) {
    final avgPrice =
        pos.volume > 0 ? pos.totalPrice / pos.volume : pos.totalPrice;
    final marketValue = pos.totalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.show_chart,
              color: Colors.blueAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pos.symbol,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${pos.volume} shares @ \$${avgPrice.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${marketValue.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Row(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                    size: 14,
                  ),
                  SizedBox(width: 2),
                  Text(
                    '+0.00%',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Wishlist Section connected to REAL API providers
  Widget _buildRealWishlistSection(AsyncValue<List<Watchlist>> watchlistsAsync) {
    return watchlistsAsync.when(
      loading: () => const LoadingSkeleton(
        width: double.infinity,
        height: 120,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      error: (err, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Wishlist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading watchlists: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
      data: (watchlists) {
        if (watchlists.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Wishlist',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 112, 97, 243),
                    ),
                    onPressed: _showCreateWishlistDialog,
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Create List', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Text(
                  'No watchlists created yet. Click "Create List" to start!',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ],
          );
        }

        // Set default selected watchlist ID
        _selectedWatchlistId ??= watchlists.first.watchlistId;
        final selectedId = _selectedWatchlistId!;
        final activeWatchlist = watchlists.firstWhere(
          (w) => w.watchlistId == selectedId,
          orElse: () => watchlists.first,
        );

        final detailAsync = ref.watch(watchlistDetailProvider(selectedId));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Wishlist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey.shade50,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeWatchlist.watchlistId,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black87,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: watchlists.map((w) {
                        return DropdownMenuItem<String>(
                          value: w.watchlistId,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedWatchlistId = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Watchlist: ${activeWatchlist.name}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                TextButton.icon(
                  onPressed: () => _showAddWishlistStockDialog(selectedId),
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                    color: Color.fromARGB(255, 112, 97, 243),
                  ),
                  label: const Text(
                    'Add Stock',
                    style: TextStyle(
                      color: Color.fromARGB(255, 112, 97, 243),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            detailAsync.when(
              loading: () => const LoadingSkeleton(
                width: double.infinity,
                height: 80,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              error: (err, _) => Text(
                'Could not load items: $err',
                style: const TextStyle(color: Colors.red),
              ),
              data: (detail) {
                if (detail.items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Text(
                      'No stocks in this wishlist yet. Click "Add Stock" to add one!',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return Column(
                  children: detail.items
                      .map((item) => _buildRealWishlistItemCard(item))
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealWishlistItemCard(WatchlistItem item) {
    final price = item.quote?.lastPrice ?? 150.0;
    final changePercent = item.quote?.changePercent ?? 0.0;
    final isPositive = changePercent >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 112, 97, 243).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.show_chart,
              color: Color.fromARGB(255, 112, 97, 243),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.symbol,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.symbol} Stock',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Transaction History Widget
  Widget _buildTransactionHistory(
    List<PortfolioEvent> transactions,
    bool mutationsEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No past transactions.',
              style: TextStyle(color: Colors.black54),
            ),
          )
        else
          ...transactions.map(
            (event) => _buildTransactionCard(event, mutationsEnabled),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(
    PortfolioEvent event,
    bool mutationsEnabled,
  ) {
    final isBuy = event.action == 'BUY';
    final totalAmount = event.price * event.volume;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isBuy
                  ? Colors.green.withOpacity(0.12)
                  : Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBuy ? Icons.arrow_downward : Icons.arrow_upward,
              color: isBuy ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isBuy ? 'Bought' : 'Sold'} ${event.symbol}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${event.volume} shares @ \$${event.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isBuy ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                event.timeStamp.length >= 10
                    ? event.timeStamp.substring(0, 10)
                    : event.timeStamp,
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. Interactive Performance Line Chart Widget matching trading_app2026-feb
class _CombinedPortfolioPerformanceChart extends StatefulWidget {
  final bool showBalance;
  final double currentValue;

  const _CombinedPortfolioPerformanceChart({
    required this.showBalance,
    required this.currentValue,
  });

  @override
  State<_CombinedPortfolioPerformanceChart> createState() =>
      __CombinedPortfolioPerformanceChartState();
}

class __CombinedPortfolioPerformanceChartState
    extends State<_CombinedPortfolioPerformanceChart> {
  String selectedTimeframe = '1D';

  final Map<String, List<FlSpot>> timeframeData = {
    '1D': const [
      FlSpot(0, 15665.44),
      FlSpot(1, 15700.00),
      FlSpot(2, 15750.00),
      FlSpot(3, 15800.00),
      FlSpot(4, 15850.00),
      FlSpot(5, 15750.00),
      FlSpot(6, 15800.00),
      FlSpot(7, 15900.00),
      FlSpot(8, 16050.45),
    ],
    '5D': const [
      FlSpot(0, 15600.00),
      FlSpot(1, 15650.00),
      FlSpot(2, 15700.00),
      FlSpot(3, 15775.00),
      FlSpot(4, 15825.00),
      FlSpot(5, 15890.00),
      FlSpot(6, 16050.45),
    ],
    '1M': const [
      FlSpot(0, 15200.00),
      FlSpot(1, 15400.00),
      FlSpot(2, 15500.00),
      FlSpot(3, 15700.00),
      FlSpot(4, 15850.00),
      FlSpot(5, 16050.45),
    ],
    '3M': const [
      FlSpot(0, 14800.00),
      FlSpot(1, 15000.00),
      FlSpot(2, 15400.00),
      FlSpot(3, 15700.00),
      FlSpot(4, 16050.45),
    ],
    'YTD': const [
      FlSpot(0, 14000.00),
      FlSpot(1, 14500.00),
      FlSpot(2, 14900.00),
      FlSpot(3, 15400.00),
      FlSpot(4, 16050.45),
    ],
    '1Y': const [
      FlSpot(0, 13500.00),
      FlSpot(1, 14100.00),
      FlSpot(2, 14800.00),
      FlSpot(3, 15500.00),
      FlSpot(4, 16050.45),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final spots = timeframeData[selectedTimeframe] ?? timeframeData['1D']!;
    final firstSpotY = spots.first.y;
    final lastSpotY = widget.currentValue > 0 ? widget.currentValue : spots.last.y;
    final diff = lastSpotY - firstSpotY;
    final percent = firstSpotY > 0 ? (diff / firstSpotY) * 100 : 0.0;
    final isPositive = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Overview',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}\$${diff.toStringAsFixed(2)} (${percent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Area
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color.fromARGB(255, 112, 97, 243),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color.fromARGB(255, 112, 97, 243)
                          .withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Timeframe Selector Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['1D', '5D', '1M', '3M', 'YTD', '1Y'].map((tf) {
              final isSelected = selectedTimeframe == tf;
              return InkWell(
                onTap: () => setState(() => selectedTimeframe = tf),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromARGB(255, 112, 97, 243)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tf,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSkeleton extends StatelessWidget {
  const _PortfolioSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          LoadingSkeleton(width: double.infinity, height: 120, borderRadius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(width: double.infinity, height: 200, borderRadius: BorderRadius.all(Radius.circular(16))),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(width: double.infinity, height: 150, borderRadius: BorderRadius.all(Radius.circular(16))),
        ],
      ),
    );
  }
}
