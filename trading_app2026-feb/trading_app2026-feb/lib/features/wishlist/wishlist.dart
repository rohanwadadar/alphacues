// import 'package:flutter/material.dart';
// import 'package:test_project/features/notifications/notification.dart';

// class TradingDashboard extends StatefulWidget {
//   @override
//   _TradingDashboardState createState() => _TradingDashboardState();
// }

// class _TradingDashboardState extends State<TradingDashboard> {
//   bool isSearching = false;
//   bool hasShownInitialDialog = false; // Track if we've shown the dialog
//   TextEditingController searchController = TextEditingController();
//   TextEditingController wishlistController = TextEditingController();
//   String selectedWishlist = "My First List";


//   List<String> wishlists = [
//     "My First List",
//   ];
//   Map<String, int> watchlistItems = {
//     "My First List": 0,
//   };
//   Map<String, IconData> watchlistIcons = {
//     "My First List": Icons.flash_on,
//   };

//   Map<String, List<Map<String, dynamic>>> wishlistStocks = {};

//   final List<Map<String, dynamic>> allStocks = [
//     {"name": "GOOGL", "fullName": "Alphabet Inc", "price": 2174.75, "change": 1.21},
//     {"name": "BABA", "fullName": "Alibaba Group", "price": 79.25, "change": -2.13},
//     {"name": "AAPL", "fullName": "Apple Inc", "price": 138.93, "change": -1.32},
//     {"name": "MSFT", "fullName": "Microsoft Corporation", "price": 289.45, "change": 1.23},
//     {"name": "TSLA", "fullName": "Tesla Inc", "price": 681.79, "change": 4.89},
//     {"name": "AMZN", "fullName": "Amazon Inc", "price": 113.22, "change": 9.77},
//     {"name": "NFLX", "fullName": "Netflix Inc", "price": 242.98, "change": 2.34},
//     {"name": "META", "fullName": "Meta Platforms", "price": 169.15, "change": -0.45},
//     {"name": "NVDA", "fullName": "Nvidia Corporation", "price": 453.12, "change": 3.75},
//     {"name": "AMD", "fullName": "Advanced Micro Devices", "price": 125.65, "change": 1.92},
//   ];

//   List<Map<String, dynamic>> searchResults = [];

//   @override
//   void initState() {
//     super.initState();
//     for (String list in wishlists) {
//       wishlistStocks[list] = [];
//     }
    
//     // Show dialog after first frame is built
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!hasShownInitialDialog && wishlists.length == 1 && (watchlistItems["My First List"] ?? 0) == 0) {
//         hasShownInitialDialog = true;
//         showAddWatchlistDialog();
//       }
//     });
//   }

//   void performSearch(String query) {
//     if (query.isEmpty) {
//       setState(() {
//         searchResults = [];
//         isSearching = false;
//       });
//       return;
//     }

//     setState(() {
//       isSearching = true;
//       searchResults = allStocks
//           .where((stock) =>
//               stock["name"].toLowerCase().contains(query.toLowerCase()) ||
//               stock["fullName"].toLowerCase().contains(query.toLowerCase()))
//           .toList();

//       searchResults.sort((a, b) {
//         bool aStartsWith = a["name"].toLowerCase().startsWith(query.toLowerCase());
//         bool bStartsWith = b["name"].toLowerCase().startsWith(query.toLowerCase());
//         if (aStartsWith && !bStartsWith) return -1;
//         if (bStartsWith && !aStartsWith) return 1;
//         return a["name"].compareTo(b["name"]);
//       });
//     });
//   }

//   void showAddWatchlistDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissing by tapping outside
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 spreadRadius: 2,
//               )
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 "Create Watchlist",
//                 style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 "Start tracking stocks by creating a watchlist",
//                 style: TextStyle(color: Colors.grey[600], fontSize: 14),
//               ),
//               SizedBox(height: 20),
//               TextField(
//                 controller: wishlistController,
//                 style: TextStyle(color: Colors.black),
//                 autofocus: true,
//                 decoration: InputDecoration(
//                   hintText: "Enter watchlist name",
//                   hintStyle: TextStyle(color: Colors.grey[600]),
//                   enabledBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(color: Colors.grey[400]!),
//                   ),
//                   focusedBorder: UnderlineInputBorder(
//                     borderSide: BorderSide(color: const Color.fromARGB(255, 15, 15, 15)),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () {
//                       wishlistController.clear();
//                       Navigator.pop(context);
//                     },
//                     child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
//                   ),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (wishlistController.text.isNotEmpty) {
//                         setState(() {
//                           String newList = wishlistController.text;
//                           wishlists.add(newList);
//                           watchlistItems[newList] = 0;
//                           watchlistIcons[newList] = Icons.visibility;
//                           wishlistStocks[newList] = [];
//                           selectedWishlist = newList; // Switch to new list
//                           wishlistController.clear();
//                         });
//                       }
//                       Navigator.pop(context);
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color.fromARGB(255, 112, 97, 243),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text("Create", style: TextStyle(color: Colors.white)),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void showQuantityDialog(Map<String, dynamic> stock) {
//     int selectedQuantity = 1;
    
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           return Dialog(
//             backgroundColor: Colors.transparent,
//             child: Container(
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Select Quantity for ${stock["name"]}",
//                     style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     "How many shares do you want to add?",
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                   SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         icon: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Icon(Icons.remove, color: Colors.black, size: 20),
//                         ),
//                         onPressed: () {
//                           if (selectedQuantity > 1) {
//                             setDialogState(() {
//                               selectedQuantity--;
//                             });
//                           }
//                         },
//                       ),
//                       SizedBox(width: 20),
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           "$selectedQuantity",
//                           style: TextStyle(
//                             color: Color.fromARGB(255, 112, 97, 243),
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 20),
//                       IconButton(
//                         icon: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Color.fromARGB(255, 112, 97, 243),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Icon(Icons.add, color: Colors.white, size: 20),
//                         ),
//                         onPressed: () {
//                           setDialogState(() {
//                             selectedQuantity++;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
//                       ),
//                       SizedBox(width: 10),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           addStockToCurrentWishlist(stock, selectedQuantity);
//                         },
//                         child: Text("Add", style: TextStyle(color: Color.fromARGB(255, 112, 97, 243))),
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

//   void showEditDialog(Map<String, dynamic> stock) {
//     int selectedQuantity = stock["quantity"] ?? 1;
    
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           return Dialog(
//             backgroundColor: Colors.transparent,
//             child: Container(
//               padding: EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Edit ${stock["name"]} Shares",
//                     style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 20),
//                   Text(
//                     "Update the quantity of shares:",
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                   SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       IconButton(
//                         icon: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Icon(Icons.remove, color: Colors.black, size: 20),
//                         ),
//                         onPressed: () {
//                           if (selectedQuantity > 1) {
//                             setDialogState(() {
//                               selectedQuantity--;
//                             });
//                           }
//                         },
//                       ),
//                       SizedBox(width: 20),
//                       Container(
//                         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           "$selectedQuantity",
//                           style: TextStyle(
//                             color: Color.fromARGB(255, 112, 97, 243),
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 20),
//                       IconButton(
//                         icon: Container(
//                           padding: EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             color: Color.fromARGB(255, 112, 97, 243),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Icon(Icons.add, color: Colors.white, size: 20),
//                         ),
//                         onPressed: () {
//                           setDialogState(() {
//                             selectedQuantity++;
//                           });
//                         },
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: 30),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
//                       ),
//                       SizedBox(width: 10),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           updateStockQuantity(stock, selectedQuantity);
//                         },
//                         child: Text("Update", style: TextStyle(color: Color.fromARGB(255, 112, 97, 243))),
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

//   void addStockToCurrentWishlist(Map<String, dynamic> stock, int quantity) {
//     setState(() {
//       if (wishlistStocks[selectedWishlist] == null) {
//         wishlistStocks[selectedWishlist] = [];
//       }
      
//       int existingIndex = wishlistStocks[selectedWishlist]!.indexWhere((item) => item["name"] == stock["name"]);
      
//       if (existingIndex != -1) {
//         wishlistStocks[selectedWishlist]![existingIndex]["quantity"] += quantity;
//       } else {
//         wishlistStocks[selectedWishlist]!.add({
//           ...stock,
//           "quantity": quantity
//         });
//       }
      
//       watchlistItems[selectedWishlist] = wishlistStocks[selectedWishlist]!.length;
      
//       searchController.clear();
//       searchResults = [];
//       isSearching = false;
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("$quantity ${stock['name']} share${quantity > 1 ? 's' : ''} added to $selectedWishlist"),
//           backgroundColor: Colors.green,
//           duration: Duration(seconds: 2),
//         ),
//       );
//     });
//   }

//   void updateStockQuantity(Map<String, dynamic> stock, int newQuantity) {
//     setState(() {
//       if (wishlistStocks[selectedWishlist] != null) {
//         int existingIndex = wishlistStocks[selectedWishlist]!.indexWhere((item) => item["name"] == stock["name"]);
        
//         if (existingIndex != -1) {
//           if (newQuantity <= 0) {
//             wishlistStocks[selectedWishlist]!.removeAt(existingIndex);
//             watchlistItems[selectedWishlist] = wishlistStocks[selectedWishlist]!.length;
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text("${stock['name']} removed from $selectedWishlist"),
//                 backgroundColor: Colors.red,
//                 duration: Duration(seconds: 2),
//               ),
//             );
//           } else {
//             wishlistStocks[selectedWishlist]![existingIndex]["quantity"] = newQuantity;
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text("${stock['name']} quantity updated to $newQuantity"),
//                 backgroundColor: Colors.green,
//                 duration: Duration(seconds: 2),
//               ),
//             );
//           }
//         }
//       }
//     });
//   }
  
//   void selectWatchlist(String watchlist) {
//     setState(() {
//       selectedWishlist = watchlist;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     bool hasStocks = wishlistStocks[selectedWishlist] != null && wishlistStocks[selectedWishlist]!.isNotEmpty;
    
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: Row(
//           children: [
//             Text(
//               "wishlist",
//               style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal, fontSize: 20),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: Image.asset(
//               'assets/Frame.png',
//               width: 24,
//               height: 24,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Icon(Icons.notifications, size: 24, color: Color.fromARGB(255, 112, 97, 243));
//               },
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NotificationScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//               child: Container(
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: TextField(
//                   controller: searchController,
//                   style: TextStyle(color: Colors.black),
//                   decoration: InputDecoration(
//                     hintText: "Search stocks...",
//                     hintStyle: TextStyle(color: Colors.grey[600]),
//                     prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
//                     border: InputBorder.none,
//                     contentPadding: EdgeInsets.symmetric(vertical: 15),
//                   ),
//                   onChanged: performSearch,
//                 ),
//               ),
//             ),

//             if (isSearching && searchResults.isNotEmpty)
//               Container(
//                 margin: EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   physics: NeverScrollableScrollPhysics(),
//                   itemCount: searchResults.length > 3 ? 3 : searchResults.length,
//                   itemBuilder: (context, index) {
//                     final stock = searchResults[index];
//                     return ListTile(
//                       leading: Icon(
//                         stock["change"] >= 0 ? Icons.trending_up : Icons.trending_down,
//                         color: stock["change"] >= 0 ? Colors.green : Colors.red,
//                       ),
//                       title: Text(
//                         stock["name"],
//                         style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//                       ),
//                       subtitle: Text(
//                         stock["fullName"],
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 "\$${stock["price"].toStringAsFixed(2)}",
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 decoration: BoxDecoration(
//                                   color: stock["change"] >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   "${stock["change"] >= 0 ? "+" : ""}${stock["change"].toStringAsFixed(2)}%",
//                                   style: TextStyle(
//                                     color: stock["change"] >= 0 ? Colors.green : Colors.red,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           SizedBox(width: 10),
//                           IconButton(
//                             icon: Container(
//                               padding: EdgeInsets.all(4),
//                               decoration: BoxDecoration(
//                                 color: Color.fromARGB(255, 112, 97, 243),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Icon(Icons.add, color: Colors.white, size: 18),
//                             ),
//                             onPressed: () => showQuantityDialog(stock),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                 ),
//               ),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Lists",
//                         style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.black,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.black, width: 1.5),
//                     ),
//                     child: IconButton(
//                       icon: Icon(Icons.add, color: Colors.white, size: 20),
//                       onPressed: () => showAddWatchlistDialog(),
//                       padding: EdgeInsets.zero,
//                       constraints: BoxConstraints(minWidth: 40, minHeight: 40),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Container(
//               height: 110,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: wishlists.length,
//                 itemBuilder: (context, index) {
//                   final watchlist = wishlists[index];
//                   final itemCount = watchlistItems[watchlist] ?? 0;
//                   final icon = watchlistIcons[watchlist] ?? Icons.list;
//                   final isSelected = selectedWishlist == watchlist;
                  
//                   return GestureDetector(
//                     onTap: () => selectWatchlist(watchlist),
//                     child: Container(
//                       width: 140,
//                       margin: EdgeInsets.only(left: 18, right: index == wishlists.length - 1 ? 18 : 0),
//                       padding: EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: isSelected 
//                           ? Border.all(color: Colors.black, width: 2)
//                           : Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             padding: EdgeInsets.all(6),
//                             decoration: BoxDecoration(
//                               color: Colors.amber[200],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Icon(icon, color: Colors.black, size: 18),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             watchlist, 
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                               fontSize: 13,
//                             ),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                           Text(
//                             "$itemCount items", 
//                             style: TextStyle(color: Colors.grey[600], fontSize: 11),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),

//             Expanded(
//               child: hasStocks 
//                 ? ListView.builder(
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     itemCount: wishlistStocks[selectedWishlist]!.length,
//                     itemBuilder: (context, index) {
//                       final stock = wishlistStocks[selectedWishlist]![index];
//                       final int quantity = stock["quantity"] ?? 1;
                      
//                       return Container(
//                         margin: EdgeInsets.only(bottom: 8),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[50],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.grey[300]!),
//                         ),
//                         child: ListTile(
//                           leading: Icon(
//                             stock["change"] >= 0 ? Icons.trending_up : Icons.trending_down,
//                             color: stock["change"] >= 0 ? Colors.green : Colors.red,
//                           ),
//                           title: Text(
//                             stock["name"],
//                             style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//                           ),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 stock["fullName"],
//                                 style: TextStyle(color: Colors.grey[600]),
//                               ),
//                               SizedBox(height: 4),
//                               Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(4),
//                                 ),
//                                 child: Text(
//                                   "Quantity: $quantity",
//                                   style: TextStyle(
//                                     color: const Color.fromARGB(255, 0, 0, 0),
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           trailing: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.end,
//                                 children: [
//                                   Text(
//                                     "\$${stock["price"].toStringAsFixed(2)}",
//                                     style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//                                   ),
//                                   Container(
//                                     padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                     decoration: BoxDecoration(
//                                       color: stock["change"] >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(4),
//                                     ),
//                                     child: Text(
//                                       "${stock["change"] >= 0 ? "+" : ""}${stock["change"].toStringAsFixed(2)}%",
//                                       style: TextStyle(
//                                         color: stock["change"] >= 0 ? Colors.green : Colors.red,
//                                         fontSize: 12,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               SizedBox(width: 10),
//                               IconButton(
//                                 icon: Container(
//                                   padding: EdgeInsets.all(4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue,
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                   child: Icon(Icons.edit, color: Colors.white, size: 18),
//                                 ),
//                                 onPressed: () => showEditDialog(stock),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   )
//                 : Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.search, color: Colors.grey[400], size: 48),
//                         SizedBox(height: 16),
//                         Text(
//                           "No stocks in this list yet.",
//                           style: TextStyle(color: Colors.grey[600]),
//                           textAlign: TextAlign.center,
//                         ),
//                         Text(
//                           "Search and add stocks above.",
//                           style: TextStyle(color: Colors.grey[600]),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     ),
//                   ),
//             ),

//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//               color: Colors.white,
//               child: Text(
//                 "For more information, view our disclosures. Options involve risk.",
//                 style: TextStyle(color: Colors.grey[600], fontSize: 10),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }







import 'package:flutter/material.dart';
import 'package:test_project/features/notifications/notification.dart';

class TradingDashboard extends StatefulWidget {
  @override
  _TradingDashboardState createState() => _TradingDashboardState();
}

class _TradingDashboardState extends State<TradingDashboard> {
  bool isSearching = false;
  bool hasShownInitialDialog = false; // Track if we've shown the dialog
  TextEditingController searchController = TextEditingController();
  TextEditingController wishlistController = TextEditingController();
  String selectedWishlist = "My First List";

  List<String> wishlists = [
    "My First List",
  ];
  Map<String, int> watchlistItems = {
    "My First List": 0,
  };
  Map<String, IconData> watchlistIcons = {
    "My First List": Icons.flash_on,
  };

  Map<String, List<Map<String, dynamic>>> wishlistStocks = {};

  final List<Map<String, dynamic>> allStocks = [
    {"name": "GOOGL", "fullName": "Alphabet Inc", "price": 2174.75, "change": 1.21},
    {"name": "BABA", "fullName": "Alibaba Group", "price": 79.25, "change": -2.13},
    {"name": "AAPL", "fullName": "Apple Inc", "price": 138.93, "change": -1.32},
    {"name": "MSFT", "fullName": "Microsoft Corporation", "price": 289.45, "change": 1.23},
    {"name": "TSLA", "fullName": "Tesla Inc", "price": 681.79, "change": 4.89},
    {"name": "AMZN", "fullName": "Amazon Inc", "price": 113.22, "change": 9.77},
    {"name": "NFLX", "fullName": "Netflix Inc", "price": 242.98, "change": 2.34},
    {"name": "META", "fullName": "Meta Platforms", "price": 169.15, "change": -0.45},
    {"name": "NVDA", "fullName": "Nvidia Corporation", "price": 453.12, "change": 3.75},
    {"name": "AMD", "fullName": "Advanced Micro Devices", "price": 125.65, "change": 1.92},
  ];

  List<Map<String, dynamic>> searchResults = [];

  @override
  void initState() {
    super.initState();
    for (String list in wishlists) {
      wishlistStocks[list] = [];
    }
    
    // Show dialog after first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasShownInitialDialog && wishlists.length == 1 && (watchlistItems["My First List"] ?? 0) == 0) {
        hasShownInitialDialog = true;
        showAddWatchlistDialog();
      }
    });
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = allStocks
          .where((stock) =>
              stock["name"].toLowerCase().contains(query.toLowerCase()) ||
              stock["fullName"].toLowerCase().contains(query.toLowerCase()))
          .toList();

      searchResults.sort((a, b) {
        bool aStartsWith = a["name"].toLowerCase().startsWith(query.toLowerCase());
        bool bStartsWith = b["name"].toLowerCase().startsWith(query.toLowerCase());
        if (aStartsWith && !bStartsWith) return -1;
        if (bStartsWith && !aStartsWith) return 1;
        return a["name"].compareTo(b["name"]);
      });
    });
  }

  void showAddWatchlistDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),

          
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Watchlist",
                style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Start tracking stocks by creating a watchlist",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              SizedBox(height: 20),
              TextField(
                controller: wishlistController,
                style: TextStyle(color: Colors.black),
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Enter watchlist name",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: const Color.fromARGB(255, 112, 97, 243)),
                  ),
                ),
              ),
              SizedBox(height: 20),


              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      wishlistController.clear();
                      Navigator.pop(context);
                    },
                    child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (wishlistController.text.isNotEmpty) {
                        setState(() {
                          String newList = wishlistController.text;
                          wishlists.add(newList);
                          watchlistItems[newList] = 0;
                          watchlistIcons[newList] = Icons.visibility;
                          wishlistStocks[newList] = [];
                          selectedWishlist = newList; // Switch to new list
                          wishlistController.clear();
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 112, 97, 243),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("Create", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showQuantityDialog(Map<String, dynamic> stock) {
    int selectedQuantity = 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select Quantity for ${stock["name"]}",
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "How many shares do you want to add?",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.remove, color: Colors.black, size: 20),
                        ),
                        onPressed: () {
                          if (selectedQuantity > 1) {
                            setDialogState(() {
                              selectedQuantity--;
                            });
                          }
                        },
                      ),
                      SizedBox(width: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$selectedQuantity",
                          style: TextStyle(
                            color: Color.fromARGB(255, 112, 97, 243),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 112, 97, 243),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                        onPressed: () {

                          setDialogState(() {
                            selectedQuantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          addStockToCurrentWishlist(stock, selectedQuantity);
                        },
                        child: Text("Add", style: TextStyle(color: Color.fromARGB(255, 112, 97, 243))),
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

  void showEditDialog(Map<String, dynamic> stock) {
    int selectedQuantity = stock["quantity"] ?? 1;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit ${stock["name"]} Shares",
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Update the quantity of shares:",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.remove, color: Colors.black, size: 20),
                        ),
                        onPressed: () {
                          if (selectedQuantity > 1) {
                            setDialogState(() {
                              selectedQuantity--;
                            });
                          }
                        },
                      ),
                      SizedBox(width: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$selectedQuantity",
                          style: TextStyle(
                            color: Color.fromARGB(255, 112, 97, 243),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 112, 97, 243),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedQuantity++;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          updateStockQuantity(stock, selectedQuantity);
                        },
                        child: Text("Update", style: TextStyle(color: Color.fromARGB(255, 112, 97, 243))),
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

  void addStockToCurrentWishlist(Map<String, dynamic> stock, int quantity) {
    setState(() {
      if (wishlistStocks[selectedWishlist] == null) {
        wishlistStocks[selectedWishlist] = [];
      }
      
      int existingIndex = wishlistStocks[selectedWishlist]!.indexWhere((item) => item["name"] == stock["name"]);
      
      if (existingIndex != -1) {
        wishlistStocks[selectedWishlist]![existingIndex]["quantity"] += quantity;
      } else {
        wishlistStocks[selectedWishlist]!.add({
          ...stock,
          "quantity": quantity
        });
      }
      
      watchlistItems[selectedWishlist] = wishlistStocks[selectedWishlist]!.length;
      
      searchController.clear();
      searchResults = [];
      isSearching = false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$quantity ${stock['name']} share${quantity > 1 ? 's' : ''} added to $selectedWishlist"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  void updateStockQuantity(Map<String, dynamic> stock, int newQuantity) {
    setState(() {
      if (wishlistStocks[selectedWishlist] != null) {
        int existingIndex = wishlistStocks[selectedWishlist]!.indexWhere((item) => item["name"] == stock["name"]);
        
        if (existingIndex != -1) {
          if (newQuantity <= 0) {
            wishlistStocks[selectedWishlist]!.removeAt(existingIndex);
            watchlistItems[selectedWishlist] = wishlistStocks[selectedWishlist]!.length;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${stock['name']} removed from $selectedWishlist"),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            wishlistStocks[selectedWishlist]![existingIndex]["quantity"] = newQuantity;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${stock['name']} quantity updated to $newQuantity"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }
  
  void selectWatchlist(String watchlist) {
    setState(() {
      selectedWishlist = watchlist;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasStocks = wishlistStocks[selectedWishlist] != null && wishlistStocks[selectedWishlist]!.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0), // Move "Watchlist" slightly right
         
        ),
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
      
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            "   Watchlist",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: searchController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Search stocks...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onChanged: performSearch,
                ),
              ),
            ),

            if (isSearching && searchResults.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: searchResults.length > 3 ? 3 : searchResults.length,
                  itemBuilder: (context, index) {
                    final stock = searchResults[index];
                    return ListTile(
                      leading: Icon(
                        stock["change"] >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: stock["change"] >= 0 ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        stock["name"],
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        stock["fullName"],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "\$${stock["price"].toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stock["change"] >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${stock["change"] >= 0 ? "+" : ""}${stock["change"].toStringAsFixed(2)}%",
                                  style: TextStyle(
                                    color: stock["change"] >= 0 ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 10),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 112, 97, 243),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                            onPressed: () => showQuantityDialog(stock),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lists",
                        style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: Offset(0, 5), // Move the button slightly below
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 112, 97, 243),
                        shape: BoxShape.circle,
                        border: Border.all(color: Color.fromARGB(255, 112, 97, 243), width: 1.0),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: Colors.white, size: 12), // Smaller icon
                        onPressed: () => showAddWatchlistDialog(),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 21, minHeight: 21), // Smaller container
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: wishlists.length,
                itemBuilder: (context, index) {
                  final watchlist = wishlists[index];
                  final itemCount = watchlistItems[watchlist] ?? 0;
                  final icon = watchlistIcons[watchlist] ?? Icons.list;
                  final isSelected = selectedWishlist == watchlist;
                  
                  return GestureDetector(
                    onTap: () => selectWatchlist(watchlist),
                    child: Container(
                      width: 140,
                      margin: EdgeInsets.only(left: 18, right: index == wishlists.length - 1 ? 18 : 0),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.amber[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, color: Colors.black, size: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            watchlist, 
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "$itemCount items", 
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: hasStocks 
                ? ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: wishlistStocks[selectedWishlist]!.length,
                    itemBuilder: (context, index) {
                      final stock = wishlistStocks[selectedWishlist]![index];
                      final int quantity = stock["quantity"] ?? 1;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ListTile(
                          leading: Icon(
                            stock["change"] >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: stock["change"] >= 0 ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            stock["name"],
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stock["fullName"],
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Quantity: $quantity",
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "\$${stock["price"].toStringAsFixed(2)}",
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: stock["change"] >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "${stock["change"] >= 0 ? "+" : ""}${stock["change"].toStringAsFixed(2)}%",
                                      style: TextStyle(
                                        color: stock["change"] >= 0 ? Colors.green : Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                                ),
                                onPressed: () => showEditDialog(stock),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: Colors.grey[400], size: 48),
                        SizedBox(height: 16),
                        Text(
                          "No stocks in this list yet.",
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Search and add stocks above.",
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
            ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: Colors.white,
              child: Text(
                "For more information, view our disclosures. Options involve risk.",
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}