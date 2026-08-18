import 'package:flutter/material.dart';
import 'dart:math' as math;
// Ensure these imports match your project filenames
import 'package:test_project/features/notifications/notification.dart'; 
import 'package:test_project/features/wishlist/wishlist.dart'; // This file should contain the TradingDashboard class
import 'package:test_project/core/config/mock_data.dart';
import 'npref.dart' hide NotificationScreen;

class InvestmentProfile extends StatefulWidget {
  const InvestmentProfile({super.key});

  @override
  State<InvestmentProfile> createState() => _InvestmentProfileState();
}

class _InvestmentProfileState extends State<InvestmentProfile> with SingleTickerProviderStateMixin {
  // Theme Colors
  final Color primaryPurple = const Color.fromARGB(255, 112, 97, 243);
  final Color successGreen = const Color.fromARGB(255, 78, 187, 63);
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Strategy Data (Replace with API calls later)
  final List<Map<String, dynamic>> strategies = [
    {
      "name": "Growth Strategy",
      "value": 12658.77,
      "color": const Color(0xFF32D74B),
      "change": "+4.06%",
      "icon": Icons.trending_up,
      "allocation": 0.0 // Will be calculated
    },
    {
      "name": "Dividend Yield",
      "value": 3241.23,
      "color": const Color(0xFFFF9F0A),
      "change": "+1.20%",
      "icon": Icons.account_balance_wallet,
      "allocation": 0.0
    },
    {
      "name": "Penny Stocks",
      "value": 150.45,
      "color": const Color(0xFF64D2FF),
      "change": "-0.50%",
      "icon": Icons.show_chart,
      "allocation": 0.0
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateAllocations();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateAllocations() {
    double total = totalPortfolioValue;
    for (var strategy in strategies) {
      strategy['allocation'] = (strategy['value'] / total * 100);
    }
  }

  double get totalPortfolioValue {
    return MockData.portfolioTotalValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            SliverAppBar(
              expandedHeight: 80,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFFF8F9FA),
              elevation: 0,
              // Title shown when the bar is collapsed (scrolled up)
              title: const Text(
                "Investment",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Only show title text when collapsed
              centerTitle: false,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.notifications_outlined, color: primaryPurple, size: 20),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NotificationScreen()),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              flexibleSpace: const FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: SizedBox.shrink(),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Portfolio Value Card
                      _buildPortfolioValueCard(),
                      
                      const SizedBox(height: 24),

                      // Chart and Allocation Section
                      _buildChartSection(),

                      const SizedBox(height: 32),

                      // Strategy Breakdown
                      _buildSectionHeader("Holdings", "3 active strategies"),
                      const SizedBox(height: 16),
                      ...strategies.map((strategy) => _buildModernStrategyCard(strategy)),

                      const SizedBox(height: 32),

                      // Market Insight Card
                      _buildMarketInsightCard(),

                      const SizedBox(height: 24),

                      // Financial Education
                      _buildSectionHeader("Learn", "Investment basics"),
                      const SizedBox(height: 16),
                      _buildEducationCard(
                        "Dividend Yield",
                        "Understanding dividend returns",
                        "A financial ratio showing the percentage of a company's share price paid out in dividends annually. It measures cash flow return on investment.",
                        Icons.payments_outlined,
                        const Color(0xFFFF9F0A),
                      ),
                      const SizedBox(height: 12),
                      _buildEducationCard(
                        "Growth Strategy",
                        "Capital appreciation focus",
                        "Focuses on increasing investor capital through companies showing above-average growth in revenues and profits.",
                        Icons.trending_up,
                        const Color(0xFF32D74B),
                      ),
                      const SizedBox(height: 12),
                      _buildEducationCard(
                        "Market Volatility",
                        "Risk measurement",
                        "Statistical measure of return dispersion for securities or market indices. Higher volatility typically indicates higher risk.",
                        Icons.candlestick_chart,
                        const Color(0xFF64D2FF),
                      ),

                      const SizedBox(height: 32),

                      // Action Button
                      _buildActionButton(),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioValueCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total Portfolio Value",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "USD",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "\$${totalPortfolioValue.toStringAsFixed(2)}",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.arrow_upward, color: successGreen, size: 16),
            const SizedBox(width: 4),
            Text(
              "\$342.15",
              style: TextStyle(
                color: successGreen,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "(1.34%)",
              style: TextStyle(
                color: successGreen,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "today",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Asset Allocation",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: ModernRingPainter(strategies: strategies),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${strategies.length}",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "Strategies",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: strategies.map((strategy) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: strategy['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "${strategy['allocation'].toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  strategy['name'],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStrategyCard(Map<String, dynamic> strategy) {
    bool isPositive = strategy['change'].startsWith('+');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (strategy['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              strategy['icon'],
              color: strategy['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strategy['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "${strategy['allocation'].toStringAsFixed(1)}% of portfolio",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "\$${strategy['value'].toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                strategy['change'],
                style: TextStyle(
                  color: isPositive ? successGreen : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: primaryPurple, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Portfolio Insight",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "AI",
                  style: TextStyle(
                    color: primaryPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Diversification is key to long-term success. Your 'Growth Strategy' currently holds the majority of assets. Consider balancing with stable 'Dividend Yield' assets to reduce overall portfolio risk.",
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(String title, String subtitle, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WatchlistSettingsScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color.fromARGB(255, 114, 70, 192),
          side: const BorderSide(color: Color.fromARGB(255, 114, 70, 192)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Watchlist Settings",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Modern Ring Chart
class ModernRingPainter extends CustomPainter {
  final List<Map<String, dynamic>> strategies;
  ModernRingPainter({required this.strategies});

  @override
  void paint(Canvas canvas, Size size) {
    double strokeWidth = 14.0;
    Rect rect = Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);
    double startAngle = -math.pi / 2; // Start at the top
    double totalValue = strategies.fold(0, (sum, item) => sum + item['value']);

    if (totalValue <= 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    // Background circle
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = Colors.grey.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    for (var strategy in strategies) {
      if (strategy['value'] <= 0) continue;
      
      final paint = Paint()
        ..color = strategy['color']
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      double sweepAngle = (strategy['value'] / totalValue) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, sweepAngle - 0.08, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}