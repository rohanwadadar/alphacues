import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:test_project/features/profile/profile.dart';
import 'package:test_project/features/notifications/notification.dart';
import 'package:test_project/core/config/mock_data.dart';
import 'package:test_project/features/portfolio/learning_section.dart';

// Enums
enum TransactionType { buy, sell }
enum HoldingType { stock, crypto, forex }

// Models
class Transaction {
  final String id;
  final TransactionType type;
  final String symbol;
  final String name;
  final double amount;
  final double shares;
  final DateTime date;
  final String currency;

  Transaction({
    required this.id,
    required this.type,
    required this.symbol,
    required this.name,
    required this.amount,
    required this.shares,
    required this.date,
    required this.currency,
  });
}

class Holding {
  final String symbol;
  final String name;
  final double value;
  final double change;
  final double changePercentage;
  final IconData icon;
  final HoldingType type;

  Holding({
    required this.symbol,
    required this.name,
    required this.value,
    required this.change,
    required this.changePercentage,
    required this.icon,
    required this.type,
  });
}

// Main App
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portfolio App',
      theme: ThemeData.light().copyWith(
        primaryColor: Color.fromARGB(255, 112, 97, 243),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
        ),
        cardColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(primary: Color.fromARGB(255, 112, 97, 243), secondary: Colors.purpleAccent, background: Colors.white),
      ),
      home: PortfolioPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PortfolioPage extends StatefulWidget {
  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  bool _showBalance = false;
  final List<Transaction> transactions = [
    Transaction(
      id: '1',
      type: TransactionType.buy,
      symbol: 'TSLA',
      name: 'Tesla, Inc.',
      amount: 244.40,
      shares: 10,
      date: DateTime.now().subtract(Duration(days: 1)),
      currency: 'USD',
    ),
    Transaction(
      id: '2',
      type: TransactionType.sell,
      symbol: 'AMRI',
      name: 'PT. Atma Merapi',
      amount: 3867.00,
      shares: 100,
      date: DateTime.now().subtract(Duration(days: 2)),
      currency: 'IDR',
    ),
  ];

  final List<Holding> holdings = [
    Holding(
      symbol: 'IDR/USD',
      name: 'Rupiah / U.S. Dollar',
      value: 139.3550,
      change: 0.0025,
      changePercentage: 0.36,
      icon: Icons.currency_exchange,
      type: HoldingType.forex,
    ),
    Holding(
      symbol: 'TSLA',
      name: 'Tesla, Inc.',
      value: 244.40,
      change: 9.54,
      changePercentage: 4.06,
      icon: Icons.directions_car,
      type: HoldingType.stock,
    ),
  ];

  final List<Holding> watchlist = [
    Holding(
      symbol: 'NVDA',
      name: 'NVIDIA Corporation',
      value: 721.28,
      change: 15.43,
      changePercentage: 2.18,
      icon: Icons.memory,
      type: HoldingType.stock,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceSection(),
                const SizedBox(height: 16),
                _buildPerformanceSection(),
                const SizedBox(height: 28),
                _buildQuickActions(),
                const SizedBox(height: 24),
                _buildTransactionHistory(),
                const SizedBox(height: 24),
                _buildHoldingsSection(),
                const SizedBox(height: 24),
                _buildWatchlistSection(),
                const SizedBox(height: 28),
                const LearningSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    return GestureDetector(
      onTap: () => setState(() => _showBalance = !_showBalance),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Balance',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                Icon(
                  _showBalance ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showBalance ? '\$${MockData.portfolioTotalValue.toStringAsFixed(2)}' : '••••••••',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return CombinedPortfolioPerformance(showBalance: _showBalance);
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(Icons.add_circle_outline, 'Deposit'),
        _buildActionButton(Icons.shopping_cart_outlined, 'Buy'),
        _buildActionButton(Icons.sell_outlined, 'Sell'),
        _buildActionButton(Icons.swap_horiz_outlined, 'Transfer'),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: Color.fromARGB(255, 112, 97, 243), size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
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
        ...transactions.map((transaction) => _buildTransactionItem(transaction)),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    bool isPositive = transaction.type == TransactionType.sell;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type == TransactionType.buy ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.currency}${(transaction.amount * transaction.shares).toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                transaction.date.toString().substring(0, 10),
                style: TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsSection() {
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
                style: TextStyle(color: Color.fromARGB(255, 112, 97, 243)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...holdings.map((holding) => _buildHoldingItem(holding)),
      ],
    );
  }

  Widget _buildWatchlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Watchlist',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Add More',
                style: TextStyle(color: Color.fromARGB(255, 112, 97, 243)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...watchlist.map((holding) => _buildHoldingItem(holding)),
      ],
    );
  }

  Widget _buildHoldingItem(Holding holding) {
    bool isPositive = holding.change >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(holding.type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              holding.icon,
              color: _getTypeColor(holding.type),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holding.symbol,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  holding.name,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${holding.value.toStringAsFixed(2)}',
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
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${holding.change.toStringAsFixed(2)} (${holding.changePercentage.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 14,
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

  Color _getTypeColor(HoldingType type) {
    switch (type) {
      case HoldingType.stock:
        return Colors.blueAccent;
      case HoldingType.crypto:
        return Colors.orangeAccent;
      case HoldingType.forex:
        return Colors.green;
      default:
        return Colors.black;
    }
  }
}

class _PortfolioPerformanceData {
  final String timeframe;
  final double portfolioValue;
  final List<FlSpot> spots;

  _PortfolioPerformanceData({
    required this.timeframe,
    required this.portfolioValue,
    required this.spots,
  });

  Map<String, double> calculateProfitAndReturn(double targetValue) {
    if (spots.isEmpty || spots.first.y == 0) return {"profit": 0, "return": 0};
    double totalProfit = targetValue - spots.first.y;
    double returnPercentage = (totalProfit / spots.first.y) * 100;
    return {"profit": totalProfit, "return": returnPercentage};
  }

  double calculateChange24h(double tappedX) {
    if (spots.isEmpty) return 0;

    FlSpot tappedSpot = spots.reduce(
        (prev, curr) => (curr.x - tappedX).abs() < (prev.x - tappedX).abs() ? curr : prev);

    if (timeframe == "1D") {
      return tappedSpot.y - spots.first.y;
    }

    FlSpot? previousSpot = spots.where((spot) => spot.x <= tappedSpot.x - 1).fold<FlSpot?>(null, (prev, curr) {
      if (prev == null) return curr;
      return (tappedSpot.x - 1 - curr.x).abs() < (tappedSpot.x - 1 - prev.x).abs() ? curr : prev;
    });

    return previousSpot != null ? tappedSpot.y - previousSpot.y : 0;
  }
}

class CombinedPortfolioPerformance extends StatefulWidget {
  final bool showBalance;

  const CombinedPortfolioPerformance({Key? key, required this.showBalance}) : super(key: key);

  @override
  CombinedPortfolioPerformanceState createState() => CombinedPortfolioPerformanceState();
}

class CombinedPortfolioPerformanceState extends State<CombinedPortfolioPerformance> {
  String selectedTimeframe = "1D";
  double selectedValue = MockData.portfolioTotalValue; // ✅ Initialized to central mock value
  String selectedDate = "";
  bool showGridLine = false;
  double gridLineX = 0;
  double? touchX;

  double liveProfit = MockData.dailyChange;
  double liveReturnPercentage = MockData.dailyChangePercentage;
  double liveChange24h = MockData.dailyChange;

  final Map<String, _PortfolioPerformanceData> timeFrameData = {
    "1D": _PortfolioPerformanceData(
      timeframe: "1D",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 15665.44),
        FlSpot(0.5, 15700.00),
        FlSpot(1, 15750.00),
        FlSpot(1.5, 15800.00),
        FlSpot(2, 15850.00),
        FlSpot(2.5, 15750.00),
        FlSpot(3, 15800.00),
        FlSpot(3.5, 15850.00),
        FlSpot(4, 16050.45),
        FlSpot(4.5, 16050.45),
      ],
    ),
    "5D": _PortfolioPerformanceData(
      timeframe: "5D",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 15600.00),
        FlSpot(0.4, 15650.00),
        FlSpot(0.8, 15700.00),
        FlSpot(1.2, 15725.00),
        FlSpot(1.6, 15775.00),
        FlSpot(2.0, 15800.00),
        FlSpot(2.4, 15825.00),
        FlSpot(2.8, 15850.00),
        FlSpot(3.2, 15875.00),
        FlSpot(3.6, 15890.00),
        FlSpot(4.0, 16050.45),
      ],
    ),
    "1M": _PortfolioPerformanceData(
      timeframe: "1M",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 15200.00),
        FlSpot(0.5, 15300.00),
        FlSpot(1.0, 15400.00),
        FlSpot(1.5, 15500.00),
        FlSpot(2.0, 15600.00),
        FlSpot(2.5, 15700.00),
        FlSpot(3.0, 15800.00),
        FlSpot(3.5, 15850.00),
        FlSpot(4.0, 16050.45),
      ],
    ),
    "3M": _PortfolioPerformanceData(
      timeframe: "3M",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 14800.00),
        FlSpot(0.5, 14900.00),
        FlSpot(1.0, 15000.00),
        FlSpot(1.5, 15200.00),
        FlSpot(2.0, 15400.00),
        FlSpot(2.5, 15500.00),
        FlSpot(3.0, 15700.00),
        FlSpot(3.5, 15800.00),
        FlSpot(4.0, 16050.45),
      ],
    ),
    "YTD": _PortfolioPerformanceData(
      timeframe: "YTD",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 14000.00),
        FlSpot(0.5, 14200.00),
        FlSpot(1.0, 14500.00),
        FlSpot(1.5, 14700.00),
        FlSpot(2.0, 14900.00),
        FlSpot(2.5, 15200.00),
        FlSpot(3.0, 15400.00),
        FlSpot(3.5, 15600.00),
        FlSpot(4.0, 16050.45),
      ],
    ),
    "1Y": _PortfolioPerformanceData(
      timeframe: "1Y",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 13500.00),
        FlSpot(0.5, 13800.00),
        FlSpot(1.0, 14100.00),
        FlSpot(1.5, 14400.00),
        FlSpot(2.0, 14700.00),
        FlSpot(2.5, 15000.00),
        FlSpot(3.0, 15300.00),
        FlSpot(3.5, 15600.00),
        FlSpot(4.0, 16050.45),
      ],
    ),
    "MAX": _PortfolioPerformanceData(
      timeframe: "MAX",
      portfolioValue: 16050.45,
      spots: [
        FlSpot(0, 8000.00),
        FlSpot(0.5, 9000.00),
        FlSpot(1.0, 10000.00),
        FlSpot(1.5, 11000.00),
        FlSpot(2.0, 12000.00),
        FlSpot(2.5, 13000.00),
        FlSpot(3.0, 14000.00),
        FlSpot(3.5, 15000.00),
        FlSpot(4.0, 16050.45),
      ],
    ),
  };

  _PortfolioPerformanceData get currentData => timeFrameData[selectedTimeframe]!;

  @override
  void initState() {
    super.initState();
    // ✅ Set the real last-spot value so graph shows current price, not $0
    selectedValue = currentData.spots.last.y;
    _updateMetrics(currentData.spots.last);
  }

  void _changeTimeFrame(String timeFrame) {
    setState(() {
      selectedTimeframe = timeFrame;
      // ✅ Always reset to the last real data point when switching timeframes
      selectedValue = currentData.spots.last.y;
      _updateMetrics(currentData.spots.last);
      selectedDate = "";
      showGridLine = false;
      touchX = null;
    });
  }

  void _updateMetrics(FlSpot spot) {
    final profitReturn = currentData.calculateProfitAndReturn(spot.y);
    final change24h = currentData.calculateChange24h(spot.x);

    liveProfit = profitReturn["profit"]!;
    liveReturnPercentage = profitReturn["return"]!;
    liveChange24h = change24h;
  }

  String getFormattedTime(String timeframe, double x) {
    switch (timeframe) {
      case "1D":
        final times = [
          "9:30 AM",
          "10:15 AM",
          "11:00 AM",
          "11:45 AM",
          "12:30 PM",
          "1:15 PM",
          "2:00 PM",
          "2:45 PM",
          "3:30 PM",
          "4:00 PM"
        ];
        int index = (x * 2).round();
        return index < times.length ? times[index] : times.last;
      case "5D":
        return "Day ${(x + 1).round()}";
      case "1M":
        return "Week ${(x + 1).round()}";
      default:
        return x.toStringAsFixed(1);
    }
  }

  // Dynamic accent: green if current is above first point, red if below
  Color get _dynamicAccent {
    final spots = currentData.spots;
    if (spots.isEmpty) return Colors.green;
    return selectedValue >= spots.first.y ? Colors.green : Colors.red;
  }

  Widget _buildTimeframeButton(String timeFrame) {
    final isSelected = selectedTimeframe == timeFrame;

    return GestureDetector(
      onTap: () => _changeTimeFrame(timeFrame),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? _dynamicAccent : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          timeFrame,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: const Text(
                    'Total Portfolio Value',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.showBalance ? '\$${selectedValue.toStringAsFixed(2)}' : '••••••••',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    liveChange24h >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: _dynamicAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${liveChange24h >= 0 ? '+' : ''}\$${liveChange24h.toStringAsFixed(2)} (${liveReturnPercentage >= 0 ? '+' : ''}${liveReturnPercentage.toStringAsFixed(2)}%) Today',
                    style: TextStyle(
                      color: _dynamicAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingVerticalLine: (value) {
                        if (showGridLine && value == gridLineX) {
                          return FlLine(
                            color: Colors.black.withOpacity(0.8),
                            strokeWidth: 2,
                            dashArray: [4, 4],
                          );
                        }
                        return FlLine(color: Colors.transparent, strokeWidth: 0);
                      },
                      drawHorizontalLine: false,
                    ),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: currentData.spots,
                        isCurved: true,
                        color: _dynamicAccent,
                        barWidth: 2,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              _dynamicAccent.withOpacity(0.15),
                              _dynamicAccent.withOpacity(0.0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                        return [];
                      },
                      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                        if ((event is FlPanDownEvent || event is FlPanUpdateEvent || event is FlTapDownEvent) &&
                            response?.lineBarSpots != null &&
                            response!.lineBarSpots!.isNotEmpty) {
                          final spot = response.lineBarSpots![0];
                          final profitReturn = currentData.calculateProfitAndReturn(spot.y);
                          final change24h = currentData.calculateChange24h(spot.x);

                          setState(() {
                            selectedValue = spot.y;
                            selectedDate = getFormattedTime(selectedTimeframe, spot.x);
                            liveProfit = profitReturn["profit"]!;
                            liveReturnPercentage = profitReturn["return"]!;
                            liveChange24h = change24h;
                            showGridLine = true;
                            gridLineX = spot.x;
                            touchX = event.localPosition?.dx;
                          });
                        } else if (event is FlPanEndEvent || event is FlTapUpEvent || event is FlLongPressEnd) {
                          final profitReturn = currentData.calculateProfitAndReturn(currentData.spots.last.y);
                          final change24h = currentData.calculateChange24h(currentData.spots.last.x);

                          setState(() {
                            selectedValue = currentData.portfolioValue;
                            selectedDate = "";
                            liveProfit = profitReturn["profit"]!;
                            liveReturnPercentage = profitReturn["return"]!;
                            liveChange24h = change24h;
                            showGridLine = false;
                            touchX = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (touchX != null && selectedDate.isNotEmpty)
                Positioned(
                  left: (touchX! - 30).clamp(10.0, MediaQuery.of(context).size.width - 90),
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      selectedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: timeFrameData.keys.map((timeFrame) => _buildTimeframeButton(timeFrame)).toList(),
        ),
      ],
    );
  }
}