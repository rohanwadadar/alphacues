import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// ═══════════════════════════════════════════════════════════
//  CONSTANTS
// ═══════════════════════════════════════════════════════════
const _kPurple = Color(0xFF7061F3);
const _kGreen  = Color(0xFF00C897);
const _kOrange = Color(0xFFF5A623);
const _kPink   = Color(0xFFE84393);
const _kTeal   = Color(0xFF3BC9DB);

// ═══════════════════════════════════════════════════════════
//  DATA MODELS
// ═══════════════════════════════════════════════════════════

class EarningsPoint {
  final String quarter;
  final double estimated;
  final double actual;
  const EarningsPoint(this.quarter, this.estimated, this.actual);
}

class FinancialBar {
  final String quarter;
  final double revenue;     // billions
  final double grossProfit;
  final double netIncome;
  final double netMargin;   // %
  const FinancialBar(this.quarter, this.revenue, this.grossProfit, this.netIncome, this.netMargin);
}

class TradeTrendPoint {
  final String date;
  final double netPercent; // >0 = buy, <0 = sell
  const TradeTrendPoint(this.date, this.netPercent);
}

class LearningStrategy {
  final String id;
  final String title;
  final String category;
  final String description;
  final String insight;
  final Color accentColor;
  final IconData icon;
  final List<FlSpot> chartSpots;
  final double earnings;
  final double stockPrice;
  final double returnOnEquity;
  final double debtToEquity;
  final double netProfitMargin;
  final String symbol;
  final double changePercent;
  final List<EarningsPoint> earningsData;
  final List<FinancialBar> financialsData;
  final List<TradeTrendPoint> tradingTrends;

  const LearningStrategy({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.insight,
    required this.accentColor,
    required this.icon,
    required this.chartSpots,
    required this.earnings,
    required this.stockPrice,
    required this.returnOnEquity,
    required this.debtToEquity,
    required this.netProfitMargin,
    required this.symbol,
    required this.changePercent,
    required this.earningsData,
    required this.financialsData,
    required this.tradingTrends,
  });
}

// ═══════════════════════════════════════════════════════════
//  MOCK DATA
// ═══════════════════════════════════════════════════════════

final List<LearningStrategy> learningStrategies = [
  LearningStrategy(
    id: '1',
    title: 'Breakout Strategy',
    category: 'Breakout',
    description: 'A breakout occurs when a stock price moves above a resistance level. Traders enter positions anticipating strong momentum.',
    insight: '🚀 Price breaks above key resistance',
    accentColor: _kPurple,
    icon: Icons.trending_up_rounded,
    chartSpots: [FlSpot(0,142),FlSpot(1,143),FlSpot(2,141),FlSpot(3,144),FlSpot(4,145),FlSpot(5,144),FlSpot(6,146),FlSpot(7,158),FlSpot(8,165),FlSpot(9,172)],
    earnings: 4.82, stockPrice: 172.5, returnOnEquity: 38.4, debtToEquity: 0.54, netProfitMargin: 22.1,
    symbol: 'AAPL', changePercent: 5.6,
    earningsData: [EarningsPoint('Q2\nFY25',1.75,1.68), EarningsPoint('Q3\nFY25',1.45,1.42), EarningsPoint('Q4\nFY25',1.90,1.88), EarningsPoint('Q1\nFY26',2.95,2.90), EarningsPoint('Q2\nFY26',1.93,1.85)],
    financialsData: [FinancialBar('Q1\nFY25',124,58,21,16.9), FinancialBar('Q2\nFY25',113,52,20,17.7), FinancialBar('Q3\nFY25',108,47,19,17.6), FinancialBar('Q4\nFY25',119,55,21,17.6), FinancialBar('Q1\nFY26',145,73,28,19.3)],
    tradingTrends: [TradeTrendPoint('Feb 24',10),TradeTrendPoint('Mar 4',-18),TradeTrendPoint('Mar 12',22),TradeTrendPoint('Mar 20',-15),TradeTrendPoint('Mar 28',30),TradeTrendPoint('Apr 4',-12),TradeTrendPoint('Apr 11',18)],
  ),
  LearningStrategy(
    id: '2',
    title: 'Bounce Strategy',
    category: 'Bounce',
    description: 'A bounce happens when price hits a strong support level and reverses upward. A counter-trend play targeting short-term recovery.',
    insight: '📈 Support holds; price bounces back',
    accentColor: _kGreen,
    icon: Icons.swap_vert_rounded,
    chartSpots: [FlSpot(0,310),FlSpot(1,295),FlSpot(2,278),FlSpot(3,265),FlSpot(4,258),FlSpot(5,263),FlSpot(6,275),FlSpot(7,291),FlSpot(8,308),FlSpot(9,322)],
    earnings: 6.15, stockPrice: 322.0, returnOnEquity: 27.9, debtToEquity: 0.88, netProfitMargin: 18.4,
    symbol: 'MSFT', changePercent: 4.2,
    earningsData: [EarningsPoint('Q2\nFY25',2.80,2.94), EarningsPoint('Q3\nFY25',3.10,3.23), EarningsPoint('Q4\nFY25',3.20,3.31), EarningsPoint('Q1\nFY26',3.40,3.46), EarningsPoint('Q2\nFY26',3.22,3.12)],
    financialsData: [FinancialBar('Q1\nFY25',62,43,22,35.4), FinancialBar('Q2\nFY25',65,46,23,35.3), FinancialBar('Q3\nFY25',70,50,25,35.7), FinancialBar('Q4\nFY25',74,53,27,36.4), FinancialBar('Q1\nFY26',80,58,30,37.5)],
    tradingTrends: [TradeTrendPoint('Feb 24',20),TradeTrendPoint('Mar 4',-10),TradeTrendPoint('Mar 12',15),TradeTrendPoint('Mar 20',25),TradeTrendPoint('Mar 28',-8),TradeTrendPoint('Apr 4',30),TradeTrendPoint('Apr 11',12)],
  ),
  LearningStrategy(
    id: '3',
    title: 'Moving Average Cross',
    category: 'Moving Avg',
    description: 'When the 50-day MA crosses above the 200-day MA (Golden Cross), it signals a bullish trend reversal institutions often follow.',
    insight: '📊 Golden Cross signals bull trend',
    accentColor: _kOrange,
    icon: Icons.show_chart_rounded,
    chartSpots: [FlSpot(0,520),FlSpot(1,510),FlSpot(2,515),FlSpot(3,525),FlSpot(4,540),FlSpot(5,555),FlSpot(6,570),FlSpot(7,585),FlSpot(8,600),FlSpot(9,618)],
    earnings: 12.40, stockPrice: 618.0, returnOnEquity: 44.6, debtToEquity: 0.31, netProfitMargin: 26.7,
    symbol: 'NVDA', changePercent: 3.0,
    earningsData: [EarningsPoint('Q2\nFY25',0.65,0.68), EarningsPoint('Q3\nFY25',0.70,0.74), EarningsPoint('Q4\nFY25',0.80,0.81), EarningsPoint('Q1\nFY26',0.89,0.96), EarningsPoint('Q2\nFY26',0.94,0.88)],
    financialsData: [FinancialBar('Q1\nFY25',26,20,15,57.6), FinancialBar('Q2\nFY25',30,23,16,53.3), FinancialBar('Q3\nFY25',35,27,20,57.1), FinancialBar('Q4\nFY25',40,31,22,55.0), FinancialBar('Q1\nFY26',44,34,25,56.8)],
    tradingTrends: [TradeTrendPoint('Feb 24',35),TradeTrendPoint('Mar 4',20),TradeTrendPoint('Mar 12',-8),TradeTrendPoint('Mar 20',40),TradeTrendPoint('Mar 28',15),TradeTrendPoint('Apr 4',-5),TradeTrendPoint('Apr 11',28)],
  ),
  LearningStrategy(
    id: '4',
    title: 'Price Momentum',
    category: 'Price Change',
    description: 'Momentum investing focuses on stocks with strong recent performance, betting that winners continue winning in the near term.',
    insight: '⚡ Follow the momentum, ride the wave',
    accentColor: _kPink,
    icon: Icons.bolt_rounded,
    chartSpots: [FlSpot(0,185),FlSpot(1,190),FlSpot(2,188),FlSpot(3,195),FlSpot(4,202),FlSpot(5,210),FlSpot(6,218),FlSpot(7,225),FlSpot(8,230),FlSpot(9,240)],
    earnings: 3.75, stockPrice: 240.0, returnOnEquity: 31.2, debtToEquity: 0.62, netProfitMargin: 15.8,
    symbol: 'TSLA', changePercent: 6.8,
    earningsData: [EarningsPoint('Q2\nFY25',0.45,0.52), EarningsPoint('Q3\nFY25',0.58,0.61), EarningsPoint('Q4\nFY25',0.72,0.71), EarningsPoint('Q1\nFY26',0.41,0.39), EarningsPoint('Q2\nFY26',0.55,0.45)],
    financialsData: [FinancialBar('Q1\nFY25',21,4,2,9.5), FinancialBar('Q2\nFY25',20,4,1,5.0), FinancialBar('Q3\nFY25',23,5,2,8.7), FinancialBar('Q4\nFY25',24,5,2,8.3), FinancialBar('Q1\nFY26',19,3,1,5.2)],
    tradingTrends: [TradeTrendPoint('Feb 24',-15),TradeTrendPoint('Mar 4',-25),TradeTrendPoint('Mar 12',10),TradeTrendPoint('Mar 20',-28),TradeTrendPoint('Mar 28',20),TradeTrendPoint('Apr 4',-12),TradeTrendPoint('Apr 11',15)],
  ),
  LearningStrategy(
    id: '5',
    title: 'Value Investing',
    category: 'Fundamentals',
    description: 'Buy undervalued stocks with strong fundamentals—low P/E, high ROE, and healthy debt ratios—and hold for long-term growth.',
    insight: '💎 Buy undervalued, grow long-term',
    accentColor: _kTeal,
    icon: Icons.savings_rounded,
    chartSpots: [FlSpot(0,410),FlSpot(1,415),FlSpot(2,408),FlSpot(3,420),FlSpot(4,430),FlSpot(5,438),FlSpot(6,445),FlSpot(7,455),FlSpot(8,462),FlSpot(9,475)],
    earnings: 9.20, stockPrice: 475.0, returnOnEquity: 22.5, debtToEquity: 0.41, netProfitMargin: 20.3,
    symbol: 'GOOGL', changePercent: 2.1,
    earningsData: [EarningsPoint('Q2\nFY25',1.85,1.89), EarningsPoint('Q3\nFY25',2.10,2.15), EarningsPoint('Q4\nFY25',2.15,2.15), EarningsPoint('Q1\nFY26',2.01,2.81), EarningsPoint('Q2\nFY26',2.26,2.20)],
    financialsData: [FinancialBar('Q1\nFY25',80,44,23,28.7), FinancialBar('Q2\nFY25',85,47,24,28.2), FinancialBar('Q3\nFY25',88,49,26,29.5), FinancialBar('Q4\nFY25',96,55,30,31.2), FinancialBar('Q1\nFY26',90,51,34,37.7)],
    tradingTrends: [TradeTrendPoint('Feb 24',12),TradeTrendPoint('Mar 4',-5),TradeTrendPoint('Mar 12',18),TradeTrendPoint('Mar 20',-10),TradeTrendPoint('Mar 28',22),TradeTrendPoint('Apr 4',15),TradeTrendPoint('Apr 11',-8)],
  ),
];

// ═══════════════════════════════════════════════════════════
//  LEARNING SECTION (home page entry)
// ═══════════════════════════════════════════════════════════

class LearningSection extends StatefulWidget {
  const LearningSection({Key? key}) : super(key: key);
  @override
  State<LearningSection> createState() => _LearningSectionState();
}

class _LearningSectionState extends State<LearningSection> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // ✅ Sync chips automatically when user swipes cards
    _pageController.addListener(() {
      final page = (_pageController.page ?? 0).round();
      if (page != _currentPage) setState(() => _currentPage = page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Learning Hub',
                    style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Master strategies with live examples',
                    style: TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
            // ✅ Same style as watchlist "See All"
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LearningAllPage()),
              ),
              child: Text(
                'See All (${learningStrategies.length})',
                style: const TextStyle(
                  color: Color.fromARGB(255, 114, 70, 192),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Category Chips ─────────────────────────────────────────────────
        // ✅ selectedIndex driven by _currentPage so chips sync with swipe
        _CategoryChipBar(
          strategies: learningStrategies,
          selectedIndex: _currentPage,
          onSelect: _goToPage,
        ),

        const SizedBox(height: 16),

        // ── Reel Cards ──────────────────────────────────────────────────────
        SizedBox(
          height: 510,
          child: PageView.builder(
            controller: _pageController,
            itemCount: learningStrategies.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _currentPage == index ? 1.0 : 0.72,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _StrategyReelCard(strategy: learningStrategies[index]),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // ── Dot Indicators ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(learningStrategies.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? learningStrategies[_currentPage].accentColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // ── Latest Stock Strip ───────────────────────────────────────────────
        const _LatestStockStrip(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CATEGORY CHIP BAR  (stateless — parent drives selection)
// ═══════════════════════════════════════════════════════════

class _CategoryChipBar extends StatelessWidget {
  final List<LearningStrategy> strategies;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _CategoryChipBar({
    required this.strategies,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(strategies.length, (i) {
          final s = strategies[i];
          final isSelected = selectedIndex == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? s.accentColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? s.accentColor : Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.icon, size: 15, color: isSelected ? Colors.white : Colors.black54),
                  const SizedBox(width: 6),
                  Text(s.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.black54,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  STRATEGY REEL CARD
// ═══════════════════════════════════════════════════════════

class _StrategyReelCard extends StatelessWidget {
  final LearningStrategy strategy;
  const _StrategyReelCard({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final bool isPositive = strategy.changePercent >= 0;
    final Color accent = strategy.accentColor;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, accent.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(strategy.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(strategy.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(strategy.insight, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                child: Column(children: [
                  Text(strategy.symbol, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white, size: 11),
                    Text('${isPositive ? '+' : ''}${strategy.changePercent.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ]),
                ]),
              ),
            ]),
          ),

          // Mini Line Chart
          SizedBox(
            height: 110,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
              child: LineChart(LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [LineChartBarData(
                  spots: strategy.chartSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: accent,
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, gradient: LinearGradient(
                    colors: [accent.withOpacity(0.18), accent.withOpacity(0.0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  )),
                )],
              )),
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Text(strategy.description,
                style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.5),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),

          const Divider(height: 1, indent: 14, endIndent: 14),

          // Key Metrics
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Key Metrics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black45, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(children: [
                _MetricTile(label: 'EPS', value: '\$${strategy.earnings.toStringAsFixed(2)}', icon: Icons.attach_money_rounded, color: accent),
                const SizedBox(width: 6),
                _MetricTile(label: 'Price', value: '\$${strategy.stockPrice.toStringAsFixed(1)}', icon: Icons.price_change_rounded, color: _kPurple),
                const SizedBox(width: 6),
                _MetricTile(label: 'ROE %', value: '${strategy.returnOnEquity.toStringAsFixed(1)}%', icon: Icons.bar_chart_rounded, color: _kGreen),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _MetricTile(label: 'D/E', value: strategy.debtToEquity.toStringAsFixed(2), icon: Icons.account_balance_rounded, color: _kOrange),
                const SizedBox(width: 6),
                _MetricTile(label: 'Net Margin', value: '${strategy.netProfitMargin.toStringAsFixed(1)}%', icon: Icons.donut_small_rounded, color: _kPink),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => LearningAllPage(initialIndex: learningStrategies.indexOf(strategy)))),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [accent, accent.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                        Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                        SizedBox(height: 3),
                        Text('Learn', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  METRIC TILE
// ═══════════════════════════════════════════════════════════

class _MetricTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.black45)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  LEARNING ALL PAGE  ("See All" full page)
// ═══════════════════════════════════════════════════════════

class LearningAllPage extends StatefulWidget {
  final int initialIndex;
  const LearningAllPage({Key? key, this.initialIndex = 0}) : super(key: key);
  @override
  State<LearningAllPage> createState() => _LearningAllPageState();
}

class _LearningAllPageState extends State<LearningAllPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final s = learningStrategies[_selectedIndex];
    final accent = s.accentColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: accent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent.withOpacity(0.95), accent.withOpacity(0.6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(s.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(s.insight, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Strategy chip selector ────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: _CategoryChipBar(
                    strategies: learningStrategies,
                    selectedIndex: _selectedIndex,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Video Placeholder ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _VideoPlaceholder(strategy: s),
                ),

                const SizedBox(height: 24),

                // ── About ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('About this Strategy', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(s.description, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.6)),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Earnings Chart ──────────────────────────────────────────
                _SectionTitle(label: 'Earnings'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EarningsChart(strategy: s),
                ),

                const SizedBox(height: 8),

                // EPS legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    _LegendDot(color: accent, label: 'Actual EPS'),
                    const SizedBox(width: 20),
                    _LegendDot(color: accent.withOpacity(0.35), label: 'Estimated EPS'),
                  ]),
                ),

                const SizedBox(height: 24),

                // ── Financials Chart ────────────────────────────────────────
                _SectionTitle(label: 'Financials'),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Row(children: [
                    _LegendBox(color: const Color(0xFF1B5E20), label: 'Revenue'),
                    const SizedBox(width: 14),
                    _LegendBox(color: const Color(0xFF388E3C), label: 'Gross Profit'),
                    const SizedBox(width: 14),
                    _LegendBox(color: const Color(0xFFA5D6A7), label: 'Net Income'),
                    const SizedBox(width: 14),
                    _LegendLine(color: Colors.black87, label: 'Net Margin'),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FinancialsChart(strategy: s),
                ),

                const SizedBox(height: 24),

                // ── Trading Trends Chart ────────────────────────────────────
                _SectionTitle(label: 'Trading Trends'),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
                  child: Row(children: [
                    _LegendBox(color: const Color(0xFF388E3C), label: 'Net Buy'),
                    const SizedBox(width: 14),
                    _LegendBox(color: const Color(0xFFD32F2F), label: 'Net Sell'),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _TradingTrendsChart(strategy: s),
                ),

                const SizedBox(height: 24),

                // ── Full Metrics Grid ───────────────────────────────────────
                _SectionTitle(label: 'Key Fundamentals'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _FullMetricsGrid(strategy: s),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Video Placeholder ─────────────────────────────────────────────────────────

class _VideoPlaceholder extends StatelessWidget {
  final LearningStrategy strategy;
  const _VideoPlaceholder({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final accent = strategy.accentColor;
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [Colors.black87, accent.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Waveform lines decoration
          ...List.generate(18, (i) {
            final h = 16.0 + Random(i * 7).nextDouble() * 55;
            return Positioned(
              left: 18.0 + i * 18,
              bottom: 55,
              child: Container(
                width: 3,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
          Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 64),
              const SizedBox(height: 10),
              Text('${strategy.title} — Video Lesson',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          // Progress bar
          Positioned(
            bottom: 14, left: 14, right: 14,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                Text('0:00', style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text('4:32', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(accent),
                  minHeight: 4,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EARNINGS CHART  (Robinhood-style scatter dots per quarter)
// ═══════════════════════════════════════════════════════════

class _EarningsChart extends StatelessWidget {
  final LearningStrategy strategy;
  const _EarningsChart({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final accent = strategy.accentColor;
    final data = strategy.earningsData;

    // Y range
    final allVals = data.expand((e) => [e.estimated, e.actual]).toList();
    final minY = (allVals.reduce((a, b) => a < b ? a : b) - 0.3).clamp(0.0, 999.0);
    final maxY = allVals.reduce((a, b) => a > b ? a : b) + 0.5;

    final quarters = data.map((e) => e.quarter).toList();

    // Actual EPS spots (larger, darker)
    final actualSpots = List.generate(data.length,
        (i) => ScatterSpot(i.toDouble(), data[i].actual,
            dotPainter: FlDotCirclePainter(radius: 8, color: accent)));

    // Estimated EPS spots (smaller, lighter)
    final estimatedSpots = List.generate(data.length,
        (i) => ScatterSpot(i.toDouble(), data[i].estimated,
            dotPainter: FlDotCirclePainter(radius: 5.5, color: accent.withOpacity(0.35))));

    return SizedBox(
      height: 180,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: [...actualSpots, ...estimatedSpots],
          minX: -0.5, maxX: data.length - 0.5,
          minY: minY,  maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (maxY - minY) / 4,
                getTitlesWidget: (v, m) => Text(
                  '\$${v.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= quarters.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(quarters[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, color: Colors.black45)),
                  );
                },
              ),
            ),
          ),
          scatterTouchData: ScatterTouchData(enabled: false),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FINANCIALS CHART  (Robinhood grouped bars + net margin line)
// ═══════════════════════════════════════════════════════════

class _FinancialsChart extends StatelessWidget {
  final LearningStrategy strategy;
  const _FinancialsChart({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final data = strategy.financialsData;
    final quarters = data.map((e) => e.quarter).toList();

    final maxRev = data.map((e) => e.revenue).reduce((a, b) => a > b ? a : b);

    final barGroups = List.generate(data.length, (i) {
      final f = data[i];
      return BarChartGroupData(
        x: i,
        barsSpace: 3,
        barRods: [
          BarChartRodData(toY: f.revenue,    color: const Color(0xFF1B5E20), width: 7, borderRadius: BorderRadius.circular(3)),
          BarChartRodData(toY: f.grossProfit, color: const Color(0xFF388E3C), width: 7, borderRadius: BorderRadius.circular(3)),
          BarChartRodData(toY: f.netIncome,  color: const Color(0xFFA5D6A7), width: 7, borderRadius: BorderRadius.circular(3)),
        ],
      );
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxRev * 1.25,
          minY: 0,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, m) => Text(
                  '${v.toStringAsFixed(0)}B',
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= quarters.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(quarters[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 9, color: Colors.black45)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TRADING TRENDS CHART  (Positive / Negative bars)
// ═══════════════════════════════════════════════════════════

class _TradingTrendsChart extends StatelessWidget {
  final LearningStrategy strategy;
  const _TradingTrendsChart({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final data = strategy.tradingTrends;
    final dates = data.map((e) => e.date).toList();

    const maxAbsY = 45.0;

    final barGroups = List.generate(data.length, (i) {
      final t = data[i];
      final isPos = t.netPercent >= 0;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          fromY: isPos ? 0 : t.netPercent,
          toY: isPos ? t.netPercent : 0,
          color: isPos ? const Color(0xFF388E3C) : const Color(0xFFD32F2F),
          width: 14,
          borderRadius: BorderRadius.circular(3),
        ),
      ]);
    });

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          minY: -maxAbsY,
          maxY: maxAbsY,
          baselineY: 0,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) {
              if (v == 0) return FlLine(color: Colors.grey.shade600, strokeWidth: 1.5);
              return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 20,
                getTitlesWidget: (v, m) => Text(
                  '${v.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 9, color: Colors.black45),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, m) {
                  final i = v.toInt();
                  if (i < 0 || i >= dates.length) return const SizedBox();
                  final parts = dates[i].split(' ');
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(parts.length >= 2 ? '${parts[0]}\n${parts[1]}' : dates[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 8, color: Colors.black45)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final val = rod.toY != 0 ? rod.toY : rod.fromY;
                final isPos = val >= 0;
                return BarTooltipItem(
                  '${isPos ? '+' : ''}${val.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FULL METRICS GRID
// ═══════════════════════════════════════════════════════════

class _FullMetricsGrid extends StatelessWidget {
  final LearningStrategy strategy;
  const _FullMetricsGrid({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final s = strategy;
    final accent = s.accentColor;
    final items = [
      _FundItem('Earnings (EPS)', '\$${s.earnings.toStringAsFixed(2)}', Icons.attach_money_rounded, accent),
      _FundItem('Stock Price', '\$${s.stockPrice.toStringAsFixed(2)}', Icons.price_change_rounded, _kPurple),
      _FundItem('Return on Equity', '${s.returnOnEquity.toStringAsFixed(1)}%', Icons.bar_chart_rounded, _kGreen),
      _FundItem('Debt / Equity', s.debtToEquity.toStringAsFixed(2), Icons.account_balance_rounded, _kOrange),
      _FundItem('Net Profit Margin', '${s.netProfitMargin.toStringAsFixed(1)}%', Icons.donut_small_rounded, _kPink),
      _FundItem('Change Today', '${s.changePercent >= 0 ? '+' : ''}${s.changePercent.toStringAsFixed(1)}%',
          s.changePercent >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          s.changePercent >= 0 ? _kGreen : _kPink),
    ];

    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(item.icon, color: item.color, size: 16),
          const SizedBox(height: 6),
          Text(item.value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(item.label, style: const TextStyle(fontSize: 9, color: Colors.black45), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      )).toList(),
    );
  }
}

class _FundItem {
  final String label, value;
  final IconData icon;
  final Color color;
  _FundItem(this.label, this.value, this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════
//  SHARED HELPERS
// ═══════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Row(children: [
      Container(width: 4, height: 18, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(2))),
      Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
    ]),
  );
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
  ]);
}

class _LegendBox extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendBox({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
  ]);
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendLine({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 16, height: 2, color: color),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
  ]);
}

// ═══════════════════════════════════════════════════════════
//  LATEST STOCK STRIP
// ═══════════════════════════════════════════════════════════

class _LatestStockStrip extends StatelessWidget {
  const _LatestStockStrip();

  static const _stocks = [
    {'sym': 'AAPL', 'price': '\$172.50', 'chg': '+5.6%', 'pos': true},
    {'sym': 'MSFT', 'price': '\$322.00', 'chg': '+4.2%', 'pos': true},
    {'sym': 'NVDA', 'price': '\$618.00', 'chg': '+3.0%', 'pos': true},
    {'sym': 'TSLA', 'price': '\$240.00', 'chg': '+6.8%', 'pos': true},
    {'sym': 'AMZN', 'price': '\$189.40', 'chg': '-1.2%', 'pos': false},
    {'sym': 'META', 'price': '\$493.50', 'chg': '+2.5%', 'pos': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      Row(children: [
        Container(width: 4, height: 18, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(2))),
        const Text('Latest Stocks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
      ]),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: _stocks.map((s) {
          final isPos = s['pos'] as bool;
          final color = isPos ? _kGreen : _kPink;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['sym'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(s['price'] as String, style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: color, size: 12),
                Text(s['chg'] as String, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          );
        }).toList()),
      ),
    ]);
  }
}
