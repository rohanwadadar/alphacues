// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:url_launcher/url_launcher.dart';

// // /// 🔹 Reusable service function to fetch stock news
// // Future<List<Map<String, dynamic>>> fetchStockNews(
// //     String ticker, String apiKey) async {
// //   final url = Uri.parse(
// //     "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=$ticker&apikey=$apiKey",
// //   );

// //   final response = await http.get(url);

// //   if (response.statusCode == 200) {
// //     final data = json.decode(response.body);
// //     final List<dynamic> feed = data["feed"] ?? [];

// //     return feed.map((item) {
// //       return {
// //         "title": item["title"] ?? "No Title",
// //         "url": item["url"] ?? "",
// //         "urlToImage": item["banner_image"] ?? "",
// //         "summary": item["summary"] ?? "No Summary Available",
// //         "source": item["source"] ?? "Unknown Source",
// //         "publishedAt": item["time_published"] ?? "",
// //       };
// //     }).toList();
// //   } else {
// //     throw Exception("Failed to fetch news: ${response.statusCode}");
// //   }
// // }

// // /// 🔹 News screen widget
// // class NewsMailScreen extends StatefulWidget {
// //   @override
// //   _NewsMailScreenState createState() => _NewsMailScreenState();
// // }

// // class _NewsMailScreenState extends State<NewsMailScreen> {
// //   List<Map<String, dynamic>> newsData = [];
// //   final String apiKey = "XH0MOF8FACW6RR0L"; // Your API Key

// //   @override
// //   void initState() {
// //     super.initState();
// //     loadNews();
// //   }

// //   Future<void> loadNews() async {
// //     try {
// //       final fetched = await fetchStockNews("AAPL", apiKey);
// //       setState(() {
// //         newsData = fetched;
// //       });
// //     } catch (e) {
// //       debugPrint("Failed to load news: $e");
// //     }
// //   }

// //   Future<void> _openArticle(String url) async {
// //     if (await canLaunch(url)) {
// //       await launch(url);
// //     } else {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text('Could not open the article')),
// //       );
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white, // changed to white theme
// //       appBar: AppBar(
// //         title: const Text("Latest News"),
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         foregroundColor: Colors.black,
// //       ),
// //       body: newsData.isEmpty
// //           ? const Center(
// //               child: CircularProgressIndicator(color: Colors.blueAccent),
// //             )
// //           : ListView.builder(
// //               padding: const EdgeInsets.all(12),
// //               itemCount: newsData.length,
// //               itemBuilder: (context, index) {
// //                 var newsItem = newsData[index];
// //                 return GestureDetector(
// //                   onTap: () => _openArticle(newsItem["url"]!),
// //                   child: Card(
// //                     color: Colors.white,
// //                     shadowColor: Colors.grey.shade300,
// //                     elevation: 3,
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                     margin: const EdgeInsets.symmetric(vertical: 8),
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(12),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           ClipRRect(
// //                             borderRadius: BorderRadius.circular(10),
// //                             child: newsItem["urlToImage"] != null &&
// //                                     newsItem["urlToImage"]!.isNotEmpty
// //                                 ? Image.network(
// //                                     newsItem["urlToImage"]!,
// //                                     height: 180,
// //                                     width: double.infinity,
// //                                     fit: BoxFit.cover,
// //                                   )
// //                                 : Container(
// //                                     height: 180,
// //                                     width: double.infinity,
// //                                     color: Colors.grey[200],
// //                                     child: const Center(
// //                                       child: Icon(Icons.image_not_supported,
// //                                           color: Colors.black54, size: 50),
// //                                     ),
// //                                   ),
// //                           ),
// //                           const SizedBox(height: 10),
// //                           Text(
// //                             newsItem["title"] ?? "No Title",
// //                             style: const TextStyle(
// //                               color: Colors.black,
// //                               fontSize: 18,
// //                               fontWeight: FontWeight.bold,
// //                             ),
// //                           ),
// //                           const SizedBox(height: 5),
// //                           Text(
// //                             newsItem["summary"] ?? "No Summary Available",
// //                             style: const TextStyle(
// //                               color: Colors.black87,
// //                               fontSize: 14,
// //                             ),
// //                             maxLines: 3,
// //                             overflow: TextOverflow.ellipsis,
// //                           ),
// //                           const SizedBox(height: 10),
// //                           Row(
// //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                             children: [
// //                               Text(
// //                                 newsItem["source"] ?? "Unknown Source",
// //                                 style: const TextStyle(
// //                                     color: Colors.blueAccent, fontSize: 14),
// //                               ),
// //                               ElevatedButton(
// //                                 onPressed: () =>
// //                                     _openArticle(newsItem["url"] ?? ""),
// //                                 style: ElevatedButton.styleFrom(
// //                                   backgroundColor: Colors.blueAccent,
// //                                   shape: RoundedRectangleBorder(
// //                                     borderRadius: BorderRadius.circular(8),
// //                                   ),
// //                                 ),
// //                                 child: const Text("Read More"),
// //                               )
// //                             ],
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
// // }



// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:url_launcher/url_launcher.dart';

// /// 🔹 Alpaca WebSocket News Service
// class AlpacaNewsService {
//   static const String newsWebSocketUrl = 'wss://stream.data.alpaca.markets/v1beta1/news';
//   static const String sandboxWebSocketUrl = 'wss://stream.data.sandbox.alpaca.markets/v1beta1/news';
  
//   // Your Alpaca credentials
//   static const String apiKeyId = 'PK6O4W6SBWAVCTZKQRPC';
//   static const String apiSecret = 'e1rimphcUKc7SmJv9N3gla0oiMPgP8sstxp0Vk7D';
  
//   WebSocketChannel? _channel;
  
//   // Connect to Alpaca news stream
//   WebSocketChannel connectToNewsStream({bool useSandbox = false}) {
//     final url = useSandbox ? sandboxWebSocketUrl : newsWebSocketUrl;
//     _channel = WebSocketChannel.connect(Uri.parse(url));
    
//     // Send authentication message
//     final authMessage = {
//       "action": "auth",
//       "key": apiKeyId,
//       "secret": apiSecret
//     };
    
//     _channel!.sink.add(json.encode(authMessage));
    
//     // Subscribe to news stream
//     final subscribeMessage = {
//       "action": "subscribe",
//       "news": ["*"] // Subscribe to all news, or specify symbols like ["AAPL", "TSLA"]
//     };
    
//     _channel!.sink.add(json.encode(subscribeMessage));
    
//     return _channel!;
//   }
  
//   void disconnect() {
//     _channel?.sink.close();
//   }
  
//   // Parse news data from WebSocket
//   Map<String, dynamic>? parseNewsData(dynamic message) {
//     try {
//       final data = json.decode(message);
      
//       // Check if it's a news message
//       if (data['T'] == 'n') {
//         return {
//           "id": data['id'] ?? 0,
//           "title": data['headline'] ?? "No Title",
//           "summary": data['summary'] ?? "No Summary Available",
//           "author": data['author'] ?? "Unknown Author",
//           "content": data['content'] ?? "",
//           "url": data['url'] ?? "",
//           "source": data['source'] ?? "Unknown Source",
//           "symbols": List<String>.from(data['symbols'] ?? []),
//           "publishedAt": data['created_at'] ?? "",
//           "updatedAt": data['updated_at'] ?? "",
//         };
//       }
//     } catch (e) {
//       debugPrint("Error parsing news data: $e");
//     }
//     return null;
//   }
// }

// /// 🔹 Updated News Screen with Alpaca WebSocket
// class NewsMailScreen extends StatefulWidget {
//   @override
//   _NewsMailScreenState createState() => _NewsMailScreenState();
// }

// class _NewsMailScreenState extends State<NewsMailScreen> {
//   List<Map<String, dynamic>> newsData = [];
//   final AlpacaNewsService _newsService = AlpacaNewsService();
//   WebSocketChannel? _channel;
  
//   @override
//   void initState() {
//     super.initState();
//     _connectToNewsStream();
//   }
  
//   void _connectToNewsStream() {
//     _channel = _newsService.connectToNewsStream(useSandbox: true); // Use sandbox for testing
    
//     _channel!.stream.listen(
//       (message) {
//         final newsItem = _newsService.parseNewsData(message);
//         if (newsItem != null) {
//           setState(() {
//             // Add new news at the beginning of the list
//             newsData.insert(0, newsItem);
            
//             // Limit the list to prevent memory issues
//             if (newsData.length > 100) {
//               newsData = newsData.sublist(0, 100);
//             }
//           });
//         }
//       },
//       onError: (error) {
//         debugPrint("WebSocket error: $error");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('News stream error: $error')),
//         );
//       },
//       onDone: () {
//         debugPrint("WebSocket connection closed");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('News stream disconnected')),
//         );
//       },
//     );
//   }
  
//   @override
//   void dispose() {
//     _channel?.sink.close();
//     _newsService.disconnect();
//     super.dispose();
//   }
  
//   Future<void> _openArticle(String url) async {
//     if (url.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No URL available for this article')),
//       );
//       return;
//     }
    
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Could not open the article')),
//       );
//     }
//   }
  
//   Widget _buildNewsItem(Map<String, dynamic> newsItem, int index) {
//     final symbols = newsItem['symbols'] as List<String>;
    
//     return GestureDetector(
//       onTap: () => _openArticle(newsItem["url"]!),
//       child: Card(
//         color: Colors.white,
//         shadowColor: Colors.grey.shade300,
//         elevation: 3,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Source and symbols
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     newsItem["source"] ?? "Unknown Source",
//                     style: const TextStyle(
//                       color: Colors.blueAccent,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (symbols.isNotEmpty)
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         symbols.join(', '),
//                         style: const TextStyle(
//                           color: Colors.black54,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
              
//               const SizedBox(height: 8),
              
//               // Title
//               Text(
//                 newsItem["title"] ?? "No Title",
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
              
//               const SizedBox(height: 8),
              
//               // Summary
//               Text(
//                 newsItem["summary"] ?? "No Summary Available",
//                 style: const TextStyle(
//                   color: Colors.black87,
//                   fontSize: 14,
//                 ),
//                 maxLines: 3,
//                 overflow: TextOverflow.ellipsis,
//               ),
              
//               const SizedBox(height: 10),
              
//               // Author and date
//               Row(
//                 children: [
//                   if (newsItem["author"] != null && newsItem["author"].isNotEmpty)
//                     Text(
//                       "By ${newsItem["author"]}",
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontSize: 12,
//                       ),
//                     ),
//                   const Spacer(),
//                   if (newsItem["publishedAt"] != null && newsItem["publishedAt"].isNotEmpty)
//                     Text(
//                       _formatDate(newsItem["publishedAt"]),
//                       style: const TextStyle(
//                         color: Colors.black54,
//                         fontSize: 12,
//                       ),
//                     ),
//                 ],
//               ),
              
//               const SizedBox(height: 10),
              
//               // Read More button
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: ElevatedButton(
//                   onPressed: () => _openArticle(newsItem["url"] ?? ""),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text("Read More"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   String _formatDate(String dateString) {
//     try {
//       final date = DateTime.parse(dateString);
//       return "${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
//     } catch (e) {
//       return dateString;
//     }
//   }
  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Live Market News"),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               setState(() {
//                 newsData.clear();
//               });
//               _connectToNewsStream();
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Connection status
//           Container(
//             padding: const EdgeInsets.all(8),
//             color: Colors.green[50],
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.circle, color: Colors.green, size: 12),
//                 const SizedBox(width: 8),
//                 const Text(
//                   "Live News Stream Active",
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           // News list
//           Expanded(
//             child: newsData.isEmpty
//                 ? const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(color: Colors.blueAccent),
//                         SizedBox(height: 16),
//                         Text(
//                           "Waiting for news updates...",
//                           style: TextStyle(color: Colors.black54),
//                         ),
//                       ],
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.all(12),
//                     itemCount: newsData.length,
//                     itemBuilder: (context, index) {
//                       return _buildNewsItem(newsData[index], index);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }









import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market News',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const NewsMailScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 🔹 Alpaca News Service using HTTP API
class AlpacaNewsService {
  static const String baseUrl = 'https://data.alpaca.markets';
  static const String apiKeyId = 'PK6O4W6SBWAVCTZKQRPC';
  static const String apiSecret = 'e1rimphcUKc7SmJv9N3gla0oiMPgP8sstxp0Vk7D';
  
  /// Fetch news from Alpaca Markets API
  static Future<List<Map<String, dynamic>>> fetchNews({
    String symbols = 'AAPL,TSLA,MSFT,GOOGL',
    int limit = 20,
    int startDateDaysAgo = 7,
  }) async {
    final endDate = DateTime.now().toUtc();
    final startDate = endDate.subtract(Duration(days: startDateDaysAgo));
    
    final formattedStart = "${startDate.toIso8601String().split('.')[0]}Z";
    final formattedEnd = "${endDate.toIso8601String().split('.')[0]}Z";
    
    final url = Uri.parse(
      '$baseUrl/v1beta1/news?symbols=$symbols&limit=$limit&start=$formattedStart&end=$formattedEnd'
    );
    
    try {
      final response = await http.get(
        url,
        headers: {
          'APCA-API-KEY-ID': apiKeyId,
          'APCA-API-SECRET-KEY': apiSecret,
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newsItems = data['news'] ?? [];
        
        // Sort by date (newest first)
        newsItems.sort((a, b) {
          final dateA = DateTime.parse(a['created_at'] ?? '');
          final dateB = DateTime.parse(b['created_at'] ?? '');
          return dateB.compareTo(dateA);
        });
        
        return newsItems.map((item) {
          return {
            "id": item['id'] ?? 0,
            "title": item['headline'] ?? "No Title",
            "summary": item['summary'] ?? "No Summary Available",
            "author": item['author'] ?? "Unknown Author",
            "content": item['content'] ?? "",
            "url": item['url'] ?? "",
            "source": item['source'] ?? "Unknown Source",
            "symbols": List<String>.from(item['symbols'] ?? []),
            "publishedAt": item['created_at'] ?? "",
            "updatedAt": item['updated_at'] ?? "",
          };
        }).toList();
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}

/// 🔹 Fallback Alpha Vantage Service
class AlphaVantageNewsService {
  static const String apiKey = "XH0MOF8FACW6RR0L";
  
  static Future<List<Map<String, dynamic>>> fetchNews({
    String tickers = 'AAPL,TSLA',
    int limit = 20,
  }) async {
    final url = Uri.parse(
      "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=$tickers&apikey=$apiKey&limit=$limit"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> feed = data["feed"] ?? [];

      return feed.map((item) {
        return {
          "id": item["url"]?.hashCode ?? 0,
          "title": item["title"] ?? "No Title",
          "url": item["url"] ?? "",
          "summary": item["summary"] ?? "No Summary Available",
          "source": item["source"] ?? "Unknown Source",
          "publishedAt": item["time_published"] ?? "",
          "author": "Alpha Vantage",
          "symbols": _extractSymbols(item),
          "content": item["summary"] ?? "",
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch news: ${response.statusCode}");
    }
  }
  
  static List<String> _extractSymbols(Map<String, dynamic> item) {
    try {
      final tickerSentiment = item["ticker_sentiment"] as List?;
      if (tickerSentiment != null) {
        return tickerSentiment.map<String>((ts) => ts["ticker"]?.toString() ?? "").where((ticker) => ticker.isNotEmpty).toList();
      }
    } catch (e) {
      debugPrint("Error extracting symbols: $e");
    }
    return [];
  }
}

/// 🔹 Main News Screen
class NewsMailScreen extends StatefulWidget {
  const NewsMailScreen({super.key});

  @override
  State<NewsMailScreen> createState() => _NewsMailScreenState();
}

class _NewsMailScreenState extends State<NewsMailScreen> {
  List<Map<String, dynamic>> newsData = [];
  bool isLoading = true;
  String errorMessage = '';
  bool useAlpaca = true;
  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'AAPL', 'TSLA', 'MSFT', 'GOOGL'];

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      List<Map<String, dynamic>> fetchedNews;
      
      if (useAlpaca) {
        fetchedNews = await AlpacaNewsService.fetchNews(
          symbols: 'AAPL,TSLA,MSFT,GOOGL',
          limit: 25,
        );
      } else {
        fetchedNews = await AlphaVantageNewsService.fetchNews(
          tickers: 'AAPL,TSLA',
          limit: 25,
        );
      }
      
      if (!mounted) return;
      
      setState(() {
        newsData = fetchedNews;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      // If Alpaca fails, try Alpha Vantage as fallback
      if (useAlpaca) {
        debugPrint("Alpaca failed, trying Alpha Vantage: $e");
        useAlpaca = false;
        loadNews(); // Retry with Alpha Vantage
      } else {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _openArticle(String url) async {
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL available for this article')),
      );
      return;
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the article')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening article: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredNews {
    if (_selectedFilter == 0) return newsData;
    
    final filterSymbol = _filters[_selectedFilter];
    return newsData.where((news) {
      final symbols = news['symbols'] as List<String>;
      return symbols.contains(filterSymbol);
    }).toList();
  }

  Widget _buildNewsItem(Map<String, dynamic> newsItem, int index) {
    final symbols = newsItem['symbols'] as List<String>;
    final hasImage = newsItem['urlToImage'] != null && newsItem['urlToImage']!.isNotEmpty;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openArticle(newsItem["url"] ?? ""),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source and symbols
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      newsItem["source"] ?? "Unknown Source",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (symbols.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Text(
                        symbols.join(', '),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                newsItem["title"] ?? "No Title",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Summary
              Text(
                newsItem["summary"] ?? "No Summary Available",
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer with author, date, and button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (newsItem["author"] != null && newsItem["author"].isNotEmpty)
                          Text(
                            "By ${newsItem["author"]}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (newsItem["publishedAt"] != null && newsItem["publishedAt"].isNotEmpty)
                          Text(
                            _formatDate(newsItem["publishedAt"]),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _openArticle(newsItem["url"] ?? ""),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text("Read More"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return "${date.month}/${date.day}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filters[index]),
              selected: _selectedFilter == index,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? index : 0;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: _selectedFilter == index ? Colors.blue[800] : Colors.black87,
                fontWeight: _selectedFilter == index ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Market News"),
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadNews,
            tooltip: 'Refresh News',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                useAlpaca = value == 'alpaca';
              });
              loadNews();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'alpaca',
                child: Text('Use Alpaca API'),
              ),
              const PopupMenuItem(
                value: 'alphavantage',
                child: Text('Use Alpha Vantage API'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (newsData.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _buildFilterChips(),
            ),
            Text(
              'Showing ${_filteredNews.length} articles',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // News list
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue),
                        SizedBox(height: 16),
                        Text(
                          "Loading latest news...",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                "Failed to load news",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: loadNews,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("Try Again"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredNews.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.article_outlined, color: Colors.grey, size: 64),
                                const SizedBox(height: 16),
                                const Text(
                                  "No news available",
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Try changing filters or refresh",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: loadNews,
                                  child: const Text("Refresh"),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadNews,
                            color: Colors.blue,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredNews.length,
                              itemBuilder: (context, index) {
                                return _buildNewsItem(_filteredNews[index], index);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadNews,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}