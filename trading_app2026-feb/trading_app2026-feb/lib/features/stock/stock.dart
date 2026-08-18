// import 'package:flutter/material.dart';
// import 'package:test_project/features/stock/stock_details.dart';

// class StockPage extends StatefulWidget {
//   @override
//   _StockPageState createState() => _StockPageState();
// }

// class _StockPageState extends State<StockPage> {
//   String selectedFilter = 'Most Traded'; // Default filter

//   // Dummy stock data (Replace with real API data later)
//   final List<Map<String, dynamic>> allStocks = [
//     {
//       'symbol': 'AAPL',
//       'name': 'Apple Inc',
//       'price': 145.50,
//       'change': '+3.5%',
//       'volume': 500000
//     },
//     {
//       'symbol': 'TSLA',
//       'name': 'Tesla Inc',
//       'price': 1100.00,
//       'change': '+10.0%',
//       'volume': 700000
//     },
//     {
//       'symbol': 'AMZN',
//       'name': 'Amazon Inc',
//       'price': 3200.00,
//       'change': '-4.5%',
//       'volume': 400000
//     },
//     {
//       'symbol': 'MSFT',
//       'name': 'Microsoft Corp',
//       'price': 299.75,
//       'change': '+3.1%',
//       'volume': 600000
//     },
//     {
//       'symbol': 'NFLX',
//       'name': 'Netflix Inc',
//       'price': 390.00,
//       'change': '-11.0%',
//       'volume': 300000
//     },
//     {
//       'symbol': 'GOOG',
//       'name': 'Alphabet Inc',
//       'price': 2850.30,
//       'change': '-2.1%',
//       'volume': 550000
//     },
//   ];

//   List<Map<String, dynamic>> filteredStocks = [];

//   static const Color _accentColor = Color.fromARGB(255, 112, 97, 243);

//   @override
//   void initState() {
//     super.initState();
//     filterStocks();
//   }

//   void filterStocks() {
//     setState(() {
//       if (selectedFilter == 'Most Traded') {
//         filteredStocks = List.from(allStocks)
//           ..sort((a, b) => b['volume'].compareTo(a['volume']));
//       } else if (selectedFilter == 'Top Gainers') {
//         filteredStocks = List.from(allStocks)
//           ..sort((a, b) => double
//                   .parse(b['change'].replaceAll('%', ''))
//               .compareTo(
//                   double.parse(a['change'].replaceAll('%', ''))));
//       } else if (selectedFilter == 'Top Losers') {
//         filteredStocks = List.from(allStocks)
//           ..sort((a, b) => double
//                   .parse(a['change'].replaceAll('%', ''))
//               .compareTo(
//                   double.parse(b['change'].replaceAll('%', ''))));
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         iconTheme: const IconThemeData(color: Colors.black),
//         title: const Text(
//           'Stocks',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 8),
//           _buildFilterChips(),
//           const SizedBox(height: 8),
//           const Divider(height: 1, thickness: 0.3),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//               itemCount: filteredStocks.length,
//               itemBuilder: (context, index) {
//                 final stock = filteredStocks[index];
//                 return _buildStockTile(stock);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChips() {
//     final filters = ['Most Traded', 'Top Gainers', 'Top Losers'];

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       child: Row(
//         children: filters.map((filter) {
//           final bool isSelected = selectedFilter == filter;
//           return Expanded(
//             child: GestureDetector(
//               onTap: () {
//                 if (!isSelected) {
//                   selectedFilter = filter;
//                   filterStocks();
//                 }
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 180),
//                 margin: const EdgeInsets.symmetric(horizontal: 4),
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isSelected ? _accentColor : Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(
//                     color: isSelected
//                         ? _accentColor
//                         : Colors.grey.shade300,
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     filter,
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: isSelected ? Colors.white : Colors.black,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildStockTile(Map<String, dynamic> stock) {
//     final bool isNegative = stock['change'].toString().contains('-');
//     final Color changeColor = isNegative ? Colors.red : Colors.green;

//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) =>
//                 StockDetailsPage(stockName: stock['symbol']),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 12),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.03),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // Left: symbol circle
//             CircleAvatar(
//               radius: 20,
//               backgroundColor: _accentColor.withOpacity(0.12),
//               child: Text(
//                 stock['symbol'][0],
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 12),
//             // Middle: name + symbol
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     stock['symbol'],
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     stock['name'],
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: Colors.grey.shade600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             // Right: price + change
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '\$${(stock['price'] as num).toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: changeColor.withOpacity(0.08),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     stock['change'],
//                     style: TextStyle(
//                       color: changeColor,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:test_project/features/stock/stock_details.dart';

class StockPage extends StatefulWidget {
  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  String selectedFilter = 'Most Traded'; // Default filter

  static const Color _accentColor = Color.fromARGB(255, 112, 97, 243);
  static const String _apiKey = 'CF7H37OIS5NWDTN3';

  // Symbols and names you care about
  final Map<String, String> _companyNames = const {
    'AAPL': 'Apple Inc',
    'TSLA': 'Tesla Inc',
    'AMZN': 'Amazon Inc',
    'MSFT': 'Microsoft Corp',
    'NFLX': 'Netflix Inc',
    'GOOG': 'Alphabet Inc',
  };

  // Dummy fallback data if API fails / rate-limits / offline
  final List<Map<String, dynamic>> _dummyStocks = const [
    {'symbol': 'AAPL', 'name': 'Apple Inc', 'price': 145.50, 'change': 3.5, 'volume': 500000},
    {'symbol': 'TSLA', 'name': 'Tesla Inc', 'price': 1100.00, 'change': 10.0, 'volume': 700000},
    {'symbol': 'AMZN', 'name': 'Amazon Inc', 'price': 3200.00, 'change': -4.5, 'volume': 400000},
    {'symbol': 'MSFT', 'name': 'Microsoft Corp', 'price': 299.75, 'change': 3.1, 'volume': 600000},
    {'symbol': 'NFLX', 'name': 'Netflix Inc', 'price': 390.00, 'change': -11.0, 'volume': 300000},
    {'symbol': 'GOOG', 'name': 'Alphabet Inc', 'price': 2850.30, 'change': -2.1, 'volume': 550000},
  ];

  List<Map<String, dynamic>> allStocks = [];
  List<Map<String, dynamic>> filteredStocks = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Start with dummy data so something appears instantly
    allStocks = List<Map<String, dynamic>>.from(_dummyStocks);
    _applyFilter();
    _loadStocksFromApi(); // then try to replace with live data
  }

  Future<void> _loadStocksFromApi() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> results = [];

      for (final symbol in _companyNames.keys) {
        final stockData = await _fetchStockFromApi(symbol);
        if (stockData != null) {
          results.add(stockData);
        }
      }

      if (results.isNotEmpty) {
        // Use live API data
        setState(() {
          allStocks = results;
          _applyFilter();
          isLoading = false;
        });
      } else {
        // API gave nothing usable → fallback to dummy
        setState(() {
          allStocks = List<Map<String, dynamic>>.from(_dummyStocks);
          _applyFilter();
          isLoading = false;
          errorMessage = 'Showing sample data (API limit / network issue)';
        });
      }
    } catch (e) {
      // On any error → fallback to dummy
      setState(() {
        allStocks = List<Map<String, dynamic>>.from(_dummyStocks);
        _applyFilter();
        isLoading = false;
        errorMessage = 'Showing sample data (failed to load live prices)';
      });
    }
  }

  /// Fetches latest price, daily % change and volume for a single symbol
  Future<Map<String, dynamic>?> _fetchStockFromApi(String symbol) async {
    final String stockUrl =
        'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$_apiKey';

    final response = await http.get(Uri.parse(stockUrl));

    if (response.statusCode != 200) return null;

    final Map<String, dynamic> jsonBody = json.decode(response.body);

    // If API returns error or rate-limit note, bail
    if (!jsonBody.containsKey('Time Series (Daily)')) return null;

    final Map<String, dynamic> timeSeries =
        jsonBody['Time Series (Daily)'] as Map<String, dynamic>;

    if (timeSeries.length < 2) return null;

    final List<String> dates = timeSeries.keys.toList()..sort();
    final String lastDate = dates.last;
    final String prevDate = dates[dates.length - 2];

    final Map<String, dynamic> lastData =
        timeSeries[lastDate] as Map<String, dynamic>;
    final Map<String, dynamic> prevData =
        timeSeries[prevDate] as Map<String, dynamic>;

    final double lastClose = double.parse(lastData['4. close']);
    final double prevClose = double.parse(prevData['4. close']);
    final int volume = int.parse(lastData['5. volume']);

    final double changePct =
        ((lastClose - prevClose) / prevClose) * 100.0; // +/- %

    return {
      'symbol': symbol,
      'name': _companyNames[symbol] ?? symbol,
      'price': lastClose,
      'change': changePct, // numeric
      'volume': volume,
    };
  }

  void _onFilterTap(String filter) {
    if (filter == selectedFilter) return;
    setState(() {
      selectedFilter = filter;
      _applyFilter();
    });
  }

  void _applyFilter() {
    List<Map<String, dynamic>> list = List.from(allStocks);

    if (selectedFilter == 'Most Traded') {
      list.sort((a, b) => (b['volume'] as int).compareTo(a['volume'] as int));
    } else if (selectedFilter == 'Top Gainers') {
      list.sort((a, b) =>
          (b['change'] as double).compareTo(a['change'] as double));
    } else if (selectedFilter == 'Top Losers') {
      list.sort((a, b) =>
          (a['change'] as double).compareTo(b['change'] as double));
    }

    filteredStocks = list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Stocks',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterChips(),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 4),
          const Divider(height: 1, thickness: 0.3),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _accentColor,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: filteredStocks.length,
                    itemBuilder: (context, index) {
                      final stock = filteredStocks[index];
                      return _buildStockTile(stock);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Most Traded', 'Top Gainers', 'Top Losers'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: filters.map((filter) {
          final bool isSelected = selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onFilterTap(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accentColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? _accentColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStockTile(Map<String, dynamic> stock) {
    final double change = (stock['change'] as num).toDouble();
    final bool isNegative = change < 0;
    final Color changeColor = isNegative ? Colors.red : Colors.green;
    final String changeText = '${change.toStringAsFixed(2)}%';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StockDetailsPage(stockName: stock['symbol']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _accentColor.withOpacity(0.12),
              child: Text(
                stock['symbol'][0],
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock['symbol'],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stock['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${(stock['price'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    changeText,
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
