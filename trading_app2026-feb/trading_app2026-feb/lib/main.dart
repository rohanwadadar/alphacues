// // import 'package:flutter/material.dart';
// // import 'package:test_project/features/profile/profile.dart'; // Import your profile screen here.
// // import 'package:test_project/features/trading/topup.dart';
// // import 'package:test_project/features/trending/treanding.dart';
// // import 'package:test_project/features/stock/stock_details.dart'; // Import the new stock details page
// // import 'package:test_project/features/notifications/notification.dart';
// // import 'package:test_project/features/wishlist/wishlist.dart' hide StockDetailsPage;
// // import 'package:test_project/features/portfolio/portfolio.dart';

// // class DashboardScreen extends StatefulWidget {
// //   @override
// //   _DashboardScreenState createState() => _DashboardScreenState();
// // }

// // class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
// //   int _selectedIndex = 0;
// //   bool _isExpanded = false;
// //   late AnimationController _controller;
// //   late Animation<double> _sizeAnimation;
// //   late Animation<double> _iconOpacityAnimation;

// //   final List<Widget> _screens = [
// //     DashboardContent(),
// //     TrendingScreen(),
// //     TopUpScreen(),
// //     TradingDashboard(),
// //     ProfileScreen(),
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(
// //       vsync: this,
// //       duration: Duration(milliseconds: 500),
// //     );

// //     _sizeAnimation = Tween<double>(begin: 50, end: 70).animate(
// //       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
// //     );

// //     _iconOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
// //       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
// //     );
// //   }

// //   // search
// // List<Map<String, String>> allStocks = [
// //     {"name": "ibm", "logo": "https://logo.clearbit.com/ibm.com"},
// //     {"name": "BUKA", "logo": "https://logo.clearbit.com/amazon.com"},
// //     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
// //     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
// //     {"name": "GOOGL", "logo": "https://logo.clearbit.com/google.com"},
// //     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
// //     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
// //   ];

// //   List<Map<String, String>> filteredStocks = [];
// //   String searchQuery = "";
// //   bool isLoading = false;
// // void _onItemTapped(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //         _shrinkNavBar(); 
// //     });
// //   }

// //  void searchStocks(String query) {
// //   setState(() {
// //     searchQuery = query;
// //     filteredStocks = allStocks
// //         .where((stock) =>
// //             stock["name"]!.toLowerCase().startsWith(query.toLowerCase())) // Only matches stocks that start with the query
// //         .toList();
// //   });
// // }

// //   // search end 


// //   void _toggleNavBar() {
// //     setState(() {
// //       _isExpanded = !_isExpanded;
// //       if (_isExpanded) {
// //         _controller.forward();
// //       } else {
// //         _controller.reverse();
// //       }
// //     });
// //   }

 
// //   void _shrinkNavBar() {
// //     if (_isExpanded) {
// //       setState(() {
// //         _isExpanded = false;
// //         _controller.reverse();
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Stack(
// //         children: [
// //           _screens[_selectedIndex], // Main content stays in sync with navbar
// //           Align(
// //             alignment: Alignment.bottomCenter,
// //             child: GestureDetector(
// //               onTap: _toggleNavBar,
// //               child: AnimatedBuilder(
// //                 animation: _controller,
// //                 builder: (context, child) {
// //                   return Container(
// //                     width: _isExpanded ? MediaQuery.of(context).size.width - 60 : 80,
// //                     height: _sizeAnimation.value,
// //                     margin: EdgeInsets.only(bottom: 15), // Slightly above bottom
// //                     decoration: BoxDecoration(
// //                       color: const Color.fromARGB(255, 31, 29, 37).withOpacity(0.9),
// //                       shape: _isExpanded ? BoxShape.rectangle : BoxShape.circle, // Ball when shrunk
// //                       borderRadius: _isExpanded ? BorderRadius.circular(60) : null,
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black.withOpacity(0.4),
// //                           blurRadius: 12.0,
// //                           spreadRadius: 4,
// //                           offset: Offset(0, -8),
// //                         ),
// //                       ],
// //                     ),
// //                     child: _isExpanded
// //                         ? ClipRRect(
// //                             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //                             child: BottomNavigationBar(
// //                               type: BottomNavigationBarType.fixed,
// //                               backgroundColor: Colors.transparent,
// //                               selectedItemColor: Colors.greenAccent,
// //                               unselectedItemColor: Colors.grey.shade400,
// //                               currentIndex: _selectedIndex,
// //                               onTap: _onItemTapped,
// //                               elevation: 0,
// //                               items: [
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.home_filled, size: 20),
// //                                   ),
// //                                   label: 'Activity',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.trending_up_rounded, size: 20),
// //                                   ),
// //                                   label: 'Investing',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Container(
// //                                       padding: EdgeInsets.all(6),
// //                                       decoration: BoxDecoration(
// //                                         color: Colors.greenAccent.withOpacity(0.15),
// //                                         shape: BoxShape.circle,
// //                                       ),
// //                                       child: Icon(Icons.account_balance_wallet_rounded, size: 22),
// //                                     ),
// //                                   ),
// //                                   label: 'Transact',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.favorite_rounded, size: 20),
// //                                   ),
// //                                   label: 'Wish List',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.person_rounded, size: 20),
// //                                   ),
// //                                   label: 'Profile',
// //                                 ),


                                
// //                               ],
// //                             ),
// //                           )
                          
// //                         : Center(
// //                             child: Icon(Icons.menu, size: 22, color: Colors.white), // Small floating ball
// //                           ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// // Widget _buildPerformanceSection() {
// //   return CombinedPortfolioPerformance(showBalance: true);
// // }

// // // Enum definitions needed for the transactions and holdings
// // enum TransactionType { buy, sell }
// // enum HoldingType { stock, crypto, forex }

// // class Transaction {
// //   final String symbol;
// //   final double amount;
// //   final int shares;
// //   final TransactionType type;
// //   final DateTime date;
// //   final String currency;

// //   Transaction({
// //     required this.symbol,
// //     required this.amount,
// //     required this.shares,
// //     required this.type,
// //     required this.date,
// //     required this.currency,
// //   });
// // }

// // class Holding {
// //   final String symbol;
// //   final String name;
// //   final double value;
// //   final double change;
// //   final double changePercentage;
// //   final HoldingType type;
// //   final IconData icon;

// //   Holding({
// //     required this.symbol,
// //     required this.name,
// //     required this.value,
// //     required this.change,
// //     required this.changePercentage,
// //     required this.type,
// //     required this.icon,
// //   });
// // }

// // class DashboardContent extends StatefulWidget {
// //   @override
// //   _DashboardContentState createState() => _DashboardContentState();
// // }

// // class _DashboardContentState extends State<DashboardContent> {
// //   List<Map<String, String>> allStocks = [
// //     {"name": "Apple", "logo": "https://logo.clearbit.com/apple.com"},
// //     {"name": "Amazon", "logo": "https://logo.clearbit.com/amazon.com"},
// //     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
// //     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
// //     {"name": "Google", "logo": "https://logo.clearbit.com/google.com"},
// //     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
// //     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
// //   ];

// //   // Add the missing data structures
// //   List<Transaction> transactions = [
// //     Transaction(
// //       symbol: 'AAPL',
// //       amount: 150.75,
// //       shares: 10,
// //       type: TransactionType.buy,
// //       date: DateTime.now().subtract(Duration(days: 5)),
// //       currency: '\$',
// //     ),
// //     Transaction(
// //       symbol: 'MSFT',
// //       amount: 240.50,
// //       shares: 5,
// //       type: TransactionType.sell,
// //       date: DateTime.now().subtract(Duration(days: 2)),
// //       currency: '\$',
// //     ),
// //     Transaction(
// //       symbol: 'GOOGL',
// //       amount: 2750.25,
// //       shares: 2,
// //       type: TransactionType.buy,
// //       date: DateTime.now().subtract(Duration(days: 1)),
// //       currency: '\$',
// //     ),
// //   ];

// //   List<Holding> holdings = [
// //     Holding(
// //       symbol: 'AAPL',
// //       name: 'Apple Inc.',
// //       value: 1507.50,
// //       change: 23.75,
// //       changePercentage: 1.58,
// //       type: HoldingType.stock,
// //       icon: Icons.phone_iphone,
// //     ),
// //     Holding(
// //       symbol: 'BTC',
// //       name: 'Bitcoin',
// //       value: 3625.00,
// //       change: -125.30,
// //       changePercentage: -3.34,
// //       type: HoldingType.crypto,
// //       icon: Icons.currency_bitcoin,
// //     ),
// //     Holding(
// //       symbol: 'EUR/USD',
// //       name: 'Euro/USD',
// //       value: 1250.75,
// //       change: 12.25,
// //       changePercentage: 0.98,
// //       type: HoldingType.forex,
// //       icon: Icons.currency_exchange,
// //     ),
// //   ];

// //   List<Holding> watchlist = [
// //     Holding(
// //       symbol: 'NVDA',
// //       name: 'NVIDIA Corporation',
// //       value: 275.50,
// //       change: 5.25,
// //       changePercentage: 1.94,
// //       type: HoldingType.stock,
// //       icon: Icons.memory,
// //     ),
// //     Holding(
// //       symbol: 'ETH',
// //       name: 'Ethereum',
// //       value: 1875.25,
// //       change: 45.75,
// //       changePercentage: 2.50,
// //       type: HoldingType.crypto,
// //       icon: Icons.auto_graph,
// //     ),
// //   ];

// //   List<Map<String, String>> filteredStocks = [];
// //   String searchQuery = "";
// //   bool isLoading = false;
// // String selectedTimeframe = '24 hour';
// //   String selectedCategory = 'Global';
// //   int _selectedIndex = 0; // For tracking the selected tab

  
 
// //   @override
// //   void initState() {
// //     super.initState();
// //     filteredStocks = allStocks;
// //   }

// // void _onItemTapped(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //     });
// //   }

// //   void searchStocks(String query) {
// //     setState(() {
// //       searchQuery = query;
// //       filteredStocks = allStocks
// //           .where((stock) =>
// //               stock["name"]!.toLowerCase().contains(query.toLowerCase()))
// //           .toList();
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Row(
// //           children: [
// //             CircleAvatar(
// //               backgroundImage: AssetImage('assets/profile.jpg'),
// //               radius: 16,
// //             ),
// //             SizedBox(width: 8),
// //             Expanded(
// //               child: Text(
// //                 'Hallo Rohan Wadadar',
// //                 style: TextStyle(fontSize: 16),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             Stack(
// //               children: [
// //                 IconButton(
// //                   icon: Icon(Icons.notifications, size: 24),
// //                   onPressed: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                           builder: (context) => NotificationScreen()),
// //                     );
// //                   },
// //                 ),
// //                 Positioned(
// //                   right: 0,
// //                   top: 0,
// //                   child: Container(
// //                     padding: EdgeInsets.all(2),
// //                     decoration: BoxDecoration(
// //                       color: Colors.red,
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: Text(
// //                       '2',
// //                       style: TextStyle(color: Colors.white, fontSize: 10),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //         backgroundColor: const Color.fromARGB(124, 24, 20, 34),
// //       ),
// //       body: isLoading
// //           ? Center(child: CircularProgressIndicator(color: Colors.blue))
// //           : SingleChildScrollView(
// //               child: Container(
// //                 decoration: BoxDecoration(
// //                   gradient: LinearGradient(
// //                     begin: Alignment.topLeft,
// //                     end: Alignment.bottomRight,
// //                     colors: [
// //                       Colors.black,
// //                       Color(0xFF1A237E).withOpacity(0.8), // Dark blue gradient
// //                     ],
// //                   ),
// //                 ),
// //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                  children: [
// //                     // Search Bar
// //                     SizedBox(height: 16),
// //                 /*//     TextField(
// //                       style: TextStyle(color: Colors.white),
// //                       decoration: InputDecoration(
// //                         hintText: 'Search stocks...',
// //                         hintStyle: TextStyle(color: Colors.white54),
// //                         prefixIcon: Icon(Icons.search, color: Colors.white),
// //                         filled: true,
// //                         fillColor:
// //                             const Color.fromARGB(41, 0, 0, 0).withOpacity(0.3),
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: BorderSide.none,
// //                         ),
// //                       ),
// //                       onChanged: searchStocks,
// //                     ),

// //                     SizedBox(height: 8),

// //                     // Filtered Stock List
// //                     if (searchQuery.isNotEmpty && filteredStocks.isNotEmpty)
// //                       SizedBox(
// //                         height: 300,
// //                         child: ListView.builder(
// //                           itemCount: filteredStocks.length,
// //                           itemBuilder: (context, index) {
// //                             return Card(
// //                               color: const Color.fromARGB(54, 33, 33, 33),
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(10),
// //                               ),
// //                               child: ListTile(
// //                                 leading: CircleAvatar(
// //                                   backgroundImage: NetworkImage(
// //                                     filteredStocks[index]["logo"]!,
// //                                   ),
// //                                 ),
// //                                 title: Text(
// //                                   filteredStocks[index]["name"]!,
// //                                   style: TextStyle(color: Colors.white),
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         ),
// //                       ),
// // */
// // TextField(
// //                 style: TextStyle(color: Colors.white),
// //                 decoration: InputDecoration(
// //                   hintText: 'Search stocks...',
// //                   hintStyle: TextStyle(color: Colors.white54),
// //                   prefixIcon: Icon(Icons.search, color: Colors.white),
// //                   filled: true,
// //                   fillColor: const Color.fromARGB(41, 0, 0, 0).withOpacity(0.3),
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                     borderSide: BorderSide.none,
// //                   ),
// //                 ),
// //                 onChanged: searchStocks,
// //               ),
// //               SizedBox(height: 16),
// //               SizedBox(height: 16),
// //               // Category Tabs
              
// //               SizedBox(height: 16),
// //               // Filtered Stock List
// //           if (searchQuery.isNotEmpty) 
// //   SizedBox(
// //     height: 300,
// //     child: filteredStocks.isNotEmpty
// //         ? ListView.builder(
// //             itemCount: filteredStocks.length,
// //             itemBuilder: (context, index) {
// //               final stock = filteredStocks[index];

// //               return GestureDetector(
// //                 onTap: () {
// //                   // Navigate to stock details page with API call
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(
// //                      builder: (context) => StockDetailsPage(stockName: stock["name"]!),

// //                     ),
// //                   );
// //                 },
// //                 child: Card(
// //                   color: const Color.fromARGB(54, 33, 33, 33),
// //                   shape: RoundedRectangleBorder(
// //                     borderRadius: BorderRadius.circular(10),
// //                   ),
// //                   child: ListTile(
// //                     leading: CircleAvatar(
// //                       backgroundImage: NetworkImage(stock["logo"]!),
// //                     ),
// //                     title: Text(
// //                       stock["name"]!,
// //                       style: TextStyle(color: Colors.white),
// //                     ),
// //                   ),
// //                 ),
// //               );
// //             },
// //           )
// //         : Center(
// //             child: Text(
// //               "No results found",
// //               style: TextStyle(color: Colors.grey, fontSize: 16),
// //             ),
// //           ),
// //   ),
// //                     SizedBox(height: 14),

// //                     // Navigation Buttons
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                       children: [
// //                         GestureDetector(
// //                           onTap: () {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (context) => PortfolioPage(),
// //                               ),
// //                             );
// //                           },
// //                           child: _buildNavigationItem(
// //                             Icons.pie_chart,
// //                             'Events',
// //                           ),
// //                         ),
// //                         _buildNavigationItem(
// //                             Icons.currency_exchange, 'All stocks'),
// //                         _buildNavigationItem(Icons.show_chart, 'Indices'),
// //                         _buildNavigationItem(Icons.new_label, 'IPO',
// //                             iconColor: Colors.red),
// //                         _buildNavigationItem(Icons.equalizer, 'Equities'),
// //                       ],
// //                     ),
// //                     SizedBox(height: 24),

// //                     // Welcome Text
// //                     Container(
// //                       width: double.infinity,
// //                       padding: EdgeInsets.all(16),
// //                       decoration: BoxDecoration(
// //                         color: const Color.fromARGB(124, 24, 20, 34),
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: Text(
// //                         'Explore stock market trends and insights here!',
// //                         style: TextStyle(color: Colors.white, fontSize: 14),
// //                       ),
// //                     ),
// //                      SizedBox(height: 24), SizedBox(height: 24),
// //                        _buildProfileBalance(),  // Profile Balance section at the top
// //                     SizedBox(height: 24),
// //                     SizedBox(height: 24),
// //                     _buildPerformanceSection(),
// //                     SizedBox(height: 24),
 

// //                     // Action buttons
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
// //       children: [
// //   _buildActionButton(Icons.add_circle_outline, 'Deposit', TopUpScreen()), // Navigates to topup.dart
// //   _buildActionButton(Icons.swap_horiz_outlined, 'Transfer', TopUpScreen()), // Also navigates to topup.dart
// // ],


// //                     ),
                    
// //                     SizedBox(height: 24),
                    
// //                     // Transaction History Section
// //                     _buildTransactionHistory(),
                    
// //                     SizedBox(height: 24),
                    
// //                     // Holdings Section
// //                     _buildHoldingsSection(),
                    
// //                     SizedBox(height: 24),
                    
// //                     // Watchlist Section
// //                     _buildWatchlistSection(),
                    
// //                     SizedBox(height: 20),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //     );
// //   }

// //   Widget _buildNavigationItem(IconData icon, String label,
// //       {Color iconColor = Colors.white}) {
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Container(
// //           padding: EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             color: const Color.fromARGB(41, 66, 66, 66),
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: Icon(icon, color: iconColor, size: 28),
// //         ),
// //         SizedBox(height: 4),
// //         Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
// //       ],
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
// //               color: Colors.white,
// //             ),
// //           ),
// //           Spacer(),
// //           GestureDetector(
// //             onTap: () {
// //               print('See Detail tapped for $title');
// //             },
// //             child: Text(
// //               'See Detail',
// //               style: TextStyle(fontSize: 16, color: Colors.blue),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //  Widget _buildActionButton(IconData icon, String label, Widget destination) {
// //   return GestureDetector(
// //     onTap: () {
// //       Navigator.push(
// //         context,
// //         MaterialPageRoute(builder: (context) => destination),
// //       );
// //     },
// //     child: Column(
// //       children: [
// //         Container(
// //           padding: EdgeInsets.all(12),
// //           decoration: BoxDecoration(
// //             color: Colors.grey[900],
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           child: Icon(icon, color: Colors.white, size: 24),
// //         ),
// //         SizedBox(height: 8),
// //         Text(
// //           label,
// //           style: TextStyle(color: Colors.white70, fontSize: 12),
// //         ),
// //       ],
// //     ),
// //   );
// // }


// //   // Transaction History Section
// //   Widget _buildTransactionHistory() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Transaction History',
// //           style: TextStyle(
// //             color: Colors.white,
// //             fontSize: 18,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         SizedBox(height: 16),
// //         ...transactions.map((transaction) => _transitem(transaction)),
// //       ],
// //     );
// //   }

// //   Widget _transitem(Transaction transaction) {
// //     bool isPositive = transaction.type == TransactionType.sell;
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12),
// //       padding: EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: const Color.fromARGB(124, 24, 20, 34),
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             padding: EdgeInsets.all(8),
// //             decoration: BoxDecoration(
// //               color: isPositive
// //                   ? Colors.green.withOpacity(0.2)
// //                   : Colors.red.withOpacity(0.2),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Icon(
// //               transaction.type == TransactionType.buy
// //                   ? Icons.arrow_downward
// //                   : Icons.arrow_upward,
// //               color: isPositive ? Colors.greenAccent : Colors.redAccent,
// //               size: 20,
// //             ),
// //           ),
// //           SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 Text(
// //                   '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
// //                   style: TextStyle(color: Colors.white70, fontSize: 14),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Column(
// //             crossAxisAlignment: CrossAxisAlignment.end,
// //             children: [
// //               Text(
// //                 '${transaction.currency}${(transaction.amount * transaction.shares).toStringAsFixed(2)}',
// //                 style: TextStyle(
// //                   color: isPositive ? Colors.greenAccent : Colors.redAccent,
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Text(
// //                 transaction.date.toString().substring(0, 10),
// //                 style: TextStyle(color: Colors.white54, fontSize: 12),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }








// // double profileBalance = 12500.75; // Example balance, replace with actual data

// // Widget _buildProfileBalance() {
// //   return Container(
// //     padding: EdgeInsets.all(16),
// //     margin: EdgeInsets.only(bottom: 16),
// //     decoration: BoxDecoration(
// //       color: const Color.fromARGB(124, 24, 20, 34),
// //       borderRadius: BorderRadius.circular(12),
// //     ),
// //     child: Row(
// //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //       children: [
// //         Text(
// //           "Profile Balance",
// //           style: TextStyle(
// //             color: Colors.white70,
// //             fontSize: 16,
// //             fontWeight: FontWeight.w600,
// //           ),
// //         ),
// //         Text(
// //           "\$${profileBalance.toStringAsFixed(2)}", // Displaying balance
// //           style: TextStyle(
// //             color: Colors.greenAccent,
// //             fontSize: 18,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //       ],
// //     ),
// //   );
// // }

// // Widget _buildTransactionItem(Transaction transaction) {
// //   bool isPositive = transaction.type == TransactionType.sell;
// //   return Container(
// //     margin: EdgeInsets.only(bottom: 12),
// //     padding: EdgeInsets.all(16),
// //     decoration: BoxDecoration(
// //       color: const Color.fromARGB(124, 24, 20, 34),
// //       borderRadius: BorderRadius.circular(12),
// //     ),
// //     child: Row(
// //       children: [
// //         Container(
// //           padding: EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             color: isPositive
// //                 ? Colors.green.withOpacity(0.2)
// //                 : Colors.red.withOpacity(0.2),
// //             borderRadius: BorderRadius.circular(8),
// //           ),
// //           child: Icon(
// //             transaction.type == TransactionType.buy
// //                 ? Icons.arrow_downward
// //                 : Icons.arrow_upward,
// //             color: isPositive ? Colors.greenAccent : Colors.redAccent,
// //             size: 20,
// //           ),
// //         ),
// //         SizedBox(width: 16),
// //         Expanded(
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Text(
// //                 '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
// //                 style: TextStyle(color: Colors.white70, fontSize: 14),
// //               ),
// //             ],
// //           ),
// //         ),
// //         Column(
// //           crossAxisAlignment: CrossAxisAlignment.end,
// //           children: [
// //             Text(
// //               '${transaction.currency}${(transaction.amount * transaction.shares).toStringAsFixed(2)}',
// //               style: TextStyle(
// //                 color: isPositive ? Colors.greenAccent : Colors.redAccent,
// //                 fontSize: 16,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             Text(
// //               transaction.date.toString().substring(0, 10),
// //               style: TextStyle(color: Colors.white54, fontSize: 12),
// //             ),
// //           ],
// //         ),
// //       ],
// //     ),
// //   );
// // }

// //   // Holdings Section
// //   Widget _buildHoldingsSection() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text(
// //               'Your Holdings',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             TextButton(
// //               onPressed: () {},
// //               child: Text(
// //                 'See All',
// //                 style: TextStyle(color: Colors.blueAccent),
// //               ),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 16),
// //         ...holdings.map((holding) => _buildHoldingItem(holding)),
// //       ],
// //     );
// //   }

// //   // Watchlist Section
// //   Widget _buildWatchlistSection() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text(
// //               'Watchlist',
// //               style: TextStyle(
// //                 color: Colors.white,
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             TextButton(
// //               onPressed: () {   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(builder: (context) => TradingDashboard()),
// //                   );},
// //               child: Text(
// //                 'Add More',
// //                 style: TextStyle(color: Colors.blueAccent),
// //               ),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 16),
// //         ...watchlist.map((holding) => _buildHoldingItem(holding)),
// //       ],
// //     );
// //   }
// // /// **Reusable Holding Item - Clickable**
// //   Widget _buildHoldingItem(Holding holding) {
// //     bool isPositive = holding.change >= 0;
// //     return GestureDetector(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (context) => StockDetailsPage(stockName: holding.name),
// //           ),
// //         );
// //       },
// //       child: Container(
// //         margin: EdgeInsets.only(bottom: 16),
// //         padding: EdgeInsets.all(16),
// //         decoration: BoxDecoration(
// //           color: const Color.fromARGB(124, 24, 20, 34),
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               padding: EdgeInsets.all(8),
// //               decoration: BoxDecoration(
// //                 color: _getTypeColor(holding.type).withOpacity(0.2),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Icon(
// //                 holding.icon,
// //                 color: _getTypeColor(holding.type),
// //                 size: 24,
// //               ),
// //             ),
// //             SizedBox(width: 16),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     holding.symbol,
// //                     style: TextStyle(
// //                       color: Colors.white,
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   Text(
// //                     holding.name,
// //                     style: TextStyle(color: Colors.white70, fontSize: 14),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.end,
// //               children: [
// //                 Text(
// //                   '\$${holding.value.toStringAsFixed(2)}',
// //                   style: TextStyle(
// //                     color: Colors.white,
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 Row(
// //                   children: [
// //                     Icon(
// //                       isPositive ? Icons.arrow_upward : Icons.arrow_downward,
// //                       color: isPositive ? Colors.greenAccent : Colors.redAccent,
// //                       size: 16,
// //                     ),
// //                     SizedBox(width: 4),
// //                     Text(
// //                       '${isPositive ? '+' : ''}${holding.change.toStringAsFixed(2)} (${holding.changePercentage.toStringAsFixed(2)}%)',
// //                       style: TextStyle(
// //                         color: isPositive ? Colors.greenAccent : Colors.redAccent,
// //                         fontSize: 14,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   /// **Stock Type Colors (Only Stocks & Forex)**
// //   Color _getTypeColor(HoldingType type) {
// //     switch (type) {
// //       case HoldingType.stock:
// //         return Colors.blueAccent;
// //       case HoldingType.forex:
// //         return Colors.greenAccent;
// //       default:
// //         return Colors.white;
// //     }
// //   }

// //   Widget _buildHorizontalCards() {
// //     return Row(
// //       children: [
// //         Expanded(
// //           child: Container(
// //             padding: EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               color: const Color.fromARGB(124, 24, 20, 34),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('Gainer Info', style: TextStyle(color: Colors.green)),
// //               ],
// //             ),
// //           ),
// //         ),
// //         SizedBox(width: 16),
// //         Expanded(
// //           child: Container(
// //             padding: EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               color: const Color.fromARGB(124, 24, 20, 34),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text('Loser Info', style: TextStyle(color: Colors.red)),
// //               ],
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildHorizontalStockList() {
// //     // List of dummy stocks
// //     final List<Map<String, String>> dummyStocks = [
// //       {'name': 'BUKA', 'price': 'Rp278.00'},
// //       {'name': 'BBN', 'price': 'Rp4,630.00'},
// //       {'name': 'SDO', 'price': 'Rp24.00'},
// //       {'name': 'AAPL', 'price': 'Rp150.00'},
// //       {'name': 'GOOGL', 'price': 'Rp2,800.00'},
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
// //                   builder: (context) => StockDetailsPage(stockName: stock['name']!),
// //                 ),
// //               );
// //             },
// //             child: Container(
// //               width: 200,
// //               margin: EdgeInsets.only(right: 16),
// //               padding: EdgeInsets.all(12),
// //               decoration: BoxDecoration(
// //                 color: const Color.fromARGB(124, 24, 20, 34),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     stock['name']!,
// //                     style: TextStyle(
// //                       fontSize: 18,
// //                       fontWeight: FontWeight.bold,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                   SizedBox(height: 8),
// //                   Text(
// //                     stock['price']!,
// //                     style: TextStyle(
// //                       fontSize: 16,
// //                       color: Colors.white,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildHorizontalNewsList() {
// //     return Container(
// //       height: 120,
// //       child: ListView.builder(
// //         scrollDirection: Axis.horizontal,
// //         itemCount: 5,
// //         itemBuilder: (context, index) {
// //           return Container(
// //             width: 200,
// //             margin: EdgeInsets.only(right: 16),
// //             padding: EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               color: const Color.fromARGB(124, 24, 20, 34),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Text('News Info $index', style: TextStyle(color: Colors.white)),
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }

// // void main() {
// //   runApp(MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Stock Market App',
// //       theme: ThemeData.dark(),
// //       home: DashboardScreen(),
// //       debugShowCheckedModeBanner: false,
// //     );
// //   }
// // }




// /// white theme

// import 'package:flutter/material.dart';
// import 'package:test_project/features/profile/profile.dart'; // Import your profile screen here.
// import 'package:test_project/features/trading/topup.dart';
// import 'package:test_project/features/trending/treanding.dart';
// import 'package:test_project/features/stock/stock_details.dart'; // Import the new stock details page
// import 'package:test_project/features/notifications/notification.dart';
// import 'package:test_project/features/wishlist/wishlist.dart' hide StockDetailsPage;
// import 'package:test_project/features/portfolio/portfolio.dart';

// class DashboardScreen extends StatefulWidget {
//   @override
//   _DashboardScreenState createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
//   int _selectedIndex = 0;
//   bool _isExpanded = false;
//   late AnimationController _controller;
//   late Animation<double> _sizeAnimation;
//   late Animation<double> _iconOpacityAnimation;

//   final List<Widget> _screens = [
//     DashboardContent(),
//     TrendingScreen(),
//     // TopUpScreen(),
//     TradingDashboard(),
//     ProfileScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 500),
//     );

//     _sizeAnimation = Tween<double>(begin: 50, end: 70).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
//     );

//     _iconOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
//     );
//   }

//   // search
// List<Map<String, String>> allStocks = [
//     {"name": "ibm", "logo": "https://logo.clearbit.com/ibm.com"},
//     {"name": "BUKA", "logo": "https://logo.clearbit.com/amazon.com"},
//     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
//     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
//     {"name": "GOOGL", "logo": "https://logo.clearbit.com/google.com"},
//     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
//     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
//   ];

//   List<Map<String, String>> filteredStocks = [];
//   String searchQuery = "";
//   bool isLoading = false;
// void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//         _shrinkNavBar(); 
//     });
//   }

//  void searchStocks(String query) {
//   setState(() {
//     searchQuery = query;
//     filteredStocks = allStocks
//         .where((stock) =>
//             stock["name"]!.toLowerCase().startsWith(query.toLowerCase())) // Only matches stocks that start with the query
//         .toList();
//   });
// }

//   // search end 


//   void _toggleNavBar() {
//     setState(() {
//       _isExpanded = !_isExpanded;
//       if (_isExpanded) {
//         _controller.forward();
//       } else {
//         _controller.reverse();
//       }
//     });
//   }

 
//   void _shrinkNavBar() {
//     if (_isExpanded) {
//       setState(() {
//         _isExpanded = false;
//         _controller.reverse();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           _screens[_selectedIndex], // Main content stays in sync with navbar
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: GestureDetector(
//               onTap: _toggleNavBar,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   return Container(
//                     width: _isExpanded ? MediaQuery.of(context).size.width - 60 : 80,
//                     height: _sizeAnimation.value,
//                     margin: EdgeInsets.only(bottom: 15), // Slightly above bottom
//                     decoration: BoxDecoration(
//                       color: Colors.deepPurple.withOpacity(0.95),
//                       shape: _isExpanded ? BoxShape.rectangle : BoxShape.circle, // Ball when shrunk
//                       borderRadius: _isExpanded ? BorderRadius.circular(60) : null,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.deepPurple.withOpacity(0.3),
//                           blurRadius: 12.0,
//                           spreadRadius: 4,
//                           offset: Offset(0, -8),
//                         ),
//                       ],
//                     ),
//                     child: _isExpanded
//                         ? ClipRRect(
//                             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//                             child: BottomNavigationBar(
//                               type: BottomNavigationBarType.fixed,
//                               backgroundColor: Colors.transparent,
//                               selectedItemColor: Colors.white,
//                               unselectedItemColor: Colors.white.withOpacity(0.7),
//                               currentIndex: _selectedIndex,
//                               onTap: _onItemTapped,
//                               elevation: 0,
//                               items: [
//                                 BottomNavigationBarItem(
//                                   icon: Opacity(
//                                     opacity: _iconOpacityAnimation.value,
//                                     child: Icon(Icons.home_filled, size: 20),
//                                   ),
//                                   label: 'Activity',
//                                 ),
//                                 BottomNavigationBarItem(
//                                   icon: Opacity(
//                                     opacity: _iconOpacityAnimation.value,
//                                     child: Icon(Icons.trending_up_rounded, size: 20),
//                                   ),
//                                   label: 'Investing',
//                                 ),
//                                 // BottomNavigationBarItem(
//                                 //   icon: Opacity(
//                                 //     opacity: _iconOpacityAnimation.value,
//                                 //     child: Container(
//                                 //       padding: EdgeInsets.all(6),
//                                 //       decoration: BoxDecoration(
//                                 //         color: Colors.white.withOpacity(0.2),
//                                 //         shape: BoxShape.circle,
//                                 //       ),
//                                 //       child: Icon(Icons.account_balance_wallet_rounded, size: 22),
//                                 //     ),
//                                 //   ),
//                                 //   label: 'Transact',
//                                 // ),
//                                 BottomNavigationBarItem(
//                                   icon: Opacity(
//                                     opacity: _iconOpacityAnimation.value,
//                                     child: Icon(Icons.favorite_rounded, size: 20),
//                                   ),
//                                   label: 'Wish List',
//                                 ),
//                                 BottomNavigationBarItem(
//                                   icon: Opacity(
//                                     opacity: _iconOpacityAnimation.value,
//                                     child: Icon(Icons.person_rounded, size: 20),
//                                   ),
//                                   label: 'Profile',
//                                 ),
//                               ],
//                             ),
//                           )
                          
//                         : Center(
//                             child: Icon(Icons.menu, size: 22, color: Colors.white), // Small floating ball
//                           ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// Widget _buildPerformanceSection() {
//   return CombinedPortfolioPerformance(showBalance: true);
// }

// // Enum definitions needed for the transactions and holdings
// enum TransactionType { buy, sell }
// enum HoldingType { stock, crypto, forex }

// class Transaction {
//   final String symbol;
//   final double amount;
//   final int shares;
//   final TransactionType type;
//   final DateTime date;
//   final String currency;

//   Transaction({
//     required this.symbol,
//     required this.amount,
//     required this.shares,
//     required this.type,
//     required this.date,
//     required this.currency,
//   });
// }

// class Holding {
//   final String symbol;
//   final String name;
//   final double value;
//   final double change;
//   final double changePercentage;
//   final HoldingType type;
//   final IconData icon;

//   Holding({
//     required this.symbol,
//     required this.name,
//     required this.value,
//     required this.change,
//     required this.changePercentage,
//     required this.type,
//     required this.icon,
//   });
// }

// class DashboardContent extends StatefulWidget {
//   @override
//   _DashboardContentState createState() => _DashboardContentState();
// }

// class _DashboardContentState extends State<DashboardContent> {
//   List<Map<String, String>> allStocks = [
//     {"name": "Apple", "logo": "https://logo.clearbit.com/apple.com"},
//     {"name": "Amazon", "logo": "https://logo.clearbit.com/amazon.com"},
//     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
//     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
//     {"name": "Google", "logo": "https://logo.clearbit.com/google.com"},
//     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
//     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
//   ];

//   // Add the missing data structures
//   List<Transaction> transactions = [
//     Transaction(
//       symbol: 'AAPL',
//       amount: 150.75,
//       shares: 10,
//       type: TransactionType.buy,
//       date: DateTime.now().subtract(Duration(days: 5)),
//       currency: '\$',
//     ),
//     Transaction(
//       symbol: 'MSFT',
//       amount: 240.50,
//       shares: 5,
//       type: TransactionType.sell,
//       date: DateTime.now().subtract(Duration(days: 2)),
//       currency: '\$',
//     ),
//     Transaction(
//       symbol: 'GOOGL',
//       amount: 2750.25,
//       shares: 2,
//       type: TransactionType.buy,
//       date: DateTime.now().subtract(Duration(days: 1)),
//       currency: '\$',
//     ),
//   ];

//   List<Holding> holdings = [
//     Holding(
//       symbol: 'AAPL',
//       name: 'Apple Inc.',
//       value: 1507.50,
//       change: 23.75,
//       changePercentage: 1.58,
//       type: HoldingType.stock,
//       icon: Icons.phone_iphone,
//     ),
//     Holding(
//       symbol: 'BTC',
//       name: 'Bitcoin',
//       value: 3625.00,
//       change: -125.30,
//       changePercentage: -3.34,
//       type: HoldingType.crypto,
//       icon: Icons.currency_bitcoin,
//     ),
//     Holding(
//       symbol: 'EUR/USD',
//       name: 'Euro/USD',
//       value: 1250.75,
//       change: 12.25,
//       changePercentage: 0.98,
//       type: HoldingType.forex,
//       icon: Icons.currency_exchange,
//     ),
//   ];

//   List<Holding> watchlist = [
//     Holding(
//       symbol: 'NVDA',
//       name: 'NVIDIA Corporation',
//       value: 275.50,
//       change: 5.25,
//       changePercentage: 1.94,
//       type: HoldingType.stock,
//       icon: Icons.memory,
//     ),
//     Holding(
//       symbol: 'ETH',
//       name: 'Ethereum',
//       value: 1875.25,
//       change: 45.75,
//       changePercentage: 2.50,
//       type: HoldingType.crypto,
//       icon: Icons.auto_graph,
//     ),
//   ];

//   List<Map<String, String>> filteredStocks = [];
//   String searchQuery = "";
//   bool isLoading = false;
// String selectedTimeframe = '24 hour';
//   String selectedCategory = 'Global';
//   int _selectedIndex = 0; // For tracking the selected tab

  
 
//   @override
//   void initState() {
//     super.initState();
//     filteredStocks = allStocks;
//   }

// void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   void searchStocks(String query) {
//     setState(() {
//       searchQuery = query;
//       filteredStocks = allStocks
//           .where((stock) =>
//               stock["name"]!.toLowerCase().contains(query.toLowerCase()))
//           .toList();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(
//               backgroundImage: AssetImage('assets/profile.jpg'),
//               radius: 16,
//             ),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Hallo Rohan Wadadar',
//                 style: TextStyle(fontSize: 16, color: Colors.black),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             Stack(
//               children: [
//                 IconButton(
//                   icon: Icon(Icons.notifications, size: 24, color: Colors.black),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => NotificationScreen()),
//                     );
//                   },
//                 ),
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: Container(
//                     padding: EdgeInsets.all(2),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Text(
//                       '2',
//                       style: TextStyle(color: Colors.white, fontSize: 10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         backgroundColor: Colors.grey[50],
//         elevation: 1,
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
//           : SingleChildScrollView(
//               child: Container(
//                 color: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                  children: [
//                     // Search Bar
//                     SizedBox(height: 16),

// TextField(
//                 style: TextStyle(color: Colors.black),
//                 decoration: InputDecoration(
//                   hintText: 'Search stocks...',
//                   hintStyle: TextStyle(color: Colors.grey[600]),
//                   prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//                   filled: true,
//                   fillColor: Colors.grey[50],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.grey[300]!),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.grey[300]!),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.deepPurple),
//                   ),
//                 ),
//                 onChanged: searchStocks,
//               ),
//               SizedBox(height: 16),
//               SizedBox(height: 16),
//               // Category Tabs
              
//               SizedBox(height: 16),
//               // Filtered Stock List
//           if (searchQuery.isNotEmpty) 
//   SizedBox(
//     height: 300,
//     child: filteredStocks.isNotEmpty
//         ? ListView.builder(
//             itemCount: filteredStocks.length,
//             itemBuilder: (context, index) {
//               final stock = filteredStocks[index];

//               return GestureDetector(
//                 onTap: () {
//                   // Navigate to stock details page with API call
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                      builder: (context) => StockDetailsPage(stockName: stock["name"]!),

//                     ),
//                   );
//                 },
//                 child: Card(
//                   color: Colors.grey[50],
//                   elevation: 1,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     side: BorderSide(color: Colors.grey[200]!),
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: NetworkImage(stock["logo"]!),
//                     ),
//                     title: Text(
//                       stock["name"]!,
//                       style: TextStyle(color: Colors.black),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           )
//         : Center(
//             child: Text(
//               "No results found",
//               style: TextStyle(color: Colors.grey[600], fontSize: 16),
//             ),
//           ),
//   ),
// //SizedBox(height: 14),

//                     // // Navigation Buttons
//                     // Row(
//                     //   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     //   children: [
//                     //     GestureDetector(
//                     //       onTap: () {
//                     //         Navigator.push(
//                     //           context,
//                     //           MaterialPageRoute(
//                     //             builder: (context) => PortfolioPage(),
//                     //           ),
//                     //         );
//                     //       },
//                     //       child: _buildNavigationItem(
//                     //         Icons.pie_chart,
//                     //         'Events',
//                     //       ),
//                     //     ),
//                     //     _buildNavigationItem(
//                     //         Icons.currency_exchange, 'All stocks'),
//                     //     _buildNavigationItem(Icons.show_chart, 'Indices'),
//                     //     _buildNavigationItem(Icons.new_label, 'IPO',
//                     //         iconColor: Colors.red),
//                     //     _buildNavigationItem(Icons.equalizer, 'Equities'),
//                     //   ],
//                     // ),
//                     // SizedBox(height: 24),

//                     // Welcome Text
//                     Container(
//                       width: double.infinity,
//                       padding: EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.deepPurple[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.deepPurple[100]!),
//                       ),
//                       child: Text(
//                         'Explore stock market trends and insights here!',
//                         style: TextStyle(color: Colors.deepPurple[800], fontSize: 14),
//                       ),
//                     ),
// //SizedBox(height: 24), SizedBox(height: 24),
//                    //    _buildProfileBalance(),  // Profile Balance section at the top
//                 //    SizedBox(height: 24),
//                     SizedBox(height: 24),
//                     _buildPerformanceSection(),
//                     SizedBox(height: 24),
 

//                     // Action buttons
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
// //       children: [
// //   _buildActionButton(Icons.add_circle_outline, 'Deposit', TopUpScreen()), // Navigates to topup.dart
// //   _buildActionButton(Icons.swap_horiz_outlined, 'Transfer', TopUpScreen()), // Also navigates to topup.dart
// // ],


//                     // ),
                    
//                     // SizedBox(height: 24),
                    
//                     // // Transaction History Section
//                     // _buildTransactionHistory(),
                    
//                      // Wishlist Section Header
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text(
// //                           'Your Wishlist',
// //                           style: TextStyle(
// //                             fontSize: 18,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.black,
// //                           ),
// //                         ),
// //                         Container(
// //                           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //                           decoration: BoxDecoration(
// //                             border: Border.all(color: Colors.grey[300]!),
// //                             borderRadius: BorderRadius.circular(8),
// //                             color: Colors.grey[50],
// //                           ),
// //                           child: DropdownButtonHideUnderline(
// //                             child: DropdownButton<String>(
// //                               value: selectedWishlist,
// //                               icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
// //                               style: TextStyle(color: Colors.black, fontSize: 14),
// //                               items: wishlistOptions.map<DropdownMenuItem<String>>((String value) {
// //                                 return DropdownMenuItem<String>(
// //                                   value: value,
// //                                   child: Text(value),
// //                                 );
// //                               }).toList(),
// //                               onChanged: (String? newValue) {
// //                                 setState(() {
// //                                   selectedWishlist = newValue!;
// //                                   _updateHoldingsForWishlist(newValue);
// //                                 });
// //                               },
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     SizedBox(height: 16),
                    
// //                     // Holdings Section (now displays wishlist stocks)
// //                     _buildHoldingsSection(),
                    
//                     SizedBox(height: 24),
                    
//                     // Watchlist Section
//                     _buildWatchlistSection(),
                    
//                     SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildNavigationItem(IconData icon, String label,
//       {Color iconColor = Colors.black}) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.grey[100],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: Icon(icon, color: iconColor, size: 28),
//         ),
//         SizedBox(height: 4),
//         Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
//       ],
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

//  Widget _buildActionButton(IconData icon, String label, Widget destination) {
//   return GestureDetector(
//     onTap: () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => destination),
//       );
//     },
//     child: Column(
//       children: [
//         Container(
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.deepPurple[50],
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.deepPurple[100]!),
//           ),
//           child: Icon(icon, color: Colors.deepPurple, size: 24),
//         ),
//         SizedBox(height: 8),
//         Text(
//           label,
//           style: TextStyle(color: Colors.black, fontSize: 12),
//         ),
//       ],
//     ),
//   );
// }


//   // Transaction History Section
//   Widget _buildTransactionHistory() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Transaction History',
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: 16),
//         ...transactions.map((transaction) => _transitem(transaction)),
//       ],
//     );
//   }

//   Widget _transitem(Transaction transaction) {
//     bool isPositive = transaction.type == TransactionType.sell;
//     return Container(
//       margin: EdgeInsets.only(bottom: 12),
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: isPositive
//                   ? Colors.green.withOpacity(0.1)
//                   : Colors.red.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               transaction.type == TransactionType.buy
//                   ? Icons.arrow_downward
//                   : Icons.arrow_upward,
//               color: isPositive ? Colors.green : Colors.red,
//               size: 20,
//             ),
//           ),
//           SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '${transaction.currency}${(transaction.amount * transaction.shares).toStringAsFixed(2)}',
//                 style: TextStyle(
//                   color: isPositive ? Colors.green : Colors.red,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 transaction.date.toString().substring(0, 10),
//                 style: TextStyle(color: Colors.grey[500], fontSize: 12),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

// double profileBalance = 12500.75; // Example balance, replace with actual data

// Widget _buildProfileBalance() {
//   return Container(
//     padding: EdgeInsets.all(16),
//     margin: EdgeInsets.only(bottom: 16),
//     decoration: BoxDecoration(
//       color: Colors.deepPurple[50],
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.deepPurple[100]!),
//     ),

//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           "Profile Balance",
//           style: TextStyle(
//             color: Colors.black,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         Text(
//           "\$${profileBalance.toStringAsFixed(2)}", // Displaying balance
//           style: TextStyle(
//             color: Colors.deepPurple,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// Widget _buildTransactionItem(Transaction transaction) {
//   bool isPositive = transaction.type == TransactionType.sell;
//   return Container(
//     margin: EdgeInsets.only(bottom: 12),
//     padding: EdgeInsets.all(16),
//     decoration: BoxDecoration(
//       color: Colors.grey[50],
//       borderRadius: BorderRadius.circular(12),
//       border: Border.all(color: Colors.grey[200]!),
//     ),
//     child: Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: isPositive
//                 ? Colors.green.withOpacity(0.1)
//                 : Colors.red.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             transaction.type == TransactionType.buy
//                 ? Icons.arrow_downward
//                 : Icons.arrow_upward,
//             color: isPositive ? Colors.green : Colors.red,
//             size: 20,
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Text(
//                 '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 14),
//               ),
//             ],
//           ),
//         ),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               '${transaction.currency}${(transaction.amount * transaction.shares).toStringAsFixed(2)}',
//               style: TextStyle(
//                 color: isPositive ? Colors.green : Colors.red,
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               transaction.date.toString().substring(0, 10),
//               style: TextStyle(color: Colors.grey[500], fontSize: 12),
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }

//   // Holdings Section
//   Widget _buildHoldingsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'my Watchlist',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton(
//               onPressed: () {},
//               child: Text(
//                 'See All',
//                 style: TextStyle(color: Colors.deepPurple),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 16),
//         ...holdings.map((holding) => _buildHoldingItem(holding)),
//       ],
//     );
//   }

//   // Watchlist Section
//   Widget _buildWatchlistSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Watchlist',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton(
//               onPressed: () {   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (context) => TradingDashboard()),
//                   );},
//               child: Text(
//                 'Add More',
//                 style: TextStyle(color: Colors.deepPurple),
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 16),
//         ...watchlist.map((holding) => _buildHoldingItem(holding)),
//       ],
//     );
//   }

//   Widget _buildHoldingItem(Holding holding) {
//     bool isPositive = holding.change >= 0;
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => StockDetailsPage(stockName: holding.name),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.grey[50],
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey[200]!),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: _getTypeColor(holding.type).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 holding.icon,
//                 color: _getTypeColor(holding.type),
//                 size: 24,
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     holding.symbol,
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     holding.name,
//                     style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   '\${holding.value.toStringAsFixed(2)}',
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Icon(
//                       isPositive ? Icons.arrow_upward : Icons.arrow_downward,
//                       color: isPositive ? Colors.green : Colors.red,
//                       size: 16,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       '${isPositive ? '+' : ''}${holding.change.toStringAsFixed(2)} (${holding.changePercentage.toStringAsFixed(2)}%)',
//                       style: TextStyle(
//                         color: isPositive ? Colors.green : Colors.red,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

// }
//   /// **Stock Type Colors (Only Stocks & Forex)**
//   Color _getTypeColor(HoldingType type) {
//     switch (type) {
//       case HoldingType.stock:
//         return Colors.deepPurple;
//       case HoldingType.forex:
//         return Colors.deepPurple[700]!;
//       case HoldingType.crypto:
//         return Colors.deepPurple[600]!;
//       default:
//         return Colors.deepPurple;
//     }
//   }

//   Widget _buildHorizontalCards() {
//     return Row(
//       children: [
//         Expanded(
//           child: Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.green[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.green[100]!),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Gainer Info', style: TextStyle(color: Colors.green[800])),
//               ],
//             ),
//           ),
//         ),
//         SizedBox(width: 16),
//         Expanded(
//           child: Container(
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.red[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.red[100]!),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Loser Info', style: TextStyle(color: Colors.red[800])),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHorizontalStockList() {
//     // List of dummy stocks
//     final List<Map<String, String>> dummyStocks = [
//       {'name': 'BUKA', 'price': 'Rp278.00'},
//       {'name': 'BBN', 'price': 'Rp4,630.00'},
//       {'name': 'SDO', 'price': 'Rp24.00'},
//       {'name': 'AAPL', 'price': 'Rp150.00'},
//       {'name': 'GOOGL', 'price': 'Rp2,800.00'},
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
//                   builder: (context) => StockDetailsPage(stockName: stock['name']!),
//                 ),
//               );
//             },
//             child: Container(
//               width: 200,
//               margin: EdgeInsets.only(right: 16),
//               padding: EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey[200]!),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     stock['name']!,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     stock['price']!,
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildHorizontalNewsList() {
//     return Container(
//       height: 120,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: 5,
//         itemBuilder: (context, index) {
//           return Container(
//             width: 200,
//             margin: EdgeInsets.only(right: 16),
//             padding: EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey[200]!),
//             ),
//             child: Text('News Info $index', style: TextStyle(color: Colors.black)),
//           );
//         },
//       ),
//     );
//   }


// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Stock Market App',
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         scaffoldBackgroundColor: Colors.white,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.grey[50],
//           foregroundColor: Colors.black,
//         ),
//       ),
//       home: DashboardScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }


































// // import 'package:flutter/material.dart';
// // import 'package:test_project/features/profile/profile.dart'; // Import your profile screen here.
// // import 'package:test_project/features/trading/topup.dart';
// // import 'package:test_project/features/trending/treanding.dart';
// // import 'package:test_project/features/stock/stock_details.dart'; // Import the new stock details page
// // import 'package:test_project/features/notifications/notification.dart';
// // import 'package:test_project/features/wishlist/wishlist.dart' hide StockDetailsPage;
// // import 'package:test_project/features/portfolio/portfolio.dart';

// // class DashboardScreen extends StatefulWidget {
// //   @override
// //   _DashboardScreenState createState() => _DashboardScreenState();
// // }

// // class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
// //   int _selectedIndex = 0;
// //   bool _isExpanded = false;
// //   late AnimationController _controller;
// //   late Animation<double> _sizeAnimation;
// //   late Animation<double> _iconOpacityAnimation;

// //   final List<Widget> _screens = [
// //     DashboardContent(),
// //     TrendingScreen(),
// //     TradingDashboard(),
// //     ProfileScreen(),
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(
// //       vsync: this,
// //       duration: Duration(milliseconds: 500),
// //     );

// //     _sizeAnimation = Tween<double>(begin: 50, end: 70).animate(
// //       CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
// //     );

// //     _iconOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
// //       CurvedAnimation(parent: _controller, curve: Curves.easeIn),
// //     );
// //   }

// //   void _onItemTapped(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //       _shrinkNavBar(); 
// //     });
// //   }

// //   void _toggleNavBar() {
// //     setState(() {
// //       _isExpanded = !_isExpanded;
// //       if (_isExpanded) {
// //         _controller.forward();
// //       } else {
// //         _controller.reverse();
// //       }
// //     });
// //   }

// //   void _shrinkNavBar() {
// //     if (_isExpanded) {
// //       setState(() {
// //         _isExpanded = false;
// //         _controller.reverse();
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Stack(
// //         children: [
// //           _screens[_selectedIndex],
// //           Align(
// //             alignment: Alignment.bottomCenter,
// //             child: GestureDetector(
// //               onTap: _toggleNavBar,
// //               child: AnimatedBuilder(
// //                 animation: _controller,
// //                 builder: (context, child) {
// //                   return Container(
// //                     width: _isExpanded ? MediaQuery.of(context).size.width - 60 : 80,
// //                     height: _sizeAnimation.value,
// //                     margin: EdgeInsets.only(bottom: 15),
// //                     decoration: BoxDecoration(
// //                       color: Colors.deepPurple.withOpacity(0.95),
// //                       shape: _isExpanded ? BoxShape.rectangle : BoxShape.circle,
// //                       borderRadius: _isExpanded ? BorderRadius.circular(60) : null,
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.deepPurple.withOpacity(0.3),
// //                           blurRadius: 12.0,
// //                           spreadRadius: 4,
// //                           offset: Offset(0, -8),
// //                         ),
// //                       ],
// //                     ),
// //                     child: _isExpanded
// //                         ? ClipRRect(
// //                             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
// //                             child: BottomNavigationBar(
// //                               type: BottomNavigationBarType.fixed,
// //                               backgroundColor: Colors.transparent,
// //                               selectedItemColor: Colors.white,
// //                               unselectedItemColor: Colors.white.withOpacity(0.7),
// //                               currentIndex: _selectedIndex,
// //                               onTap: _onItemTapped,
// //                               elevation: 0,
// //                               items: [
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.home_filled, size: 20),
// //                                   ),
// //                                   label: 'Activity',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.trending_up_rounded, size: 20),
// //                                   ),
// //                                   label: 'Investing',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.favorite_rounded, size: 20),
// //                                   ),
// //                                   label: 'Wish List',
// //                                 ),
// //                                 BottomNavigationBarItem(
// //                                   icon: Opacity(
// //                                     opacity: _iconOpacityAnimation.value,
// //                                     child: Icon(Icons.person_rounded, size: 20),
// //                                   ),
// //                                   label: 'Profile',
// //                                 ),
// //                               ],
// //                             ),
// //                           )
// //                         : Center(
// //                             child: Icon(Icons.menu, size: 22, color: Colors.white),
// //                           ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _controller.dispose();
// //     super.dispose();
// //   }
// // }

// // Widget _buildPerformanceSection() {
// //   return CombinedPortfolioPerformance(showBalance: true);
// // }

// // // Enum definitions
// // enum TransactionType { buy, sell }
// // enum HoldingType { stock, crypto, forex }

// // class Transaction {
// //   final String symbol;
// //   final double amount;
// //   final int shares;
// //   final TransactionType type;
// //   final DateTime date;
// //   final String currency;

// //   Transaction({
// //     required this.symbol,
// //     required this.amount,
// //     required this.shares,
// //     required this.type,
// //     required this.date,
// //     required this.currency,
// //   });
// // }

// // class Holding {
// //   final String symbol;
// //   final String name;
// //   final double value;
// //   final double change;
// //   final double changePercentage;
// //   final HoldingType type;
// //   final IconData icon;

// //   Holding({
// //     required this.symbol,
// //     required this.name,
// //     required this.value,
// //     required this.change,
// //     required this.changePercentage,
// //     required this.type,
// //     required this.icon,
// //   });
// // }

// // class DashboardContent extends StatefulWidget {
// //   @override
// //   _DashboardContentState createState() => _DashboardContentState();
// // }

// // class _DashboardContentState extends State<DashboardContent> {
// //   // Stock search data
// //   List<Map<String, String>> allStocks = [
// //     {"name": "Apple", "logo": "https://logo.clearbit.com/apple.com"},
// //     {"name": "Amazon", "logo": "https://logo.clearbit.com/amazon.com"},
// //     {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
// //     {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
// //     {"name": "Google", "logo": "https://logo.clearbit.com/google.com"},
// //     {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
// //     {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
// //   ];

// //   List<Map<String, String>> filteredStocks = [];
// //   String searchQuery = "";
// //   bool isLoading = false;

// //   // Wishlist variables
// //   String selectedWishlist = 'My Watchlist';
// //   List<String> wishlistOptions = [
// //     'My Watchlist',
// //     'Tech Stocks',
// //     'Blue Chips',
// //     'Growth Stocks',
// //     'Dividend Stocks'
// //   ];

// //   // Sample data
// //   List<Transaction> transactions = [
// //     Transaction(
// //       symbol: 'AAPL',
// //       amount: 150.75,
// //       shares: 10,
// //       type: TransactionType.buy,
// //       date: DateTime.now().subtract(Duration(days: 5)),
// //       currency: '\$',
// //     ),
// //     Transaction(
// //       symbol: 'MSFT',
// //       amount: 240.50,
// //       shares: 5,
// //       type: TransactionType.sell,
// //       date: DateTime.now().subtract(Duration(days: 2)),
// //       currency: '\$',
// //     ),
// //     Transaction(
// //       symbol: 'GOOGL',
// //       amount: 2750.25,
// //       shares: 2,
// //       type: TransactionType.buy,
// //       date: DateTime.now().subtract(Duration(days: 1)),
// //       currency: '\$',
// //     ),
// //   ];

// //   List<Holding> holdings = [
// //     Holding(
// //       symbol: 'AAPL',
// //       name: 'Apple Inc.',
// //       value: 1507.50,
// //       change: 23.75,
// //       changePercentage: 1.58,
// //       type: HoldingType.stock,
// //       icon: Icons.phone_iphone,
// //     ),
// //     Holding(
// //       symbol: 'BTC',
// //       name: 'Bitcoin',
// //       value: 3625.00,
// //       change: -125.30,
// //       changePercentage: -3.34,
// //       type: HoldingType.crypto,
// //       icon: Icons.currency_bitcoin,
// //     ),
// //     Holding(
// //       symbol: 'EUR/USD',
// //       name: 'Euro/USD',
// //       value: 1250.75,
// //       change: 12.25,
// //       changePercentage: 0.98,
// //       type: HoldingType.forex,
// //       icon: Icons.currency_exchange,
// //     ),
// //   ];

// //   List<Holding> watchlist = [
// //     Holding(
// //       symbol: 'NVDA',
// //       name: 'NVIDIA Corporation',
// //       value: 275.50,
// //       change: 5.25,
// //       changePercentage: 1.94,
// //       type: HoldingType.stock,
// //       icon: Icons.memory,
// //     ),
// //     Holding(
// //       symbol: 'ETH',
// //       name: 'Ethereum',
// //       value: 1875.25,
// //       change: 45.75,
// //       changePercentage: 2.50,
// //       type: HoldingType.crypto,
// //       icon: Icons.auto_graph,
// //     ),
// //   ];

// //   double profileBalance = 12500.75;

// //   @override
// //   void initState() {
// //     super.initState();
// //     filteredStocks = allStocks;
// //   }

// //   void searchStocks(String query) {
// //     setState(() {
// //       searchQuery = query;
// //       filteredStocks = allStocks
// //           .where((stock) =>
// //               stock["name"]!.toLowerCase().contains(query.toLowerCase()))
// //           .toList();
// //     });
// //   }

// //   // Method to get stocks for specific wishlist
// //   List<Map<String, String>> getStocksForWishlist(String wishlistName) {
// //     Map<String, List<Map<String, String>>> wishlistData = {
// //       'My Watchlist': [
// //         {'name': 'Apple Inc.', 'symbol': 'AAPL', 'price': '\$150.25', 'change': '+2.5%', 'logo': 'https://logo.clearbit.com/apple.com'},
// //         {'name': 'Google', 'symbol': 'GOOGL', 'price': '\$2750.80', 'change': '+1.2%', 'logo': 'https://logo.clearbit.com/google.com'},
// //         {'name': 'Microsoft', 'symbol': 'MSFT', 'price': '\$305.15', 'change': '-0.8%', 'logo': 'https://logo.clearbit.com/microsoft.com'},
// //       ],
// //       'Tech Stocks': [
// //         {'name': 'Apple Inc.', 'symbol': 'AAPL', 'price': '\$150.25', 'change': '+2.5%', 'logo': 'https://logo.clearbit.com/apple.com'},
// //         {'name': 'Tesla', 'symbol': 'TSLA', 'price': '\$890.50', 'change': '+3.2%', 'logo': 'https://logo.clearbit.com/tesla.com'},
// //         {'name': 'Netflix', 'symbol': 'NFLX', 'price': '\$385.90', 'change': '+1.8%', 'logo': 'https://logo.clearbit.com/netflix.com'},
// //         {'name': 'Meta', 'symbol': 'META', 'price': '\$325.45', 'change': '-1.1%', 'logo': 'https://logo.clearbit.com/meta.com'},
// //       ],
// //       'Blue Chips': [
// //         {'name': 'Johnson & Johnson', 'symbol': 'JNJ', 'price': '\$165.75', 'change': '+0.5%', 'logo': 'https://logo.clearbit.com/jnj.com'},
// //         {'name': 'Coca Cola', 'symbol': 'KO', 'price': '\$58.20', 'change': '+0.8%', 'logo': 'https://logo.clearbit.com/coca-cola.com'},
// //         {'name': 'Procter & Gamble', 'symbol': 'PG', 'price': '\$145.30', 'change': '+0.3%', 'logo': 'https://logo.clearbit.com/pg.com'},
// //       ],
// //       'Growth Stocks': [
// //         {'name': 'Amazon', 'symbol': 'AMZN', 'price': '\$3200.15', 'change': '+2.8%', 'logo': 'https://logo.clearbit.com/amazon.com'},
// //         {'name': 'Zoom', 'symbol': 'ZM', 'price': '\$85.60', 'change': '+4.2%', 'logo': 'https://logo.clearbit.com/zoom.us'},
// //         {'name': 'Shopify', 'symbol': 'SHOP', 'price': '\$1250.90', 'change': '+5.1%', 'logo': 'https://logo.clearbit.com/shopify.com'},
// //       ],
// //       'Dividend Stocks': [
// //         {'name': 'AT&T', 'symbol': 'T', 'price': '\$25.45', 'change': '-0.2%', 'logo': 'https://logo.clearbit.com/att.com'},
// //         {'name': 'Verizon', 'symbol': 'VZ', 'price': '\$52.80', 'change': '+0.1%', 'logo': 'https://logo.clearbit.com/verizon.com'},
// //         {'name': 'ExxonMobil', 'symbol': 'XOM', 'price': '\$95.25', 'change': '+1.5%', 'logo': 'https://logo.clearbit.com/exxonmobil.com'},
// //       ],
// //     };
    
// //     return wishlistData[wishlistName] ?? [];
// //   }

// //   // Method to update holdings based on selected wishlist
// //   void _updateHoldingsForWishlist(String wishlist) {
// //     setState(() {
// //       // The UI will automatically update since we're using selectedWishlist
// //       // in the _buildHoldingsSection method
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         title: Row(
// //           children: [
// //             CircleAvatar(
// //               backgroundImage: AssetImage('assets/profile.jpg'),
// //               radius: 16,
// //             ),
// //             SizedBox(width: 8),
// //             Expanded(
// //               child: Text(
// //                 'Hallo Rohan Wadadar',
// //                 style: TextStyle(fontSize: 16, color: Colors.black),
// //                 overflow: TextOverflow.ellipsis,
// //               ),
// //             ),
// //             Stack(
// //               children: [
// //                 IconButton(
// //                   icon: Icon(Icons.notifications, size: 24, color: Colors.black),
// //                   onPressed: () {
// //                     Navigator.push(
// //                       context,
// //                       MaterialPageRoute(
// //                           builder: (context) => NotificationScreen()),
// //                     );
// //                   },
// //                 ),
// //                 Positioned(
// //                   right: 0,
// //                   top: 0,
// //                   child: Container(
// //                     padding: EdgeInsets.all(2),
// //                     decoration: BoxDecoration(
// //                       color: Colors.red,
// //                       shape: BoxShape.circle,
// //                     ),
// //                     child: Text(
// //                       '2',
// //                       style: TextStyle(color: Colors.white, fontSize: 10),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //         backgroundColor: Colors.grey[50],
// //         elevation: 1,
// //       ),
// //       body: isLoading
// //           ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
// //           : SingleChildScrollView(
// //               child: Container(
// //                 color: Colors.white,
// //                 padding: const EdgeInsets.symmetric(horizontal: 16),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     // Search Bar
// //                     SizedBox(height: 16),
// //                     TextField(
// //                       style: TextStyle(color: Colors.black),
// //                       decoration: InputDecoration(
// //                         hintText: 'Search stocks...',
// //                         hintStyle: TextStyle(color: Colors.grey[600]),
// //                         prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
// //                         filled: true,
// //                         fillColor: Colors.grey[50],
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: BorderSide(color: Colors.grey[300]!),
// //                         ),
// //                         enabledBorder: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: BorderSide(color: Colors.grey[300]!),
// //                         ),
// //                         focusedBorder: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(12),
// //                           borderSide: BorderSide(color: Colors.deepPurple),
// //                         ),
// //                       ),
// //                       onChanged: searchStocks,
// //                     ),
// //                     SizedBox(height: 16),

// //                     // Filtered Stock List
// //                     if (searchQuery.isNotEmpty) 
// //                       SizedBox(
// //                         height: 300,
// //                         child: filteredStocks.isNotEmpty
// //                             ? ListView.builder(
// //                                 itemCount: filteredStocks.length,
// //                                 itemBuilder: (context, index) {
// //                                   final stock = filteredStocks[index];
// //                                   return GestureDetector(
// //                                     onTap: () {
// //                                       Navigator.push(
// //                                         context,
// //                                         MaterialPageRoute(
// //                                          builder: (context) => StockDetailsPage(stockName: stock["name"]!),
// //                                         ),
// //                                       );
// //                                     },
// //                                     child: Card(
// //                                       color: Colors.grey[50],
// //                                       elevation: 1,
// //                                       shape: RoundedRectangleBorder(
// //                                         borderRadius: BorderRadius.circular(10),
// //                                         side: BorderSide(color: Colors.grey[200]!),
// //                                       ),
// //                                       child: ListTile(
// //                                         leading: CircleAvatar(
// //                                           backgroundImage: NetworkImage(stock["logo"]!),
// //                                         ),
// //                                         title: Text(
// //                                           stock["name"]!,
// //                                           style: TextStyle(color: Colors.black),
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   );
// //                                 },
// //                               )
// //                             : Center(
// //                                 child: Text(
// //                                   "No results found",
// //                                   style: TextStyle(color: Colors.grey[600], fontSize: 16),
// //                                 ),
// //                               ),
// //                       ),

// //                     // Navigation Buttons
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                       children: [
// //                         GestureDetector(
// //                           onTap: () {
// //                             Navigator.push(
// //                               context,
// //                               MaterialPageRoute(
// //                                 builder: (context) => PortfolioPage(),
// //                               ),
// //                             );
// //                           },
// //                           child: _buildNavigationItem(
// //                             Icons.pie_chart,
// //                             'Events',
// //                           ),
// //                         ),
// //                         _buildNavigationItem(
// //                             Icons.currency_exchange, 'All stocks'),
// //                         _buildNavigationItem(Icons.show_chart, 'Indices'),
// //                         _buildNavigationItem(Icons.new_label, 'IPO',
// //                             iconColor: Colors.red),
// //                         _buildNavigationItem(Icons.equalizer, 'Equities'),
// //                       ],
// //                     ),
// //                     SizedBox(height: 24),

// //                     // Welcome Text
// //                     Container(
// //                       width: double.infinity,
// //                       padding: EdgeInsets.all(16),
// //                       decoration: BoxDecoration(
// //                         color: Colors.deepPurple[50],
// //                         borderRadius: BorderRadius.circular(8),
// //                         border: Border.all(color: Colors.deepPurple[100]!),
// //                       ),
// //                       child: Text(
// //                         'Explore stock market trends and insights here!',
// //                         style: TextStyle(color: Colors.deepPurple[800], fontSize: 14),
// //                       ),
// //                     ),
// //                     SizedBox(height: 24),

// //                     // // Profile Balance Section
// //                     // _buildProfileBalance(),
// //                     // SizedBox(height: 24),
                    
// //                     // Performance Section
// //                     _buildPerformanceSection(),
// //                     // SizedBox(height: 24),

// //                     // // Action buttons
// //                     // Row(
// //                     //   mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                     //   children: [
// //                     //     _buildActionButton(Icons.add_circle_outline, 'Deposit', TopUpScreen()),
// //                     //     _buildActionButton(Icons.swap_horiz_outlined, 'Transfer', TopUpScreen()),
// //                     //   ],
// //                     // ),
                    
// //                     SizedBox(height: 24),
                    
// //                     // Transaction History Section
// //                  //   _buildTransactionHistory(),
                    
// //                     SizedBox(height: 24),
                    
// //                     // Wishlist Section Header
// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Text(
// //                           'Your Wishlist',
// //                           style: TextStyle(
// //                             fontSize: 18,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.black,
// //                           ),
// //                         ),
// //                         Container(
// //                           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
// //                           decoration: BoxDecoration(
// //                             border: Border.all(color: Colors.grey[300]!),
// //                             borderRadius: BorderRadius.circular(8),
// //                             color: Colors.grey[50],
// //                           ),
// //                           child: DropdownButtonHideUnderline(
// //                             child: DropdownButton<String>(
// //                               value: selectedWishlist,
// //                               icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
// //                               style: TextStyle(color: Colors.black, fontSize: 14),
// //                               items: wishlistOptions.map<DropdownMenuItem<String>>((String value) {
// //                                 return DropdownMenuItem<String>(
// //                                   value: value,
// //                                   child: Text(value),
// //                                 );
// //                               }).toList(),
// //                               onChanged: (String? newValue) {
// //                                 setState(() {
// //                                   selectedWishlist = newValue!;
// //                                   _updateHoldingsForWishlist(newValue);
// //                                 });
// //                               },
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     SizedBox(height: 16),
                    
// //                     // Holdings Section (now displays wishlist stocks)
// //                     _buildHoldingsSection(),
                    
// //                     SizedBox(height: 24),
                    
// //                     // Watchlist Section
// //            //         _buildWatchlistSection(),
                    
// //                     SizedBox(height: 20),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //     );
// //   }

// //   Widget _buildNavigationItem(IconData icon, String label, {Color iconColor = Colors.black}) {
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         Container(
// //           padding: EdgeInsets.all(8),
// //           decoration: BoxDecoration(
// //             color: Colors.grey[100],
// //             borderRadius: BorderRadius.circular(12),
// //             border: Border.all(color: Colors.grey[300]!),
// //           ),
// //           child: Icon(icon, color: iconColor, size: 28),
// //         ),
// //         SizedBox(height: 4),
// //         Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
// //       ],
// //     );
// //   }

// //   Widget _buildActionButton(IconData icon, String label, Widget destination) {
// //     return GestureDetector(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(builder: (context) => destination),
// //         );
// //       },
// //       child: Column(
// //         children: [
// //           Container(
// //             padding: EdgeInsets.all(12),
// //             decoration: BoxDecoration(
// //               color: Colors.deepPurple[50],
// //               borderRadius: BorderRadius.circular(12),
// //               border: Border.all(color: Colors.deepPurple[100]!),
// //             ),
// //             child: Icon(icon, color: Colors.deepPurple, size: 24),
// //           ),
// //           SizedBox(height: 8),
// //           Text(
// //             label,
// //             style: TextStyle(color: Colors.black, fontSize: 12),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildProfileBalance() {
// //     return Container(
// //       padding: EdgeInsets.all(16),
// //       margin: EdgeInsets.only(bottom: 16),
// //       decoration: BoxDecoration(
// //         color: Colors.deepPurple[50],
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.deepPurple[100]!),
// //       ),
// //       child: Row(
// //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //         children: [
// //           Text(
// //             "Profile Balance",
// //             style: TextStyle(
// //               color: Colors.black,
// //               fontSize: 16,
// //               fontWeight: FontWeight.w600,
// //             ),
// //           ),
// //           Text(
// //             "\$${profileBalance.toStringAsFixed(2)}",
// //             style: TextStyle(
// //               color: Colors.deepPurple,
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildTransactionHistory() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(
// //           'Transaction History',
// //           style: TextStyle(
// //             color: Colors.black,
// //             fontSize: 18,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //         SizedBox(height: 16),
// //         ...transactions.map((transaction) => _buildTransactionItem(transaction)),
// //       ],
// //     );
// //   }

// //   Widget _buildTransactionItem(Transaction transaction) {
// //     bool isPositive = transaction.type == TransactionType.sell;
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12),
// //       padding: EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.grey[50],
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey[200]!),
// //       ),
// //       child: Row(
// //         children: [
// //           Container(
// //             padding: EdgeInsets.all(8),
// //             decoration: BoxDecoration(
// //               color: isPositive
// //                   ? Colors.green.withOpacity(0.1)
// //                   : Colors.red.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Icon(
// //               transaction.type == TransactionType.buy
// //                   ? Icons.arrow_downward
// //                   : Icons.arrow_upward,
// //               color: isPositive ? Colors.green : Colors.red,
// //               size: 20,
// //             ),
// //           ),
// //           SizedBox(width: 16),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(
// //                   '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
// //                   style: TextStyle(
// //                     color: Colors.black,
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 Text(
// //                   '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
// //                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           Column(
// //             crossAxisAlignment: CrossAxisAlignment.end,
// //             children: [
// //               Text(
// //                 '${transaction.currency}${(transaction.amount * transaction.shares).toStringAsFixed(2)}',
// //                 style: TextStyle(
// //                   color: isPositive ? Colors.green : Colors.red,
// //                   fontSize: 16,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //               Text(
// //                 transaction.date.toString().substring(0, 10),
// //                 style: TextStyle(color: Colors.grey[500], fontSize: 12),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildHoldingsSection() {
// //     // Get stocks based on selected wishlist
// //     List<Map<String, String>> currentWishlistStocks = getStocksForWishlist(selectedWishlist);
    
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         SizedBox(height: 16),
        
// //         // Display stocks from selected wishlist
// //         if (currentWishlistStocks.isEmpty)
// //           Container(
// //             padding: EdgeInsets.all(20),
// //             decoration: BoxDecoration(
// //               color: Colors.grey[50],
// //               borderRadius: BorderRadius.circular(8),
// //               border: Border.all(color: Colors.grey[200]!),
// //             ),
// //             child: Center(
// //               child: Column(
// //                 children: [
// //                   Icon(
// //                     Icons.bookmark_outline,
// //                     size: 40,
// //                     color: Colors.grey[400],
// //                   ),
// //                   SizedBox(height: 8),
// //                   Text(
// //                     'No stocks in this wishlist',
// //                     style: TextStyle(
// //                       color: Colors.grey[600],
// //                       fontSize: 16,
// //                     ),
// //                   ),
// //                   SizedBox(height: 4),
// //                   Text(
// //                     'Add stocks to see them here',
// //                     style: TextStyle(
// //                       color: Colors.grey[500],
// //                       fontSize: 14,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           )
// //         else
// //           ...currentWishlistStocks.take(5).map((stock) => _buildWishlistStockItem(stock)),
        
// //         // Show "See All" hint if there are more than 5 stocks
// //         if (currentWishlistStocks.length > 5)
// //           Padding(
// //             padding: EdgeInsets.only(top: 8),
// //             child: Center(
// //               child: Text(
// //                 '+${currentWishlistStocks.length - 5} more stocks',
// //                 style: TextStyle(
// //                   color: Colors.grey[600],
// //                   fontSize: 12,
// //                 ),
// //               ),
// //             ),
// //           ),
// //       ],
// //     );
// //   }

// //   // Method to build individual wishlist stock item
// //   Widget _buildWishlistStockItem(Map<String, String> stock) {
// //     bool isPositive = stock['change']!.startsWith('+');
    
// //     return Container(
// //       margin: EdgeInsets.only(bottom: 12),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.grey[200]!),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             spreadRadius: 1,
// //             blurRadius: 3,
// //             offset: Offset(0, 1),
// //           ),
// //         ],
// //       ),
// //       child: ListTile(
// //         contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //         leading: CircleAvatar(
// //           radius: 20,
// //           backgroundImage: NetworkImage(stock['logo']!),
// //           backgroundColor: Colors.grey[200],
// //         ),
// //         title: Text(
// //           stock['name']!,
// //           style: TextStyle(
// //             fontWeight: FontWeight.w600,
// //             fontSize: 16,
// //             color: Colors.black,
// //           ),
// //         ),
// //         subtitle: Text(
// //           stock['symbol']!,
// //           style: TextStyle(
// //             color: Colors.grey[600],
// //             fontSize: 14,
// //           ),
// //         ),
// //         trailing: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           crossAxisAlignment: CrossAxisAlignment.end,
// //           children: [
// //             Text(
// //               stock['price']!,
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 fontSize: 16,
// //                 color: Colors.black,
// //               ),
// //             ),
// //             Container(
// //               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //               decoration: BoxDecoration(
// //                 color: isPositive ? Colors.green[50] : Colors.red[50],
// //                 borderRadius: BorderRadius.circular(12),
// //               ),
// //               child: Text(
// //                 stock['change']!,
// //                 style: TextStyle(
// //                   color: isPositive ? Colors.green[700] : Colors.red[700],
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //         onTap: () {
// //           Navigator.push(
// //             context,
// //             MaterialPageRoute(
// //               builder: (context) => StockDetailsPage(stockName: stock['name']!),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }

// //   Widget _buildWatchlistSection() {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Row(
// //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //           children: [
// //             Text(
// //               'Watchlist',
// //               style: TextStyle(
// //                 color: Colors.black,
// //                 fontSize: 18,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //             TextButton(
// //               onPressed: () {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(builder: (context) => TradingDashboard()),
// //                 );
// //               },
// //               child: Text(
// //                 'Add More',
// //                 style: TextStyle(color: Colors.deepPurple),
// //               ),
// //             ),
// //           ],
// //         ),
// //         SizedBox(height: 16),
// //         ...watchlist.map((holding) => _buildHoldingItem(holding)),
// //       ],
// //     );
// //   }

// //   Widget _buildHoldingItem(Holding holding) {
// //     bool isPositive = holding.change >= 0;
// //     return GestureDetector(
// //       onTap: () {
// //         Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (context) => StockDetailsPage(stockName: holding.name),
// //           ),
// //         );
// //       },
// //       child: Container(
// //         margin: const EdgeInsets.only(bottom: 16),
// //         padding: const EdgeInsets.all(16),
// //         decoration: BoxDecoration(
// //           color: Colors.grey[50],
// //           borderRadius: BorderRadius.circular(12),
// //           border: Border.all(color: Colors.grey[200]!),
// //         ),
// //         child: Row(
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(8),
// //               decoration: BoxDecoration(
// //                 color: _getTypeColor(holding.type).withOpacity(0.1),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Icon(
// //                 holding.icon,
// //                 color: _getTypeColor(holding.type),
// //                 size: 24,
// //               ),
// //             ),
// //             const SizedBox(width: 16),
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     holding.symbol,
// //                     style: const TextStyle(
// //                       color: Colors.black,
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   Text(
// //                     holding.name,
// //                     style: TextStyle(color: Colors.grey[600], fontSize: 14),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.end,
// //               children: [
// //                 Text(
// //                   '\${holding.value.toStringAsFixed(2)}',
// //                   style: const TextStyle(
// //                     color: Colors.black,
// //                     fontSize: 16,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //                 Row(
// //                   children: [
// //                     Icon(
// //                       isPositive ? Icons.arrow_upward : Icons.arrow_downward,
// //                       color: isPositive ? Colors.green : Colors.red,
// //                       size: 16,
// //                     ),
// //                     const SizedBox(width: 4),
// //                     Text(
// //                       '${isPositive ? '+' : ''}${holding.change.toStringAsFixed(2)} (${holding.changePercentage.toStringAsFixed(2)}%)',
// //                       style: TextStyle(
// //                         color: isPositive ? Colors.green : Colors.red,
// //                         fontSize: 14,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Color _getTypeColor(HoldingType type) {
// //     switch (type) {
// //       case HoldingType.stock:
// //         return Colors.deepPurple;
// //       case HoldingType.forex:
// //         return Colors.deepPurple[700]!;
// //       case HoldingType.crypto:
// //         return Colors.deepPurple[600]!;
// //       default:
// //         return Colors.deepPurple;
// //     }
// //   }
// // }

// // // Placeholder widget for CombinedPortfolioPerformance
// // class CombinedPortfolioPerformance extends StatelessWidget {
// //   final bool showBalance;
  
// //   const CombinedPortfolioPerformance({Key? key, required this.showBalance}) : super(key: key);
  
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: EdgeInsets.all(16),
// //       decoration: BoxDecoration(
// //         color: Colors.deepPurple[50],
// //         borderRadius: BorderRadius.circular(12),
// //         border: Border.all(color: Colors.deepPurple[100]!),
// //       ),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             'Portfolio Performance',
// //             style: TextStyle(
// //               fontSize: 18,
// //               fontWeight: FontWeight.bold,
// //               color: Colors.black,
// //             ),
// //           ),
// //           SizedBox(height: 12),
// //           Row(
// //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //             children: [
// //               Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     'Total Value',
// //                     style: TextStyle(color: Colors.grey[600], fontSize: 14),
// //                   ),
// //                   Text(
// //                     '\$25,847.32',
// //                     style: TextStyle(
// //                       color: Colors.black,
// //                       fontSize: 20,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //               Column(
// //                 crossAxisAlignment: CrossAxisAlignment.end,
// //                 children: [
// //                   Text(
// //                     'Today\'s Change',
// //                     style: TextStyle(color: Colors.grey[600], fontSize: 14),
// //                   ),
// //                   Text(
// //                     '+\$342.15 (+1.34%)',
// //                     style: TextStyle(
// //                       color: Colors.green,
// //                       fontSize: 16,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // void main() {
// //   runApp(MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Stock Market App',
// //       theme: ThemeData(
// //         primarySwatch: Colors.deepPurple,
// //         scaffoldBackgroundColor: Colors.white,
// //         appBarTheme: AppBarTheme(
// //           backgroundColor: Colors.grey[50],
// //           foregroundColor: Colors.black,
// //         ),
// //       ),
// //       home: DashboardScreen(),
// //       debugShowCheckedModeBanner: false,
// //     );
// //   }
// // // }


























// //version6
// //
// //
// //
//
// 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test_project/features/profile/profile.dart';
import 'package:test_project/features/trading/topup.dart';
import 'package:test_project/features/trending/treanding.dart';
import 'package:test_project/features/stock/stock_details.dart';
import 'package:test_project/features/notifications/notification.dart';
import 'package:test_project/features/wishlist/wishlist.dart' hide StockDetailsPage;
import 'package:test_project/features/portfolio/portfolio.dart';
import 'package:test_project/features/news/newsmail.dart';
import 'package:test_project/features/news/news.dart';
import 'package:test_project/features/security/app_lock_wrapper.dart';
import 'package:test_project/features/security/security_screen.dart';
import 'package:test_project/features/portfolio/learning_section.dart';



class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<double> _iconOpacityAnimation;

  final List<Widget> _screens = [
    DashboardContent(),
    TrendingScreen(),
    // TopUpScreen(),
   // TradingDashboard(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _sizeAnimation = Tween<double>(begin: 50, end: 70).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _iconOpacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  // search
List<Map<String, String>> allStocks = [
    {"name": "ibm", "logo": "https://logo.clearbit.com/ibm.com"},
    {"name": "BUKA", "logo": "https://logo.clearbit.com/amazon.com"},
    {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
    {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
    {"name": "GOOGL", "logo": "https://logo.clearbit.com/google.com"},
    {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
    {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
  ];

  List<Map<String, String>> filteredStocks = [];
  String searchQuery = "";
  bool isLoading = false;
void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
        _shrinkNavBar(); 
    });
  }

 void searchStocks(String query) {
  setState(() {
    searchQuery = query;
    filteredStocks = allStocks
        .where((stock) =>
            stock["name"]!.toLowerCase().startsWith(query.toLowerCase())) // Only matches stocks that start with the query
        .toList();
  });
}

  // search end 


  void _toggleNavBar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

 
  void _shrinkNavBar() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: Stack(
      children: [
        _screens[_selectedIndex], // Main content stays in sync with navbar
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: _toggleNavBar,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: _isExpanded ? MediaQuery.of(context).size.width - 60 : 80,
                  height: _sizeAnimation.value,
                  margin: EdgeInsets.only(bottom: 15), // Slightly above bottom
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.95),
                    shape: _isExpanded ? BoxShape.rectangle : BoxShape.circle, // Ball when shrunk
                    borderRadius: _isExpanded ? BorderRadius.circular(60) : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                        blurRadius: 12.0,
                        spreadRadius: 4,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: _isExpanded
                      ? ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          child: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            backgroundColor: Colors.transparent,
                            selectedItemColor: Colors.white,
                            unselectedItemColor: Colors.white.withOpacity(0.7),
                            currentIndex: _selectedIndex,
                            onTap: _onItemTapped,
                            elevation: 0,
                            showSelectedLabels: false,   // hide labels
                            showUnselectedLabels: false, // hide labels
                            items: [
                              BottomNavigationBarItem(
                                icon: Opacity(
                                  opacity: _iconOpacityAnimation.value,
                                  child: Icon(Icons.home_filled, size: 20),
                                ),
                                label: '',
                              ),
                              BottomNavigationBarItem(
                                icon: Opacity(
                                  opacity: _iconOpacityAnimation.value,
                                  child: Icon(Icons.search_sharp, size: 20),
                                ),
                                label: '',
                              ),
                              BottomNavigationBarItem(
                                icon: Opacity(
                                  opacity: _iconOpacityAnimation.value,
                                  child: Icon(Icons.person_rounded, size: 20),
                                ),
                                label: '',
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Icon(Icons.menu, size: 22, color: Colors.white), // Small floating ball
                        ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
}
Widget _buildPerformanceSection() {
  return CombinedPortfolioPerformance(showBalance: true);
}//
//portfolio page

// Enum definitions needed for the transactions and holdings
enum TransactionType { buy, sell }
enum HoldingType { stock, crypto, forex }

class Transaction {
  final String symbol;
  final double amount;
  final int shares;
  final TransactionType type;
  final DateTime date;
  final String currency;

  Transaction({
    required this.symbol,
    required this.amount,
    required this.shares,
    required this.type,
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
  final HoldingType type;
  final IconData icon;

  Holding({
    required this.symbol,
    required this.name,
    required this.value,
    required this.change,
    required this.changePercentage,
    required this.type,
    required this.icon,
  });
}

// Add the WishlistHoldingsWidget here (copied from wishlist.dart)
class WishlistHoldingsWidget extends StatefulWidget {
  @override
  _WishlistHoldingsWidgetState createState() => _WishlistHoldingsWidgetState();
}

class _WishlistHoldingsWidgetState extends State<WishlistHoldingsWidget> {
  // Wishlist variables
  String selectedWishlist = 'My Watchlist';
  List<String> wishlistOptions = [
    'My Watchlist',
    'Tech Stocks',
    'Blue Chips',
    'Growth Stocks',
    'Dividend Stocks'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wishlist Section Header
        // Text(
        //   'Watchlist',
        //   style: TextStyle(
        //     fontSize: 18,
        //     fontWeight: FontWeight.bold,
        //     color: Colors.black,
        //   ),
        // ),
        // SizedBox(height: 16),
  //     / //Add New Button (below dropdown)
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TradingDashboard()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
           //   color: Colors.deepPurple[50],
           //   borderRadius: BorderRadius.circular(8),
          //    border: Border.all(color: Colors.deepPurple[100]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: Colors.deepPurple),
                SizedBox(width: 4),
                Text(
                  'Create New List',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 114, 70, 192),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),


        SizedBox(height: 12),
        
        




         
//         // Dropdown (moved to left, below title)
//       Container(
//   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//   child: DropdownButtonHideUnderline(
//     child: DropdownButton<String>(
//       value: selectedWishlist,
//       icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
//       style: TextStyle(color: Colors.black, fontSize: 14),
      
//       // Add these properties to ensure proper menu positioning
//       isExpanded: true,
//       elevation: 2,
//       menuMaxHeight: 200, // Optional: limit menu height
      
//       items: wishlistOptions.map<DropdownMenuItem<String>>((String value) {
//         return DropdownMenuItem<String>(
//           value: value,
//           child: Text(value),
//         );
//       }).toList(),
//       onChanged: (String? newValue) {
//         setState(() {
//           selectedWishlist = newValue!;
//           _updateHoldingsForWishlist(newValue);
//         });
//       },
//     ),
//   ),
// ),
//         SizedBox(height: 16),
        
        // Holdings Section
        _buildHoldingsSection(),
      ],
    );
  }

  // Method to get stocks for specific wishlist
  List<Map<String, String>> getStocksForWishlist(String wishlistName) {
    Map<String, List<Map<String, String>>> wishlistData = {
      'My Watchlist': [
        {
          'name': 'Apple Inc.',
          'symbol': 'AAPL',
          'price': '\$150.25',
          'change': '+2.5%',
          'logo': 'https://logo.clearbit.com/apple.com'
        },
        {
          'name': 'Google',
          'symbol': 'GOOGL',
          'price': '\$2750.80',
          'change': '+1.2%',
          'logo': 'https://logo.clearbit.com/google.com'
        },
        {
          'name': 'Microsoft',
          'symbol': 'MSFT',
          'price': '\$305.15',
          'change': '-0.8%',
          'logo': 'https://logo.clearbit.com/microsoft.com'
        },
      ],
      'Tech Stocks': [
        {
          'name': 'Apple Inc.',
          'symbol': 'AAPL',
          'price': '\$150.25',
          'change': '+2.5%',
          'logo': 'https://logo.clearbit.com/apple.com'
        },
        {
          'name': 'Tesla',
          'symbol': 'TSLA',
          'price': '\$890.50',
          'change': '+3.2%',
          'logo': 'https://logo.clearbit.com/tesla.com'
        },
        {
          'name': 'Netflix',
          'symbol': 'NFLX',
          'price': '\$385.90',
          'change': '+1.8%',
          'logo': 'https://logo.clearbit.com/netflix.com'
        },
        {
          'name': 'Meta',
          'symbol': 'META',
          'price': '\$325.45',
          'change': '-1.1%',
          'logo': 'https://logo.clearbit.com/meta.com'
        },
        {
          'name': 'NVIDIA',
          'symbol': 'NVDA',
          'price': '\$875.60',
          'change': '+4.5%',
          'logo': 'https://logo.clearbit.com/nvidia.com'
        },
        {
          'name': 'AMD',
          'symbol': 'AMD',
          'price': '\$165.30',
          'change': '+2.8%',
          'logo': 'https://logo.clearbit.com/amd.com'
        },
      ],
      'Blue Chips': [
        {
          'name': 'Johnson & Johnson',
          'symbol': 'JNJ',
          'price': '\$165.75',
          'change': '+0.5%',
          'logo': 'https://logo.clearbit.com/jnj.com'
        },
        {
          'name': 'Coca Cola',
          'symbol': 'KO',
          'price': '\$58.20',
          'change': '+0.8%',
          'logo': 'https://logo.clearbit.com/coca-cola.com'
        },
        {
          'name': 'Procter & Gamble',
          'symbol': 'PG',
          'price': '\$145.30',
          'change': '+0.3%',
          'logo': 'https://logo.clearbit.com/pg.com'
        },
        {
          'name': 'Walmart',
          'symbol': 'WMT',
          'price': '\$158.45',
          'change': '+0.7%',
          'logo': 'https://logo.clearbit.com/walmart.com'
        },
      ],
      'Growth Stocks': [
        {
          'name': 'Amazon',
          'symbol': 'AMZN',
          'price': '\$3200.15',
          'change': '+2.8%',
          'logo': 'https://logo.clearbit.com/amazon.com'
        },
        {
          'name': 'Zoom',
          'symbol': 'ZM',
          'price': '\$85.60',
          'change': '+4.2%',
          'logo': 'https://logo.clearbit.com/zoom.us'
        },
        {
          'name': 'Shopify',
          'symbol': 'SHOP',
          'price': '\$1250.90',
          'change': '+5.1%',
          'logo': 'https://logo.clearbit.com/shopify.com'
        },
        {
          'name': 'Square',
          'symbol': 'SQ',
          'price': '\$245.80',
          'change': '+3.7%',
          'logo': 'https://logo.clearbit.com/squareup.com'
        },
        {
          'name': 'PayPal',
          'symbol': 'PYPL',
          'price': '\$185.25',
          'change': '+2.1%',
          'logo': 'https://logo.clearbit.com/paypal.com'
        },
        {
          'name': 'Salesforce',
          'symbol': 'CRM',
          'price': '\$295.40',
          'change': '+1.9%',
          'logo': 'https://logo.clearbit.com/salesforce.com'
        },
      ],
      'Dividend Stocks': [
        {
          'name': 'AT&T',
          'symbol': 'T',
          'price': '\$25.45',
          'change': '-0.2%',
          'logo': 'https://logo.clearbit.com/att.com'
        },
        {
          'name': 'Verizon',
          'symbol': 'VZ',
          'price': '\$52.80',
          'change': '+0.1%',
          'logo': 'https://logo.clearbit.com/verizon.com'
        },
        {
          'name': 'ExxonMobil',
          'symbol': 'XOM',
          'price': '\$95.25',
          'change': '+1.5%',
          'logo': 'https://logo.clearbit.com/exxonmobil.com'
        },
        {
          'name': 'IBM',
          'symbol': 'IBM',
          'price': '\$142.60',
          'change': '+0.8%',
          'logo': 'https://logo.clearbit.com/ibm.com'
        },
        {
          'name': 'General Electric',
          'symbol': 'GE',
          'price': '\$108.75',
          'change': '+0.4%',
          'logo': 'https://logo.clearbit.com/ge.com'
        },
      ],
    };
    
    return wishlistData[wishlistName] ?? [];
  }




  // Method to update holdings based on selected wishlist
  void _updateHoldingsForWishlist(String wishlist) {
    setState(() {
      // The UI will automatically update since we're using selectedWishlist
      // in the _buildHoldingsSection method
    });
  }
// Holdings Section
Widget _buildHoldingsSection() {
  // Get stocks based on selected wishlist
  List<Map<String, String>> currentWishlistStocks = getStocksForWishlist(selectedWishlist);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Row with Dropdown & See All
      if (currentWishlistStocks.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dropdown Button on the left
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
              //    color: Colors.grey[50],
                //  borderRadius: BorderRadius.circular(8),
               //   border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedWishlist,
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 20),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    isExpanded: false,
                    elevation: 2,
                    items: wishlistOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedWishlist = newValue!;
                        _updateHoldingsForWishlist(newValue);
                      });
                    },
                  ),
                ),
              ),

              // See All button on the right
              TextButton(
                onPressed: () {
                  _showAllStocks(currentWishlistStocks);
                },
                child: Text(
                  "See All (${currentWishlistStocks.length})",
                  style: TextStyle(
                    color: Color.fromARGB(255, 114, 70, 192),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

      // If empty wishlist
      if (currentWishlistStocks.isEmpty)
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bookmark_outline,
                  size: 40,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8),
                Text(
                  'No stocks in this wishlist',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add stocks to see them here',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        )
      else
        ...currentWishlistStocks.take(5).map((stock) => _buildWishlistStockItem(stock)),

      // Show "+N more" hint if > 5
      if (currentWishlistStocks.length > 5)
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Center(
            child: Text(
              '+${currentWishlistStocks.length - 5} more stocks',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ),
    ],
  );
}

// Method to build individual wishlist stock item
Widget _buildWishlistStockItem(Map<String, String> stock) {
  bool isPositive = stock['change']!.startsWith('+');
  
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(stock['logo']!),
        backgroundColor: Colors.grey[200],
      ),
      title: Text(
        stock['name']!,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        stock['symbol']!,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            stock['price']!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              stock['change']!,
              style: TextStyle(
                color: isPositive ? Colors.green[700] : Colors.red[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailsPage(stockName: stock['name']!),
          ),
        );
      },
    ),
  );
}
  // Method to show all stocks in a modal bottom sheet
  void _showAllStocks(List<Map<String, String>> stocks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 50,
                height: 5,
                margin: EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedWishlist,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${stocks.length} stocks',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stock list
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: stocks.length,
                  itemBuilder: (context, index) {
                    return _buildWishlistStockItem(stocks[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardContent extends StatefulWidget {
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
   // News-related variables
  String apiKey = "XH0MOF8FACW6RR0L";
  List<dynamic> newsData = [];
  bool newsLoading = true;

  @override
  void initState() {
    super.initState();
    filteredStocks = allStocks;
    fetchNews(); // Add news fetching
  }

  // News fetching function (copied from TrendingScreen)
  Future<void> fetchNews() async {
    final url = Uri.parse(
        "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        newsData = data["feed"] ?? [];
        newsLoading = false;
      });
    } else {
      print("Failed to load news");
      setState(() {
        newsLoading = false;
      });
    }
  }

  // News display widget (adapted from TrendingScreen)
  Widget _buildVerticalNewsList(BuildContext context) {
    return Container(
      child: newsLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 114, 70, 192),
              ),
            )
          : newsData.isEmpty
              ? Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Center(
                    child: Text(
                      'No news available at the moment',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: newsData.length > 3 ? 3 : newsData.length, // Show only 3 items on dashboard
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
                        margin: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      newsItem["title"] ?? "No Title",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      newsItem["subtitle"] ?? newsItem["source"] ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color.fromARGB(255, 114, 70, 192).withOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Color.fromARGB(255, 114, 70, 192),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // News section header (adapted from TrendingScreen)
  Widget _buildSectionHeaderNews(String title) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsMailScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward, color: Color.fromARGB(255, 114, 70, 192)),
          ],
        ),
      ),
    );
  }



  List<Map<String, String>> allStocks = [
    {"name": "Apple", "logo": "https://logo.clearbit.com/apple.com"},
    {"name": "Amazon", "logo": "https://logo.clearbit.com/amazon.com"},
    {"name": "Microsoft", "logo": "https://logo.clearbit.com/microsoft.com"},
    {"name": "Tesla", "logo": "https://logo.clearbit.com/tesla.com"},
    {"name": "Google", "logo": "https://logo.clearbit.com/google.com"},
    {"name": "Netflix", "logo": "https://logo.clearbit.com/netflix.com"},
    {"name": "Meta", "logo": "https://logo.clearbit.com/meta.com"},
  ];


  // Add the missing data structures
  List<Transaction> transactions = [
    Transaction(
      symbol: 'AAPL',
      amount: 150.75,
      shares: 10,
      type: TransactionType.buy,
      date: DateTime.now().subtract(Duration(days: 5)),
      currency: '\$',
    ),
    Transaction(
      symbol: 'MSFT',
      amount: 240.50,
      shares: 5,
      type: TransactionType.sell,
      date: DateTime.now().subtract(Duration(days: 2)),
      currency: '\$',
    ),
    Transaction(
      symbol: 'GOOGL',
      amount: 2750.25,
      shares: 2,
      type: TransactionType.buy,
      date: DateTime.now().subtract(Duration(days: 1)),
      currency: '\$',
    ),
  ];

  List<Holding> holdings = [
    Holding(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      value: 1507.50,
      change: 23.75,
      changePercentage: 1.58,
      type: HoldingType.stock,
      icon: Icons.phone_iphone,
    ),
    Holding(
      symbol: 'BTC',
      name: 'Bitcoin',
      value: 3625.00,
      change: -125.30,
      changePercentage: -3.34,
      type: HoldingType.crypto,
      icon: Icons.currency_bitcoin,
    ),
    Holding(
      symbol: 'EUR/USD',
      name: 'Euro/USD',
      value: 1250.75,
      change: 12.25,
      changePercentage: 0.98,
      type: HoldingType.forex,
      icon: Icons.currency_exchange,
    ),
  ];

  List<Holding> watchlist = [
    Holding(
      symbol: 'NVDA',
      name: 'NVIDIA Corporation',
      value: 275.50,
      change: 5.25,
      changePercentage: 1.94,
      type: HoldingType.stock,
      icon: Icons.memory,
    ),
    Holding(
      symbol: 'ETH',
      name: 'Ethereum',
      value: 1875.25,
      change: 45.75,
      changePercentage: 2.50,
      type: HoldingType.crypto,
      icon: Icons.auto_graph,
    ),
  ];

  List<Map<String, String>> filteredStocks = [];
  String searchQuery = "";
  bool isLoading = false;
String selectedTimeframe = '24 hour';
  String selectedCategory = 'Global';
  int _selectedIndex = 0; // For tracking the selected tab

  
 
  // @override
  // void initState() {
  //   super.initState();
  //   filteredStocks = allStocks;
  // }

void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getTodayLabel() {
    final now = DateTime.now();
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const months  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  void searchStocks(String query) {
    setState(() {
      searchQuery = query;
      filteredStocks = allStocks
          .where((stock) =>
              stock["name"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              alignment: Alignment.center,
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: const Text('AC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: const Text(
                  'Rohan Wadadar',
                  style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications, // Bell icon
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
                      '3', // You can dynamically change this value
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 1,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 114, 70, 192)))
          : SingleChildScrollView(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    // Search Bar
//                     SizedBox(height: 16),

// TextField(
//                 style: TextStyle(color: Colors.black),
//                 decoration: InputDecoration(
//                   hintText: 'Search stocks...',
//                   hintStyle: TextStyle(color: Colors.grey[600]),
//                   prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//                   filled: true,
//                   fillColor: Colors.grey[50],
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.grey[300]!),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.grey[300]!),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: Colors.deepPurple),
//                   ),
//                 ),
//                 onChanged: searchStocks,
//               ),
//               SizedBox(height: 16),
              SizedBox(height: 16),
              
              // Filtered Stock List
          if (searchQuery.isNotEmpty) 
  SizedBox(
    height: 300,
    child: filteredStocks.isNotEmpty
        ? ListView.builder(
            itemCount: filteredStocks.length,
            itemBuilder: (context, index) {
              final stock = filteredStocks[index];

              return GestureDetector(
                onTap: () {
                  // Navigate to stock details page with API call
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                     builder: (context) => StockDetailsPage(stockName: stock["name"]!),

                    ),
                  );
                },
                child: Card(
                  color: Colors.grey[50],
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(stock["logo"]!),
                    ),
                    title: Text(
                      stock["name"]!,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              );
            },
          )
        : Center(
            child: Text(
              "No results found",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
  ),

                    // Welcome Text
                    // Container(
                    //   width: double.infinity,
                    //   padding: EdgeInsets.all(16),
                    //   decoration: BoxDecoration(
                    //     color: Colors.deepPurple[50],
                    //     borderRadius: BorderRadius.circular(8),
                    //     border: Border.all(color: Colors.deepPurple[100]!),
                    //   ),
                    //   // child: Text(
                    //   //   'Explore stock market trends and insights here!',
                    //   //   style: TextStyle(color: Colors.deepPurple[800], fontSize: 14),
                    //   // ),
                    // ),
                    SizedBox(height: 24),

                    _buildPerformanceSection(),
                    SizedBox(height: 24),
 
                    // Add WishlistHoldingsWidget here
                    WishlistHoldingsWidget(),
                    SizedBox(height: 28),

                    // ── Learning Hub Section ──
                    const LearningSection(),
                    SizedBox(height: 24),
                    
                    // Watchlist Section
                 //   _buildWatchlistSection(),
            // Latest News Section - NEW ADDITION
// r
// SizedBox(height: 20),
        
        
        
        
        
                  ],
                ),
              ),
            ),
    );
  }






  Widget _buildNavigationItem(IconData icon, String label,
      {Color iconColor = Colors.black}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              print('See Detail tapped for $title');
            },
            child: Text(
              'See Detail',
              style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 114, 70, 192)),
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildActionButton(IconData icon, String label, Widget destination) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    },
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.deepPurple[100]!),
          ),
          child: Icon(icon, color: Color.fromARGB(255, 114, 70, 192), size: 24),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
      ],
    ),
  );
}


  // Transaction History Section
  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        ...transactions.map((transaction) => _transitem(transaction)),
      ],
    );
  }

  Widget _transitem(Transaction transaction) {
    bool isPositive = transaction.type == TransactionType.sell;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type == TransactionType.buy
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: isPositive ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

double profileBalance = 12500.75; // Example balance, replace with actual data

Widget _buildProfileBalance() {
  return Container(
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.deepPurple[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.deepPurple[100]!),
    ),

    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Profile Balance",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          "\${profileBalance.toStringAsFixed(2)}", // Displaying balance
          style: TextStyle(
            color: Colors.deepPurple,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTransactionItem(Transaction transaction) {
  bool isPositive = transaction.type == TransactionType.sell;
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPositive
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            transaction.type == TransactionType.buy
                ? Icons.arrow_downward
                : Icons.arrow_upward,
            color: isPositive ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${transaction.type == TransactionType.buy ? 'Bought' : 'Sold'} ${transaction.symbol}',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${transaction.shares} shares @ ${transaction.currency}${transaction.amount}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

  // Holdings Section
  Widget _buildHoldingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'my Watchlist',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'See All',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...holdings.map((holding) => _buildHoldingItem(holding)),
      ],
    );
  }

  
  // Watchlist Section
  Widget _buildWatchlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Watchlist',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TradingDashboard()),
                );
              },
              child: Text(
                'Add More',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...watchlist.map((holding) => _buildHoldingItem(holding)),
      ],
    );
  }


  Widget _buildHoldingItem(Holding holding) {
    bool isPositive = holding.change >= 0;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailsPage(stockName: holding.name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(holding.type).withOpacity(0.1),
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\${holding.value.toStringAsFixed(2)}',
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
      ),
    );
  }

}
  /// **Stock Type Colors (Only Stocks & Forex)**
  Color _getTypeColor(HoldingType type) {
    switch (type) {
      case HoldingType.stock:
        return Colors.deepPurple;
      case HoldingType.forex:
        return Colors.deepPurple[700]!;
      case HoldingType.crypto:
        return Colors.deepPurple[600]!;
      default:
        return Colors.deepPurple;
    }
  }

  Widget _buildHorizontalCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gainer Info', style: TextStyle(color: Colors.green[800])),
              ],
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loser Info', style: TextStyle(color: Colors.red[800])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalStockList() {
    // List of dummy stocks
    final List<Map<String, String>> dummyStocks = [
      {'name': 'BUKA', 'price': 'Rp278.00'},
      {'name': 'BBN', 'price': 'Rp4,630.00'},
      {'name': 'SDO', 'price': 'Rp24.00'},
      {'name': 'AAPL', 'price': 'Rp150.00'},
      {'name': 'GOOGL', 'price': 'Rp2,800.00'},
    ];

    return Container(
      height: 120,
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
                  builder: (context) => StockDetailsPage(stockName: stock['name']!),
                ),
              );
            },
            child: Container(
              width: 200,
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock['name']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    stock['price']!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
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

  Widget _buildHorizontalNewsList() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text('News Info $index', style: TextStyle(color: Colors.black)),
          );
        },
      ),
    );
  }


// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Stock Market App',
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         scaffoldBackgroundColor: Colors.white,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.grey[50],
//           foregroundColor: Colors.black,
//         ),
//       ),
//       home: DashboardScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlphaCues',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const RootDecider(),
    );
  }
}

///
/// ROOT DECIDER
/// - No lock before login
/// - Lock after dashboard
///
class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider>
    with SingleTickerProviderStateMixin {
  bool? _loggedIn;
  late AnimationController _splashController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeIn,
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.elasticOut),
    );
    _splashController.forward();
    _checkLogin();
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  Future<void> _checkLogin() async {
    // Minimum 2.8 s so the user sees the animation
    await Future.delayed(const Duration(milliseconds: 2800));
    if (mounted) setState(() => _loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3B1F8F),
                Color(0xFF7061F3),
                Color(0xFF9B8AF6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _splashController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo circle
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'AC',
                            style: TextStyle(
                              color: Color(0xFF7061F3),
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'AlphaCues',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Smart Trading. Simplified.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // ❌ Not logged in → landing (if you add later)
    if (_loggedIn == false) {
      return const Scaffold(
        body: Center(child: Text('Landing / Login Page')),
      );
    }

    // ✅ Logged in → apply app lock
    return AppLockWrapper(
      child: DashboardScreen(), // YOUR EXISTING DASHBOARD
    );
  }
}
