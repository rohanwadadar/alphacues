import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:test_project/features/wishlist/wishlist.dart';
import 'package:test_project/features/notifications/alerts.dart';
import 'package:test_project/features/notifications/notification.dart';

void main() => runApp(StockScreenerApp());

class StockScreenerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enhanced Stock Screener',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: StockScreenerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AlpacaApiService {
  static const String baseUrl = 'https://data.alpaca.markets';
  static const String tradingUrl = 'https://paper-api.alpaca.markets';
  static const String apiKeyId = 'PK6O4W6SBWAVCTZKQRPC';
  static const String apiSecret = 'e1rimphcUKc7SmJv9N3gla0oiMPgP8sstxp0Vk7D';

  static Map<String, String> get headers => {
    'APCA-API-KEY-ID': apiKeyId,
    'APCA-API-SECRET-KEY': apiSecret,
    'accept': 'application/json',
  };

  static Future<List<Map<String, dynamic>>> getActiveAssets() async {
    try {
      final url = '$tradingUrl/v2/assets?status=active&asset_class=us_equity';
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return list
            .where((asset) => asset['tradable'] == true && asset['status'] == 'active')
            .take(50)
            .map<Map<String, dynamic>>((asset) => {
                  'symbol': asset['symbol'],
                  'name': asset['name'] ?? asset['symbol'],
                  'exchange': asset['exchange'] ?? 'NASDAQ',
                })
            .toList();
      }
    } catch (e) {
      print('API Error: $e');
    }
    return _getFallbackStocks();
  }

  static List<Map<String, dynamic>> _getFallbackStocks() {
    return [
      {'symbol': 'TSLA', 'name': 'Tesla Inc', 'exchange': 'NASDAQ'},
      {'symbol': 'AVGO', 'name': 'Broadcom Inc', 'exchange': 'NASDAQ'},
      {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'exchange': 'NASDAQ'},
      {'symbol': 'META', 'name': 'Meta Platforms', 'exchange': 'NASDAQ'},
      {'symbol': 'AMD', 'name': 'Advanced Micro Devices', 'exchange': 'NASDAQ'},
      {'symbol': 'MU', 'name': 'Micron Technology', 'exchange': 'NASDAQ'},
      {'symbol': 'AAPL', 'name': 'Apple Inc', 'exchange': 'NASDAQ'},
      {'symbol': 'AMZN', 'name': 'Amazon.com Inc', 'exchange': 'NASDAQ'},
      {'symbol': 'GOOGL', 'name': 'Alphabet Inc', 'exchange': 'NASDAQ'},
      {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'exchange': 'NASDAQ'},
    ];
  }
}

class StockScreenerPage extends StatefulWidget {
  final String initialStrategy;
  final Map<String, dynamic>? initialFilters;

  const StockScreenerPage({
    Key? key,
    this.initialStrategy = 'Breakout',
    this.initialFilters,
  }) : super(key: key);

  @override
  _StockScreenerPageState createState() => _StockScreenerPageState();
}

class _StockScreenerPageState extends State<StockScreenerPage> {
  List<Map<String, dynamic>> allStocks = [];
  List<Map<String, dynamic>> filteredStocks = [];
  bool isLoading = false;
  late String selectedStrategy;
  DateTime lastUpdated = DateTime.now();

  // Wishlist management
  List<String> wishlists = ["My First List", "Options Watchlist", "Growth Stocks"];
  String selectedWishlist = "My First List";

  // Default filter presets per strategy
  static Map<String, dynamic> _defaultFiltersForStrategy(String strategy) {
    switch (strategy) {
      case 'Bounce':
        return {
          'strategy': 'Bounce',
          'price': 'Any',
          'marketCap': 'Mid',
          'change': 'Down 5%',
          'peRatio': 'Under 25',
          'roe': 'Over 10%',
          'epsGrowth': 'Over 10%',
          'netProfitMargin': 'Over 10%',
          'debtEquity': 'Under 1',
          'avgVolume': 'Over 500K',
          'volatility': 'Over 2',
          'relativeVolume': 'Over 3',
          'currentVolume': 'Over 500K',
          'rsi': 'Oversold (30)',
          'sma20': 'Price below SMA20',
          'sma50': 'Price below SMA50',
          'sma200': 'Price below SMA200',
          'highLow': 'New Low',
        };
      case 'Moving Average':
        return {
          'strategy': 'Momentum',
          'price': 'Over \$50',
          'marketCap': '+Mid (over \$2bln)',
          'change': 'Up 1%',
          'peRatio': 'Under 25',
          'roe': 'Over 15%',
          'epsGrowth': 'Over 25%',
          'netProfitMargin': 'Over 20%',
          'debtEquity': 'Under 0.5',
          'avgVolume': 'Over 1M',
          'volatility': 'Over 1.5',
          'relativeVolume': 'Over 1.5',
          'currentVolume': 'Over 500K',
          'rsi': '30-70',
          'sma20': 'Price above SMA20',
          'sma50': 'Price above SMA50',
          'sma200': 'Price above SMA200',
          'highLow': '52W High',
        };
      case 'Price Change':
        return {
          'strategy': 'Momentum',
          'price': 'Any',
          'marketCap': 'Mid',
          'change': 'Up 5%',
          'peRatio': 'Under 15',
          'roe': 'Over 10%',
          'epsGrowth': 'Over 10%',
          'netProfitMargin': 'Over 10%',
          'debtEquity': 'Under 1',
          'avgVolume': 'Over 100K',
          'volatility': 'Over 2',
          'relativeVolume': 'Over 2',
          'currentVolume': 'Over 200K',
          'rsi': '30-70',
          'sma20': 'Price above SMA20',
          'sma50': 'Any',
          'sma200': 'Any',
          'highLow': 'New High',
        };
      case 'Breakout':
      default:
        return {
          'strategy': 'Breakout',
          'price': 'Under \$5',
          'marketCap': '+Mid (over \$2bln)',
          'change': 'Up 1%',
          'peRatio': 'Under 5',
          'roe': 'Over 10%',
          'epsGrowth': 'Over 10%',
          'netProfitMargin': 'Over 20%',
          'debtEquity': 'Under 1',
          'avgVolume': 'Over 100K',
          'volatility': 'Over 1.5',
          'relativeVolume': 'Over 2',
          'currentVolume': 'Over 200K',
          'rsi': 'Oversold (30)',
          'sma20': 'Price above SMA20',
          'sma50': 'Price above SMA50',
          'sma200': 'Price above SMA200',
          'highLow': 'New High',
        };
    }
  }

  late Map<String, dynamic> filters;

  final Map<String, List<String>> filterOptions = {
    'strategy': ['Breakout', 'Growth', 'Value', 'Momentum', 'Dividend'],
    'price': ['Any', 'Under \$1', 'Under \$5', 'Under \$10', 'Over \$50'],
    'marketCap': ['Nano', 'Micro', 'Small', 'Mid', '+Mid (over \$2bln)', 'Large', 'Mega'],
    'change': ['Any', 'Up 1%', 'Up 5%', 'Up 10%', 'Down 1%', 'Down 5%'],
    'peRatio': ['Any', 'Under 5', 'Under 15', 'Under 25', 'Over 25'],
    'roe': ['Any', 'Over 10%', 'Over 15%', 'Over 20%', 'Over 25%'],
    'epsGrowth': ['Any', 'Over 10%', 'Over 25%', 'Over 50%', 'Negative'],
    'netProfitMargin': ['Any', 'Over 10%', 'Over 20%', 'Over 30%', 'Negative'],
    'debtEquity': ['Any', 'Under 0.1', 'Under 0.5', 'Under 1', 'Over 1'],
    'avgVolume': ['Any', 'Over 50K', 'Over 100K', 'Over 500K', 'Over 1M'],
    'volatility': ['Any', 'Over 1.5', 'Over 2', 'Over 3', 'Under 1'],
    'relativeVolume': ['Any', 'Over 1.5', 'Over 2', 'Over 3', 'Over 5'],
    'currentVolume': ['Any', 'Over 100K', 'Over 200K', 'Over 500K', 'Over 1M'],
    'rsi': ['Any', 'Oversold (30)', 'Overbought (70)', '30-70', 'Under 20'],
    'sma20': ['Any', 'Price above SMA20', 'Price below SMA20', 'SMA20 above SMA50'],
    'sma50': ['Any', 'Price above SMA50', 'Price below SMA50', 'SMA50 above SMA200'],
    'sma200': ['Any', 'Price above SMA200', 'Price below SMA200'],
    'highLow': ['Any', 'New High', 'New Low', '52W High', '52W Low'],
  };

  @override
  void initState() {
    super.initState();
    selectedStrategy = widget.initialStrategy;
    // Use caller-provided filters or auto-generate defaults for the strategy
    filters = widget.initialFilters != null
        ? Map<String, dynamic>.from(widget.initialFilters!)
        : _defaultFiltersForStrategy(widget.initialStrategy);
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    setState(() => isLoading = true);
    
    try {
      final assets = await AlpacaApiService.getActiveAssets();
      final List<Map<String, dynamic>> stocks = [];
      final random = Random();
      
      // Generate realistic breakout stock data based on your screenshot
      final breakoutStocks = [
        {'symbol': 'TSLA', 'name': 'Tesla Inc', 'changePercent': 10.77, 'price': 247.53, 'volume': 213.70, 'marketCap': 1.01},
        {'symbol': 'AVGO', 'name': 'Broadcom Inc', 'changePercent': 9.34, 'price': 170.59, 'volume': 6.28, 'marketCap': 1.30},
        {'symbol': 'NVDA', 'name': 'NVIDIA Corporation', 'changePercent': 8.95, 'price': 105.31, 'volume': 188.23, 'marketCap': 4.24},
        {'symbol': 'META', 'name': 'Meta Platforms', 'changePercent': 8.17, 'price': 548.11, 'volume': 11.66, 'marketCap': 1.86},
        {'symbol': 'AMD', 'name': 'Advanced Micro Devices', 'changePercent': 11.13, 'price': 87.52, 'volume': 77.24, 'marketCap': 0.274},
        {'symbol': 'MU', 'name': 'Micron Technology', 'changePercent': 10.07, 'price': 71.75, 'volume': 21.36, 'marketCap': 0.124},
        {'symbol': 'AAPL', 'name': 'Apple Inc', 'changePercent': 8.38, 'price': 185.63, 'volume': 19.89, 'marketCap': 2.98},
        {'symbol': 'AMZN', 'name': 'Amazon.com Inc', 'changePercent': 6.83, 'price': 180.88, 'volume': 47.35, 'marketCap': 2.29},
        {'symbol': 'GOOGL', 'name': 'Alphabet Inc', 'changePercent': 5.33, 'price': 151.71, 'volume': 158.51, 'marketCap': 1.85},
        {'symbol': 'MSFT', 'name': 'Microsoft Corporation', 'changePercent': 5.94, 'price': 372.52, 'volume': 19.72, 'marketCap': 2.84},
      ];

      for (final stock in breakoutStocks) {
        stocks.add({
          'symbol': stock['symbol'],
          'name': stock['name'],
          'price': stock['price'],
          'changePercent': stock['changePercent'],
          'volume': stock['volume'], // in millions
          'marketCap': stock['marketCap'], // in trillions
          'peRatio': 4.5 + random.nextDouble() * 0.8, // Under 5 for breakout filter
          'roe': 10.5 + random.nextDouble() * 15, // Over 10%
          'epsGrowth': 15 + random.nextDouble() * 85, // Over 10%
          'netProfitMargin': 25 + random.nextDouble() * 25, // Over 20%
          'debtEquity': 0.2 + random.nextDouble() * 0.7, // Under 1
          'avgVolume': 150 + random.nextInt(850), // Over 100K (in thousands)
          'volatility': 1.6 + random.nextDouble() * 1.4, // Over 1.5
          'relativeVolume': 2.1 + random.nextDouble() * 2.9, // Over 2
          'currentVolume': 250 + random.nextInt(750), // Over 200K (in thousands)
          'rsi': 25 + random.nextDouble() * 10, // Oversold around 30
          'sma20': true, // Price above SMA20
          'sma50': true, // Price above SMA50
          'sma200': true, // Price above SMA200
          'isNewHigh': true, // New High
          'sector': 'Technology',
          'exchange': 'NASDAQ',
        });
      }

      setState(() {
        allStocks = stocks;
        filteredStocks = List.from(allStocks);
        isLoading = false;
        lastUpdated = DateTime.now();
      });
      
    } catch (e) {
      print('Error loading stock data: $e');
      setState(() => isLoading = false);
    }
  }

  void showFilterDialog(String filterKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(_getFilterTitle(filterKey), style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filterOptions[filterKey]!.length,
            itemBuilder: (context, index) {
              final option = filterOptions[filterKey]![index];
              final isSelected = filters[filterKey] == option;
              
              return ListTile(
                title: Text(option, style: TextStyle(color: Colors.black87)),
                trailing: isSelected 
                    ? Icon(Icons.check, color: Color.fromARGB(255, 112, 97, 243)) 
                    : null,
                onTap: () {
                  setState(() {
                    filters[filterKey] = option;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void showWishlistDialog(Map<String, dynamic> stock) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Watchlist",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: const Color.fromARGB(255, 0, 0, 0)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(height: 20),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: wishlists.length,
                      itemBuilder: (context, index) {
                        final wishlist = wishlists[index];
                        final isSelected = selectedWishlist == wishlist;
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color.fromARGB(255, 112, 97, 243).withOpacity(0.1) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Color.fromARGB(255, 112, 97, 243) : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              wishlist,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected 
                                ? Icon(Icons.check_circle, color: Color.fromARGB(255, 112, 97, 243), size: 20)
                                : null,
                            onTap: () {
                              setDialogState(() {
                                selectedWishlist = wishlist;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showCreateWatchlistDialog();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color.fromARGB(255, 112, 97, 243),
                            side: BorderSide(color: Color.fromARGB(255, 112, 97, 243)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: Text(
                            "Create New",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAddConfirmation(stock);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 112, 97, 243),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            "Add",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateWatchlistDialog() {
    TextEditingController wishlistController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Create Watchlist",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 16),
              
              // Description
              Text(
                "Start tracking stocks by creating a watchlist",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Text field with label
              Text(
                "Enter watchlist name",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              SizedBox(height: 8),
              
              // Text field
              TextField(
                controller: wishlistController,
                style: TextStyle(color: Colors.black, fontSize: 16),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "e.g., Tech Stocks, Portfolio, etc.",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: const Color.fromARGB(255, 97, 101, 145)!),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(255, 112, 97, 243)),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (wishlistController.text.trim().isNotEmpty) {
                        setState(() {
                          wishlists.add(wishlistController.text.trim());
                          selectedWishlist = wishlistController.text.trim();
                        });
                        Navigator.pop(context);
                        
                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Watchlist '${wishlistController.text.trim()}' created"),
                            backgroundColor: Color.fromARGB(255, 112, 97, 243),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 112, 97, 243),
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Create",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddConfirmation(Map<String, dynamic> stock) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${stock['symbol']} added to $selectedWishlist"),
        backgroundColor: Color.fromARGB(255, 112, 97, 243),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TradingDashboard(),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getFilterTitle(String key) {
    final titles = {
      'strategy': 'Strategy',
      'price': 'Price',
      'marketCap': 'Market Cap.',
      'change': 'Change',
      'peRatio': 'P/E',
      'roe': 'Return on Equity',
      'epsGrowth': 'EPS Growth YoY',
      'netProfitMargin': 'Net Profit Margin',
      'debtEquity': 'Debt/Equity',
      'avgVolume': 'Average Volume',
      'volatility': 'Volatility',
      'relativeVolume': 'Relative Volume',
      'currentVolume': 'Current Volume',
      'rsi': 'RSI(14)',
      'sma20': '20-Day Simple Moving Average',
      'sma50': '50-Day Simple Moving Average',
      'sma200': '200-Day Simple Moving Average',
      'highLow': '50-Day High/Low',
    };
    return titles[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(""), // Empty title
        actions: [
        Stack(
  children: [
    IconButton(
      icon: Icon(
        Icons.notifications,  // Bell icon
        color: Color.fromARGB(255, 112, 97, 243), // Purple-blue color
        size: 26,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationScreen()),
        );
      },
    ),

    // Notification counter
    Positioned(
      right: 6,
      top: 6,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '3',  // You can dynamically change this value
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
)

        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color.fromARGB(255, 112, 97, 243)),
                  SizedBox(height: 16),
                  Text("Loading breakout stocks...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                // Header section - FIXED LEFT ALIGNMENT
                Container(
                  width: double.infinity, // Take full width
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align to left
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Screener", 
                        style: TextStyle(
                          color: Colors.black, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              selectedStrategy,
                              style: TextStyle(
                                color: Color.fromARGB(255, 112, 97, 243),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        "${filteredStocks.length} stocks. Updated ${_getTimeSinceUpdate()}", 
                        style: TextStyle(
                          color: Colors.grey, 
                          fontSize: 12
                        ),
                      ),
                    ],
                  ),
                ),
                // Filters section
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.grey[50],
                    child: ListView(
                      padding: EdgeInsets.all(16),
                      children: [
                        _buildFilterSection("Strategy & Basic", [
                          _buildFilterRow("Strategy", filters['strategy']!, 'strategy'),
                          _buildFilterRow("Price", filters['price']!, 'price'),
                          _buildFilterRow("Market Cap.", filters['marketCap']!, 'marketCap'),
                          _buildFilterRow("Change", filters['change']!, 'change'),
                          _buildFilterRow("P/E", filters['peRatio']!, 'peRatio'),
                        ]),
                        _buildFilterSection("Fundamental", [
                          _buildFilterRow("Return on Equity", filters['roe']!, 'roe'),
                          _buildFilterRow("EPS Growth YoY", filters['epsGrowth']!, 'epsGrowth'),
                          _buildFilterRow("Net Profit Margin", filters['netProfitMargin']!, 'netProfitMargin'),
                          _buildFilterRow("Debt/Equity", filters['debtEquity']!, 'debtEquity'),
                        ]),
                        _buildFilterSection("Technical", [
                          _buildFilterRow("Average Volume", filters['avgVolume']!, 'avgVolume'),
                          _buildFilterRow("Volatility", filters['volatility']!, 'volatility'),
                          _buildFilterRow("Relative Volume", filters['relativeVolume']!, 'relativeVolume'),
                          _buildFilterRow("Current Volume", filters['currentVolume']!, 'currentVolume'),
                          _buildFilterRow("RSI(14)", filters['rsi']!, 'rsi'),
                        ]),
                        _buildFilterSection("Moving Averages", [
                          _buildFilterRow("20-Day Simple Moving Average", filters['sma20']!, 'sma20'),
                          _buildFilterRow("50-Day Simple Moving Average", filters['sma50']!, 'sma50'),
                          _buildFilterRow("200-Day Simple Moving Average", filters['sma200']!, 'sma200'),
                          _buildFilterRow("50-Day High/Low", filters['highLow']!, 'highLow'),
                        ]),
                      ],
                    ),
                  ),
                ),
                // Results section
               Expanded(
  flex: 3,
  child: Container(
    color: Colors.white,
    child: Column(
      children: [
        // Table header
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 40), // Space for checkbox/number column
              Expanded(flex: 2, child: Text("Symbol", style: TextStyle(color: Colors.grey[600]!, fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Change", style: TextStyle(color: Colors.grey[600]!, fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Price", style: TextStyle(color: Colors.grey[600]!, fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Vol", style: TextStyle(color: Colors.grey[600]!, fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Mkt.Cap", style: TextStyle(color: Colors.grey[600]!, fontSize: 12, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Watch", style: TextStyle(color: Colors.grey[600]!, fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        // Stock list
        Expanded(
          child: ListView.builder(
            itemCount: filteredStocks.length,
            itemBuilder: (context, index) {
              final stock = filteredStocks[index];
              return _buildStockRow(stock, index + 1);
            },
          ),
        ),
      ],
    ),
  ),
),
              ],
            ),
    );
  }

  Widget _buildFilterSection(String title, List<Widget> filters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(title, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ...filters,
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterRow(String label, String value, String key) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        dense: true,
        title: Text(label, style: TextStyle(color: Colors.black, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: 120),
              child: Text(value, 
                  style: TextStyle(color: Color.fromARGB(255, 112, 97, 243), fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
        onTap: () => showFilterDialog(key),
      ),
    );
  }

  Widget _buildStockRow(Map<String, dynamic> stock, int index) {
    final changePercent = stock['changePercent'].toDouble();
    final isPositive = changePercent >= 0;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Index
          Container(
            width: 20,
            child: Text("$index", style: TextStyle(color: Colors.grey[600]!, fontSize: 12)),
          ),
          // Symbol and name
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock['symbol'], 
                    style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(stock['name'].length > 15 ? stock['name'].substring(0, 15) + '...' : stock['name'], 
                    style: TextStyle(color: Colors.grey[600]!, fontSize: 10)),
              ],
            ),
          ),
          // Change
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%",
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Price
          Expanded(
            flex: 1,
            child: Text("\$${stock['price'].toStringAsFixed(2)}", 
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          // Volume
          Expanded(
            flex: 1,
            child: Text("${stock['volume'].toStringAsFixed(2)}M", 
                style: TextStyle(color: Colors.grey[600]!, fontSize: 12)),
          ),
          // Market Cap
          Expanded(
            flex: 1,
            child: Text(stock['marketCap'] >= 1 
                ? "${stock['marketCap'].toStringAsFixed(2)}T" 
                : "${(stock['marketCap'] * 1000).toStringAsFixed(0)}B", 
                style: TextStyle(color: Colors.grey[600]!, fontSize: 12)),
          ),
          // Watch button
          Container(
            width: 30,
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.add, color: Color.fromARGB(255, 112, 97, 243), size: 14),
              ),
              onPressed: () {
                showWishlistDialog(stock);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeSinceUpdate() {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inMinutes < 1) return "now";
    return "${diff.inMinutes} mins ago";
  }
}
