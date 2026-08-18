// // version 5 oct 2025

// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:test_project/features/profile/profile.dart';
// import 'package:test_project/features/portfolio/portfolio.dart';
// import 'package:test_project/features/news/news.dart';
// import 'package:test_project/features/news/newsmail.dart';
// import 'package:test_project/features/stock/stock.dart';
// import 'package:test_project/features/stock/stock_details.dart' as details;
// import 'package:test_project/features/notifications/notification.dart';
// import 'package:test_project/features/screener/screener.dart';
// import 'package:test_project/features/simulator/stock_stimulator.dart';
// import 'package:test_project/features/notifications/notification.dart';

// class TrendingScreen extends StatefulWidget {
//   @override
//   _TrendingScreenState createState() => _TrendingScreenState();
// }

// class _TrendingScreenState extends State<TrendingScreen> {
//   String apiKey = "XH0MOF8FACW6RR0L";
//   List<dynamic> newsData = [];
//   bool isSearchingStimulator = false;
//   String searchQuery = "";
//   bool isLoading = false;
  
//   // Add debounce timer
//   Timer? _debounceTimer;
  
//   List<Map<String, dynamic>> searchResults = [];
//   List<Map<String, String>> filteredStimulatorStocks = [];
  
//   // Text editing controller for better state management
//   final TextEditingController _searchController = TextEditingController();
  
//   final List<Map<String, String>> popularStocks = [
//     {"symbol": "AAPL", "name": "Apple Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "GOOGL", "name": "Alphabet Inc - Class A", "region": "United States", "currency": "USD"},
//     {"symbol": "MSFT", "name": "Microsoft Corporation", "region": "United States", "currency": "USD"},
//     {"symbol": "TSLA", "name": "Tesla Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "AMZN", "name": "Amazon.com Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "META", "name": "Meta Platforms Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "NVDA", "name": "NVIDIA Corporation", "region": "United States", "currency": "USD"},
//     {"symbol": "NFLX", "name": "Netflix Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "IBM", "name": "International Business Machines", "region": "United States", "currency": "USD"},
//     {"symbol": "INTC", "name": "Intel Corporation", "region": "United States", "currency": "USD"},
//     {"symbol": "CSCO", "name": "Cisco Systems Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "ORCL", "name": "Oracle Corporation", "region": "United States", "currency": "USD"},
//     {"symbol": "ADBE", "name": "Adobe Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "PYPL", "name": "PayPal Holdings Inc", "region": "United States", "currency": "USD"},
//     {"symbol": "SBUX", "name": "Starbucks Corporation", "region": "United States", "currency": "USD"},
//   ];

//   List<Map<String, String>> allStimulatorStocks = [
//     {"name": "STIM_A", "logo": "https://logo.clearbit.com/ibm.com", "fullName": "Stimulator Stock A"},
//     {"name": "STIM_B", "logo": "https://logo.clearbit.com/amazon.com", "fullName": "Stimulator Stock B"},
//     {"name": "STIM_MSFT", "logo": "https://logo.clearbit.com/microsoft.com", "fullName": "Stimulator Microsoft"},
//     {"name": "STIM_TSLA", "logo": "https://logo.clearbit.com/tesla.com", "fullName": "Stimulator Tesla"},
//     {"name": "STIM_GOOG", "logo": "https://logo.clearbit.com/google.com", "fullName": "Stimulator Google"},
//   ];

//   String selectedCategory = 'Global';

//   @override
//   void initState() {
//     super.initState();
//     fetchNews();
//   }

//   @override
//   void dispose() {
//     _debounceTimer?.cancel();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<void> fetchNews() async {
//     final url = Uri.parse(
//         "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           newsData = data["feed"] ?? [];
//         });
//       }
//     } catch (e) {
//       print("Failed to load news: $e");
//     }
//   }

//   void _onSearchChanged(String query) {
//     // Cancel previous timer
//     _debounceTimer?.cancel();
    
//     setState(() {
//       searchQuery = query;
//     });

//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//         filteredStimulatorStocks = [];
//         isLoading = false;
//       });
//       return;
//     }

//     // Show loading immediately for better UX
//     setState(() {
//       isLoading = true;
//     });

//     // Debounce the search - wait for user to stop typing
//     _debounceTimer = Timer(const Duration(milliseconds: 500), () {
//       if (isSearchingStimulator) {
//         _performStimulatorSearch(query);
//       } else {
//         _performRealStockSearch(query);
//       }
//     });
//   }

//   void _performStimulatorSearch(String query) {
//     final results = allStimulatorStocks
//         .where((stock) =>
//             stock["name"]!.toLowerCase().contains(query.toLowerCase()) ||
//             stock["fullName"]!.toLowerCase().contains(query.toLowerCase()))
//         .toList();

//     setState(() {
//       filteredStimulatorStocks = results;
//       isLoading = false;
//     });
//   }

//   Future<void> _performRealStockSearch(String query) async {
//     // First, search in our local popular stocks database
//     final localResults = _searchLocalStocks(query);
    
//     if (localResults.isNotEmpty) {
//       setState(() {
//         searchResults = localResults;
//         isLoading = false;
//       });
//       return;
//     }

//     // If no local results, try the Alpha Vantage API
//     try {
//       final url = Uri.parse(
//           "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=$query&apikey=$apiKey");

//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List<dynamic> bestMatches = data["bestMatches"] ?? [];

//         if (bestMatches.isNotEmpty) {
//           final apiResults = bestMatches.map((match) {
//             return {
//               "symbol": match["1. symbol"] ?? "",
//               "name": match["2. name"] ?? "",
//               "type": match["3. type"] ?? "",
//               "region": match["4. region"] ?? "",
//               "currency": match["8. currency"] ?? "",
//               "source": "API",
//             };
//           }).toList();

//           setState(() {
//             searchResults = apiResults;
//             isLoading = false;
//           });
//         } else {
//           // If API returns no results, show popular stocks
//           final relatedResults = _getRelatedStocks(query);
//           setState(() {
//             searchResults = relatedResults;
//             isLoading = false;
//           });
//         }
//       } else {
//         // Fallback to local search if API fails
//         final fallbackResults = _getRelatedStocks(query);
//         setState(() {
//           searchResults = fallbackResults;
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error searching stocks: $e");
//       // Fallback to local search on error
//       final fallbackResults = _getRelatedStocks(query);
//       setState(() {
//         searchResults = fallbackResults;
//         isLoading = false;
//       });
//     }
//   }

//   List<Map<String, dynamic>> _searchLocalStocks(String query) {
//     final lowerQuery = query.toLowerCase();
//     return popularStocks
//         .where((stock) =>
//             stock["symbol"]!.toLowerCase().contains(lowerQuery) ||
//             stock["name"]!.toLowerCase().contains(lowerQuery))
//         .map((stock) => {
//               "symbol": stock["symbol"]!,
//               "name": stock["name"]!,
//               "region": stock["region"]!,
//               "currency": stock["currency"]!,
//               "source": "Local",
//             })
//         .toList();
//   }

//   List<Map<String, dynamic>> _getRelatedStocks(String query) {
//     final lowerQuery = query.toLowerCase();
    
//     final similarStocks = popularStocks
//         .where((stock) {
//           final name = stock["name"]!.toLowerCase();
//           final symbol = stock["symbol"]!.toLowerCase();
          
//           return name.contains(lowerQuery) || 
//                  symbol.contains(lowerQuery);
//         })
//         .map((stock) => {
//               "symbol": stock["symbol"]!,
//               "name": stock["name"]!,
//               "region": stock["region"]!,
//               "currency": stock["currency"]!,
//               "source": "Related",
//             })
//         .toList();

//     if (similarStocks.isEmpty) {
//       return popularStocks.take(5).map((stock) => {
//             "symbol": stock["symbol"]!,
//             "name": stock["name"]!,
//             "region": stock["region"]!,
//             "currency": stock["currency"]!,
//             "source": "Popular",
//           }).toList();
//     }

//     return similarStocks;
//   }

//   void toggleSearchMode() {
//     // Cancel any ongoing search
//     _debounceTimer?.cancel();
    
//     setState(() {
//       isSearchingStimulator = !isSearchingStimulator;
//       searchQuery = "";
//       _searchController.clear();
//       searchResults = [];
//       filteredStimulatorStocks = [];
//       isLoading = false;
//     });
//   }

//   String getStockLogo(String symbol) {
//     final logoMap = {
//       'AAPL': 'apple.com',
//       'GOOGL': 'google.com',
//       'MSFT': 'microsoft.com',
//       'TSLA': 'tesla.com',
//       'AMZN': 'amazon.com',
//       'META': 'meta.com',
//       'NFLX': 'netflix.com',
//       'NVDA': 'nvidia.com',
//       'IBM': 'ibm.com',
//       'INTC': 'intel.com',
//       'CSCO': 'cisco.com',
//       'ORCL': 'oracle.com',
//       'ADBE': 'adobe.com',
//       'PYPL': 'paypal.com',
//       'SBUX': 'starbucks.com',
//     };
    
//     final domain = logoMap[symbol] ?? '${symbol.toLowerCase().replaceAll(' ', '')}.com';
//     return "https://logo.clearbit.com/$domain";
//   }

//   void _clearSearch() {
//     _debounceTimer?.cancel();
//     setState(() {
//       searchQuery = "";
//       _searchController.clear();
//       searchResults = [];
//       filteredStimulatorStocks = [];
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(16.0),
//           children: [
//             SizedBox(height: 8),
//             _buildHeader(),
//             SizedBox(height: 20),
            
//             _buildSearchBarWithSwitch(),
            
//             SizedBox(height: 16),
            
//             if (isLoading) _buildLoadingIndicator(),
            
//             if (searchQuery.isNotEmpty && !isLoading) 
//               _buildSearchResults(),
            
//             if (searchQuery.isEmpty) _buildMainContent(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMainContent() {
//     return Column(
//       children: [
//         _buildCategoryTabs(),
//         SizedBox(height: 16),
        
//         SizedBox(height: 10),
//         _buildSectionHeader('Most Traded Stocks'),
//         _buildHorizontalStockList(),
//         SizedBox(height: 10),
        
//         SizedBox(height: 24),
//         SizedBox(height: 10),
        
//         _buildTrendingSection(),
//         SizedBox(height: 16),
        
//         _buildTrendingStocksList(),
        
//         GainersLosersSection(),
        
//         SizedBox(height: 16),
//         SizedBox(height: 24),
        
//         _buildSectionHeadernews('Latest News'),
//         _buildNewNewsSection(),
//       ],
//     );
//   }

//   Widget _buildLoadingIndicator() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             CircularProgressIndicator(
//               color: Colors.deepPurple,
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Searching...",
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBarWithSwitch() {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _searchController,
//                 style: TextStyle(color: Colors.black),
//                 decoration: InputDecoration(
//                   hintText: isSearchingStimulator 
//                       ? 'Search stimulator stocks...' 
//                       : 'Search stocks (e.g., Apple, TSLA, Google)...',
//                   hintStyle: TextStyle(color: Colors.grey[600]),
//                   prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//                   suffixIcon: searchQuery.isNotEmpty ? IconButton(
//                     icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
//                     onPressed: _clearSearch,
//                   ) : null,
//                   filled: true,
//                   fillColor: Colors.grey[100],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//                 onChanged: _onSearchChanged,
//               ),
//             ),
//             SizedBox(width: 8),
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: IconButton(
//                 icon: Icon(
//                   isSearchingStimulator ? Icons.switch_right : Icons.switch_left,
//                   color: isSearchingStimulator ? Colors.deepPurple : Colors.grey[600],
//                 ),
//                 onPressed: toggleSearchMode,
//                 tooltip: isSearchingStimulator 
//                     ? 'Switch to Real Stocks' 
//                     : 'Switch to Stimulator Stocks',
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               "Try: Apple, Google, Tesla, Microsoft",
//               style: TextStyle(
//                 color: Colors.grey[500],
//                 fontSize: 12,
//               ),
//             ),
//             Text(
//               isSearchingStimulator ? 'Stimulator Mode' : 'Real Stocks Mode',
//               style: TextStyle(
//                 color: Colors.deepPurple,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSearchResults() {
//     if (isSearchingStimulator) {
//       return _buildStimulatorSearchResults();
//     } else {
//       return _buildRealStocksSearchResults();
//     }
//   }

//   Widget _buildRealStocksSearchResults() {
//     return SizedBox(
//       height: 350,
//       child: searchResults.isNotEmpty
//           ? Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   child: Text(
//                     "Found ${searchResults.length} stocks",
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 14,
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: searchResults.length,
//                     itemBuilder: (context, index) {
//                       final stock = searchResults[index];
//                       final symbol = stock["symbol"] ?? "";
//                       final name = stock["name"] ?? "";
//                       final region = stock["region"] ?? "";
//                       final currency = stock["currency"] ?? "";
//                       final source = stock["source"] ?? "API";

//                       return GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => details.StockDetailsPage(stockName: symbol),
//                             ),
//                           );
//                         },
//                         child: Card(
//                           color: Colors.grey[50],
//                           elevation: 2,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: ListTile(
//                             leading: CircleAvatar(
//                               backgroundColor: Colors.deepPurple.withOpacity(0.1),
//                               backgroundImage: NetworkImage(getStockLogo(symbol)),
//                               child: symbol.isNotEmpty 
//                                   ? Text(
//                                       symbol.substring(0, 1),
//                                       style: TextStyle(
//                                         color: Colors.deepPurple,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     )
//                                   : Icon(Icons.business, color: Colors.deepPurple),
//                             ),
//                             title: Row(
//                               children: [
//                                 Text(
//                                   symbol,
//                                   style: TextStyle(
//                                     color: Colors.black,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 SizedBox(width: 6),
//                                 Container(
//                                   padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                   decoration: BoxDecoration(
//                                     color: _getSourceColor(source),
//                                     borderRadius: BorderRadius.circular(4),
//                                   ),
//                                   child: Text(
//                                     source,
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             subtitle: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   name,
//                                   style: TextStyle(color: Colors.grey[600]),
//                                   maxLines: 1,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 Text(
//                                   '$region • $currency',
//                                   style: TextStyle(color: Colors.grey[500], fontSize: 11),
//                                 ),
//                               ],
//                             ),
//                             trailing: Icon(
//                               Icons.arrow_forward_ios,
//                               color: Colors.deepPurple,
//                               size: 16,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             )
//           : _buildNoResultsWidget(),
//     );
//   }

//   Color _getSourceColor(String source) {
//     switch (source) {
//       case 'Local':
//         return Colors.green;
//       case 'API':
//         return Colors.blue;
//       case 'Related':
//         return Colors.orange;
//       case 'Popular':
//         return Color.fromARGB(255, 112, 97, 243);
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildNoResultsWidget() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.search_off,
//             color: Colors.grey[400],
//             size: 64,
//           ),
//           SizedBox(height: 16),
//           Text(
//             "No stocks found",
//             style: TextStyle(
//               color: Colors.grey[600], 
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             "Try searching with company names like:",
//             style: TextStyle(color: Colors.grey[500], fontSize: 14),
//           ),
//           SizedBox(height: 8),
//           Wrap(
//             spacing: 8,
//             runSpacing: 4,
//             children: ['Apple', 'Google', 'Tesla', 'Microsoft']
//                 .map((name) => Chip(
//                       label: Text(
//                         name,
//                         style: TextStyle(fontSize: 12),
//                       ),
//                       backgroundColor: Colors.deepPurple.withOpacity(0.1),
//                     ))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStimulatorSearchResults() {
//     return SizedBox(
//       height: 300,
//       child: filteredStimulatorStocks.isNotEmpty
//           ? ListView.builder(
//               itemCount: filteredStimulatorStocks.length,
//               itemBuilder: (context, index) {
//                 final stock = filteredStimulatorStocks[index];

//                return GestureDetector(
//   onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => StockSimulatorPage(stockName:  stock["name"]!),
//            //builder: (context) => StockStimulatorDetailsPage(stockName: stock["name"]!),
//       ),
//     );
//   },
//                   child: Card(
//                     color: Colors.grey[50],
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundImage: NetworkImage(stock["logo"]!),
//                       ),
//                       title: Text(
//                         stock["name"]!,
//                         style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         stock["fullName"]!,
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       trailing: Icon(
//                         Icons.arrow_forward_ios,
//                         color: Colors.deepPurple,
//                         size: 16,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             )
//           : Center(
//               child: Text(
//                 "No stimulator stocks found",
//                 style: TextStyle(color: Colors.grey[600], fontSize: 16),
//               ),
//             ),
//     );
//   }

//   // NEW: Updated News Section without side arrows
//   Widget _buildNewNewsSection() {
//     return Container(
//       child: newsData.isEmpty
//           ? Center(
//               child: CircularProgressIndicator(
//                 color: Colors.deepPurple,
//               ),
//             )
//           : ListView.builder(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: newsData.length > 5 ? 5 : newsData.length,
//               itemBuilder: (context, index) {
//                 var newsItem = newsData[index];
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => NewsDetailScreen(newsItem: newsItem)),
//                     );
//                   },
//                   child: Container(
//                     margin: EdgeInsets.symmetric(vertical: 8),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       color: Colors.white,
//                       border: Border.all(
//                         color: Colors.grey[300]!,
//                         width: 1,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.withOpacity(0.1),
//                           blurRadius: 4,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // News Source and Time
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 newsItem["source"] ?? "Unknown Source",
//                                 style: TextStyle(
//                                   color: Colors.deepPurple,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                               Text(
//                                 _formatNewsDate(newsItem["time_published"] ?? ""),
//                                 style: TextStyle(
//                                   color: Colors.grey[500],
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: 8),
                          
//                           // News Title
//                           Text(
//                             newsItem["title"] ?? "No Title",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               height: 1.3,
//                             ),
//                             maxLines: 3,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           SizedBox(height: 8),
                          
//                           // News Summary
//                           Text(
//                             newsItem["summary"] ?? "No summary available",
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 14,
//                               height: 1.4,
//                             ),
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           SizedBox(height: 8),
                          
//                           // Related Tickers
//                           if (newsItem["ticker_sentiment"] != null)
//                             _buildTickerSentiment(newsItem["ticker_sentiment"]),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   // Helper method to format news date
//   String _formatNewsDate(String dateString) {
//     try {
//       if (dateString.isEmpty) return "";
//       // Format: "20241205T120000" to "Dec 5, 2024"
//       final year = dateString.substring(0, 4);
//       final month = dateString.substring(4, 6);
//       final day = dateString.substring(6, 8);
      
//       final monthNames = {
//         '01': 'Jan', '02': 'Feb', '03': 'Mar', '04': 'Apr',
//         '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Aug',
//         '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dec'
//       };
      
//       return '${monthNames[month]} $day, $year';
//     } catch (e) {
//       return dateString;
//     }
//   }

//   // Helper method to build ticker sentiment chips
//   Widget _buildTickerSentiment(List<dynamic> tickerSentiment) {
//     final tickers = tickerSentiment.take(3).toList(); // Show only first 3 tickers
    
//     return Wrap(
//       spacing: 8,
//       runSpacing: 4,
//       children: tickers.map((ticker) {
//         final tickerSymbol = ticker["ticker"] ?? "";
//         final sentiment = ticker["ticker_sentiment_score"] ?? "0.0";
//         final sentimentScore = double.tryParse(sentiment) ?? 0.0;
        
//         Color sentimentColor = Colors.grey;
//         if (sentimentScore > 0.1) sentimentColor = Colors.green;
//         if (sentimentScore < -0.1) sentimentColor = Colors.red;
        
//         return Container(
//           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: sentimentColor.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(6),
//             border: Border.all(color: sentimentColor.withOpacity(0.3)),
//           ),
//           child: Text(
//             tickerSymbol,
//             style: TextStyle(
//               color: sentimentColor,
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildSectionHeader(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: Row(
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           Spacer(),
//           GestureDetector(
//             onTap: () {
//               print('See Detail tapped for $title');
//             },
//             child: Text(
//               'See Detail',
//               style: TextStyle(fontSize: 16, color: Colors.deepPurple),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionHeadernews(String title) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => NewsMailScreen()),
//         );
//       },
//       child: Padding(
//         padding: const EdgeInsets.only(bottom: 16.0),
//         child: Row(
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//             Spacer(),
//             Text(
//               'View All',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.deepPurple,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(
//         'Strategy Builder',
//         style: TextStyle(
//           fontSize: 28,
//           fontWeight: FontWeight.bold,
//           color: Colors.black,
//         ),
//       ),
//       Container(
//         decoration: BoxDecoration(
//           color: const Color.fromARGB(255, 255, 255, 255),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: 
//         Stack(
//   children: [
//     IconButton(
//       icon: Icon(
//         Icons.notifications,  // Bell icon
//         color: Color.fromARGB(255, 112, 97, 243), // Purple-blue color
//         size: 26,
//       ),
//       onPressed: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => NotificationScreen()),
//         );
//       },
//     ),

//     // Notification counter
//     Positioned(
//       right: 6,
//       top: 6,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
//         decoration: BoxDecoration(
//           color: Colors.red,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Text(
//           '3',  // You can dynamically change this value
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 10,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     ),
//   ],
// )

//       ),
//     ],
//   );
// }
//   Widget _buildCategoryTabs() {
//     List<Map<String, dynamic>> categories = [
//       {'name': 'Breakout', 'icon': Icons.trending_up},
//       {'name': 'Bounce', 'icon': Icons.show_chart},
//       {'name': 'Moving Average', 'icon': Icons.timeline},
//       {'name': 'Percent Price Change', 'icon': Icons.percent},
//       {'name': 'Custom', 'icon': Icons.star},
//     ];

//     return SingleChildScrollView(
//       scrollDirection: Axis.vertical,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: categories.map((category) {
//           bool isSelected = category['name'] == selectedCategory;
//           return GestureDetector(
//             onTap: () {
//               if (category['name'] == 'Custom') {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => StockScreenerPage(),
//                   ),
//                 );
//               } else {
//                 setState(() {
//                   selectedCategory = category['name'];
//                 });
//               }
//             },
//             child: Container(
//               decoration: BoxDecoration(
//                 color: isSelected 
//                     ? Colors.deepPurple.withOpacity(0.1) 
//                     : Colors.transparent,
//                 borderRadius: BorderRadius.circular(8),
//                 border: category['name'] == 'Custom' 
//                     ? Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1)
//                     : null,
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//                 child: Row(
//                   children: [
//                     Icon(
//                       category['icon'],
//                       color: isSelected ? Colors.deepPurple : Colors.grey[600],
//                       size: 22,
//                     ),
//                     SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         category['name'],
//                         style: TextStyle(
//                           color: isSelected ? Colors.deepPurple : Colors.grey[700],
//                           fontSize: 16,
//                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                         ),
//                       ),
//                     ),
//                     if (category['name'] == 'Custom')
//                       Icon(
//                         Icons.arrow_forward_ios,
//                         color: Colors.deepPurple.withOpacity(0.7),
//                         size: 16,
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildHorizontalStockList() {
//     final List<Map<String, dynamic>> dummyStocks = [
//       {
//         'name': 'BUKA', 
//         'fullName': 'Bukalapak', 
//         'price': '278.00', 
//         'change': '+2.5%', 
//         'color': Colors.green
//       },
//       {
//         'name': 'BBN', 
//         'fullName': 'Bank Negara', 
//         'price': '4,630.00', 
//         'change': '+0.8%', 
//         'color': Colors.green
//       },
//       {
//         'name': 'SDO', 
//         'fullName': 'Sido Muncul', 
//         'price': '24.00', 
//         'change': '-1.2%', 
//         'color': Colors.red
//       },
//       {
//         'name': 'AAPL', 
//         'fullName': 'Apple Inc', 
//         'price': '150.00', 
//         'change': '+0.5%', 
//         'color': Colors.green
//       },
//       {
//         'name': 'GOOGL', 
//         'fullName': 'Alphabet', 
//         'price': '2,800.00', 
//         'change': '-0.3%', 
//         'color': Colors.red
//       },
//     ];

//     return Container(
//       height: 120,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: dummyStocks.length,
//         itemBuilder: (context, index) {
//           final stock = dummyStocks[index];
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),
//                 ),
//               );
//             },
//             child: Container(
//               width: 200,
//               margin: EdgeInsets.only(right: 16),
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey[300]!, width: 1),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         stock['name'],
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       Icon(
//                         stock['change'].contains('+') 
//                           ? Icons.trending_up 
//                           : Icons.trending_down,
//                         color: stock['color'],
//                         size: 20,
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         stock['fullName'],
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                       SizedBox(height: 4),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Rp${stock['price']}',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black,
//                             ),
//                           ),
//                           Text(
//                             stock['change'],
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: stock['color'],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildTrendingSection() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           'Top Intraday Stock',
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => StockPage()),
//             );
//           },
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   'See more',
//                   style: TextStyle(color: Colors.deepPurple),
//                 ),
//                 SizedBox(width: 4),
//                 Icon(Icons.arrow_forward, color: Colors.deepPurple, size: 20),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTrendingStocksList() {
//     return Column(
//       children: [
//         _buildStockItem('ROTI', 'Nippon Indosari Tbk', '8600.00', '+50', '+3.23%', Colors.amber),
//         _buildStockItem('GOTO', 'GoTo Gojek Tokopedia', '2421.05', '-121', '-20.6%', Colors.green),
//         _buildStockItem('ABNB', 'Airbnb Inc', '5300.50', '+31', '+2.23%', Colors.red),
//         _buildStockItem('UNVR', 'Unilever Indonesia', '3867.10', '-71', '-4.1%', Colors.blue),
//         _buildStockItem('ADRO', 'Adaro Energy Indonesia', '3600.45', '+21', '+3.23%', Colors.grey),
//       ],
//     );
//   }

//   Widget _buildStockItem(String symbol, String name, String price, String change, String percentage, Color logoColor) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[300]!, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             blurRadius: 4,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 40,
//             height: 40,
//             decoration: BoxDecoration(
//               color: logoColor,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Center(
//               child: Text(
//                 symbol[0],
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   symbol,
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   name,
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 price,
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 '$change ($percentage)',
//                 style: TextStyle(
//                   color: change.contains('-') ? Colors.red : Colors.green,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Keep your existing GainersLosersSection class here...
// class GainersLosersSection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         _buildHeader(context, title: 'Top Gainers'),
//         SizedBox(height: 16),
//         _buildStocksList(context, [
//           _buildStockItem(context, 'TSLA', 'Tesla Inc', '1100.00', '+100', '+10.0%', Colors.green),
//           _buildStockItem(context, 'AAPL', 'Apple Inc', '145.50', '+5', '+3.5%', Colors.green),
//           _buildStockItem(context, 'MSFT', 'Microsoft Corp', '299.75', '+9', '+3.1%', Colors.green),
//         ]),
//         SizedBox(height: 20),
//         _buildHeader(context, title: 'Top Losers'),
//         SizedBox(height: 16),
//         _buildStocksList(context, [
//           _buildStockItem(context, 'NFLX', 'Netflix Inc', '390.00', '-50', '-11.0%', Colors.red),
//           _buildStockItem(context, 'AMZN', 'Amazon Inc', '3200.00', '-150', '-4.5%', Colors.red),
//           _buildStockItem(context, 'GOOG', 'Alphabet Inc', '2850.30', '-30', '-2.1%', Colors.red),
//         ]),
//       ],
//     );
//   }

//   Widget _buildHeader(BuildContext context, {required String title}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => StockPage()),
//             );
//           },
//           child: Container(
//             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               children: [
//                 Text(
//                   'See more',
//                   style: TextStyle(color: Colors.deepPurple),
//                 ),
//                 SizedBox(width: 4),
//                 Icon(Icons.arrow_forward, color: Colors.deepPurple, size: 20),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStocksList(BuildContext context, List<Widget> stocks) {
//     return Column(children: stocks);
//   }

//   Widget _buildStockItem(BuildContext context, String symbol, String name, String price, String change, String percentChange, Color color) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => details.StockDetailsPage(stockName: symbol)),
//         );
//       },
//       child: Container(
//         padding: EdgeInsets.all(12),
//         margin: EdgeInsets.symmetric(vertical: 6),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey[300]!, width: 1),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.1),
//               blurRadius: 4,
//               offset: Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Row(
//               children: [
//                 CircleAvatar(
//                   backgroundColor: color.withOpacity(0.2),
//                   child: Text(symbol, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
//                 ),
//                 SizedBox(width: 10),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(name, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
//                     Text(price, style: TextStyle(color: Colors.grey[600])),
//                   ],
//                 ),
//               ],
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(change, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
//                 Text(percentChange, style: TextStyle(color: color)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










// // // version 5 oct 2025



// // import 'dart:async';
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:test_project/features/profile/profile.dart';
// // import 'package:test_project/features/portfolio/portfolio.dart';
// // import 'package:test_project/features/news/news.dart';
// // import 'package:test_project/features/news/newsmail.dart';
// // import 'package:test_project/features/stock/stock.dart';
// // import 'package:test_project/features/stock/stock_details.dart' as details;
// // import 'package:test_project/features/notifications/notification.dart';
// // import 'package:test_project/features/screener/screener.dart';
// // import 'package:test_project/features/simulator/stock_stimulator.dart';

// // class TrendingScreen extends StatefulWidget {
// //   @override
// //   _TrendingScreenState createState() => _TrendingScreenState();
// // }

// // class _TrendingScreenState extends State<TrendingScreen> {
// //   String apiKey = "XH0MOF8FACW6RR0L";
// //   List<dynamic> newsData = [];
// //   bool isSearchingStimulator = false;
// //   String searchQuery = "";
// //   bool isLoading = false;
  
// //   // Add debounce timer
// //   Timer? _debounceTimer;
  
// //   List<Map<String, dynamic>> searchResults = [];
// //   List<Map<String, String>> filteredStimulatorStocks = [];
  
// //   // Text editing controller for better state management
// //   final TextEditingController _searchController = TextEditingController();
  
// //   final List<Map<String, String>> popularStocks = [
// //     {"symbol": "AAPL", "name": "Apple Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "GOOGL", "name": "Alphabet Inc - Class A", "region": "United States", "currency": "USD"},
// //     {"symbol": "MSFT", "name": "Microsoft Corporation", "region": "United States", "currency": "USD"},
// //     {"symbol": "TSLA", "name": "Tesla Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "AMZN", "name": "Amazon.com Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "META", "name": "Meta Platforms Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "NVDA", "name": "NVIDIA Corporation", "region": "United States", "currency": "USD"},
// //     {"symbol": "NFLX", "name": "Netflix Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "IBM", "name": "International Business Machines", "region": "United States", "currency": "USD"},
// //     {"symbol": "INTC", "name": "Intel Corporation", "region": "United States", "currency": "USD"},
// //     {"symbol": "CSCO", "name": "Cisco Systems Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "ORCL", "name": "Oracle Corporation", "region": "United States", "currency": "USD"},
// //     {"symbol": "ADBE", "name": "Adobe Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "PYPL", "name": "PayPal Holdings Inc", "region": "United States", "currency": "USD"},
// //     {"symbol": "SBUX", "name": "Starbucks Corporation", "region": "United States", "currency": "USD"},
// //   ];

// //   List<Map<String, String>> allStimulatorStocks = [
// //     {"name": "STIM_A", "logo": "https://logo.clearbit.com/ibm.com", "fullName": "Stimulator Stock A"},
// //     {"name": "STIM_B", "logo": "https://logo.clearbit.com/amazon.com", "fullName": "Stimulator Stock B"},
// //     {"name": "STIM_MSFT", "logo": "https://logo.clearbit.com/microsoft.com", "fullName": "Stimulator Microsoft"},
// //     {"name": "STIM_TSLA", "logo": "https://logo.clearbit.com/tesla.com", "fullName": "Stimulator Tesla"},
// //     {"name": "STIM_GOOG", "logo": "https://logo.clearbit.com/google.com", "fullName": "Stimulator Google"},
// //   ];

// //   String selectedCategory = 'Global';

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchNews();
// //   }

// //   @override
// //   void dispose() {
// //     _debounceTimer?.cancel();
// //     _searchController.dispose();
// //     super.dispose();
// //   }

// //   Future<void> fetchNews() async {
// //     final url = Uri.parse(
// //         "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

// //     try {
// //       final response = await http.get(url);
// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         setState(() {
// //           newsData = data["feed"] ?? [];
// //         });
// //       }
// //     } catch (e) {
// //       print("Failed to load news: $e");
// //     }
// //   }

// //   void _onSearchChanged(String query) {
// //     // Cancel previous timer
// //     _debounceTimer?.cancel();
    
// //     setState(() {
// //       searchQuery = query;
// //     });

// //     if (query.isEmpty) {
// //       setState(() {
// //         searchResults = [];
// //         filteredStimulatorStocks = [];
// //         isLoading = false;
// //       });
// //       return;
// //     }

// //     // Show loading immediately for better UX
// //     setState(() {
// //       isLoading = true;
// //     });

// //     // Debounce the search - wait for user to stop typing
// //     _debounceTimer = Timer(const Duration(milliseconds: 500), () {
// //       if (isSearchingStimulator) {
// //         _performStimulatorSearch(query);
// //       } else {
// //         _performRealStockSearch(query);
// //       }
// //     });
// //   }

// //   void _performStimulatorSearch(String query) {
// //     final results = allStimulatorStocks
// //         .where((stock) =>
// //             stock["name"]!.toLowerCase().contains(query.toLowerCase()) ||
// //             stock["fullName"]!.toLowerCase().contains(query.toLowerCase()))
// //         .toList();

// //     setState(() {
// //       filteredStimulatorStocks = results;
// //       isLoading = false;
// //     });
// //   }

// //   Future<void> _performRealStockSearch(String query) async {
// //     // First, search in our local popular stocks database
// //     final localResults = _searchLocalStocks(query);
    
// //     if (localResults.isNotEmpty) {
// //       setState(() {
// //         searchResults = localResults;
// //         isLoading = false;
// //       });
// //       return;
// //     }

// //     // If no local results, try the Alpha Vantage API
// //     try {
// //       final url = Uri.parse(
// //           "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=$query&apikey=$apiKey");

// //       final response = await http.get(url);

// //       if (response.statusCode == 200) {
// //         final data = json.decode(response.body);
// //         final List<dynamic> bestMatches = data["bestMatches"] ?? [];

// //         if (bestMatches.isNotEmpty) {
// //           final apiResults = bestMatches.map((match) {
// //             return {
// //               "symbol": match["1. symbol"] ?? "",
// //               "name": match["2. name"] ?? "",
// //               "type": match["3. type"] ?? "",
// //               "region": match["4. region"] ?? "",
// //               "currency": match["8. currency"] ?? "",
// //               "source": "API",
// //             };
// //           }).toList();

// //           setState(() {
// //             searchResults = apiResults;
// //             isLoading = false;
// //           });
// //         } else {
// //           // If API returns no results, show popular stocks
// //           final relatedResults = _getRelatedStocks(query);
// //           setState(() {
// //             searchResults = relatedResults;
// //             isLoading = false;
// //           });
// //         }
// //       } else {
// //         // Fallback to local search if API fails
// //         final fallbackResults = _getRelatedStocks(query);
// //         setState(() {
// //           searchResults = fallbackResults;
// //           isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       print("Error searching stocks: $e");
// //       // Fallback to local search on error
// //       final fallbackResults = _getRelatedStocks(query);
// //       setState(() {
// //         searchResults = fallbackResults;
// //         isLoading = false;
// //       });
// //     }
// //   }

// //   List<Map<String, dynamic>> _searchLocalStocks(String query) {
// //     final lowerQuery = query.toLowerCase();
// //     return popularStocks
// //         .where((stock) =>
// //             stock["symbol"]!.toLowerCase().contains(lowerQuery) ||
// //             stock["name"]!.toLowerCase().contains(lowerQuery))
// //         .map((stock) => {
// //               "symbol": stock["symbol"]!,
// //               "name": stock["name"]!,
// //               "region": stock["region"]!,
// //               "currency": stock["currency"]!,
// //               "source": "Local",
// //             })
// //         .toList();
// //   }

// //   List<Map<String, dynamic>> _getRelatedStocks(String query) {
// //     final lowerQuery = query.toLowerCase();
    
// //     final similarStocks = popularStocks
// //         .where((stock) {
// //           final name = stock["name"]!.toLowerCase();
// //           final symbol = stock["symbol"]!.toLowerCase();
          
// //           return name.contains(lowerQuery) || 
// //                  symbol.contains(lowerQuery);
// //         })
// //         .map((stock) => {
// //               "symbol": stock["symbol"]!,
// //               "name": stock["name"]!,
// //               "region": stock["region"]!,
// //               "currency": stock["currency"]!,
// //               "source": "Related",
// //             })
// //         .toList();

// //     if (similarStocks.isEmpty) {
// //       return popularStocks.take(5).map((stock) => {
// //             "symbol": stock["symbol"]!,
// //             "name": stock["name"]!,
// //             "region": stock["region"]!,
// //             "currency": stock["currency"]!,
// //             "source": "Popular",
// //           }).toList();
// //     }

// //     return similarStocks;
// //   }

// //   void toggleSearchMode() {
// //     // Cancel any ongoing search
// //     _debounceTimer?.cancel();
    
// //     setState(() {
// //       isSearchingStimulator = !isSearchingStimulator;
// //       searchQuery = "";
// //       _searchController.clear();
// //       searchResults = [];
// //       filteredStimulatorStocks = [];
// //       isLoading = false;
// //     });
// //   }

// //   String getStockLogo(String symbol) {
// //     final logoMap = {
// //       'AAPL': 'apple.com',
// //       'GOOGL': 'google.com',
// //       'MSFT': 'microsoft.com',
// //       'TSLA': 'tesla.com',
// //       'AMZN': 'amazon.com',
// //       'META': 'meta.com',
// //       'NFLX': 'netflix.com',
// //       'NVDA': 'nvidia.com',
// //       'IBM': 'ibm.com',
// //       'INTC': 'intel.com',
// //       'CSCO': 'cisco.com',
// //       'ORCL': 'oracle.com',
// //       'ADBE': 'adobe.com',
// //       'PYPL': 'paypal.com',
// //       'SBUX': 'starbucks.com',
// //     };
    
// //     final domain = logoMap[symbol] ?? '${symbol.toLowerCase().replaceAll(' ', '')}.com';
// //     return "https://logo.clearbit.com/$domain";
// //   }

// //   void _clearSearch() {
// //     _debounceTimer?.cancel();
// //     setState(() {
// //       searchQuery = "";
// //       _searchController.clear();
// //       searchResults = [];
// //       filteredStimulatorStocks = [];
// //       isLoading = false;
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: SafeArea(
// //         child: ListView(
// //           padding: const EdgeInsets.all(16.0),
// //           children: [
// //             SizedBox(height: 8),
// //             _buildHeader(),
// //             SizedBox(height: 20),
            
// //             _buildSearchBarWithSwitch(),
            
// //             SizedBox(height: 16),
            
// //             if (isLoading) _buildLoadingIndicator(),
            
// //             if (searchQuery.isNotEmpty && !isLoading) 
// //               _buildSearchResults(),
            
// //             if (searchQuery.isEmpty) _buildMainContent(),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMainContent() {
// //     return Column(
// //       children: [
// //         _buildCategoryTabs(),
// //         SizedBox(height: 16),
        
// //         SizedBox(height: 10),
// //         _buildSectionHeader('Most Traded Stocks'),
// //         _buildHorizontalStockList(),
// //         SizedBox(height: 10),
        
// //         SizedBox(height: 24),
// //         SizedBox(height: 10),
        
// //         _buildTrendingSection(),
// //         SizedBox(height: 16),
        
// //         _buildTrendingStocksList(),
        
// //         GainersLosersSection(),
        
// //         SizedBox(height: 16),
// //         SizedBox(height: 24),
        
// //         _buildSectionHeadernews('Latest News'),
// //         _buildVerticalNewsList(context),
// //       ],
// //     );
// //   }

// //   Widget _buildLoadingIndicator() {
// //     return Center(
// //       child: Padding(
// //         padding: const EdgeInsets.all(16.0),
// //         child: Column(
// //           children: [
// //             CircularProgressIndicator(
// //               color: Colors.deepPurple,
// //             ),
// //             SizedBox(height: 8),
// //             Text(
// //               "Searching...",
// //               style: TextStyle(
// //                 color: Colors.grey[600],
// //                 fontSize: 14,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSearchBarWithSwitch() {
// //     return Column(
// //       children: [
// //         Row(
// //           children: [
// //             Expanded(
// //               child: TextField(
// //                 controller: _searchController,
// //                 style: TextStyle(color: Colors.black),
// //                 decoration: InputDecoration(
// //                   hintText: isSearchingStimulator 
// //                       ? 'Search stimulator stocks...' 
// //                       : 'Search stocks (e.g., Apple, TSLA, Google)...',
// //                   hintStyle: TextStyle(color: Colors.grey[600]),
// //                   prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
// //                   suffixIcon: searchQuery.isNotEmpty ? IconButton(
// //                     icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
// //                     onPressed: _clearSearch,
// //                   ) : null,
// //                   filled: true,
// //                   fillColor: Colors.grey[100],
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                     borderSide: BorderSide.none,
// //                   ),
// //                 ),
// //                 onChanged: _onSearchChanged,
// //               ),
// //             ),
// //             SizedBox(width: 8),
// //             Container(
// //               decoration: BoxDecoration(
// //                 color: Colors.grey[100],
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: IconButton(
// //                 icon: Icon(
// //                   isSearchingStimulator ? Icons.switch_right : Icons.switch_left,
// //                   color: isSearchingStimulator ? Colors.deepPurple : Colors.grey[600],
// //                 ),
// //                 onPressed: toggleSearchMode,
// //                 tooltip: isSearchingStimulator 
// //                     ? 'Switch to Real Stocks' 
// //                     : 'Switch to Stimulator Stocks',
// //               ),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 8),
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text(
// //               "Try: Apple, Google, Tesla, Microsoft",
// //               style: TextStyle(
// //                 color: Colors.grey[500],
// //                 fontSize: 12,
// //               ),
// //             ),
// //             Text(
// //               isSearchingStimulator ? 'Stimulator Mode' : 'Real Stocks Mode',
// //               style: TextStyle(
// //                 color: Colors.deepPurple,
// //                 fontSize: 12,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildSearchResults() {
// //     if (isSearchingStimulator) {
// //       return _buildStimulatorSearchResults();
// //     } else {
// //       return _buildRealStocksSearchResults();
// //     }
// //   }

// //   Widget _buildRealStocksSearchResults() {
// //     return SizedBox(
// //       height: 350,
// //       child: searchResults.isNotEmpty
// //           ? Column(
// //               children: [
// //                 Padding(
// //                   padding: const EdgeInsets.symmetric(vertical: 8.0),
// //                   child: Text(
// //                     "Found ${searchResults.length} stocks",
// //                     style: TextStyle(
// //                       color: Colors.grey[600],
// //                       fontSize: 14,
// //                     ),
// //                   ),
// //                 ),
// //                 Expanded(
// //                   child: ListView.builder(
// //                     itemCount: searchResults.length,
// //                     itemBuilder: (context, index) {
// //                       final stock = searchResults[index];
// //                       final symbol = stock["symbol"] ?? "";
// //                       final name = stock["name"] ?? "";
// //                       final region = stock["region"] ?? "";
// //                       final currency = stock["currency"] ?? "";
// //                       final source = stock["source"] ?? "API";

// //                       return GestureDetector(
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                               builder: (context) => details.StockDetailsPage(stockName: symbol),
// //                             ),
// //                           );
// //                         },
// //                         child: Card(
// //                           color: Colors.grey[50],
// //                           elevation: 2,
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(10),
// //                           ),
// //                           child: ListTile(
// //                             leading: CircleAvatar(
// //                               backgroundColor: Colors.deepPurple.withOpacity(0.1),
// //                               backgroundImage: NetworkImage(getStockLogo(symbol)),
// //                               child: symbol.isNotEmpty 
// //                                   ? Text(
// //                                       symbol.substring(0, 1),
// //                                       style: TextStyle(
// //                                         color: Colors.deepPurple,
// //                                         fontWeight: FontWeight.bold,
// //                                       ),
// //                                     )
// //                                   : Icon(Icons.business, color: Colors.deepPurple),
// //                             ),
// //                             title: Row(
// //                               children: [
// //                                 Text(
// //                                   symbol,
// //                                   style: TextStyle(
// //                                     color: Colors.black,
// //                                     fontWeight: FontWeight.bold,
// //                                   ),
// //                                 ),
// //                                 SizedBox(width: 6),
// //                                 Container(
// //                                   padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
// //                                   decoration: BoxDecoration(
// //                                     color: _getSourceColor(source),
// //                                     borderRadius: BorderRadius.circular(4),
// //                                   ),
// //                                   child: Text(
// //                                     source,
// //                                     style: TextStyle(
// //                                       color: Colors.white,
// //                                       fontSize: 10,
// //                                       fontWeight: FontWeight.bold,
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                             subtitle: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   name,
// //                                   style: TextStyle(color: Colors.grey[600]),
// //                                   maxLines: 1,
// //                                   overflow: TextOverflow.ellipsis,
// //                                 ),
// //                                 Text(
// //                                   '$region • $currency',
// //                                   style: TextStyle(color: Colors.grey[500], fontSize: 11),
// //                                 ),
// //                               ],
// //                             ),
// //                             trailing: Icon(
// //                               Icons.arrow_forward_ios,
// //                               color: Colors.deepPurple,
// //                               size: 16,
// //                             ),
// //                           ),
// //                         ),
// //                       );
// //                     },
// //                   ),
// //                 ),
// //               ],
// //             )
// //           : _buildNoResultsWidget(),
// //     );
// //   }

// //   Color _getSourceColor(String source) {
// //     switch (source) {
// //       case 'Local':
// //         return Colors.green;
// //       case 'API':
// //         return Colors.blue;
// //       case 'Related':
// //         return Colors.orange;
// //       case 'Popular':
// //         return Color.fromARGB(255, 112, 97, 243);
// //       default:
// //         return Colors.grey;
// //     }
// //   }

// //   Widget _buildNoResultsWidget() {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             Icons.search_off,
// //             color: Colors.grey[400],
// //             size: 64,
// //           ),
// //           SizedBox(height: 16),
// //           Text(
// //             "No stocks found",
// //             style: TextStyle(
// //               color: Colors.grey[600], 
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //           SizedBox(height: 8),
// //           Text(
// //             "Try searching with company names like:",
// //             style: TextStyle(color: Colors.grey[500], fontSize: 14),
// //           ),
// //           SizedBox(height: 8),
// //           Wrap(
// //             spacing: 8,
// //             runSpacing: 4,
// //             children: ['Apple', 'Google', 'Tesla', 'Microsoft']
// //                 .map((name) => Chip(
// //                       label: Text(
// //                         name,
// //                         style: TextStyle(fontSize: 12),
// //                       ),
// //                       backgroundColor: Colors.deepPurple.withOpacity(0.1),
// //                     ))
// //                 .toList(),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildStimulatorSearchResults() {
// //     return SizedBox(
// //       height: 300,
// //       child: filteredStimulatorStocks.isNotEmpty
// //           ? ListView.builder(
// //               itemCount: filteredStimulatorStocks.length,
// //               itemBuilder: (context, index) {
// //                 final stock = filteredStimulatorStocks[index];

// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                         builder: (context) => StockStimulatorDetailsPage(stockName: stock["name"]!),
// //                       ),
// //                     );
// //                   },
// //                   child: Card(
// //                     color: Colors.grey[50],
// //                     elevation: 2,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     child: ListTile(
// //                       leading: CircleAvatar(
// //                         backgroundImage: NetworkImage(stock["logo"]!),
// //                       ),
// //                       title: Text(
// //                         stock["name"]!,
// //                         style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
// //                       ),
// //                       subtitle: Text(
// //                         stock["fullName"]!,
// //                         style: TextStyle(color: Colors.grey[600]),
// //                       ),
// //                       trailing: Icon(
// //                         Icons.arrow_forward_ios,
// //                         color: Colors.deepPurple,
// //                         size: 16,
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             )
// //           : Center(
// //               child: Text(
// //                 "No stimulator stocks found",
// //                 style: TextStyle(color: Colors.grey[600], fontSize: 16),
// //               ),
// //             ),
// //     );
// //   }

// //   // ... (Keep all your other existing UI methods the same)
// //   // _buildVerticalNewsList, _buildSectionHeader, _buildSectionHeadernews, 
// //   // _buildHeader, _buildCategoryTabs, _buildHorizontalStockList,
// //   // _buildTrendingSection, _buildTrendingStocksList, _buildStockItem

// //   Widget _buildVerticalNewsList(BuildContext context) {
// //     return Container(
// //       child: newsData.isEmpty
// //           ? Center(
// //               child: CircularProgressIndicator(
// //                 color: Colors.deepPurple,
// //               ),
// //             )
// //           : ListView.builder(
// //               shrinkWrap: true,
// //               physics: NeverScrollableScrollPhysics(),
// //               itemCount: newsData.length > 5 ? 5 : newsData.length,
// //               itemBuilder: (context, index) {
// //                 var newsItem = newsData[index];
// //                 return GestureDetector(
// //                   onTap: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(builder: (context) => NewsDetailScreen(newsItem: newsItem)),
// //                     );
// //                   },
// //                   child: Container(
// //                     margin: EdgeInsets.symmetric(vertical: 8),
// //                     decoration: BoxDecoration(
// //                       borderRadius: BorderRadius.circular(12),
// //                       color: Colors.transparent,
// //                       border: Border.all(
// //                         color: Colors.grey[300]!,
// //                         width: 1,
// //                       ),
// //                     ),
// //                     child: Padding(
// //                       padding: EdgeInsets.all(12),
// //                       child: Row(
// //                         children: [
// //                           Expanded(
// //                             child: Column(
// //                               crossAxisAlignment: CrossAxisAlignment.start,
// //                               children: [
// //                                 Text(
// //                                   newsItem["title"] ?? "No Title",
// //                                   maxLines: 2,
// //                                   overflow: TextOverflow.ellipsis,
// //                                   style: TextStyle(
// //                                     color: Colors.black,
// //                                     fontSize: 16,
// //                                     fontWeight: FontWeight.bold,
// //                                   ),
// //                                 ),
// //                                 SizedBox(height: 4),
// //                                 Text(
// //                                   newsItem["subtitle"] ?? newsItem["source"] ?? "",
// //                                   maxLines: 1,
// //                                   overflow: TextOverflow.ellipsis,
// //                                   style: TextStyle(
// //                                     color: Colors.grey[600],
// //                                     fontSize: 13,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                           SizedBox(width: 8),
// //                           Container(
// //                             padding: EdgeInsets.all(8),
// //                             decoration: BoxDecoration(
// //                               shape: BoxShape.circle,
// //                               color: Colors.deepPurple.withOpacity(0.1),
// //                             ),
// //                             child: Icon(
// //                               Icons.arrow_forward,
// //                               color: Colors.deepPurple,
// //                               size: 16,
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 );
// //               },
// //             ),
// //     );
// //   }

// //   Widget _buildSectionHeader(String title) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 16.0),
// //       child: Row(
// //         children: [
// //           Text(
// //             title,
// //             style: TextStyle(
// //               fontSize: 16,
// //               fontWeight: FontWeight.bold,
// //               color: Colors.black,
// //             ),
// //           ),
// //           Spacer(),
// //           GestureDetector(
// //             onTap: () {
// //               print('See Detail tapped for $title');
// //             },
// //             child: Text(
// //               'See Detail',
// //               style: TextStyle(fontSize: 16, color: Colors.deepPurple),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildSectionHeadernews(String title) {
// //     return GestureDetector(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(builder: (context) => NewsMailScreen()),
// //         );
// //       },
// //       child: Padding(
// //         padding: const EdgeInsets.only(bottom: 16.0),
// //         child: Row(
// //           children: [
// //             Text(
// //               title,
// //               style: TextStyle(
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.bold,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             Spacer(),
// //             Icon(Icons.arrow_forward, color: Colors.deepPurple),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildHeader() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         Text(
// //           'Strategy Builder',
// //           style: TextStyle(
// //             fontSize: 28,
// //             fontWeight: FontWeight.bold,
// //             color: Colors.black,
// //           ),
// //         ),
// //         Container(
// //           decoration: BoxDecoration(
// //             color: Colors.grey[100],
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: IconButton(
// //             icon: Icon(Icons.notifications, size: 24, color: Colors.black),
// //             onPressed: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(builder: (context) => NotificationScreen()),
// //               );
// //             },
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildCategoryTabs() {
// //     List<Map<String, dynamic>> categories = [
// //       {'name': 'Custom', 'icon': Icons.star},
// //       {'name': 'Breakout', 'icon': Icons.trending_up},
// //       {'name': 'Bounce', 'icon': Icons.show_chart},
// //       {'name': 'Moving Average', 'icon': Icons.timeline},
// //       {'name': 'Percent Price Change', 'icon': Icons.percent},
// //     ];

// //     return SingleChildScrollView(
// //       scrollDirection: Axis.vertical,
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: categories.map((category) {
// //           bool isSelected = category['name'] == selectedCategory;
// //           return GestureDetector(
// //             onTap: () {
// //               if (category['name'] == 'Custom') {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                     builder: (context) => StockScreenerPage(),
// //                   ),
// //                 );
// //               } else {
// //                 setState(() {
// //                   selectedCategory = category['name'];
// //                 });
// //               }
// //             },
// //             child: Container(
// //               decoration: BoxDecoration(
// //                 color: isSelected 
// //                     ? Colors.deepPurple.withOpacity(0.1) 
// //                     : Colors.transparent,
// //                 borderRadius: BorderRadius.circular(8),
// //                 border: category['name'] == 'Custom' 
// //                     ? Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1)
// //                     : null,
// //               ),
// //               child: Padding(
// //                 padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
// //                 child: Row(
// //                   children: [
// //                     Icon(
// //                       category['icon'],
// //                       color: isSelected ? Colors.deepPurple : Colors.grey[600],
// //                       size: 22,
// //                     ),
// //                     SizedBox(width: 12),
// //                     Expanded(
// //                       child: Text(
// //                         category['name'],
// //                         style: TextStyle(
// //                           color: isSelected ? Colors.deepPurple : Colors.grey[700],
// //                           fontSize: 16,
// //                           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
// //                         ),
// //                       ),
// //                     ),
// //                     if (category['name'] == 'Custom')
// //                       Icon(
// //                         Icons.arrow_forward_ios,
// //                         color: Colors.deepPurple.withOpacity(0.7),
// //                         size: 16,
// //                       ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         }).toList(),
// //       ),
// //     );
// //   }

// //   Widget _buildHorizontalStockList() {
// //     final List<Map<String, dynamic>> dummyStocks = [
// //       {
// //         'name': 'BUKA', 
// //         'fullName': 'Bukalapak', 
// //         'price': '278.00', 
// //         'change': '+2.5%', 
// //         'color': Colors.green
// //       },
// //       {
// //         'name': 'BBN', 
// //         'fullName': 'Bank Negara', 
// //         'price': '4,630.00', 
// //         'change': '+0.8%', 
// //         'color': Colors.green
// //       },
// //       {
// //         'name': 'SDO', 
// //         'fullName': 'Sido Muncul', 
// //         'price': '24.00', 
// //         'change': '-1.2%', 
// //         'color': Colors.red
// //       },
// //       {
// //         'name': 'AAPL', 
// //         'fullName': 'Apple Inc', 
// //         'price': '150.00', 
// //         'change': '+0.5%', 
// //         'color': Colors.green
// //       },
// //       {
// //         'name': 'GOOGL', 
// //         'fullName': 'Alphabet', 
// //         'price': '2,800.00', 
// //         'change': '-0.3%', 
// //         'color': Colors.red
// //       },
// //     ];

// //     return Container(
// //       height: 120,
// //       child: ListView.builder(
// //         scrollDirection: Axis.horizontal,
// //         itemCount: dummyStocks.length,
// //         itemBuilder: (context, index) {
// //           final stock = dummyStocks[index];
// //           return GestureDetector(
// //             onTap: () {
// //               Navigator.push(
// //                 context,
// //                 MaterialPageRoute(
// //                   builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),
// //                 ),
// //               );
// //             },
// //             child: Container(
// //               width: 200,
// //               margin: EdgeInsets.only(right: 16),
// //               padding: EdgeInsets.all(16),
// //               decoration: BoxDecoration(
// //                 color: Colors.white,
// //                 borderRadius: BorderRadius.circular(12),
// //                 border: Border.all(color: Colors.grey[300]!, width: 1),
// //                 boxShadow: [
// //                   BoxShadow(
// //                     color: Colors.grey.withOpacity(0.1),
// //                     blurRadius: 4,
// //                     offset: Offset(0, 2),
// //                   ),
// //                 ],
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   Row(
// //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                     children: [
// //                       Text(
// //                         stock['name'],
// //                         style: TextStyle(
// //                           fontSize: 18,
// //                           fontWeight: FontWeight.bold,
// //                           color: Colors.black,
// //                         ),
// //                       ),
// //                       Icon(
// //                         stock['change'].contains('+') 
// //                           ? Icons.trending_up 
// //                           : Icons.trending_down,
// //                         color: stock['color'],
// //                         size: 20,
// //                       ),
// //                     ],
// //                   ),
// //                   Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         stock['fullName'],
// //                         style: TextStyle(
// //                           fontSize: 12,
// //                           color: Colors.grey[600],
// //                         ),
// //                       ),
// //                       SizedBox(height: 4),
// //                       Row(
// //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                         children: [
// //                           Text(
// //                             'Rp${stock['price']}',
// //                             style: TextStyle(
// //                               fontSize: 16,
// //                               fontWeight: FontWeight.bold,
// //                               color: Colors.black,
// //                             ),
// //                           ),
// //                           Text(
// //                             stock['change'],
// //                             style: TextStyle(
// //                               fontSize: 14,
// //                               color: stock['color'],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ],
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildTrendingSection() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         Text(
// //           'Top Intraday Stock',
// //           style: TextStyle(
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //             color: Colors.black,
// //           ),
// //         ),
// //         GestureDetector(
// //           onTap: () {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (context) => StockPage()),
// //             );
// //           },
// //           child: Container(
// //             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //             decoration: BoxDecoration(
// //               color: Colors.deepPurple.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(20),
// //             ),
// //             child: Row(
// //               children: [
// //                 Text(
// //                   'See more',
// //                   style: TextStyle(color: Colors.deepPurple),
// //                 ),
// //                 SizedBox(width: 4),
// //                 Icon(Icons.arrow_forward, color: Colors.deepPurple, size: 20),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildTrendingStocksList() {
// //     return Column(
// //       children: [
// //         _buildStockItem('ROTI', 'Nippon Indosari Tbk', '8600.00', '+50', '+3.23%', Colors.amber),
// //         _buildStockItem('GOTO', 'GoTo Gojek Tokopedia', '2421.05', '-121', '-20.6%', Colors.green),
// //         _buildStockItem('ABNB', 'Airbnb Inc', '5300.50', '+31', '+2.23%', Colors.red),
// //         _buildStockItem('UNVR', 'Unilever Indonesia', '3867.10', '-71', '-4.1%', Colors.blue),
// //         _buildStockItem('ADRO', 'Adaro Energy Indonesia', '3600.45', '+21', '+3.23%', Colors.grey),
// //       ],
// //     );
// //   }

// //   Widget _buildStockItem(String symbol, String name, String price, String change, String percentage, Color logoColor) {
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 16),
// //       padding: EdgeInsets.all(12),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey[300]!, width: 1),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             blurRadius: 4,
// //             offset: Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             width: 40,
// //             height: 40,
// //             decoration: BoxDecoration(
// //               color: logoColor,
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Center(
// //               child: Text(
// //                 symbol[0],
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ),
// //           ),
// //           SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   symbol,
// //                   style: TextStyle(
// //                     color: Colors.black,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 Text(
// //                   name,
// //                   style: TextStyle(color: Colors.grey[600]),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Column(
// //             crossAxisAlignment: CrossAxisAlignment.end,
// //             children: [
// //               Text(
// //                 price,
// //                 style: TextStyle(
// //                   color: Colors.black,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Text(
// //                 '$change ($percentage)',
// //                 style: TextStyle(
// //                   color: change.contains('-') ? Colors.red : Colors.green,
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // Keep your existing GainersLosersSection class here...
// // class GainersLosersSection extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       children: [
// //         _buildHeader(context, title: 'Top Gainers'),
// //         SizedBox(height: 16),
// //         _buildStocksList(context, [
// //           _buildStockItem(context, 'TSLA', 'Tesla Inc', '1100.00', '+100', '+10.0%', Colors.green),
// //           _buildStockItem(context, 'AAPL', 'Apple Inc', '145.50', '+5', '+3.5%', Colors.green),
// //           _buildStockItem(context, 'MSFT', 'Microsoft Corp', '299.75', '+9', '+3.1%', Colors.green),
// //         ]),
// //         SizedBox(height: 20),
// //         _buildHeader(context, title: 'Top Losers'),
// //         SizedBox(height: 16),
// //         _buildStocksList(context, [
// //           _buildStockItem(context, 'NFLX', 'Netflix Inc', '390.00', '-50', '-11.0%', Colors.red),
// //           _buildStockItem(context, 'AMZN', 'Amazon Inc', '3200.00', '-150', '-4.5%', Colors.red),
// //           _buildStockItem(context, 'GOOG', 'Alphabet Inc', '2850.30', '-30', '-2.1%', Colors.red),
// //         ]),
// //       ],
// //     );
// //   }

// //   Widget _buildHeader(BuildContext context, {required String title}) {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         Text(
// //           title,
// //           style: TextStyle(
// //             fontSize: 20,
// //             fontWeight: FontWeight.bold,
// //             color: Colors.black,
// //           ),
// //         ),
// //         GestureDetector(
// //           onTap: () {
// //             Navigator.push(
// //               context,
// //               MaterialPageRoute(builder: (context) => StockPage()),
// //             );
// //           },
// //           child: Container(
// //             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //             decoration: BoxDecoration(
// //               color: Colors.deepPurple.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(20),
// //             ),
// //             child: Row(
// //               children: [
// //                 Text(
// //                   'See more',
// //                   style: TextStyle(color: Colors.deepPurple),
// //                 ),
// //                 SizedBox(width: 4),
// //                 Icon(Icons.arrow_forward, color: Colors.deepPurple, size: 20),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildStocksList(BuildContext context, List<Widget> stocks) {
// //     return Column(children: stocks);
// //   }

// //   Widget _buildStockItem(BuildContext context, String symbol, String name, String price, String change, String percentChange, Color color) {
// //     return GestureDetector(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(builder: (context) => details.StockDetailsPage(stockName: symbol)),
// //         );
// //       },
// //       child: Container(
// //         padding: EdgeInsets.all(12),
// //         margin: EdgeInsets.symmetric(vertical: 6),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(12),
// //           border: Border.all(color: Colors.grey[300]!, width: 1),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.grey.withOpacity(0.1),
// //               blurRadius: 4,
// //               offset: Offset(0, 2),
// //             ),
// //           ],
// //         ),
// //         child: Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Row(
// //               children: [
// //                 CircleAvatar(
// //                   backgroundColor: color.withOpacity(0.2),
// //                   child: Text(symbol, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// //                 ),
// //                 SizedBox(width: 10),
// //                 Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     Text(name, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
// //                     Text(price, style: TextStyle(color: Colors.grey[600])),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.end,
// //               children: [
// //                 Text(change, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// //                 Text(percentChange, style: TextStyle(color: color)),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
















// // // // import 'dart:convert';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:http/http.dart' as http;
// // // // import 'package:test_project/features/profile/profile.dart';
// // // // import 'package:test_project/features/portfolio/portfolio.dart';
// // // // import 'package:test_project/features/news/news.dart';
// // // // import 'package:test_project/features/news/newsmail.dart';
// // // // import 'package:test_project/features/stock/stock.dart';
// // // // import 'package:test_project/features/stock/stock_details.dart' as details;


// // // // class TrendingScreen extends StatefulWidget {
// // // //   @override
// // // //   _TrendingScreenState createState() => _TrendingScreenState();
// // // // }

// // // // class _TrendingScreenState extends State<TrendingScreen> {
// // // //    String apiKey = "XH0MOF8FACW6RR0L"; // Your API Key
// // // //   List<dynamic> newsData = [];
// // // // //news
// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     filteredStocks = allStocks;
// // // //     fetchNews();
// // // //   }

// // // //   Future<void> fetchNews() async {
// // // //     final url = Uri.parse(
// // // //         "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

// // // //     final response = await http.get(url);

// // // //     if (response.statusCode == 200) {
// // // //       final data = json.decode(response.body);
// // // //       setState(() {
// // // //         newsData = data["feed"] ?? []; // Extracting the news feed list
// // // //       });
// // // //     } else {
// // // //       print("Failed to load news");
// // // //     }
// // // //   }

// // // //  Widget _buildVerticalNewsList(BuildContext context) {
// // // //   return Container(
// // // //     child: newsData.isEmpty
// // // //         ? Center(
// // // //             child: CircularProgressIndicator(
// // // //               color: Theme.of(context).primaryColor,
// // // //             ),
// // // //           ) // Show loading indicator with theme color
// // // //         : ListView.builder(
// // // //             shrinkWrap: true, // Ensures it takes only required space
// // // //             physics: NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
// // // //             itemCount: newsData.length > 5 ? 5 : newsData.length, // Limits display to 5 items
// // // //             itemBuilder: (context, index) {
// // // //               var newsItem = newsData[index];
// // // //               return GestureDetector(
// // // //                 onTap: () {
// // // //                   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => NewsDetailScreen(newsItem: newsItem)),
// // // //                   );
// // // //                 },
// // // //                 child: Container(
// // // //                   margin: EdgeInsets.symmetric(vertical: 8),
// // // //                   decoration: BoxDecoration(
// // // //                     borderRadius: BorderRadius.circular(12),
// // // //                     color: Colors.transparent,
// // // //                     border: Border.all(
// // // //                       color: Colors.white24,
// // // //                       width: 0.5,
// // // //                     ),
// // // //                   ),
// // // //                   child: Padding(
// // // //                     padding: EdgeInsets.all(12),
// // // //                     child: Row(
// // // //                       children: [
// // // //                         Expanded(
// // // //                           child: Column(
// // // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // // //                             children: [
// // // //                               Text(
// // // //                                 newsItem["title"] ?? "No Title",
// // // //                                 maxLines: 2,
// // // //                                 overflow: TextOverflow.ellipsis,
// // // //                                 style: TextStyle(
// // // //                                   color: Colors.white,
// // // //                                   fontSize: 16,
// // // //                                   fontWeight: FontWeight.bold,
// // // //                                 ),
// // // //                               ),
// // // //                               SizedBox(height: 4),
// // // //                               Text(
// // // //                                 newsItem["subtitle"] ?? newsItem["source"] ?? "",
// // // //                                 maxLines: 1,
// // // //                                 overflow: TextOverflow.ellipsis,
// // // //                                 style: TextStyle(
// // // //                                   color: Colors.white70,
// // // //                                   fontSize: 13,
// // // //                                 ),
// // // //                               ),
// // // //                             ],
// // // //                           ),
// // // //                         ),
// // // //                         SizedBox(width: 8),
// // // //                         Container(
// // // //                           padding: EdgeInsets.all(8),
// // // //                           decoration: BoxDecoration(
// // // //                             shape: BoxShape.circle,
// // // //                             color: Theme.of(context).primaryColor.withOpacity(0.2),
// // // //                           ),
// // // //                           child: Icon(
// // // //                             Icons.arrow_forward,
// // // //                             color: Theme.of(context).primaryColor,
// // // //                             size: 16,
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               );
// // // //             },
// // // //           ),
// // // //   );
// // // // }

// // // //   void _showNewsDetail(Map<String, dynamic> newsItem) {
// // // //     showDialog(
// // // //       context: context,
// // // //       builder: (context) {
// // // //         return AlertDialog(
// // // //           title: Text(newsItem["title"] ?? "News Detail"),
// // // //           content: Column(
// // // //             mainAxisSize: MainAxisSize.min,
// // // //             children: [
// // // //               Text(newsItem["summary"] ?? "No Summary Available"),
// // // //               SizedBox(height: 10),
// // // //               Text("Sentiment Score: ${newsItem["sentiment_score"]}"),
// // // //               SizedBox(height: 10),
// // // //               newsItem["url"] != null
// // // //                   ? TextButton(
// // // //                       onPressed: () {
// // // //                         // Implement URL opening (e.g., using url_launcher package)
// // // //                       },
// // // //                       child: Text("Read More", style: TextStyle(color: Colors.blue)),
// // // //                     )
// // // //                   : Container(),
// // // //             ],
// // // //           ),
// // // //           actions: [
// // // //             TextButton(
// // // //               onPressed: () => Navigator.pop(context),
// // // //               child: Text("Close"),
// // // //             ),
// // // //           ],
// // // //         );
// // // //       },
// // // //     );
// // // //   }


// // // //   Widget _buildSectionHeader(String title) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 16.0),
// // // //       child: Row(
// // // //         children: [
// // // //           Text(
// // // //             title,
// // // //             style: TextStyle(
// // // //               fontSize: 16,
// // // //               fontWeight: FontWeight.bold,
// // // //               color: Colors.white,
// // // //             ),
// // // //           ),
// // // //           Spacer(),
// // // //           GestureDetector(
// // // //             onTap: () {
// // // //               print('See Detail tapped for $title');
// // // //             },
// // // //             child: Text(
// // // //               'See Detail',
// // // //               style: TextStyle(fontSize: 16, color: Colors.blue),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   String selectedTimeframe = '24 hour';
// // // //   String selectedCategory = 'Global';
// // // //   int _selectedIndex = 0; // For tracking the selected tab

// // // //   List<Map<String, String>> allStocks = [
// // // //     {"name": "ibm", "logo": "https://logo.clearbit.com/ibm.com"},
// // // //     {"name": "BUKA", "logo": "https://logo.clearbit.com/amazon.com"},
// // // //     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
// // // //     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
// // // //     {"name": "GOOGL", "logo": "https://logo.clearbit.com/google.com"},
// // // //     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
// // // //     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
// // // //   ];

// // // //   List<Map<String, String>> filteredStocks = [];
// // // //   String searchQuery = "";
// // // //   bool isLoading = false;

// // // //   /*@override
// // // //   void initState() {
// // // //     super.initState();
// // // //     filteredStocks = allStocks;
// // // //   }
// // // // */
// // // //   void _onItemTapped(int index) {
// // // //     setState(() {
// // // //       _selectedIndex = index;
// // // //     });
// // // //   }

// // // //  void searchStocks(String query) {
// // // //   setState(() {
// // // //     searchQuery = query;
// // // //     filteredStocks = allStocks
// // // //         .where((stock) =>
// // // //             stock["name"]!.toLowerCase().startsWith(query.toLowerCase())) // Only matches stocks that start with the query
// // // //         .toList();
// // // //   });
// // // // }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: Colors.black,
// // // //       body: Container(
// // // //         decoration: BoxDecoration(
// // // //           gradient: LinearGradient(
// // // //             begin: Alignment.topLeft,
// // // //             end: Alignment.bottomRight,
// // // //             colors: [
// // // //               Colors.black,
// // // //               Color(0xFF1A237E).withOpacity(0.8),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //         child: SafeArea(
// // // //           child: ListView(
// // // //             padding: const EdgeInsets.all(16.0),
// // // //             children: [
// // // //               SizedBox(height: 8),
// // // //               // Header with Title and Settings
// // // //               _buildHeader(),
// // // //               SizedBox(height: 20),
// // // //               SizedBox(height: 16),
// // // //               // Search Bar
// // // //               TextField(
// // // //                 style: TextStyle(color: Colors.white),
// // // //                 decoration: InputDecoration(
// // // //                   hintText: 'Search stocks...',
// // // //                   hintStyle: TextStyle(color: Colors.white54),
// // // //                   prefixIcon: Icon(Icons.search, color: Colors.white),
// // // //                   filled: true,
// // // //                   fillColor: const Color.fromARGB(41, 0, 0, 0).withOpacity(0.3),
// // // //                   border: OutlineInputBorder(
// // // //                     borderRadius: BorderRadius.circular(12),
// // // //                     borderSide: BorderSide.none,
// // // //                   ),
// // // //                 ),
// // // //                 onChanged: searchStocks,
// // // //               ),
// // // //               SizedBox(height: 16),
// // // //               SizedBox(height: 16),
// // // //               // Category Tabs
// // // //               _buildCategoryTabs(),
// // // //               SizedBox(height: 16),
// // // //               // Filtered Stock List
// // // //           if (searchQuery.isNotEmpty) 
// // // //   SizedBox(
// // // //     height: 300,
// // // //     child: filteredStocks.isNotEmpty
// // // //         ? ListView.builder(
// // // //             itemCount: filteredStocks.length,
// // // //             itemBuilder: (context, index) {
// // // //               final stock = filteredStocks[index];

// // // //               return GestureDetector(
// // // //                 onTap: () {
// // // //                   // Navigate to stock details page with API call
// // // //                   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(
// // // //                      builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),

// // // //                     ),
// // // //                   );
// // // //                 },
// // // //                 child: Card(
// // // //                   color: const Color.fromARGB(54, 33, 33, 33),
// // // //                   shape: RoundedRectangleBorder(
// // // //                     borderRadius: BorderRadius.circular(10),
// // // //                   ),
// // // //                   child: ListTile(
// // // //                     leading: CircleAvatar(
// // // //                       backgroundImage: NetworkImage(stock["logo"]!),
// // // //                     ),
// // // //                     title: Text(
// // // //                       stock["name"]!,
// // // //                       style: TextStyle(color: Colors.white),
// // // //                     ),
// // // //                   ),
// // // //                 ),
// // // //               );
// // // //             },
// // // //           )
// // // //         : Center(
// // // //             child: Text(
// // // //               "No results found",
// // // //               style: TextStyle(color: Colors.grey, fontSize: 16),
// // // //             ),
// // // //           ),
// // // //   ),

// // // //               SizedBox(height: 24),
// // // //               // Region Pills
// // // //               _buildRegionPills(),
// // // //               SizedBox(height: 20),

// // // //               // Market Indices Cards
// // // //               _buildMarketIndicesCards(),
// // // //               SizedBox(height: 24),
// // // //               SizedBox(height: 10),
// // // //               // Most Trending Stocks
// // // //               _buildSectionHeader('Most Traded Stocks'),
// // // //               _buildHorizontalStockList(),
// // // //               SizedBox(height: 10),
              

// // // //                     SizedBox(height: 24),

// // // //               /*/ Navigation Buttons
// // // //               Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
// // // //                 children: [
// // // //                   GestureDetector(
// // // //                     onTap: () {
// // // //                       Navigator.push(
// // // //                         context,
// // // //                         MaterialPageRoute(
// // // //                           builder: (context) => PortfolioPage(),
// // // //                         ),
// // // //                       );
// // // //                     },
// // // //                     child: _buildNavigationItem(
// // // //                       Icons.pie_chart, 'Events',
// // // //                     ),
// // // //                   ),
                 
// // // //                   _buildNavigationItem(Icons.show_chart, 'Indices'),
// // // //                   _buildNavigationItem(Icons.new_label, 'IPO',
// // // //                       iconColor: Colors.red),
// // // //                   _buildNavigationItem(Icons.equalizer, 'Equities'),
// // // //                 ],
// // // //               ), */
// // // //               SizedBox(height: 24),
              
              
              
              
              
              
              
          
// // // //               SizedBox(height: 10),
// // // //               // Trending Section
// // // //              _buildTrendingSection(),
// // // //               SizedBox(height: 16),

// // // //               // Trending Stocks List
// // // //               _buildTrendingStocksList(),

// // // //               // See More Button
// // // //               _buildSeeMoreButton(),
// // // //               SizedBox(height: 24),

// // // //               // Gainers and Losers Section
// // // //               GainersLosersSection(),
              
// // // //               SizedBox(height: 16),
// // // //               _buildSeeMoreButton(),
// // // //               SizedBox(height: 24),
              

// // // //               // Recommendations Section
// // // //               // _buildRecommendationsSection(),
// // // //               SizedBox(height: 24),
// // // //                // Latest News
// // // //               _buildSectionHeadernews('Latest News'),
// // // //               // Call the updated Vertical News List function here
// // // //     _buildVerticalNewsList(context), 
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }


// // // // Widget _buildSectionHeadernews(String title) {
// // // //   return GestureDetector(
// // // //     onTap: () {
// // // //       Navigator.push(
// // // //         context,
// // // //         MaterialPageRoute(builder: (context) => NewsMailScreen()), // Ensure NewsMailScreen is correctly defined in newmail.dart
// // // //       );
// // // //     },
// // // //     child: Padding(
// // // //       padding: const EdgeInsets.only(bottom: 16.0),
// // // //       child: Row(
// // // //         children: [
// // // //           Text(
// // // //             title,
// // // //             style: TextStyle(
// // // //               fontSize: 16,
// // // //               fontWeight: FontWeight.bold,
// // // //               color: Colors.white,
// // // //             ),
// // // //           ),
// // // //           Spacer(),
// // // //           Icon(Icons.arrow_forward, color: Colors.blue),
// // // //         ],
// // // //       ),
// // // //     ),
// // // //   );
// // // // }

// // // //   Widget _buildNavigationItem(IconData icon, String label,
// // // //       {Color iconColor = Colors.white}) {
// // // //     return Column(
// // // //       mainAxisSize: MainAxisSize.min,
// // // //       children: [
// // // //         Container(
// // // //           padding: EdgeInsets.all(8),
// // // //           decoration: BoxDecoration(
// // // //             color: const Color.fromARGB(41, 66, 66, 66),
// // // //             borderRadius: BorderRadius.circular(12),
// // // //           ),
// // // //           child: Icon(icon, color: iconColor, size: 28),
// // // //         ),
// // // //         SizedBox(height: 4),
// // // //         Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
// // // //       ],
// // // //     );
// // // //   }

// // // // Widget _buildHorizontalCards() {
// // // //   return Row(
// // // //     children: [
// // // //       Expanded(
// // // //         child: Container(
// // // //           padding: EdgeInsets.all(16),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.green.withOpacity(0.1),
// // // //             borderRadius: BorderRadius.circular(12),
// // // //             border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
// // // //           ),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                 children: [
// // // //                   Text('Top Gainers', 
// // // //                     style: TextStyle(
// // // //                       color: Colors.green, 
// // // //                       fontWeight: FontWeight.bold
// // // //                     )
// // // //                   ),
// // // //                   Icon(Icons.trending_up, color: Colors.green, size: 20)
// // // //                 ],
// // // //               ),
// // // //               SizedBox(height: 10),
// // // //               Text('+12.5%', 
// // // //                 style: TextStyle(
// // // //                   color: Colors.green, 
// // // //                   fontSize: 18, 
// // // //                   fontWeight: FontWeight.bold
// // // //                 )
// // // //               ),
// // // //               SizedBox(height: 5),
// // // //               Text('Market Insight', 
// // // //                 style: TextStyle(
// // // //                   color: Colors.white54, 
// // // //                   fontSize: 12
// // // //                 )
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //       SizedBox(width: 16),
// // // //       Expanded(
// // // //         child: Container(
// // // //           padding: EdgeInsets.all(16),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.red.withOpacity(0.1),
// // // //             borderRadius: BorderRadius.circular(12),
// // // //             border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
// // // //           ),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               Row(
// // // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                 children: [
// // // //                   Text('Top Losers', 
// // // //                     style: TextStyle(
// // // //                       color: Colors.red, 
// // // //                       fontWeight: FontWeight.bold
// // // //                     )
// // // //                   ),
// // // //                   Icon(Icons.trending_down, color: Colors.red, size: 20)
// // // //                 ],
// // // //               ),
// // // //               SizedBox(height: 10),
// // // //               Text('-8.3%', 
// // // //                 style: TextStyle(
// // // //                   color: Colors.red, 
// // // //                   fontSize: 18, 
// // // //                   fontWeight: FontWeight.bold
// // // //                 )
// // // //               ),
// // // //               SizedBox(height: 5),
// // // //               Text('Market Insight', 
// // // //                 style: TextStyle(
// // // //                   color: Colors.white54, 
// // // //                   fontSize: 12
// // // //                 )
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     ],
// // // //   );
// // // // }

// // // // Widget _buildHorizontalStockList() {
// // // //   // Expanded stock data with more details
// // // //   final List<Map<String, dynamic>> dummyStocks = [
// // // //     {
// // // //       'name': 'BUKA', 
// // // //       'fullName': 'Bukalapak', 
// // // //       'price': '278.00', 
// // // //       'change': '+2.5%', 
// // // //       'color': Colors.green
// // // //     },
// // // //     {
// // // //       'name': 'BBN', 
// // // //       'fullName': 'Bank Negara', 
// // // //       'price': '4,630.00', 
// // // //       'change': '+0.8%', 
// // // //       'color': Colors.green
// // // //     },
// // // //     {
// // // //       'name': 'SDO', 
// // // //       'fullName': 'Sido Muncul', 
// // // //       'price': '24.00', 
// // // //       'change': '-1.2%', 
// // // //       'color': Colors.red
// // // //     },
// // // //     {
// // // //       'name': 'AAPL', 
// // // //       'fullName': 'Apple Inc', 
// // // //       'price': '150.00', 
// // // //       'change': '+0.5%', 
// // // //       'color': Colors.green
// // // //     },
// // // //     {
// // // //       'name': 'GOOGL', 
// // // //       'fullName': 'Alphabet', 
// // // //       'price': '2,800.00', 
// // // //       'change': '-0.3%', 
// // // //       'color': Colors.red
// // // //     },
// // // //   ];

// // // //   return Container(
// // // //     height: 120,
// // // //     child: ListView.builder(
// // // //       scrollDirection: Axis.horizontal,
// // // //       itemCount: dummyStocks.length,
// // // //       itemBuilder: (context, index) {
// // // //         final stock = dummyStocks[index];
// // // //         return GestureDetector(
// // // //           onTap: () {
// // // //             Navigator.push(
// // // //               context,
// // // //               MaterialPageRoute(
// // // //              builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),

// // // //               ),
// // // //             );
// // // //           },
// // // //           child: Container(
// // // //             width: 200,
// // // //             margin: EdgeInsets.only(right: 16),
// // // //             padding: EdgeInsets.all(16),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.grey[900],
// // // //               borderRadius: BorderRadius.circular(12),
// // // //               boxShadow: [
// // // //                 BoxShadow(
// // // //                   color: Colors.black.withOpacity(0.1),
// // // //                   blurRadius: 4,
// // // //                   offset: Offset(0, 2),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //               children: [
// // // //                 Row(
// // // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                   children: [
// // // //                     Text(
// // // //                       stock['name'],
// // // //                       style: TextStyle(
// // // //                         fontSize: 18,
// // // //                         fontWeight: FontWeight.bold,
// // // //                         color: Colors.white,
// // // //                       ),
// // // //                     ),
// // // //                     Icon(
// // // //                       stock['change'].contains('+') 
// // // //                         ? Icons.trending_up 
// // // //                         : Icons.trending_down,
// // // //                       color: stock['color'],
// // // //                       size: 20,
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //                 Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     Text(
// // // //                       stock['fullName'],
// // // //                       style: TextStyle(
// // // //                         fontSize: 12,
// // // //                         color: Colors.white70,
// // // //                       ),
// // // //                     ),
// // // //                     SizedBox(height: 4),
// // // //                     Row(
// // // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //                       children: [
// // // //                         Text(
// // // //                           'Rp${stock['price']}',
// // // //                           style: TextStyle(
// // // //                             fontSize: 16,
// // // //                             fontWeight: FontWeight.bold,
// // // //                             color: Colors.white,
// // // //                           ),
// // // //                         ),
// // // //                         Text(
// // // //                           stock['change'],
// // // //                           style: TextStyle(
// // // //                             fontSize: 14,
// // // //                             color: stock['color'],
// // // //                           ),
// // // //                         ),
// // // //                       ],
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         );
// // // //       },
// // // //     ),
// // // //   );
// // // // }
// // // // /*
// // // //   Widget _buildHorizontalNewsList() {
// // // //     return Container(
// // // //       height: 120,
// // // //       child: ListView.builder(
// // // //         scrollDirection: Axis.horizontal,
// // // //         itemCount: 5,
// // // //         itemBuilder: (context, index) {
// // // //           return Container(
// // // //             width: 200,
// // // //             margin: EdgeInsets.only(right: 16),
// // // //             padding: EdgeInsets.all(12),
// // // //             decoration: BoxDecoration(
// // // //               color: const Color.fromARGB(28, 0, 0, 0),
// // // //               borderRadius: BorderRadius.circular(8),
// // // //             ),
// // // //             child: Text('News Info $index', style: TextStyle(color: Colors.white)),
// // // //           );
// // // //         },
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildSectionHeader(String title) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.only(bottom: 16.0),
// // // //       child: Row(
// // // //         children: [
// // // //           Text(
// // // //             title,
// // // //             style: TextStyle(
// // // //               fontSize: 16,
// // // //               fontWeight: FontWeight.bold,
// // // //               color: Colors.white,
// // // //             ),
// // // //           ),
// // // //           Spacer(),
// // // //           GestureDetector(
// // // //             onTap: () {
// // // //               print('See Detail tapped for $title');
// // // //             },
// // // //             child: Text(
// // // //               'See Detail',
// // // //               style: TextStyle(fontSize: 16, color: Colors.blue),
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }
// // // //   */

// // // //   Widget _buildHeader() {
// // // //     return Row(
// // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //       children: [
// // // //         Text(
// // // //           'Investing',
// // // //           style: TextStyle(
// // // //             fontSize: 28,
// // // //             fontWeight: FontWeight.bold,
// // // //             color: Colors.white,
// // // //           ),
// // // //         ),
// // // //         Container(
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.grey[850]?.withOpacity(0.5),
// // // //             borderRadius: BorderRadius.circular(12),
// // // //           ),
// // // //           child: IconButton(
// // // //             icon: Icon(Icons.settings, color: Colors.white),
// // // //             onPressed: () {
// // // //               Navigator.push(
// // // //                 context,
// // // //                 MaterialPageRoute(builder: (context) => ProfileScreen()),
// // // //               );
// // // //             },
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildCategoryTabs() {
// // // //     List<String> categories = ['Global', 'Crypto', 'Mutual funds', 'CFD'];
// // // //     return SingleChildScrollView(
// // // //       scrollDirection: Axis.horizontal,
// // // //       child: Row(
// // // //         children: categories.map((category) {
// // // //           bool isSelected = category == selectedCategory;
// // // //           return GestureDetector(
// // // //             onTap: () {
// // // //               setState(() {
// // // //                 selectedCategory = category;
// // // //               });
// // // //             },
// // // //             child: Container(
// // // //               margin: EdgeInsets.only(right: 24),
// // // //               padding: EdgeInsets.only(bottom: 8),
// // // //               decoration: BoxDecoration(
// // // //                 border: Border(
// // // //                   bottom: BorderSide(
// // // //                     color: isSelected ? Colors.green : Colors.transparent,
// // // //                     width: 2,
// // // //                   ),
// // // //                 ),
// // // //               ),
// // // //               child: Text(
// // // //                 category,
// // // //                 style: TextStyle(
// // // //                   color: isSelected ? Colors.green : Colors.grey,
// // // //                   fontSize: 16,
// // // //                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           );
// // // //         }).toList(),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildRegionPills() {
// // // //     return SingleChildScrollView(
// // // //       scrollDirection: Axis.horizontal,
// // // //       child: Row(
// // // //         children: [
// // // //           _buildRegionPill('Asia', true),
// // // //           _buildRegionPill('Asia', false),
// // // //           _buildRegionPill('Eropa', false),
// // // //           _buildRegionPill('Amerika', false),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildRegionPill(String text, bool isSelected) {
// // // //     return Container(
// // // //       margin: EdgeInsets.only(right: 8),
// // // //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // //       decoration: BoxDecoration(
// // // //         color: isSelected ? Colors.grey[850] : Colors.transparent,
// // // //         borderRadius: BorderRadius.circular(20),
// // // //         border: Border.all(color: Colors.grey[850]!),
// // // //       ),
// // // //       child: Text(
// // // //         text,
// // // //         style: TextStyle(color: Colors.white),
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildMarketIndicesCards() {
// // // //     return Container(
// // // //       height: 100,
// // // //       child: ListView(
// // // //         scrollDirection: Axis.horizontal,
// // // //         children: [
// // // //           _buildMarketIndex('IH5G', '27,206.92', true, '+1.2%'),
// // // //           _buildMarketIndex('NIKKEI', '2,915.18', false, '-0.8%'),
// // // //           _buildMarketIndex('SENSEI', '14,863.10', true, '+2.1%'),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   Widget _buildMarketIndex(String name, String value, bool isPositive, String percentage) {
// // // //     return Container(
// // // //       width: 150,
// // // //       margin: EdgeInsets.only(right: 12),
// // // //       padding: EdgeInsets.all(12),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.grey[850]?.withOpacity(0.5),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //       ),
// // // //       child: Column(
// // // //         crossAxisAlignment: CrossAxisAlignment.start,
// // // //         mainAxisAlignment: MainAxisAlignment.center,
// // // //         children: [
// // // //           Row(
// // // //             children: [
// // // //               Icon(
// // // //                 isPositive ? Icons.arrow_upward : Icons.arrow_downward,
// // // //                 color: isPositive ? Colors.green : Colors.red,
// // // //                 size: 16,
// // // //               ),
// // // //               SizedBox(width: 4),
// // // //               Text(
// // // //                 name,
// // // //                 style: TextStyle(color: Colors.white),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //           SizedBox(height: 4),
// // // //           Text(
// // // //             value,
// // // //             style: TextStyle(
// // // //               color: Colors.white,
// // // //               fontWeight: FontWeight.bold,
// // // //             ),
// // // //           ),
// // // //           Text(
// // // //             percentage,
// // // //             style: TextStyle(
// // // //               color: isPositive ? Colors.green : Colors.red,
// // // //               fontSize: 12,
// // // //             ),
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //  Widget _buildTrendingSection() {
// // // //   return Row(
// // // //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //     children: [
// // // //       Text(
// // // //         'Top Intraday Stock',
// // // //         style: TextStyle(
// // // //           fontSize: 20,
// // // //           fontWeight: FontWeight.bold,
// // // //           color: Colors.white,
// // // //         ),
// // // //       ),
// // // //       GestureDetector(
// // // //         onTap: () {
// // // //           Navigator.push(
// // // //             context,
// // // //             MaterialPageRoute(builder: (context) => StockPage()),
// // // //           );
// // // //         },
// // // //         child: Container(
// // // //           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.grey[850]?.withOpacity(0.5),
// // // //             borderRadius: BorderRadius.circular(20),
// // // //           ),
// // // //           child: Row(
// // // //             children: [
// // // //               Text(
// // // //                 'See more',
// // // //                 style: TextStyle(color: Colors.white),
// // // //               ),
// // // //               SizedBox(width: 4),
// // // //               Icon(Icons.arrow_forward, color: Colors.white, size: 20),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     ],
// // // //   );
// // // // }

// // // //   Widget _buildTrendingStocksList() {
// // // //     return Column(
// // // //       children: [
// // // //         _buildStockItem('ROTI', 'Nippon Indosari Tbk', '8600.00', '+50', '+3.23%', Colors.amber),
// // // //         _buildStockItem('GOTO', 'GoTo Gojek Tokopedia', '2421.05', '-121', '-20.6%', Colors.green),
// // // //         _buildStockItem('ABNB', 'Airbnb Inc', '5300.50', '+31', '+2.23%', Colors.red),
// // // //         _buildStockItem('UNVR', 'Unilever Indonesia', '3867.10', '-71', '-4.1%', Colors.blue),
// // // //         _buildStockItem('ADRO', 'Adaro Energy Indonesia', '3600.45', '+21', '+3.23%', Colors.grey),
// // // //       ],
// // // //     );
// // // //   }

// // // //   Widget _buildStockItem(String symbol, String name, String price, String change, String percentage, Color logoColor) {
// // // //     return Container(
// // // //       margin: EdgeInsets.only(bottom: 16),
// // // //       padding: EdgeInsets.all(12),
// // // //       decoration: BoxDecoration(
// // // //         color: Colors.grey[850]?.withOpacity(0.3),
// // // //         borderRadius: BorderRadius.circular(12),
// // // //       ),
// // // //       child: Row(
// // // //         children: [
// // // //           Container(
// // // //             width: 40,
// // // //             height: 40,
// // // //             decoration: BoxDecoration(
// // // //               color: logoColor,
// // // //               borderRadius: BorderRadius.circular(8),
// // // //             ),
// // // //             child: Center(
// // // //               child: Text(
// // // //                 symbol[0],
// // // //                 style: TextStyle(
// // // //                   color: Colors.white,
// // // //                   fontWeight: FontWeight.bold,
// // // //                 ),
// // // //               ),
// // // //             ),
// // // //           ),
// // // //           SizedBox(width: 12),
// // // //           Expanded(
// // // //             child: Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.start,
// // // //               children: [
// // // //                 Text(
// // // //                   symbol,
// // // //                   style: TextStyle(
// // // //                     color: Colors.white,
// // // //                     fontWeight: FontWeight.bold,
// // // //                   ),
// // // //                 ),
// // // //                 Text(
// // // //                   name,
// // // //                   style: TextStyle(color: Colors.grey),
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //           Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.end,
// // // //             children: [
// // // //               Text(
// // // //                 price,
// // // //                 style: TextStyle(
// // // //                   color: Colors.white,
// // // //                   fontWeight: FontWeight.bold,
// // // //                 ),
// // // //               ),
// // // //               Text(
// // // //                 '$change ($percentage)',
// // // //                 style: TextStyle(
// // // //                   color: change.contains('-') ? Colors.red : Colors.green,
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ],
// // // //       ),
// // // //     );
// // // //   }

// // // //   // Widget _buildRecommendationsSection() {
// // // //   //   return Column(
// // // //   //     crossAxisAlignment: CrossAxisAlignment.start,
// // // //   //     children: [
// // // //   //       Text(
// // // //   //         'Recommendation',
// // // //   //         style: TextStyle(
// // // //   //           fontSize: 20,
// // // //   //           fontWeight: FontWeight.bold,
// // // //   //           color: Colors.white,
// // // //   //         ),
// // // //   //       ),
// // // //   //       SizedBox(height: 16),
// // // //   //       Row(
// // // //   //         children: [
// // // //   //           Expanded(
// // // //   //             child: _buildRecommendationCard(
// // // //   //               'NFLX',
// // // //   //               'Netflix, Inc',
// // // //   //               '2,122.340',
// // // //   //               '-0.201%',
// // // //   //               Colors.red,
// // // //   //               false,
// // // //   //             ),
// // // //   //           ),
// // // //   //           SizedBox(width: 12),
// // // //   //           Expanded(
// // // //   //             child: _buildRecommendationCard(
// // // //   //               'META',
// // // //   //               'Meta Platforms',
// // // //   //               '987.890',
// // // //   //               '+1.29%',
// // // //   //               Colors.blue,
// // // //   //               true,
// // // //   //             ),
// // // //   //           ),
// // // //   //           SizedBox(width: 12),
// // // //   //           Expanded(
// // // //   //             child: _buildRecommendationCard(
// // // //   //               'AMZN',
// // // //   //               'Amazon.com, Inc',
// // // //   //               '1,001.333',
// // // //   //               '-8.20%',
// // // //   //               Colors.orange,
// // // //   //               false,
// // // //   //             ),
// // // //   //           ),
// // // //   //         ],
// // // //   //       ),
// // // //   //     ],
// // // //   //   );
// // // //   // }

// // // //   // Widget _buildRecommendationCard(
// // // //   //   String symbol,
// // // //   //   String name,
// // // //   //   String price,
// // // //   //   String change,
// // // //   //   Color tagColor,
// // // //   //   bool isPositive,
// // // //   // ) {
// // // //   //   return Container(
// // // //   //     padding: EdgeInsets.all(12),
// // // //   //     decoration: BoxDecoration(
// // // //   //       color: Colors.grey[850]?.withOpacity(0.5),
// // // //   //       borderRadius: BorderRadius.circular(12),
// // // //   //     ),
// // // //   //     child: Column(
// // // //   //       crossAxisAlignment: CrossAxisAlignment.start,
// // // //   //       children: [
// // // //   //         Container(
// // // //   //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // //   //           decoration: BoxDecoration(
// // // //   //             color: tagColor,
// // // //   //             borderRadius: BorderRadius.circular(4),
// // // //   //           ),
// // // //   //           child: Text(
// // // //   //             symbol,
// // // //   //             style: TextStyle(
// // // //   //               color: Colors.white,
// // // //   //               fontWeight: FontWeight.bold,
// // // //   //               fontSize: 12,
// // // //   //             ),
// // // //   //           ),
// // // //   //         ),
// // // //   //         SizedBox(height: 8),
// // // //   //         Text(
// // // //   //           name,
// // // //   //           style: TextStyle(color: Colors.grey[400], fontSize: 12),
// // // //   //           maxLines: 1,
// // // //   //           overflow: TextOverflow.ellipsis,
// // // //   //         ),
// // // //   //         SizedBox(height: 4),
// // // //   //         Text(
// // // //   //           price,
// // // //   //           style: TextStyle(
// // // //   //             color: Colors.white,
// // // //   //             fontWeight: FontWeight.bold,
// // // //   //             fontSize: 16,
// // // //   //           ),
// // // //   //         ),
// // // //   //         Text(
// // // //   //           change,
// // // //   //           style: TextStyle(
// // // //   //             color: isPositive ? Colors.green : Colors.red,
// // // //   //             fontSize: 12,
// // // //   //           ),
// // // //   //         ),
// // // //   //       ],
// // // //   //     ),
// // // //   //   );
// // // //   // }

// // // //   Widget _buildSeeMoreButton() {
// // // //     return Center(
// // // //       child: TextButton(
// // // //         onPressed: () {},
// // // //         child: Row(
// // // //           mainAxisSize: MainAxisSize.min,
// // // //           children: [
// // // //             Text(
// // // //               'See More',
// // // //               style: TextStyle(color: Colors.green),
// // // //             ),
// // // //             Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class GainersLosersSection extends StatelessWidget {
// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Column(
// // // //       children: [
// // // //         _buildHeader(context, title: 'Top Gainers'),
// // // //         SizedBox(height: 16),
// // // //         _buildStocksList(context, [
// // // //           _buildStockItem(context, 'TSLA', 'Tesla Inc', '1100.00', '+100', '+10.0%', Colors.green),
// // // //           _buildStockItem(context, 'AAPL', 'Apple Inc', '145.50', '+5', '+3.5%', Colors.green),
// // // //           _buildStockItem(context, 'MSFT', 'Microsoft Corp', '299.75', '+9', '+3.1%', Colors.green),
// // // //         ]),
// // // //         SizedBox(height: 20),
// // // //         _buildHeader(context, title: 'Top Losers'),
// // // //         SizedBox(height: 16),
// // // //         _buildStocksList(context, [
// // // //           _buildStockItem(context, 'NFLX', 'Netflix Inc', '390.00', '-50', '-11.0%', Colors.red),
// // // //           _buildStockItem(context, 'AMZN', 'Amazon Inc', '3200.00', '-150', '-4.5%', Colors.red),
// // // //           _buildStockItem(context, 'GOOG', 'Alphabet Inc', '2850.30', '-30', '-2.1%', Colors.red),
// // // //         ]),
// // // //       ],
// // // //     );
// // // //   }

// // // //   // Header with "See More" button
// // // //   Widget _buildHeader(BuildContext context, {required String title}) {
// // // //     return Row(
// // // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //       children: [
// // // //         Text(
// // // //           title,
// // // //           style: TextStyle(
// // // //             fontSize: 20,
// // // //             fontWeight: FontWeight.bold,
// // // //             color: Colors.white,
// // // //           ),
// // // //         ),
// // // //         GestureDetector(
// // // //           onTap: () {
// // // //             Navigator.push(
// // // //               context,
// // // //               MaterialPageRoute(builder: (context) => StockPage()), // Navigate to full stock list
// // // //             );
// // // //           },
// // // //           child: Container(
// // // //             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // // //             decoration: BoxDecoration(
// // // //               color: Colors.grey[850]?.withOpacity(0.5),
// // // //               borderRadius: BorderRadius.circular(20),
// // // //             ),
// // // //             child: Row(
// // // //               children: [
// // // //                 Text(
// // // //                   'See more',
// // // //                   style: TextStyle(color: Colors.white),
// // // //                 ),
// // // //                 SizedBox(width: 4),
// // // //                 Icon(Icons.arrow_forward, color: Colors.white, size: 20),
// // // //               ],
// // // //             ),
// // // //           ),
// // // //         ),
// // // //       ],
// // // //     );
// // // //   }

// // // //   // Builds a list of stocks
// // // //   Widget _buildStocksList(BuildContext context, List<Widget> stocks) {
// // // //     return Column(children: stocks);
// // // //   }

// // // //   // Single Stock Item - Now Clickable
// // // //   Widget _buildStockItem(BuildContext context, String symbol, String name, String price, String change, String percentChange, Color color) {
// // // //     return GestureDetector(
// // // //       onTap: () {
// // // //         Navigator.push(
// // // //           context,
// // // //           MaterialPageRoute(builder: (context) => details.StockDetailsPage(stockName: symbol)),
// // // //         );
// // // //       },
// // // //       child: Container(
// // // //         padding: EdgeInsets.all(12),
// // // //         margin: EdgeInsets.symmetric(vertical: 6),
// // // //         decoration: BoxDecoration(
// // // //           color: Colors.grey[850]?.withOpacity(0.5),
// // // //           borderRadius: BorderRadius.circular(12),
// // // //         ),
// // // //         child: Row(
// // // //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // // //           children: [
// // // //             Row(
// // // //               children: [
// // // //                 CircleAvatar(
// // // //                   backgroundColor: color.withOpacity(0.2),
// // // //                   child: Text(symbol, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// // // //                 ),
// // // //                 SizedBox(width: 10),
// // // //                 Column(
// // // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // // //                   children: [
// // // //                     Text(name, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
// // // //                     Text(price, style: TextStyle(color: Colors.grey[400])),
// // // //                   ],
// // // //                 ),
// // // //               ],
// // // //             ),
// // // //             Column(
// // // //               crossAxisAlignment: CrossAxisAlignment.end,
// // // //               children: [
// // // //                 Text(change, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// // // //                 Text(percentChange, style: TextStyle(color: color)),
// // // //               ],
// // // //             ),
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }




// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;
// // // import 'package:test_project/features/profile/profile.dart';
// // // import 'package:test_project/features/portfolio/portfolio.dart';
// // // import 'package:test_project/features/news/news.dart';
// // // import 'package:test_project/features/news/newsmail.dart';
// // // import 'package:test_project/features/stock/stock.dart';
// // // import 'package:test_project/features/stock/stock_details.dart' as details;
// // // import 'package:test_project/features/notifications/notification.dart';
// // // import 'package:test_project/features/screener/screener.dart';
// // // import 'package:test_project/features/simulator/stock_stimulator.dart';

// // // class TrendingScreen extends StatefulWidget {
// // //   @override
// // //   _TrendingScreenState createState() => _TrendingScreenState();
// // // }

// // // class _TrendingScreenState extends State<TrendingScreen> {
// // //    String apiKey = "XH0MOF8FACW6RR0L"; // Your API Key
// // //   List<dynamic> newsData = [];

// // //   bool isSearchingStimulator = false; // Track search mode
  






// // // //news
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     filteredStocks = allStocks;
// // //     fetchNews();
// // //   }

// // //   Future<void> fetchNews() async {
// // //     final url = Uri.parse(
// // //         "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

// // //     final response = await http.get(url);

// // //     if (response.statusCode == 200) {
// // //       final data = json.decode(response.body);
// // //       setState(() {
// // //         newsData = data["feed"] ?? []; // Extracting the news feed list
// // //       });
// // //     } else {
// // //       print("Failed to load news");
// // //     }
// // //   }



// // //   // New method: Search Bar with Switch Button
// // //   Widget _buildSearchBarWithSwitch() {
// // //     return Row(
// // //       children: [
// // //         Expanded(
// // //           child: TextField(
// // //             style: TextStyle(color: Colors.black),
// // //             decoration: InputDecoration(
// // //               hintText: isSearchingStimulator 
// // //                   ? 'Search stimulator stocks...' 
// // //                   : 'Search stocks...',
// // //               hintStyle: TextStyle(color: Colors.grey[600]),
// // //               prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
// // //               filled: true,
// // //               fillColor: Colors.grey[100],
// // //               border: OutlineInputBorder(
// // //                 borderRadius: BorderRadius.circular(12),
// // //                 borderSide: BorderSide.none,
// // //               ),
// // //             ),
// // //             onChanged: searchStocks,
// // //           ),
// // //         ),
// // //         SizedBox(width: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Colors.grey[100],
// // //             borderRadius: BorderRadius.circular(12),
// // //           ),
// // //           child: IconButton(
// // //             icon: Icon(
// // //               isSearchingStimulator ? Icons.switch_right : Icons.switch_left,
// // //               color: isSearchingStimulator ? Colors.deepPurple : Colors.grey[600],
// // //             ),
// // //             onPressed: toggleSearchMode,
// // //             tooltip: isSearchingStimulator 
// // //                 ? 'Switch to Regular Stocks' 
// // //                 : 'Switch to Stimulator Stocks',
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }

// // //   // New method: Build search results based on current mode
// // //   Widget _buildSearchResults() {
// // //     final currentList = isSearchingStimulator ? filteredStimulatorStocks : filteredStocks;
// // //     final isEmpty = isSearchingStimulator 
// // //         ? filteredStimulatorStocks.isEmpty 
// // //         : filteredStocks.isEmpty;

// // //     return SizedBox(
// // //       height: 300,
// // //       child: isEmpty
// // //           ? Center(
// // //               child: Text(
// // //                 "No results found",
// // //                 style: TextStyle(color: Colors.grey[600], fontSize: 16),
// // //               ),
// // //             )
// // //           : ListView.builder(
// // //               itemCount: currentList.length,
// // //               itemBuilder: (context, index) {
// // //                 final stock = currentList[index];

// // //                 return GestureDetector(
// // //                   onTap: () {
// // //                     // Navigate to appropriate details page based on search mode
// // //                     if (isSearchingStimulator) {
// // //                       // Navigate to stimulator stock details
// // //                       Navigator.push(
// // //                         context,
// // //                         MaterialPageRoute(
// // //                           builder: (context) => StockStimulatorDetailsPage(stockName: stock["name"]!),
// // //                         ),
// // //                       );
// // //                     } else {
// // //                       // Navigate to regular stock details
// // //                       Navigator.push(
// // //                         context,
// // //                         MaterialPageRoute(
// // //                           builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),
// // //                         ),
// // //                       );
// // //                     }
// // //                   },
// // //                   child: Card(
// // //                     color: Colors.grey[50],
// // //                     elevation: 2,
// // //                     shape: RoundedRectangleBorder(
// // //                       borderRadius: BorderRadius.circular(10),
// // //                     ),
// // //                     child: ListTile(
// // //                       leading: CircleAvatar(
// // //                         backgroundImage: NetworkImage(stock["logo"]!),
// // //                       ),
// // //                       title: Text(
// // //                         stock["name"]!,
// // //                         style: TextStyle(color: Colors.black),
// // //                       ),
// // //                       subtitle: Text(
// // //                         isSearchingStimulator ? "Stimulator Stock" : "Regular Stock",
// // //                         style: TextStyle(color: Colors.grey[600], fontSize: 12),
// // //                       ),
// // //                       trailing: Icon(
// // //                         Icons.arrow_forward_ios,
// // //                         color: Colors.deepPurple,
// // //                         size: 16,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 );
// // //               },
// // //             ),
// // //     );
// // //   }
// // //  Widget _buildVerticalNewsList(BuildContext context) {
// // //   return Container(
// // //     child: newsData.isEmpty
// // //         ? Center(
// // //             child: CircularProgressIndicator(
// // //               color: Colors.deepPurple,
// // //             ),
// // //           ) // Show loading indicator with theme color
// // //         : ListView.builder(
// // //             shrinkWrap: true, // Ensures it takes only required space
// // //             physics: NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
// // //             itemCount: newsData.length > 5 ? 5 : newsData.length, // Limits display to 5 items
// // //             itemBuilder: (context, index) {
// // //               var newsItem = newsData[index];
// // //               return GestureDetector(
// // //                 onTap: () {
// // //                   Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => NewsDetailScreen(newsItem: newsItem)),
// // //                   );
// // //                 },
// // //                 child: Container(
// // //                   margin: EdgeInsets.symmetric(vertical: 8),
// // //                   decoration: BoxDecoration(
// // //                     borderRadius: BorderRadius.circular(12),
// // //                     color: Colors.transparent,
// // //                     border: Border.all(
// // //                       color: Colors.grey[300]!,
// // //                       width: 1,
// // //                     ),
// // //                   ),
// // //                   child: Padding(
// // //                     padding: EdgeInsets.all(12),
// // //                     child: Row(
// // //                       children: [
// // //                         Expanded(
// // //                           child: Column(
// // //                             crossAxisAlignment: CrossAxisAlignment.start,
// // //                             children: [
// // //                               Text(
// // //                                 newsItem["title"] ?? "No Title",
// // //                                 maxLines: 2,
// // //                                 overflow: TextOverflow.ellipsis,
// // //                                 style: TextStyle(
// // //                                   color: Colors.black,
// // //                                   fontSize: 16,
// // //                                   fontWeight: FontWeight.bold,
// // //                                 ),
// // //                               ),
// // //                               SizedBox(height: 4),
// // //                               Text(
// // //                                 newsItem["subtitle"] ?? newsItem["source"] ?? "",
// // //                                 maxLines: 1,
// // //                                 overflow: TextOverflow.ellipsis,
// // //                                 style: TextStyle(
// // //                                   color: Colors.grey[600],
// // //                                   fontSize: 13,
// // //                                 ),
// // //                               ),
// // //                             ],
// // //                           ),
// // //                         ),
// // //                         SizedBox(width: 8),
// // //                         Container(
// // //                           padding: EdgeInsets.all(8),
// // //                           decoration: BoxDecoration(
// // //                             shape: BoxShape.circle,
// // //                             color: Colors.deepPurple.withOpacity(0.1),
// // //                           ),
// // //                           child: Icon(
// // //                             Icons.arrow_forward,
// // //                             color: Colors.deepPurple,
// // //                             size: 16,
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           ),
// // //   );
// // // }

// // //   void _showNewsDetail(Map<String, dynamic> newsItem) {
// // //     showDialog(
// // //       context: context,
// // //       builder: (context) {
// // //         return AlertDialog(
// // //           backgroundColor: Colors.white,
// // //           title: Text(newsItem["title"] ?? "News Detail", style: TextStyle(color: Colors.black)),
// // //           content: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Text(newsItem["summary"] ?? "No Summary Available", style: TextStyle(color: Colors.black)),
// // //               SizedBox(height: 10),
// // //               Text("Sentiment Score: ${newsItem["sentiment_score"]}", style: TextStyle(color: Colors.black)),
// // //               SizedBox(height: 10),
// // //               newsItem["url"] != null
// // //                   ? TextButton(
// // //                       onPressed: () {
// // //                         // Implement URL opening (e.g., using url_launcher package)
// // //                       },
// // //                       child: Text("Read More", style: TextStyle(color: Colors.deepPurple)),
// // //                     )
// // //                   : Container(),
// // //             ],
// // //           ),
// // //           actions: [
// // //             TextButton(
// // //               onPressed: () => Navigator.pop(context),
// // //               child: Text("Close", style: TextStyle(color: Colors.deepPurple)),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }


// // //   Widget _buildSectionHeader(String title) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 16.0),
// // //       child: Row(
// // //         children: [
// // //           Text(
// // //             title,
// // //             style: TextStyle(
// // //               fontSize: 16,
// // //               fontWeight: FontWeight.bold,
// // //               color: Colors.black,
// // //             ),
// // //           ),
// // //           Spacer(),
// // //           GestureDetector(
// // //             onTap: () {
// // //               print('See Detail tapped for $title');
// // //             },
// // //             child: Text(
// // //               'See Detail',
// // //               style: TextStyle(fontSize: 16, color: Colors.deepPurple),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   String selectedTimeframe = '24 hour';
// // //   String selectedCategory = 'Global';
// // //   int _selectedIndex = 0; // For tracking the selected tab

// // //   List<Map<String, String>> allStocks = [
// // //     {"name": "ibm", "logo": "https://logo.clearbit.com/ibm.com"},
// // //     {"name": "BUKA", "logo": "https://logo.clearbit.com/amazon.com"},
// // //     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
// // //     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
// // //     {"name": "GOOGL", "logo": "https://logo.clearbit.com/google.com"},
// // //     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
// // //     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
// // //   ];
 

// // //   // Add stimulator stocks list
// // //   List<Map<String, String>> allStimulatorStocks = [
// // //     {"name": "STIM_A", "logo": "https://logo.clearbit.com/ibm.com"},
// // //     {"name": "STIM_B", "logo": "https://logo.clearbit.com/amazon.com"},
// // //     {"name": "STIM_MSFT", "logo": "https://logo.clearbit.com/microsoft.com"},
// // //     {"name": "STIM_TSLA", "logo": "https://logo.clearbit.com/tesla.com"},
// // //     {"name": "STIM_GOOG", "logo": "https://logo.clearbit.com/google.com"},
// // //   ];

// // //   List<Map<String, String>> filteredStocks = [];
// // //   List<Map<String, String>> filteredStimulatorStocks = [];
// // //   String searchQuery = "";

// // //   bool isLoading = false;

// // //   /*@override
// // //   void initState() {
// // //     super.initState();
// // //     filteredStocks = allStocks;
// // //   }
// // // */
// // //   void _onItemTapped(int index) {
// // //     setState(() {
// // //       _selectedIndex = index;
// // //     });
// // //   }

// // //  void searchStocks(String query) {
// // //     setState(() {
// // //       searchQuery = query;
// // //       if (isSearchingStimulator) {
// // //         filteredStimulatorStocks = allStimulatorStocks
// // //             .where((stock) =>
// // //                 stock["name"]!.toLowerCase().startsWith(query.toLowerCase()))
// // //             .toList();
// // //       } else {
// // //         filteredStocks = allStocks
// // //             .where((stock) =>
// // //                 stock["name"]!.toLowerCase().startsWith(query.toLowerCase()))
// // //             .toList();
// // //       }
// // //     });
// // //   }

// // //   void toggleSearchMode() {
// // //     setState(() {
// // //       isSearchingStimulator = !isSearchingStimulator;
// // //       searchQuery = ""; // Clear search query when switching modes
// // //       filteredStocks = allStocks;
// // //       filteredStimulatorStocks = allStimulatorStocks;
// // //     });
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       body: SafeArea(
// // //         child: ListView(
// // //           padding: const EdgeInsets.all(16.0),
// // //           children: [
// // //             SizedBox(height: 8),
// // //             _buildHeader(),
// // //             SizedBox(height: 20),
// // //             SizedBox(height: 16),
            
// // //             // Updated Search Bar with Switch Button
// // //             _buildSearchBarWithSwitch(),
            
// // //             SizedBox(height: 16),
// // //             SizedBox(height: 16),
            
// // //             // Category Tabs
// // //             _buildCategoryTabs(),
// // //             SizedBox(height: 16),
            
// // //             // Filtered Stock List based on search mode
// // //             if (searchQuery.isNotEmpty) 
// // //               _buildSearchResults(),
            
// // //             SizedBox(height: 10),
            
// // //             // Most Trending Stocks
// // //             _buildSectionHeader('Most Traded Stocks'),
// // //             _buildHorizontalStockList(),
// // //             SizedBox(height: 10),
            
// // //             SizedBox(height: 24),
// // //             SizedBox(height: 10),
            
// // //             // Trending Section
// // //             _buildTrendingSection(),
// // //             SizedBox(height: 16),
            
// // //             // Trending Stocks List
// // //             _buildTrendingStocksList(),
            
// // //             // Gainers and Losers Section
// // //             GainersLosersSection(),
            
// // //             SizedBox(height: 16),
// // //             SizedBox(height: 24),
            
// // //             // Latest News
// // //             _buildSectionHeadernews('Latest News'),
// // //             _buildVerticalNewsList(context),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }



// // // Widget _buildSectionHeadernews(String title) {
// // //   return GestureDetector(
// // //     onTap: () {
// // //       Navigator.push(
// // //         context,
// // //         MaterialPageRoute(builder: (context) => NewsMailScreen()), // Ensure NewsMailScreen is correctly defined in newmail.dart
// // //       );
// // //     },
// // //     child: Padding(
// // //       padding: const EdgeInsets.only(bottom: 16.0),
// // //       child: Row(
// // //         children: [
// // //           Text(
// // //             title,
// // //             style: TextStyle(
// // //               fontSize: 16,
// // //               fontWeight: FontWeight.bold,
// // //               color: Colors.black,
// // //             ),
// // //           ),
// // //           Spacer(),
// // //           Icon(Icons.arrow_forward, color: Colors.deepPurple),
// // //         ],
// // //       ),
// // //     ),
// // //   );
// // // }

// // //   Widget _buildNavigationItem(IconData icon, String label,
// // //       {Color iconColor = Colors.black}) {
// // //     return Column(
// // //       mainAxisSize: MainAxisSize.min,
// // //       children: [
// // //         Container(
// // //           padding: EdgeInsets.all(8),
// // //           decoration: BoxDecoration(
// // //             color: Colors.grey[100],
// // //             borderRadius: BorderRadius.circular(12),
// // //           ),
// // //           child: Icon(icon, color: iconColor, size: 28),
// // //         ),
// // //         SizedBox(height: 4),
// // //         Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
// // //       ],
// // //     );
// // //   }

// // // Widget _buildHorizontalCards() {
// // //   return Row(
// // //     children: [
// // //       Expanded(
// // //         child: Container(
// // //           padding: EdgeInsets.all(16),
// // //           decoration: BoxDecoration(
// // //             color: Colors.green.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
// // //           ),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   Text('Top Gainers', 
// // //                     style: TextStyle(
// // //                       color: Colors.green, 
// // //                       fontWeight: FontWeight.bold
// // //                     )
// // //                   ),
// // //                   Icon(Icons.trending_up, color: Colors.green, size: 20)
// // //                 ],
// // //               ),
// // //               SizedBox(height: 10),
// // //               Text('+12.5%', 
// // //                 style: TextStyle(
// // //                   color: Colors.green, 
// // //                   fontSize: 18, 
// // //                   fontWeight: FontWeight.bold
// // //                 )
// // //               ),
// // //               SizedBox(height: 5),
// // //               Text('Market Insight', 
// // //                 style: TextStyle(
// // //                   color: Colors.grey[600], 
// // //                   fontSize: 12
// // //                 )
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //       SizedBox(width: 16),
// // //       Expanded(
// // //         child: Container(
// // //           padding: EdgeInsets.all(16),
// // //           decoration: BoxDecoration(
// // //             color: Colors.red.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
// // //           ),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   Text('Top Losers', 
// // //                     style: TextStyle(
// // //                       color: Colors.red, 
// // //                       fontWeight: FontWeight.bold
// // //                     )
// // //                   ),
// // //                   Icon(Icons.trending_down, color: Colors.red, size: 20)
// // //                 ],
// // //               ),
// // //               SizedBox(height: 10),
// // //               Text('-8.3%', 
// // //                 style: TextStyle(
// // //                   color: Colors.red, 
// // //                   fontSize: 18, 
// // //                   fontWeight: FontWeight.bold
// // //                 )
// // //               ),
// // //               SizedBox(height: 5),
// // //               Text('Market Insight', 
// // //                 style: TextStyle(
// // //                   color: Colors.grey[600], 
// // //                   fontSize: 12
// // //                 )
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     ],
// // //   );
// // // }

// // // Widget _buildHorizontalStockList() {
// // //   // Expanded stock data with more details
// // //   final List<Map<String, dynamic>> dummyStocks = [
// // //     {
// // //       'name': 'BUKA', 
// // //       'fullName': 'Bukalapak', 
// // //       'price': '278.00', 
// // //       'change': '+2.5%', 
// // //       'color': Colors.green
// // //     },
// // //     {
// // //       'name': 'BBN', 
// // //       'fullName': 'Bank Negara', 
// // //       'price': '4,630.00', 
// // //       'change': '+0.8%', 
// // //       'color': Colors.green
// // //     },
// // //     {
// // //       'name': 'SDO', 
// // //       'fullName': 'Sido Muncul', 
// // //       'price': '24.00', 
// // //       'change': '-1.2%', 
// // //       'color': Colors.red
// // //     },
// // //     {
// // //       'name': 'AAPL', 
// // //       'fullName': 'Apple Inc', 
// // //       'price': '150.00', 
// // //       'change': '+0.5%', 
// // //       'color': Colors.green
// // //     },
// // //     {
// // //       'name': 'GOOGL', 
// // //       'fullName': 'Alphabet', 
// // //       'price': '2,800.00', 
// // //       'change': '-0.3%', 
// // //       'color': Colors.red
// // //     },
// // //   ];

// // //   return Container(
// // //     height: 120,
// // //     child: ListView.builder(
// // //       scrollDirection: Axis.horizontal,
// // //       itemCount: dummyStocks.length,
// // //       itemBuilder: (context, index) {
// // //         final stock = dummyStocks[index];
// // //         return GestureDetector(
// // //           onTap: () {
// // //             Navigator.push(
// // //               context,
// // //               MaterialPageRoute(
// // //            builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),

// // //             ),
// // //             );
// // //           },
// // //           child: Container(
// // //             width: 200,
// // //             margin: EdgeInsets.only(right: 16),
// // //             padding: EdgeInsets.all(16),
// // //             decoration: BoxDecoration(
// // //               color: Colors.white,
// // //               borderRadius: BorderRadius.circular(12),
// // //               border: Border.all(color: Colors.grey[300]!, width: 1),
// // //               boxShadow: [
// // //                 BoxShadow(
// // //                   color: Colors.grey.withOpacity(0.1),
// // //                   blurRadius: 4,
// // //                   offset: Offset(0, 2),
// // //                 ),
// // //               ],
// // //             ),
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //               children: [
// // //                 Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: [
// // //                     Text(
// // //                       stock['name'],
// // //                       style: TextStyle(
// // //                         fontSize: 18,
// // //                         fontWeight: FontWeight.bold,
// // //                         color: Colors.black,
// // //                       ),
// // //                     ),
// // //                     Icon(
// // //                       stock['change'].contains('+') 
// // //                         ? Icons.trending_up 
// // //                         : Icons.trending_down,
// // //                       color: stock['color'],
// // //                       size: 20,
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(
// // //                       stock['fullName'],
// // //                       style: TextStyle(
// // //                         fontSize: 12,
// // //                         color: Colors.grey[600],
// // //                       ),
// // //                     ),
// // //                     SizedBox(height: 4),
// // //                     Row(
// // //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                       children: [
// // //                         Text(
// // //                           'Rp${stock['price']}',
// // //                           style: TextStyle(
// // //                             fontSize: 16,
// // //                             fontWeight: FontWeight.bold,
// // //                             color: Colors.black,
// // //                           ),
// // //                         ),
// // //                         Text(
// // //                           stock['change'],
// // //                           style: TextStyle(
// // //                             fontSize: 14,
// // //                             color: stock['color'],
// // //                           ),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         );
// // //       },
// // //     ),
// // //   );
// // // }
// // // /*
// // //   Widget _buildHorizontalNewsList() {
// // //     return Container(
// // //       height: 120,
// // //       child: ListView.builder(
// // //         scrollDirection: Axis.horizontal,
// // //         itemCount: 5,
// // //         itemBuilder: (context, index) {
// // //           return Container(
// // //             width: 200,
// // //             margin: EdgeInsets.only(right: 16),
// // //             padding: EdgeInsets.all(12),
// // //             decoration: BoxDecoration(
// // //               color: const Color.fromARGB(28, 0, 0, 0),
// // //               borderRadius: BorderRadius.circular(8),
// // //             ),
// // //             child: Text('News Info $index', style: TextStyle(color: Colors.white)),
// // //           );
// // //         },
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildSectionHeader(String title) {
// // //     return Padding(
// // //       padding: const EdgeInsets.only(bottom: 16.0),
// // //       child: Row(
// // //         children: [
// // //           Text(
// // //             title,
// // //             style: TextStyle(
// // //               fontSize: 16,
// // //               fontWeight: FontWeight.bold,
// // //               color: Colors.white,
// // //             ),
// // //           ),
// // //           Spacer(),
// // //           GestureDetector(
// // //             onTap: () {
// // //               print('See Detail tapped for $title');
// // //             },
// // //             child: Text(
// // //               'See Detail',
// // //               style: TextStyle(fontSize: 16, color: Colors.blue),
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }
// // //   */

// // //   Widget _buildHeader() {
// // //     return Row(
// // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //       children: [
// // //         Text(
// // //           'Strategy Builder',
// // //           style: TextStyle(
// // //             fontSize: 28,
// // //             fontWeight: FontWeight.bold,
// // //             color: Colors.black,
// // //           ),
// // //         ),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Colors.grey[100],
// // //             borderRadius: BorderRadius.circular(12),
// // //           ),
// // //           child: IconButton(
// // //  icon: Icon(Icons.notifications, size: 24, color: Colors.black),
// // //                   onPressed: () {
// // //                     Navigator.push(
// // //                       context,
// // //                       MaterialPageRoute(
// // //                           builder: (context) => NotificationScreen()),
// // //                     );
// // //             },
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // // Widget _buildCategoryTabs() {
// // //   // Categories with icons
// // //   List<Map<String, dynamic>> categories = [
// // //     {'name': 'Custom', 'icon': Icons.star},
// // //     {'name': 'Breakout', 'icon': Icons.trending_up},
// // //     {'name': 'Bounce', 'icon': Icons.show_chart},
// // //     {'name': 'Moving Average', 'icon': Icons.timeline},
// // //     {'name': 'Percent Price Change', 'icon': Icons.percent},
// // //   ];

// // //   return SingleChildScrollView(
// // //     scrollDirection: Axis.vertical,
// // //     child: Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: categories.map((category) {
// // //         bool isSelected = category['name'] == selectedCategory;
// // //         return GestureDetector(
// // //           onTap: () {
// // //             // Navigate to screener page if Custom is selected
// // //             if (category['name'] == 'Custom') {
// // //               Navigator.push(
// // //                 context,
// // //                 MaterialPageRoute(
// // //                   builder: (context) => StockScreenerPage(),
// // //                 ),
// // //               );
// // //             } else {
// // //               // Update selected category for other tabs
// // //               setState(() {
// // //                 selectedCategory = category['name'];
// // //               });
// // //             }
// // //           },
// // //           child: Container(
// // //             decoration: BoxDecoration(
// // //               color: isSelected 
// // //                   ? Colors.deepPurple.withOpacity(0.1) 
// // //                   : Colors.transparent,
// // //               borderRadius: BorderRadius.circular(8),
// // //               border: category['name'] == 'Custom' 
// // //                   ? Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1)
// // //                   : null,
// // //             ),
// // //             child: Padding(
// // //               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
// // //               child: Row(
// // //                 children: [
// // //                   Icon(
// // //                     category['icon'],
// // //                     color: isSelected ? Colors.deepPurple : Colors.grey[600],
// // //                     size: 22,
// // //                   ),
// // //                   SizedBox(width: 12),
// // //                   Expanded(
// // //                     child: Text(
// // //                       category['name'],
// // //                       style: TextStyle(
// // //                         color: isSelected ? Colors.deepPurple : Colors.grey[700],
// // //                         fontSize: 16,
// // //                         fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   // Add navigation indicator for Custom tab
// // //                   if (category['name'] == 'Custom')
// // //                     Icon(
// // //                       Icons.arrow_forward_ios,
// // //                       color: Colors.deepPurple.withOpacity(0.7),
// // //                       size: 16,
// // //                     ),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         );
// // //       }).toList(),
// // //     ),
// // //   );
// // // }

// // //   Widget _buildRegionPills() {
// // //     return SingleChildScrollView(
// // //       scrollDirection: Axis.horizontal,
// // //       child: Row(
// // //         children: [
// // //           _buildRegionPill('Asia', true),
// // //           _buildRegionPill('Asia', false),
// // //           _buildRegionPill('Eropa', false),
// // //           _buildRegionPill('Amerika', false),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildRegionPill(String text, bool isSelected) {
// // //     return Container(
// // //       margin: EdgeInsets.only(right: 8),
// // //       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //       decoration: BoxDecoration(
// // //         color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.transparent,
// // //         borderRadius: BorderRadius.circular(20),
// // //         border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey[300]!),
// // //       ),
// // //       child: Text(
// // //         text,
// // //         style: TextStyle(color: isSelected ? Colors.deepPurple : Colors.black),
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildMarketIndicesCards() {
// // //     return Container(
// // //       height: 100,
// // //       child: ListView(
// // //         scrollDirection: Axis.horizontal,
// // //         children: [
// // //           _buildMarketIndex('IH5G', '27,206.92', true, '+1.2%'),
// // //           _buildMarketIndex('NIKKEI', '2,915.18', false, '-0.8%'),
// // //           _buildMarketIndex('SENSEI', '14,863.10', true, '+2.1%'),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildMarketIndex(String name, String value, bool isPositive, String percentage) {
// // //     return Container(
// // //       width: 150,
// // //       margin: EdgeInsets.only(right: 12),
// // //       padding: EdgeInsets.all(12),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: Colors.grey[300]!, width: 1),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.grey.withOpacity(0.1),
// // //             blurRadius: 4,
// // //             offset: Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Column(
// // //         crossAxisAlignment: CrossAxisAlignment.start,
// // //         mainAxisAlignment: MainAxisAlignment.center,
// // //         children: [
// // //           Row(
// // //             children: [
// // //               Icon(
// // //                 isPositive ? Icons.arrow_upward : Icons.arrow_downward,
// // //                 color: isPositive ? Colors.green : Colors.red,
// // //                 size: 16,
// // //               ),
// // //               SizedBox(width: 4),
// // //               Text(
// // //                 name,
// // //                 style: TextStyle(color: Colors.black),
// // //               ),
// // //             ],
// // //           ),
// // //           SizedBox(height: 4),
// // //           Text(
// // //             value,
// // //             style: TextStyle(
// // //               color: Colors.black,
// // //               fontWeight: FontWeight.bold,
// // //             ),
// // //           ),
// // //           Text(
// // //             percentage,
// // //             style: TextStyle(
// // //               color: isPositive ? Colors.green : Colors.red,
// // //               fontSize: 12,
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //  Widget _buildTrendingSection() {
// // //   return Row(
// // //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //     children: [
// // //       Text(
// // //         'Top Intraday Stock',
// // //         style: TextStyle(
// // //           fontSize: 20,
// // //           fontWeight: FontWeight.bold,
// // //           color: Colors.black,
// // //         ),
// // //       ),
// // //       GestureDetector(
// // //         onTap: () {
// // //           Navigator.push(
// // //             context,
// // //             MaterialPageRoute(builder: (context) => StockPage()),
// // //           );
// // //         },
// // //         child: Container(
// // //           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //           decoration: BoxDecoration(
// // //             color: Colors.deepPurple.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(20),
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               Text(
// // //                 'See more',
// // //                 style: TextStyle(color: Colors.deepPurple),
// // //               ),
// // //               SizedBox(width: 4),
// // //               Icon(Icons.arrow_forward, color: Colors.deepPurple, size: 20),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     ],
// // //   );
// // // }

// // //   Widget _buildTrendingStocksList() {
// // //     return Column(
// // //       children: [
// // //         _buildStockItem('ROTI', 'Nippon Indosari Tbk', '8600.00', '+50', '+3.23%', Colors.amber),
// // //         _buildStockItem('GOTO', 'GoTo Gojek Tokopedia', '2421.05', '-121', '-20.6%', Colors.green),
// // //         _buildStockItem('ABNB', 'Airbnb Inc', '5300.50', '+31', '+2.23%', Colors.red),
// // //         _buildStockItem('UNVR', 'Unilever Indonesia', '3867.10', '-71', '-4.1%', Colors.blue),
// // //         _buildStockItem('ADRO', 'Adaro Energy Indonesia', '3600.45', '+21', '+3.23%', Colors.grey),
// // //       ],
// // //     );
// // //   }

// // //   Widget _buildStockItem(String symbol, String name, String price, String change, String percentage, Color logoColor) {
// // //     return Container(
// // //       margin: EdgeInsets.only(bottom: 16),
// // //       padding: EdgeInsets.all(12),
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(12),
// // //         border: Border.all(color: Colors.grey[300]!, width: 1),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.grey.withOpacity(0.1),
// // //             blurRadius: 4,
// // //             offset: Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: Row(
// // //         children: [
// // //           Container(
// // //             width: 40,
// // //             height: 40,
// // //             decoration: BoxDecoration(
// // //               color: logoColor,
// // //               borderRadius: BorderRadius.circular(8),
// // //             ),
// // //             child: Center(
// // //               child: Text(
// // //                 symbol[0],
// // //                 style: TextStyle(
// // //                   color: Colors.white,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //             ),
// // //           ),
// // //           SizedBox(width: 12),
// // //           Expanded(
// // //             child: Column(
// // //               crossAxisAlignment: CrossAxisAlignment.start,
// // //               children: [
// // //                 Text(
// // //                   symbol,
// // //                   style: TextStyle(
// // //                     color: Colors.black,
// // //                     fontWeight: FontWeight.bold,
// // //                   ),
// // //                 ),
// // //                 Text(
// // //                   name,
// // //                   style: TextStyle(color: Colors.grey[600]),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //           Column(
// // //             crossAxisAlignment: CrossAxisAlignment.end,
// // //             children: [
// // //               Text(
// // //                 price,
// // //                 style: TextStyle(
// // //                   color: Colors.black,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //               Text(
// // //                 '$change ($percentage)',
// // //                 style: TextStyle(
// // //                   color: change.contains('-') ? Colors.red : Colors.green,
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   Widget _buildSeeMoreButton() {
// // //     return Center(
// // //       child: TextButton(
// // //         onPressed: () {},
// // //         child: Row(
// // //           mainAxisSize: MainAxisSize.min,
// // //           children: [
// // //             Text(
// // //               'See More',
// // //               style: TextStyle(color: Colors.deepPurple),
// // //             ),
// // //             Icon(Icons.arrow_forward_ios, color: Colors.deepPurple, size: 16),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class GainersLosersSection extends StatelessWidget {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Column(
// // //       children: [
// // //         _buildHeader(context, title: 'Top Gainers'),
// // //         SizedBox(height: 16),
// // //         _buildStocksList(context, [
// // //           _buildStockItem(context, 'TSLA', 'Tesla Inc', '1100.00', '+100', '+10.0%', Colors.green),
// // //           _buildStockItem(context, 'AAPL', 'Apple Inc', '145.50', '+5', '+3.5%', Colors.green),
// // //           _buildStockItem(context, 'MSFT', 'Microsoft Corp', '299.75', '+9', '+3.1%', Colors.green),
// // //         ]),
// // //         SizedBox(height: 20),
// // //         _buildHeader(context, title: 'Top Losers'),
// // //         SizedBox(height: 16),
// // //         _buildStocksList(context, [
// // //           _buildStockItem(context, 'NFLX', 'Netflix Inc', '390.00', '-50', '-11.0%', Colors.red),
// // //           _buildStockItem(context, 'AMZN', 'Amazon Inc', '3200.00', '-150', '-4.5%', Colors.red),
// // //           _buildStockItem(context, 'GOOG', 'Alphabet Inc', '2850.30', '-30', '-2.1%', Colors.red),
// // //         ]),
// // //       ],
// // //     );
// // //   }

// // //   // Header with "See More" button
// // //   Widget _buildHeader(BuildContext context, {required String title}) {
// // //     return Row(
// // //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //       children: [
// // //         Text(
// // //           title,
// // //           style: TextStyle(
// // //             fontSize: 20,
// // //             fontWeight: FontWeight.bold,
// // //             color: Colors.black,
// // //           ),
// // //         ),
// // //       GestureDetector(
// // //         onTap: () {
// // //           Navigator.push(
// // //             context,
// // //             MaterialPageRoute(builder: (context) => StockPage()),
// // //           );
// // //         },
// // //         child: Container(
// // //           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //           decoration: BoxDecoration(
// // //             color: Colors.deepPurple.withOpacity(0.1),
// // //             borderRadius: BorderRadius.circular(20),
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               Text(
// // //                 'See more',
// // //                 style: TextStyle(color: Colors.deepPurple),
// // //               ),
// // //               SizedBox(width: 4),
// // //               Icon(Icons.arrow_forward, color: Colors.deepPurple, size: 20),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //       ],
// // //     );
// // //   }

// // //   // Builds a list of stocks
// // //   Widget _buildStocksList(BuildContext context, List<Widget> stocks) {
// // //     return Column(children: stocks);
// // //   }

// // //   // Single Stock Item - Now Clickable
// // //   Widget _buildStockItem(BuildContext context, String symbol, String name, String price, String change, String percentChange, Color color) {
// // //     return GestureDetector(
// // //       onTap: () {
// // //         Navigator.push(
// // //           context,
// // //           MaterialPageRoute(builder: (context) => details.StockDetailsPage(stockName: symbol)),
// // //         );
// // //       },
// // //       child: Container(
// // //         padding: EdgeInsets.all(12),
// // //         margin: EdgeInsets.symmetric(vertical: 6),
// // //         decoration: BoxDecoration(
// // //           color: Colors.white,
// // //           borderRadius: BorderRadius.circular(12),
// // //           border: Border.all(color: Colors.grey[300]!, width: 1),
// // //           boxShadow: [
// // //             BoxShadow(
// // //               color: Colors.grey.withOpacity(0.1),
// // //               blurRadius: 4,
// // //               offset: Offset(0, 2),
// // //             ),
// // //           ],
// // //         ),
// // //         child: Row(
// // //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //           children: [
// // //             Row(
// // //               children: [
// // //                 CircleAvatar(
// // //                   backgroundColor: color.withOpacity(0.2),
// // //                   child: Text(symbol, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// // //                 ),
// // //                 SizedBox(width: 10),
// // //                 Column(
// // //                   crossAxisAlignment: CrossAxisAlignment.start,
// // //                   children: [
// // //                     Text(name, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
// // //                     Text(price, style: TextStyle(color: Colors.grey[600])),
// // //                   ],
// // //                 ),
// // //               ],
// // //             ),
// // //             Column(
// // //               crossAxisAlignment: CrossAxisAlignment.end,
// // //               children: [
// // //                 Text(change, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
// // //                 Text(percentChange, style: TextStyle(color: color)),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }














import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:test_project/features/profile/profile.dart';
import 'package:test_project/features/portfolio/portfolio.dart';
import 'package:test_project/features/news/news.dart';
import 'package:test_project/features/news/newsmail.dart';
import 'package:test_project/features/stock/stock.dart';
import 'package:test_project/features/stock/stock_details.dart' as details;
import 'package:test_project/features/notifications/notification.dart';
import 'package:test_project/features/screener/screener.dart';
import 'package:test_project/features/simulator/stock_stimulator.dart';

class TrendingScreen extends StatefulWidget {
  @override
  _TrendingScreenState createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  String apiKey = "XH0MOF8FACW6RR0L";
  List<dynamic> newsData = [];
  bool isSearchingStimulator = false;
  String searchQuery = "";
  bool isLoading = false;
  
  Timer? _debounceTimer;
  
  List<Map<String, dynamic>> searchResults = [];
  List<Map<String, String>> filteredStimulatorStocks = [];
  
  final TextEditingController _searchController = TextEditingController();
  
  final List<Map<String, String>> popularStocks = [
    {"symbol": "AAPL", "name": "Apple Inc", "region": "United States", "currency": "USD"},
    {"symbol": "GOOGL", "name": "Alphabet Inc - Class A", "region": "United States", "currency": "USD"},
    {"symbol": "MSFT", "name": "Microsoft Corporation", "region": "United States", "currency": "USD"},
    {"symbol": "TSLA", "name": "Tesla Inc", "region": "United States", "currency": "USD"},
    {"symbol": "AMZN", "name": "Amazon.com Inc", "region": "United States", "currency": "USD"},
    {"symbol": "META", "name": "Meta Platforms Inc", "region": "United States", "currency": "USD"},
    {"symbol": "NVDA", "name": "NVIDIA Corporation", "region": "United States", "currency": "USD"},
    {"symbol": "NFLX", "name": "Netflix Inc", "region": "United States", "currency": "USD"},
    {"symbol": "IBM", "name": "International Business Machines", "region": "United States", "currency": "USD"},
    {"symbol": "INTC", "name": "Intel Corporation", "region": "United States", "currency": "USD"},
    {"symbol": "CSCO", "name": "Cisco Systems Inc", "region": "United States", "currency": "USD"},
    {"symbol": "ORCL", "name": "Oracle Corporation", "region": "United States", "currency": "USD"},
    {"symbol": "ADBE", "name": "Adobe Inc", "region": "United States", "currency": "USD"},
    {"symbol": "PYPL", "name": "PayPal Holdings Inc", "region": "United States", "currency": "USD"},
    {"symbol": "SBUX", "name": "Starbucks Corporation", "region": "United States", "currency": "USD"},
  ];

  List<Map<String, String>> allStimulatorStocks = [
    {"name": "STIM_A", "logo": "https://logo.clearbit.com/ibm.com", "fullName": "Stimulator Stock A"},
    {"name": "STIM_B", "logo": "https://logo.clearbit.com/amazon.com", "fullName": "Stimulator Stock B"},
    {"name": "STIM_MSFT", "logo": "https://logo.clearbit.com/microsoft.com", "fullName": "Stimulator Microsoft"},
    {"name": "STIM_TSLA", "logo": "https://logo.clearbit.com/tesla.com", "fullName": "Stimulator Tesla"},
    {"name": "STIM_GOOG", "logo": "https://logo.clearbit.com/google.com", "fullName": "Stimulator Google"},
  ];

  String selectedCategory = 'Breakout';

  // Holds user-created custom strategies
  List<Map<String, dynamic>> customStrategies = [];

  @override
  void initState() {
    super.initState();
    fetchNews();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchNews() async {
    final url = Uri.parse(
        "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          newsData = data["feed"] ?? [];
        });
      }
    } catch (e) {
      print("Failed to load news: $e");
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    setState(() {
      searchQuery = query;
    });

    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        filteredStimulatorStocks = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (isSearchingStimulator) {
        _performStimulatorSearch(query);
      } else {
        _performRealStockSearch(query);
      }
    });
  }

  void _performStimulatorSearch(String query) {
    final results = allStimulatorStocks
        .where((stock) =>
            stock["name"]!.toLowerCase().contains(query.toLowerCase()) ||
            stock["fullName"]!.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      filteredStimulatorStocks = results;
      isLoading = false;
    });
  }

  Future<void> _performRealStockSearch(String query) async {
    final localResults = _searchLocalStocks(query);
    
    if (localResults.isNotEmpty) {
      setState(() {
        searchResults = localResults;
        isLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse(
          "https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=$query&apikey=$apiKey");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> bestMatches = data["bestMatches"] ?? [];

        if (bestMatches.isNotEmpty) {
          final apiResults = bestMatches.map((match) {
            return {
              "symbol": match["1. symbol"] ?? "",
              "name": match["2. name"] ?? "",
              "type": match["3. type"] ?? "",
              "region": match["4. region"] ?? "",
              "currency": match["8. currency"] ?? "",
              "source": "API",
            };
          }).toList();

          setState(() {
            searchResults = apiResults;
            isLoading = false;
          });
        } else {
          final relatedResults = _getRelatedStocks(query);
          setState(() {
            searchResults = relatedResults;
            isLoading = false;
          });
        }
      } else {
        final fallbackResults = _getRelatedStocks(query);
        setState(() {
          searchResults = fallbackResults;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error searching stocks: $e");
      final fallbackResults = _getRelatedStocks(query);
      setState(() {
        searchResults = fallbackResults;
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _searchLocalStocks(String query) {
    final lowerQuery = query.toLowerCase();
    return popularStocks
        .where((stock) =>
            stock["symbol"]!.toLowerCase().contains(lowerQuery) ||
            stock["name"]!.toLowerCase().contains(lowerQuery))
        .map((stock) => {
              "symbol": stock["symbol"]!,
              "name": stock["name"]!,
              "region": stock["region"]!,
              "currency": stock["currency"]!,
              "source": "Local",
            })
        .toList();
  }

  List<Map<String, dynamic>> _getRelatedStocks(String query) {
    final lowerQuery = query.toLowerCase();
    
    final similarStocks = popularStocks
        .where((stock) {
          final name = stock["name"]!.toLowerCase();
          final symbol = stock["symbol"]!.toLowerCase();
          
          return name.contains(lowerQuery) || 
                 symbol.contains(lowerQuery);
        })
        .map((stock) => {
              "symbol": stock["symbol"]!,
              "name": stock["name"]!,
              "region": stock["region"]!,
              "currency": stock["currency"]!,
              "source": "Related",
            })
        .toList();

    if (similarStocks.isEmpty) {
      return popularStocks.take(5).map((stock) => {
            "symbol": stock["symbol"]!,
            "name": stock["name"]!,
            "region": stock["region"]!,
            "currency": stock["currency"]!,
            "source": "Popular",
          }).toList();
    }

    return similarStocks;
  }

  void toggleSearchMode() {
    _debounceTimer?.cancel();
    
    setState(() {
      isSearchingStimulator = !isSearchingStimulator;
      searchQuery = "";
      _searchController.clear();
      searchResults = [];
      filteredStimulatorStocks = [];
      isLoading = false;
    });
  }

  String getStockLogo(String symbol) {
    final logoMap = {
      'AAPL': 'apple.com',
      'GOOGL': 'google.com',
      'MSFT': 'microsoft.com',
      'TSLA': 'tesla.com',
      'AMZN': 'amazon.com',
      'META': 'meta.com',
      'NFLX': 'netflix.com',
      'NVDA': 'nvidia.com',
      'IBM': 'ibm.com',
      'INTC': 'intel.com',
      'CSCO': 'cisco.com',
      'ORCL': 'oracle.com',
      'ADBE': 'adobe.com',
      'PYPL': 'paypal.com',
      'SBUX': 'starbucks.com',
    };
    
    final domain = logoMap[symbol] ?? '${symbol.toLowerCase().replaceAll(' ', '')}.com';
    return "https://logo.clearbit.com/$domain";
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    setState(() {
      searchQuery = "";
      _searchController.clear();
      searchResults = [];
      filteredStimulatorStocks = [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            
            _buildSearchBar(),
            
            const SizedBox(height: 20),
            
            if (isLoading) _buildLoadingIndicator(),
            
            if (searchQuery.isNotEmpty && !isLoading) 
              _buildSearchResults(),
            
            if (searchQuery.isEmpty) _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryTabs(),
        const SizedBox(height: 24),
        
        _buildSectionHeader('Most Traded', 'View all'),
        const SizedBox(height: 12),
        _buildHorizontalStockList(),
        
        const SizedBox(height: 32),
        
        _buildSectionHeader('Top Intraday', 'See more', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StockPage()),
          );
        }),
        const SizedBox(height: 12),
        _buildTrendingStocksList(),
        
        const SizedBox(height: 24),
        
        GainersLosersSection(),
        
        const SizedBox(height: 32),
        
        _buildSectionHeader('Latest News', 'View all', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NewsMailScreen()),
          );
        }),
        const SizedBox(height: 12),
        _buildNewNewsSection(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: const Color.fromARGB(255, 112, 97, 243),
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              "Searching...",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isSearchingStimulator 
                        ? 'Search stimulator stocks...' 
                        : 'Search stocks...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                    suffixIcon: searchQuery.isNotEmpty ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500], size: 18),
                      onPressed: _clearSearch,
                    ) : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: BoxDecoration(
                color: isSearchingStimulator 
                    ? const Color.fromARGB(255, 112, 97, 243).withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSearchingStimulator 
                      ? const Color.fromARGB(255, 112, 97, 243)
                      : Colors.grey.shade200,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  color: isSearchingStimulator 
                      ? const Color.fromARGB(255, 112, 97, 243)
                      : Colors.grey[600],
                  size: 20,
                ),
                onPressed: toggleSearchMode,
                tooltip: isSearchingStimulator 
                    ? 'Real Stocks' 
                    : 'Stimulator',
              ),
            ),
          ],
        ),
        if (isSearchingStimulator)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: const Color.fromARGB(255, 112, 97, 243),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Stimulator Mode',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 112, 97, 243),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (isSearchingStimulator) {
      return _buildStimulatorSearchResults();
    } else {
      return _buildRealStocksSearchResults();
    }
  }

  Widget _buildRealStocksSearchResults() {
    return SizedBox(
      height: 350,
      child: searchResults.isNotEmpty
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "${searchResults.length} results",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final stock = searchResults[index];
                      final symbol = stock["symbol"] ?? "";
                      final name = stock["name"] ?? "";
                      final region = stock["region"] ?? "";
                      final currency = stock["currency"] ?? "";
                      final source = stock["source"] ?? "API";

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => details.StockDetailsPage(stockName: symbol),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
                                backgroundImage: NetworkImage(getStockLogo(symbol)),
                                child: symbol.isNotEmpty 
                                    ? null
                                    : Icon(Icons.business, color: const Color.fromARGB(255, 112, 97, 243), size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          symbol,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getSourceColor(source).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            source,
                                            style: TextStyle(
                                              color: _getSourceColor(source),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : _buildNoResultsWidget(),
    );
  }

  Color _getSourceColor(String source) {
    switch (source) {
      case 'Local':
        return Colors.green;
      case 'API':
        return Colors.blue;
      case 'Related':
        return Colors.orange;
      case 'Popular':
        return const Color.fromARGB(255, 112, 97, 243);
      default:
        return Colors.grey;
    }
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey[300],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            "No stocks found",
            style: TextStyle(
              color: Colors.grey[600], 
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Try: Apple, Google, Tesla",
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStimulatorSearchResults() {
    return SizedBox(
      height: 300,
      child: filteredStimulatorStocks.isNotEmpty
          ? ListView.builder(
              itemCount: filteredStimulatorStocks.length,
              itemBuilder: (context, index) {
                final stock = filteredStimulatorStocks[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockSimulatorPage(stockName: stock["name"]!),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(stock["logo"]!),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stock["name"]!,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                stock["fullName"]!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                "No stimulator stocks found",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
    );
  }

  Widget _buildNewNewsSection() {
    return Container(
      child: newsData.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: const Color.fromARGB(255, 112, 97, 243),
                strokeWidth: 2,
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newsData.length > 5 ? 5 : newsData.length,
              itemBuilder: (context, index) {
                var newsItem = newsData[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewsDetailScreen(newsItem: newsItem)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              newsItem["source"] ?? "Unknown",
                              style: const TextStyle(
                                color: Color.fromARGB(255, 112, 97, 243),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatNewsDate(newsItem["time_published"] ?? ""),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          newsItem["title"] ?? "No Title",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          newsItem["summary"] ?? "No summary",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        if (newsItem["ticker_sentiment"] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildTickerSentiment(newsItem["ticker_sentiment"]),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatNewsDate(String dateString) {
    try {
      if (dateString.isEmpty) return "";
      final year = dateString.substring(0, 4);
      final month = dateString.substring(4, 6);
      final day = dateString.substring(6, 8);
      
      final monthNames = {
        '01': 'Jan', '02': 'Feb', '03': 'Mar', '04': 'Apr',
        '05': 'May', '06': 'Jun', '07': 'Jul', '08': 'Aug',
        '09': 'Sep', '10': 'Oct', '11': 'Nov', '12': 'Dec'
      };
      
      return '${monthNames[month]} $day';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildTickerSentiment(List<dynamic> tickerSentiment) {
    final tickers = tickerSentiment.take(3).toList();
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tickers.map((ticker) {
        final tickerSymbol = ticker["ticker"] ?? "";
        final sentiment = ticker["ticker_sentiment_score"] ?? "0.0";
        final sentimentScore = double.tryParse(sentiment) ?? 0.0;
        
        Color sentimentColor = Colors.grey;
        if (sentimentScore > 0.1) sentimentColor = Colors.green;
        if (sentimentScore < -0.1) sentimentColor = Colors.red;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: sentimentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            tickerSymbol,
            style: TextStyle(
              color: sentimentColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, String action, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Strategy Builder',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
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
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── strategy → screener preset filters ──────────────────────────────────
  Map<String, dynamic> _filtersForStrategy(String strategy) {
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
      default: // Breakout
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

  // ── navigate to screener with preset strategy ────────────────────────────
  void _openStrategyScreener(String strategyName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockScreenerPage(
          initialStrategy: strategyName,
          initialFilters: _filtersForStrategy(strategyName),
        ),
      ),
    );
  }

  // ── Custom Strategy Builder bottom-sheet ─────────────────────────────────
  void _showCustomStrategyBuilder({Map<String, dynamic>? existingStrategy}) {
    // Local copy of filters and a strategy name the user can set
    final customFilters = existingStrategy != null
        ? Map<String, dynamic>.from(existingStrategy['filters'] as Map)
        : Map<String, dynamic>.from({
            'strategy': 'Custom',
            'price': 'Any',
            'marketCap': 'Mid',
            'change': 'Any',
            'peRatio': 'Any',
            'roe': 'Any',
            'epsGrowth': 'Any',
            'netProfitMargin': 'Any',
            'debtEquity': 'Any',
            'avgVolume': 'Any',
            'volatility': 'Any',
            'relativeVolume': 'Any',
            'currentVolume': 'Any',
            'rsi': 'Any',
            'sma20': 'Any',
            'sma50': 'Any',
            'sma200': 'Any',
            'highLow': 'Any',
          });
    final nameController = TextEditingController(
        text: existingStrategy != null
            ? existingStrategy['name'] as String
            : 'My Custom Strategy');

    final filterOptions = <String, List<String>>{
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
      'sma20': ['Any', 'Price above SMA20', 'Price below SMA20'],
      'sma50': ['Any', 'Price above SMA50', 'Price below SMA50'],
      'sma200': ['Any', 'Price above SMA200', 'Price below SMA200'],
      'highLow': ['Any', 'New High', 'New Low', '52W High', '52W Low'],
    };

    final filterLabels = <String, String>{
      'price': 'Price',
      'marketCap': 'Market Cap',
      'change': 'Price Change',
      'peRatio': 'P/E Ratio',
      'roe': 'Return on Equity',
      'epsGrowth': 'EPS Growth YoY',
      'netProfitMargin': 'Net Profit Margin',
      'debtEquity': 'Debt / Equity',
      'avgVolume': 'Avg Volume',
      'volatility': 'Volatility',
      'relativeVolume': 'Relative Volume',
      'currentVolume': 'Current Volume',
      'rsi': 'RSI (14)',
      'sma20': '20-Day SMA',
      'sma50': '50-Day SMA',
      'sma200': '200-Day SMA',
      'highLow': '52W High / Low',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.6,
            maxChildSize: 0.97,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── handle ──
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── title row ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune,
                              color: Color.fromARGB(255, 112, 97, 243), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existingStrategy != null ? 'Edit Strategy' : 'Custom Strategy Builder',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 24, thickness: 1),

                  // ── scrollable content ──
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Strategy name field
                        const Text(
                          'Strategy Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.black, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. High Volume Momentum',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color.fromARGB(255, 112, 97, 243)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Filter rows
                        ...filterLabels.entries.map((entry) {
                          final key = entry.key;
                          final label = entry.value;
                          final options = filterOptions[key]!;
                          final currentValue = customFilters[key] ?? 'Any';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: options.contains(currentValue) ? currentValue : 'Any',
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 112, 97, 243),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  dropdownColor: Colors.white,
                                  items: options
                                      .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => customFilters[key] = val);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // ── bottom action buttons ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey[100]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save, size: 18),
                            label: Text(existingStrategy != null ? 'Update' : 'Save'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 112, 97, 243),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              final strategyName =
                                  nameController.text.trim().isEmpty
                                      ? 'My Custom Strategy'
                                      : nameController.text.trim();
                              customFilters['strategy'] = 'Custom';
                              final savedFilters =
                                  Map<String, dynamic>.from(customFilters);
                              
                              setState(() {
                                if (existingStrategy != null) {
                                  // Update existing strategy
                                  final index = customStrategies.indexOf(existingStrategy);
                                  if (index != -1) {
                                    customStrategies[index] = {
                                      'name': strategyName,
                                      'filters': savedFilters,
                                      'createdAt': existingStrategy['createdAt'] ?? DateTime.now(),
                                    };
                                  }
                                } else {
                                  // Add new strategy
                                  customStrategies.add({
                                    'name': strategyName,
                                    'filters': savedFilters,
                                    'createdAt': DateTime.now(),
                                  });
                                }
                                selectedCategory = strategyName;
                              });

                              // Close builder sheet, then show save animation
                              Navigator.pop(sheetCtx);
                              _showSaveAnimation(
                                strategyName: strategyName,
                                onDone: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StockScreenerPage(
                                        initialStrategy: strategyName,
                                        initialFilters: savedFilters,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Save animation overlay ───────────────────────────────────────────────
  void _showSaveAnimation({
    required String strategyName,
    required VoidCallback onDone,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => _SaveAnimationDialog(
        strategyName: strategyName,
        onDone: () {
          Navigator.of(ctx).pop();
          onDone();
        },
      ),
    );
  }

  // ── Custom chip action sheet (Open / Delete) ─────────────────────────────
  void _showCustomChipActions(Map<String, dynamic> cs) {
    final name = cs['name'] as String;
    final filters = cs['filters'] as Map<String, dynamic>;
    final activeCount = filters.entries
        .where((e) => e.value != 'Any' && e.key != 'strategy')
        .length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Strategy info header
            Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7061F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune,
                      color: Color(0xFF7061F3), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$activeCount active filter${activeCount == 1 ? '' : 's'}  •  Custom Strategy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),

            // Open Screener action
            _buildActionTile(
              icon: Icons.search_rounded,
              iconColor: const Color(0xFF7061F3),
              label: 'Open Screener',
              subtitle: 'View stocks matching this strategy',
              onTap: () {
                Navigator.pop(ctx);
                setState(() => selectedCategory = name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockScreenerPage(
                      initialStrategy: name,
                      initialFilters:
                          Map<String, dynamic>.from(filters),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Delete action
            _buildActionTile(
              icon: Icons.delete_outline_rounded,
              iconColor: Colors.red[400]!,
              label: 'Delete Strategy',
              subtitle: 'Remove from your saved strategies',
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteStrategy(cs);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper: single action row tile
  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.04)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.15)
                : Colors.grey.shade100,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDestructive ? Colors.red[500] : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: isDestructive
                  ? Colors.red[200]
                  : Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  // Delete confirmation dialog
  void _confirmDeleteStrategy(Map<String, dynamic> cs) {
    final name = cs['name'] as String;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_outline,
                  color: Colors.red[400], size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Strategy?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This cannot be undone.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                customStrategies.remove(cs);
                if (selectedCategory == name) {
                  selectedCategory = 'Breakout';
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$name" deleted'),
                  backgroundColor: Colors.red[400],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Strategies overview full-screen bottom-sheet ────────────────────────
  void _showStrategiesOverview() {
    final builtIn = [
      {
        'name': 'Breakout',
        'icon': Icons.trending_up,
        'color': const Color(0xFF7061F3),
        'desc': 'Stocks breaking above resistance with high volume surge.',
        'tags': ['Price < \$5', 'RSI Oversold', 'New High', 'High RelVol'],
      },
      {
        'name': 'Bounce',
        'icon': Icons.show_chart,
        'color': const Color(0xFF00B899),
        'desc': 'Oversold stocks bouncing from key support levels.',
        'tags': ['Down 5%', 'RSI < 30', 'Below SMA20', 'High Volume'],
      },
      {
        'name': 'Moving Average',
        'icon': Icons.timeline,
        'color': const Color(0xFFFF8C42),
        'desc': 'Strong uptrend confirmed by all three moving averages.',
        'tags': ['Above SMA20/50/200', '52W High', 'Over \$50'],
      },
      {
        'name': 'Price Change',
        'icon': Icons.percent,
        'color': const Color(0xFF4CAF50),
        'desc': 'Stocks with significant intra-day price momentum.',
        'tags': ['Up 5%+', 'Above SMA20', 'New High', 'Mid Cap'],
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Strategies',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StatefulBuilder(
                  builder: (ctx2, setLocal) => ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      const Text(
                        'BUILT-IN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black38,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...builtIn.map((s) => _buildOverviewCard(
                            ctx: ctx,
                            name: s['name'] as String,
                            icon: s['icon'] as IconData,
                            accentColor: s['color'] as Color,
                            desc: s['desc'] as String,
                            tags: s['tags'] as List<String>,
                            isCustom: false,
                            onDelete: null,
                          )),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'MY STRATEGIES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black38,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (customStrategies.isNotEmpty)
                            Text(
                              '${customStrategies.length} saved',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7061F3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (customStrategies.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.add_chart, size: 36,
                                  color: Colors.grey[300]),
                              const SizedBox(height: 10),
                              Text(
                                'No custom strategies yet',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap 'Custom +' to build your first screener",
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        ...customStrategies.map((cs) {
                          final filters =
                              cs['filters'] as Map<String, dynamic>;
                          final tags = filters.entries
                              .where((e) =>
                                  e.value != 'Any' && e.key != 'strategy')
                              .take(4)
                              .map((e) => e.value as String)
                              .toList();
                          return _buildOverviewCard(
                            ctx: ctx,
                            name: cs['name'] as String,
                            icon: Icons.tune,
                            accentColor: const Color(0xFF7061F3),
                            desc:
                                'Custom strategy with ${filters.entries.where((e) => e.value != "Any" && e.key != "strategy").length} active filters.',
                            tags: tags.isEmpty
                                ? ['All filters: Any']
                                : tags,
                            isCustom: true,
                            onDelete: () {
                              setState(() {
                                customStrategies.remove(cs);
                                if (selectedCategory == cs['name']) {
                                  selectedCategory = 'Breakout';
                                }
                              });
                              setLocal(() {});
                            },
                            onEdit: () {
                              Navigator.pop(ctx);
                              _showCustomStrategyBuilder(existingStrategy: cs);
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Strategy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7061F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCustomStrategyBuilder();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable card for the overview sheet
  Widget _buildOverviewCard({
    required BuildContext ctx,
    required String name,
    required IconData icon,
    required Color accentColor,
    required String desc,
    required List<String> tags,
    required bool isCustom,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        setState(() => selectedCategory = name);
        if (isCustom) {
          final cs = customStrategies.firstWhere(
              (s) => s['name'] == name, orElse: () => {});
          if (cs.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StockScreenerPage(
                  initialStrategy: name,
                  initialFilters: Map<String, dynamic>.from(
                      cs['filters'] as Map<String, dynamic>),
                ),
              ),
            );
          }
        } else {
          _openStrategyScreener(name);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCustom)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        GestureDetector(
                          onTap: onEdit,
                          child: Icon(Icons.edit_outlined,
                              color: Colors.grey[400], size: 18),
                        ),
                      if (onEdit != null && onDelete != null)
                        const SizedBox(width: 12),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(Icons.delete_outline,
                              color: Colors.red[300], size: 20),
                        ),
                    ],
                  )
                else
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.black26),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              desc,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentColor),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    // Take newest 4 custom strategies
    final displayStrategies = customStrategies.reversed.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: _showCustomStrategyBuilder,
              child: const Text(
                '+ Create Strategy',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7061F3),
                ),
              ),
            ),
            GestureDetector(
              onTap: _showStrategiesOverview,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7061F3).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'See more',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios,
                        size: 10, color: Colors.black54),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayStrategies.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayStrategies.map((cs) {
              final name = cs['name'] as String;
              final filters = cs['filters'] as Map<String, dynamic>;
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => selectedCategory = name);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockScreenerPage(
                                initialStrategy: name,
                                initialFilters: Map<String, dynamic>.from(filters),
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert, size: 16, color: Colors.black54),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showCustomStrategyBuilder(existingStrategy: cs);
                          } else if (value == 'delete') {
                            _confirmDeleteStrategy(cs);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            height: 35,
                            child: Text('Edit', style: TextStyle(fontSize: 13)),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            height: 35,
                            child: Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildHorizontalStockList() {
    final List<Map<String, dynamic>> dummyStocks = [
      {'name': 'BUKA', 'fullName': 'Bukalapak', 'price': '278.00', 'change': '+2.5%', 'color': Colors.green},
      {'name': 'BBN', 'fullName': 'Bank Negara', 'price': '4,630.00', 'change': '+0.8%', 'color': Colors.green},
      {'name': 'SDO', 'fullName': 'Sido Muncul', 'price': '24.00', 'change': '-1.2%', 'color': Colors.red},
      {'name': 'AAPL', 'fullName': 'Apple Inc', 'price': '150.00', 'change': '+0.5%', 'color': Colors.green},
      {'name': 'GOOGL', 'fullName': 'Alphabet', 'price': '2,800.00', 'change': '-0.3%', 'color': Colors.red},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dummyStocks.length,
        itemBuilder: (context, index) {
          final stock = dummyStocks[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => details.StockDetailsPage(stockName: stock["name"]!),
                ),
              );
            },
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stock['name'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      Icon(
                        stock['change'].contains('+') 
                          ? Icons.trending_up 
                          : Icons.trending_down,
                        color: stock['color'],
                        size: 16,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock['fullName'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${stock['price']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            stock['change'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: stock['color'],
                            ),
                          ),
                        ],
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

  Widget _buildTrendingStocksList() {
    return Column(
      children: [
        _buildStockItem('ROTI', 'Nippon Indosari Tbk', '8600.00', '+50', '+3.23%', Colors.amber),
        _buildStockItem('GOTO', 'GoTo Gojek Tokopedia', '2421.05', '-121', '-20.6%', Colors.green),
        _buildStockItem('ABNB', 'Airbnb Inc', '5300.50', '+31', '+2.23%', Colors.red),
        _buildStockItem('UNVR', 'Unilever Indonesia', '3867.10', '-71', '-4.1%', Colors.blue),
      ],
    );
  }

  Widget _buildStockItem(String symbol, String name, String price, String change, String percentage, Color logoColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: logoColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                symbol[0],
                style: TextStyle(
                  color: logoColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                percentage,
                style: TextStyle(
                  color: change.contains('-') ? Colors.red : Colors.green,
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
}
// ── Save success animation dialog ─────────────────────────────────────────
class _SaveAnimationDialog extends StatefulWidget {
  final String strategyName;
  final VoidCallback onDone;

  const _SaveAnimationDialog({
    required this.strategyName,
    required this.onDone,
  });

  @override
  State<_SaveAnimationDialog> createState() => _SaveAnimationDialogState();
}

class _SaveAnimationDialogState extends State<_SaveAnimationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _checkCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _checkAnim;

  @override
  void initState() {
    super.initState();

    // Card scale-in
    _scaleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnim = CurvedAnimation(
        parent: _scaleCtrl, curve: Curves.elasticOut);

    // Overall fade-in
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    // Checkmark draw
    _checkCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _checkAnim =
        CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOutCubic);

    // Chain: fade → scale → check → wait → done
    _fadeCtrl.forward().then((_) {
      _scaleCtrl.forward().then((_) {
        _checkCtrl.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 900), widget.onDone);
        });
      });
    });
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark circle
                AnimatedBuilder(
                  animation: _checkAnim,
                  builder: (_, __) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF7061F3)
                          .withOpacity(0.08 + 0.07 * _checkAnim.value),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer ring pulse
                        Container(
                          width: 64 + 10 * _checkAnim.value,
                          height: 64 + 10 * _checkAnim.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF7061F3)
                                .withOpacity(0.12 * _checkAnim.value),
                          ),
                        ),
                        // Check icon with scale
                        Transform.scale(
                          scale: _checkAnim.value,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF7061F3),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Strategy Saved!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Strategy name pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7061F3).withOpacity(0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.strategyName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7061F3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Opening your screener...',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GainersLosersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context, title: 'Top Gainers'),
        const SizedBox(height: 12),
        _buildStocksList(context, [
          _buildStockItem(context, 'TSLA', 'Tesla Inc', '1100.00', '+100', '+10.0%', Colors.green),
          _buildStockItem(context, 'AAPL', 'Apple Inc', '145.50', '+5', '+3.5%', Colors.green),
          _buildStockItem(context, 'MSFT', 'Microsoft Corp', '299.75', '+9', '+3.1%', Colors.green),
        ]),
        const SizedBox(height: 24),
        _buildHeader(context, title: 'Top Losers'),
        const SizedBox(height: 12),
        _buildStocksList(context, [
          _buildStockItem(context, 'NFLX', 'Netflix Inc', '390.00', '-50', '-11.0%', Colors.red),
          _buildStockItem(context, 'AMZN', 'Amazon Inc', '3200.00', '-150', '-4.5%', Colors.red),
          _buildStockItem(context, 'GOOG', 'Alphabet Inc', '2850.30', '-30', '-2.1%', Colors.red),
        ]),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required String title}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => StockPage()),
            );
          },
          child: Text(
            'See more',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStocksList(BuildContext context, List<Widget> stocks) {
    return Column(children: stocks);
  }

  Widget _buildStockItem(BuildContext context, String symbol, String name, String price, String change, String percentChange, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => details.StockDetailsPage(stockName: symbol)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      symbol[0],
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  percentChange,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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