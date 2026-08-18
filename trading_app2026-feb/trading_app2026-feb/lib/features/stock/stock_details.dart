// // lib/stock_details.dart
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:test_project/features/news/newsmail.dart'; // adapt if your helper is named or located differently

// // ------------------ Top-level: Candlestick model & painter ------------------

// class CandlestickData {
//   final double open;
//   final double high;
//   final double low;
//   final double close;
//   CandlestickData({
//     required this.open,
//     required this.high,
//     required this.low,
//     required this.close,
//   });
// }

// class CandlestickPainter extends CustomPainter {
//   final List<CandlestickData> data;
//   final Color upColor;
//   final Color downColor;
//   final int? highlightedIndex;

//   CandlestickPainter({
//     required this.data,
//     required this.upColor,
//     required this.downColor,
//     this.highlightedIndex,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     if (data.isEmpty) return;

//     final double w = size.width;
//     final double h = size.height;

//     final double maxPrice = data.map((d) => d.high).reduce((a, b) => a > b ? a : b);
//     final double minPrice = data.map((d) => d.low).reduce((a, b) => a < b ? a : b);
//     final double range = (maxPrice - minPrice) == 0 ? 1 : (maxPrice - minPrice);

//     final double rawWidth = w / data.length;
//     final double candleWidth = rawWidth * 0.6;

//     for (int i = 0; i < data.length; i++) {
//       final c = data[i];
//       final double centerX = i * rawWidth + rawWidth / 2;

//       final double yHigh = h - ((c.high - minPrice) / range) * h;
//       final double yLow = h - ((c.low - minPrice) / range) * h;
//       final double yOpen = h - ((c.open - minPrice) / range) * h;
//       final double yClose = h - ((c.close - minPrice) / range) * h;

//       final bool up = c.close >= c.open;
//       final Paint paint = Paint()..color = up ? upColor : downColor;

//       // wick
//       final Paint wickPaint = Paint()
//         ..color = paint.color
//         ..strokeWidth = 1.0;
//       canvas.drawLine(Offset(centerX, yHigh), Offset(centerX, yLow), wickPaint);

//       // body
//       final Rect bodyRect = Rect.fromLTRB(
//         centerX - candleWidth / 2,
//         up ? yClose : yOpen,
//         centerX + candleWidth / 2,
//         up ? yOpen : yClose,
//       );
//       canvas.drawRect(bodyRect, paint);

//       // highlight if selected
//       if (highlightedIndex != null && highlightedIndex == i) {
//         final Paint highlight = Paint()..color = Colors.black.withOpacity(0.08);
//         canvas.drawRect(bodyRect.inflate(4.0), highlight);
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CandlestickPainter oldDelegate) {
//     return oldDelegate.data != data || oldDelegate.highlightedIndex != highlightedIndex;
//   }
// }

// // ------------------ StockDetailsPage and UI (keeps your white theme) ------------------

// class StockDetailsPage extends StatefulWidget {
//   final String stockName;

//   const StockDetailsPage({Key? key, required this.stockName}) : super(key: key);

//   @override
//   State<StockDetailsPage> createState() => _StockDetailsPageState();
// }

// class _StockDetailsPageState extends State<StockDetailsPage> {
//   // UI state - keep your existing booleans
//   bool showCandlestick = false;

//   // Minimal interaction state for candlestick
//   int? _highlightedCandleIndex;

//   // Touch state for line chart tooltip
//   FlSpot? _touchedSpot;

//   // News loading
//   bool loadingNews = true;
//   List<Map<String, dynamic>> articles = [];

//   // Timeframe selection
//   String selectedTime = "1D";

//   // ---------------- lifecycle ----------------
//   @override
//   void initState() {
//     super.initState();
//     loadNews();
//   }

//   Future<void> loadNews() async {
//     setState(() => loadingNews = true);
//     try {
//       // If your news helper has a different function signature, adapt this line.
//       final fetched = await fetchStockNews(widget.stockName, "XH0MOF8FACW6RR0L");
//       setState(() {
//         articles = List<Map<String, dynamic>>.from(fetched);
//         loadingNews = false;
//       });
//     } catch (e) {
//       setState(() {
//         articles = [
//           {
//             "title": "Unable to fetch news. Please check connection.",
//             "url": "",
//             "urlToImage": null,
//             "publishedAt": null
//           }
//         ];
//         loadingNews = false;
//       });
//     }
//   }

//   // ---------------- sample chart data provider ----------------
//   // Replace with your actual source (widget.stockData or fetched series)
//   List<FlSpot> chartSpots() {
//     switch (selectedTime) {
//       case "1W":
//         return [FlSpot(0, 1), FlSpot(1, 1.05), FlSpot(2, 1.02), FlSpot(3, 1.08)];
//       case "1M":
//         return [FlSpot(0, 1), FlSpot(1, 1.12), FlSpot(2, 1.18), FlSpot(3, 1.25)];
//       case "1Y":
//         return [FlSpot(0, 1), FlSpot(1, 1.4), FlSpot(2, 1.9), FlSpot(3, 2.2)];
//       default:
//         return [FlSpot(0, 1), FlSpot(1, 1.03), FlSpot(2, 1.05), FlSpot(3, 1.07)];
//     }
//   }

//   // ---------------- candlestick helpers (minimal & non-destructive) ----------------

//   /// Convert a list of FlSpot into a simple list of CandlestickData.
//   /// By default uses windowSize = 1 (one candle per spot). Increase windowSize
//   /// to aggregate multiple spots into one candle if desired.
//   List<CandlestickData> _candlesFromSpots(List<FlSpot> spots, {int windowSize = 1}) {
//     if (spots.isEmpty) return [];
//     final List<CandlestickData> out = [];
//     for (int i = 0; i < spots.length; i += windowSize) {
//       final end = (i + windowSize).clamp(0, spots.length);
//       final chunk = spots.sublist(i, end);
//       final open = chunk.first.y;
//       final close = chunk.last.y;
//       double high = chunk.first.y;
//       double low = chunk.first.y;
//       for (final s in chunk) {
//         if (s.y > high) high = s.y;
//         if (s.y < low) low = s.y;
//       }
//       out.add(CandlestickData(open: open, high: high, low: low, close: close));
//     }
//     return out;
//   }

//   /// Handle tapping on the candlestick area. Calculates which candle index
//   /// was tapped and highlights it.
//   void _handleCandleTap(Offset localPos, Size size, List<CandlestickData> candles) {
//     if (candles.isEmpty) return;
//     final rawWidth = size.width / candles.length;
//     int idx = (localPos.dx / rawWidth).floor();
//     idx = idx.clamp(0, candles.length - 1);
//     setState(() {
//       _highlightedCandleIndex = idx;
//       // If you want also to set selected value for display, do it here:
//       // selectedValue = candles[idx].close;
//     });
//   }

//   // ---------------- line chart touch configuration (compatible with fl_chart 0.70.x) ----------------

//   LineTouchData _getLineTouchData() {
//     return LineTouchData(
//       enabled: true,
//       handleBuiltInTouches: true,
//       touchCallback: (event, response) {
//         if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
//           setState(() {
//             _touchedSpot = null;
//             _highlightedCandleIndex = null;
//           });
//           return;
//         }
//         final spot = response.lineBarSpots![0];
//         setState(() {
//           _touchedSpot = spot;
//           // Map spot.x (index) to highlight if needed
//           _highlightedCandleIndex = spot.x.toInt();
//         });
//       },
//       touchTooltipData: LineTouchTooltipData(
//         tooltipRoundedRadius: 8,
//         tooltipPadding: const EdgeInsets.all(6),
//         tooltipMargin: 8,
//         getTooltipItems: (touchedSpots) {
//           return touchedSpots.map((t) {
//             final text = t.y.toStringAsFixed(2);
//             return LineTooltipItem(text, const TextStyle(color: Colors.white, fontWeight: FontWeight.w600));
//           }).toList();
//         },
//       ),
//     );
//   }

//   // ---------------- build interactive chart widget (keeps all style) ----------------

//   Widget _buildChartArea({required double height}) {
//     // Get the data - if your file uses widget.stockData inside a nested StockGraph,
//     // adapt this to use that variable instead. This function uses chartSpots() as fallback.
//     List<FlSpot> baseSpots = chartSpots();

//     // Visible spots - if you have zoom/pan logic, use visible subset instead.
//     final visibleSpots = baseSpots;

//     // Build candles from the visible spots. Use windowSize > 1 to aggregate if needed.
//     final candles = _candlesFromSpots(visibleSpots, windowSize: 1);

//     return LayoutBuilder(builder: (context, constraints) {
//       return GestureDetector(
//         behavior: HitTestBehavior.translucent,
//         onTapDown: (details) {
//           // If currently showing candles and user taps, highlight a candle
//           if (showCandlestick) {
//             _handleCandleTap(details.localPosition, Size(constraints.maxWidth, height), candles);
//           }
//         },
//         child: Container(
//           height: height,
//           child: showCandlestick
//               ? CustomPaint(
//                   size: Size.infinite,
//                   painter: CandlestickPainter(
//                     data: candles,
//                     upColor: Colors.green,
//                     downColor: Colors.red,
//                     highlightedIndex: _highlightedCandleIndex,
//                   ),
//                 )
//               : LineChart(
//                   LineChartData(
//                     gridData: FlGridData(show: false),
//                     titlesData: FlTitlesData(show: false),
//                     borderData: FlBorderData(show: false),
//                     lineBarsData: [
//                       LineChartBarData(
//                         spots: visibleSpots,
//                         isCurved: true,
//                         color: Colors.green,
//                         barWidth: 2,
//                         dotData: FlDotData(show: false),
//                         belowBarData: BarAreaData(
//                           show: true,
//                           gradient: LinearGradient(
//                             colors: [Colors.green.withOpacity(0.12), Colors.green.withOpacity(0.0)],
//                             begin: Alignment.topCenter,
//                             end: Alignment.bottomCenter,
//                           ),
//                         ),
//                       ),
//                     ],
//                     lineTouchData: _getLineTouchData(),
//                   ),
//                 ),
//         ),
//       );
//     });
//   }

//   // ---------------- UI (kept identical to your earlier white theme) ----------------

//   static const double kPadding = 16.0;
//   static const double kCardRadius = 16.0;

//   @override
//   Widget build(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     final TextStyle sectionTitle = theme.textTheme.titleMedium!.copyWith(
//       fontWeight: FontWeight.bold,
//       color: Colors.black,
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         titleSpacing: 0,
//         title: Text(
//           widget.stockName,
//           style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.maybePop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add, color: Colors.deepPurple),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.notifications, color: Colors.deepPurple),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(kPadding),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ===== Top header: symbol, price, change, chart mode button =====
//               _buildTopHeader(),

//               const SizedBox(height: 20),

//               // ===== Chart card =====
//               SectionCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Chart area (we only replaced the inner chart rendering to support candlesticks)
//                     SizedBox(height: 220, child: _buildChartArea(height: 220)),
//                     const SizedBox(height: 12),
//                     // Price summary row
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         PriceSummary(
//                           price: "\$151.71",
//                           change: "+\$7.66",
//                           pct: "(5.33%)",
//                         ),
//                         // small action buttons
//                         Row(children: [
//                           IconButton(
//                             icon: const Icon(Icons.share, color: Colors.black54),
//                             onPressed: () {},
//                             tooltip: "Share",
//                           ),
//                           const SizedBox(width: 8),
//                           ElevatedButton(
//                             onPressed: () => setState(() => showCandlestick = !showCandlestick),
//                             style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.deepPurple,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(999),
//                                 )),
//                             child: Text(showCandlestick ? "Line" : "Candle"),
//                           )
//                         ])
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 16),

//               // ===== Timeframe selector =====
//               _buildTimeframe(),

//               const SizedBox(height: 20),

//               // ===== About company =====
//               Text("About the company", style: sectionTitle),
//               const SizedBox(height: 8),
//               SectionCard(
//                 child: Column(
//                   children: [
//                     InfoRow(left: "HQ", right: "Cupertino, CA"),
//                     InfoRow(left: "CEO", right: "Tim Cook"),
//                     InfoRow(left: "Employees", right: "154,000"),
//                     InfoRow(left: "Market Cap", right: "\$2.5T"),
//                     InfoRow(left: "52W High / Low", right: "\$182 / \$120"),
//                     InfoRow(left: "P/E Ratio", right: "29.3"),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ===== Analyst ratings =====
//               Text("Analyst ratings", style: sectionTitle),
//               const SizedBox(height: 8),
//               SectionCard(
//                 child: Column(
//                   children: [
//                     RatingRow(label: "Buy", percent: 0.65, color: Colors.green),
//                     const SizedBox(height: 8),
//                     RatingRow(label: "Hold", percent: 0.25, color: Colors.orange),
//                     const SizedBox(height: 8),
//                     RatingRow(label: "Sell", percent: 0.10, color: Colors.red),
//                     const SizedBox(height: 8),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: Text("Consensus: Moderate Buy",
//                           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
//                     )
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ===== Earnings =====
//               Text("Earnings", style: sectionTitle),
//               const SizedBox(height: 8),
//               SectionCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     SizedBox(
//                       height: 120,
//                       child: LineChart(
//                         LineChartData(
//                           gridData: FlGridData(show: false),
//                           titlesData: FlTitlesData(show: false),
//                           borderData: FlBorderData(show: false),
//                           lineBarsData: [
//                             LineChartBarData(
//                               spots: const [
//                                 FlSpot(0, 1.0),
//                                 FlSpot(1, 1.1),
//                                 FlSpot(2, 1.15),
//                                 FlSpot(3, 1.18)
//                               ],
//                               isCurved: true,
//                               color: Colors.black,
//                               barWidth: 2,
//                               dotData: FlDotData(show: false),
//                             ),
//                             LineChartBarData(
//                               spots: const [
//                                 FlSpot(0, 1.0),
//                                 FlSpot(1, 1.05),
//                                 FlSpot(2, 1.2),
//                                 FlSpot(3, 1.25)
//                               ],
//                               isCurved: true,
//                               color: Colors.grey,
//                               barWidth: 2,
//                               dotData: FlDotData(show: false),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: const [
//                         Text("Estimated EPS: \$1.20", style: TextStyle(color: Colors.black87)),
//                         Text("Actual EPS: \$1.25", style: TextStyle(color: Colors.black87)),
//                       ],
//                     )
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ===== Transactions (center card) =====
//               Text("Transactions", style: sectionTitle),
//               const SizedBox(height: 8),
//               SectionCard(
//                 child: Column(
//                   children: [
//                     // header row of table
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 8.0),
//                       child: Row(
//                         children: const [
//                           Expanded(flex: 3, child: Text("Trade", style: TextStyle(fontWeight: FontWeight.bold))),
//                           Expanded(flex: 2, child: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
//                           Expanded(flex: 2, child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
//                         ],
//                       ),
//                     ),
//                     const Divider(height: 1, color: Colors.grey),
//                     _transactionTableRow("MU Market Buy", "-\$72.77", "Apr 14, 2025"),
//                     const Divider(height: 1, color: Colors.grey),
//                     _transactionTableRow("MRVL Market Buy", "-\$53.53", "Apr 14, 2025"),
//                     const Divider(height: 1, color: Colors.grey),
//                     _transactionTableRow("AAPL Sell", "+\$1,200.00", "Jun 07, 2025"),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ===== Recommendation =====
//               Text("Recommendation", style: sectionTitle),
//               const SizedBox(height: 8),
//               SectionCard(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text(
//                       "Analyst note",
//                       style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       "We recommend a HOLD in the short term. Recent product announcements increase long-term visibility, "
//                       "but near-term macro uncertainty suggests accumulating on dips. Portfolio allocation: 3–5% "
//                       "of growth-oriented allocation; adjust to risk profile.",
//                       style: TextStyle(color: Colors.black87, height: 1.4),
//                     ),
//                     SizedBox(height: 12),
//                     Text(
//                       "Risk: Market volatility may cause short-term drawdowns. This is informational and not financial advice.",
//                       style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
//                     )
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // ===== News (pulled from your news service) =====
//               Text("Latest News", style: sectionTitle),
//               const SizedBox(height: 8),
//               if (loadingNews)
//                 const Center(child: Padding(
//                   padding: EdgeInsets.symmetric(vertical: 24.0),
//                   child: CircularProgressIndicator(),
//                 ))
//               else
//                 Column(
//                   children: articles.map((a) => NewsCard(article: a)).toList(),
//                 ),
//               const SizedBox(height: 32),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ===== small helpers / widgets used inside build =====

//   Widget _buildTopHeader() {
//     return Row(
//       children: [
//         // left column: symbol + name
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: const [
//               Text("AAPL", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
//               SizedBox(height: 6),
//               Text("Apple Inc.", style: TextStyle(fontSize: 15, color: Colors.black87)),
//             ],
//           ),
//         ),
//         // right column: small quick actions
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text("\$151.71", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
//             const SizedBox(height: 6),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Text("+5.33%", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
//             )
//           ],
//         )
//       ],
//     );
//   }

//   Widget _buildTimeframe() {
//     final times = ["1D", "1W", "1M", "3M", "YTD", "1Y", "5Y", "Max"];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: times.map((t) {
//         final bool active = selectedTime == t;
//         return Expanded(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 4.0),
//             child: OutlinedButton(
//               onPressed: () => setState(() => selectedTime = t),
//               style: OutlinedButton.styleFrom(
//                 backgroundColor: active ? Colors.black : Colors.grey.shade100,
//                 foregroundColor: active ? Colors.white : Colors.black,
//                 padding: const EdgeInsets.symmetric(vertical: 10),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               ),
//               child: Text(t, style: const TextStyle(fontSize: 12)),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _transactionTableRow(String title, String amount, String date) {
//     final bool positive = !amount.startsWith("-");
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4),
//       child: Row(
//         children: [
//           Expanded(flex: 3, child: Text(title, style: const TextStyle(color: Colors.black87))),
//           Expanded(flex: 2, child: Text(amount, style: TextStyle(color: positive ? Colors.green : Colors.red, fontWeight: FontWeight.w600))),
//           Expanded(flex: 2, child: Text(date, style: const TextStyle(color: Colors.black54))),
//         ],
//       ),
//     );
//   }
// }

// /// Thin wrapper card used across the screen for visual consistency.
// class SectionCard extends StatelessWidget {
//   final Widget child;
//   const SectionCard({Key? key, required this.child}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(_kCardRadius),
//         boxShadow: [
//           BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
//         ],
//         border: Border.all(color: Colors.grey.shade100),
//       ),
//       child: child,
//     );
//   }

//   static const double _kCardRadius = 16.0;
// }

// /// Small two-column label/value row for "About company".
// class InfoRow extends StatelessWidget {
//   final String left;
//   final String right;
//   const InfoRow({Key? key, required this.left, required this.right}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
//       child: Row(
//         children: [
//           Expanded(child: Text(left, style: const TextStyle(color: Colors.black87))),
//           Expanded(child: Text(right, textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87))),
//         ],
//       ),
//     );
//   }
// }

// /// Rating row widget
// class RatingRow extends StatelessWidget {
//   final String label;
//   final double percent;
//   final Color color;
//   const RatingRow({Key? key, required this.label, required this.percent, required this.color}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         SizedBox(width: 56, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
//         Expanded(
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(value: percent, color: color, backgroundColor: Colors.grey.shade200, minHeight: 10),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Text("${(percent * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.w600)),
//       ],
//     );
//   }
// }

// /// Small component to show price summary next to chart.
// class PriceSummary extends StatelessWidget {
//   final String price;
//   final String change;
//   final String pct;
//   const PriceSummary({Key? key, required this.price, required this.change, required this.pct}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//         const SizedBox(height: 6),
//         Row(children: [
//           Text(change, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
//           const SizedBox(width: 6),
//           Text(pct, style: const TextStyle(color: Colors.black54)),
//         ])
//       ],
//     );
//   }
// }

// /// News card that expects a map with title, url, urlToImage, publishedAt
// class NewsCard extends StatelessWidget {
//   final Map<String, dynamic> article;
//   const NewsCard({Key? key, required this.article}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final String title = (article["title"] ?? "Untitled").toString();
//     final String? image = article["urlToImage"] as String?;
//     final String? url = article["url"] as String?;
//     final String date = article["publishedAt"]?.toString() ?? "";

//     return GestureDetector(
//       onTap: () async {
//         if (url != null && url.isNotEmpty) {
//           final uri = Uri.tryParse(url);
//           if (uri != null && await canLaunchUrl(uri)) {
//             await launchUrl(uri, mode: LaunchMode.externalApplication);
//           }
//         }
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
//         ),
//         child: Row(
//           children: [
//             if (image != null && image.isNotEmpty)
//               ClipRRect(
//                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
//                 child: Image.network(image, height: 92, width: 120, fit: BoxFit.cover, errorBuilder: (c, e, s) => _imagePlaceholder()),
//               )
//             else
//               Container(width: 120, height: 92, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14))), child: _imagePlaceholder()),

//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black), maxLines: 3, overflow: TextOverflow.ellipsis),
//                     const SizedBox(height: 8),
//                     Text(date, style: const TextStyle(color: Colors.black54, fontSize: 12)),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _imagePlaceholder() {
//     return Center(child: Icon(Icons.newspaper, color: Colors.grey.shade400, size: 36));
//   }
// }

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:test_project/features/trading/buy.dart';
import 'package:test_project/features/trading/sell.dart';
import 'package:test_project/features/news/newsmail.dart';
import 'package:test_project/features/news/news.dart';
import 'package:test_project/features/notifications/notification.dart';
import 'package:test_project/features/wishlist/wishlist.dart';
import 'package:test_project/features/simulator/simulator.dart';
import 'package:test_project/features/notifications/alerts.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Tracker',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        primaryColor: Color.fromARGB(255, 112, 97, 243),
      ),
      home: StockDetailsPage(stockName: 'AAPL'),
    );
  }
}

// Candlestick data model
class CandlestickData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandlestickData({
    required this.time, 
    required this.open, 
    required this.high, 
    required this.low, 
    required this.close
  });
}

class StockDetailsPage extends StatefulWidget {
  final String stockName;

  StockDetailsPage({required this.stockName});

  @override
  _StockDetailsPageState createState() => _StockDetailsPageState();
}

class _StockDetailsPageState extends State<StockDetailsPage> {
  List<dynamic> newsData = [];
  final String apiKey = 'CF7H37OIS5NWDTN3';

  // ── Time Range ────────────────────────────────────────────
  String _selectedTimeRange = '1D';

  // ── Rate Limit Flag ──────────────────────────────────────
  bool _apiRateLimited = false;
  
  List<FlSpot> earningsData = [
    FlSpot(1, 2.5), FlSpot(2, 3.0), FlSpot(3, 3.5), FlSpot(4, 4.2),
    FlSpot(5, 4.8), FlSpot(6, 5.1), FlSpot(7, 5.5), FlSpot(8, 6.0),
  ];

  List<FlSpot> quarterlyEarningsData = [
    FlSpot(1, 2.0), FlSpot(2, 2.8), FlSpot(3, 3.2), FlSpot(4, 3.6),
    FlSpot(5, 4.0), FlSpot(6, 4.3), FlSpot(7, 4.7), FlSpot(8, 5.2),
  ];

  List<FlSpot> stockData = [
    FlSpot(1, 150), FlSpot(2, 155), FlSpot(3, 160), FlSpot(4, 165),
    FlSpot(5, 170), FlSpot(6, 175), FlSpot(7, 180), FlSpot(8, 190),
  ];

  List<FlSpot> returnOnEquityData = [
    FlSpot(1, 12.5), FlSpot(2, 13.0), FlSpot(3, 14.2), FlSpot(4, 15.5),
    FlSpot(5, 16.0), FlSpot(6, 16.8), FlSpot(7, 17.5), FlSpot(8, 18.0),
  ];

  List<FlSpot> debtEquityRatioData = [
    FlSpot(1, 1.2), FlSpot(2, 1.4), FlSpot(3, 1.3), FlSpot(4, 1.5),
    FlSpot(5, 1.6), FlSpot(6, 1.8), FlSpot(7, 1.7), FlSpot(8, 1.9),
  ];

  List<FlSpot> netProfitMarginData = [
    FlSpot(1, 8.0), FlSpot(2, 8.5), FlSpot(3, 9.0), FlSpot(4, 9.8),
    FlSpot(5, 10.5), FlSpot(6, 11.0), FlSpot(7, 11.8), FlSpot(8, 12.5),
  ];

  bool isLoading = true;
  double? selectedSpotX;

  // ── Per-range stock data (populated on fetch or with fallbacks) ──
  Map<String, List<FlSpot>> _rangedStockData = {};

  List<FlSpot> get _activeStockData =>
      _rangedStockData[_selectedTimeRange] ?? stockData;

  @override
  void initState() {
    super.initState();
    _buildRangedData(); // generate fallback dummy data immediately
    fetchStockAndEarningsData();
    fetchNews();
  }

  Future<void> fetchStockAndEarningsData() async {
    final String symbol = widget.stockName;
    final String earningsUrl =
        'https://www.alphavantage.co/query?function=EARNINGS&symbol=$symbol&apikey=$apiKey';
    final String stockUrl =
        'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$apiKey';

    try {
      final earningsResponse = await http.get(Uri.parse(earningsUrl));
      final stockResponse = await http.get(Uri.parse(stockUrl));

      if (earningsResponse.statusCode == 200 && stockResponse.statusCode == 200) {
        final Map<String, dynamic> earningsDataJson = json.decode(earningsResponse.body);
        final Map<String, dynamic> stockDataJson = json.decode(stockResponse.body);

        // ── Check for API rate limit (Alpha Vantage returns a "Note" key) ──
        if (stockDataJson.containsKey('Note') ||
            stockDataJson.containsKey('Information') ||
            earningsDataJson.containsKey('Note') ||
            earningsDataJson.containsKey('Information')) {
          print('⚠️ Alpha Vantage API rate limit reached. Using fallback data.');
          setState(() {
            _apiRateLimited = true;
            isLoading = false;
          });
          return; // keep default fallback data
        }

        final annualEarnings = earningsDataJson['annualEarnings'];
        final quarterlyEarnings = earningsDataJson['quarterlyEarnings'];
        final timeSeries = stockDataJson['Time Series (Daily)'];

        // ── Guard against null / missing keys ─────────────────────
        if (annualEarnings == null || quarterlyEarnings == null || timeSeries == null) {
          print('⚠️ Unexpected API response shape. Using fallback data.');
          setState(() {
            _apiRateLimited = true;
            isLoading = false;
          });
          return;
        }

        List<FlSpot> tempAnnualData = [];
        List<FlSpot> tempQuarterlyData = [];
        List<FlSpot> tempStockData = [];

        int annualIndex = 0;
        int quarterlyIndex = 0;
        int stockIndex = 0;

        for (var entry in (annualEarnings as List).reversed) {
          final epsStr = entry['reportedEPS'];
          if (epsStr == null || epsStr == 'None') continue;
          double eps = double.tryParse(epsStr.toString()) ?? 0;
          tempAnnualData.add(FlSpot(annualIndex.toDouble(), eps));
          annualIndex++;
        }

        for (var entry in (quarterlyEarnings as List).reversed) {
          final epsStr = entry['reportedEPS'];
          if (epsStr == null || epsStr == 'None') continue;
          double eps = double.tryParse(epsStr.toString()) ?? 0;
          tempQuarterlyData.add(FlSpot(quarterlyIndex.toDouble(), eps));
          quarterlyIndex++;
        }

        (timeSeries as Map<String, dynamic>).forEach((date, values) {
          double closePrice = double.tryParse(values['4. close']?.toString() ?? '0') ?? 0;
          if (closePrice > 0) {
            tempStockData.add(FlSpot(stockIndex.toDouble(), closePrice));
            stockIndex++;
          }
        });

        setState(() {
          if (tempAnnualData.isNotEmpty) earningsData = tempAnnualData;
          if (tempQuarterlyData.isNotEmpty) quarterlyEarningsData = tempQuarterlyData;
          if (tempStockData.isNotEmpty) stockData = tempStockData.reversed.toList();
          _apiRateLimited = false;
          _buildRangedData(); // populate all time-range variants
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load stock or earnings data (HTTP ${stockResponse.statusCode})');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _apiRateLimited = true;
        _buildRangedData();
        isLoading = false;
      });
    }
  }

  // ── Build realistic dummy data for each time range ──────────
  void _buildRangedData() {
    final base = stockData;
    final lastPrice = base.isNotEmpty ? base.last.y : 190.0;

    _rangedStockData = {
      '1D': base,
      '5D': _generateSmoothData(lastPrice, 40, 0.003, 1),
      '1M': _generateSmoothData(lastPrice, 30, 0.005, 2),
      '6M': _generateSmoothData(lastPrice, 130, 0.006, 3),
      'YTD': _generateSmoothData(lastPrice, 100, 0.007, 4),
      '1Y': _generateSmoothData(lastPrice, 252, 0.008, 5),
      '5Y': _generateSmoothData(lastPrice, 300, 0.010, 6),
      'MAX': _generateSmoothData(lastPrice, 350, 0.012, 7),
    };
  }

  /// Generate a smooth, realistic price series ending near [endPrice].
  ///
  /// Uses a seeded random walk + exponential moving average smoothing
  /// so the output looks like a genuine stock chart (gentle curves,
  /// occasional trends) instead of a jagged sawtooth.
  List<FlSpot> _generateSmoothData(
      double endPrice, int points, double stepVol, int seed) {
    final rng = Random(seed + endPrice.truncate());

    // 1. Walk forward from a lower/higher starting price
    //    with small random steps that have slight upward drift.
    final double startPrice = endPrice * (0.70 + rng.nextDouble() * 0.20);
    final List<double> raw = List.filled(points, startPrice);

    // Drift per step so we end roughly at endPrice
    final double drift = (endPrice - startPrice) / points;

    for (int i = 1; i < points; i++) {
      final double noise = (rng.nextDouble() - 0.48) * stepVol * raw[i - 1];
      raw[i] = raw[i - 1] + drift + noise;
      if (raw[i] < 1) raw[i] = 1; // floor at $1
    }

    // 2. Apply EMA smoothing (alpha = 0.15) to remove jitter
    const double alpha = 0.15;
    final List<double> smooth = List.filled(points, raw[0]);
    for (int i = 1; i < points; i++) {
      smooth[i] = alpha * raw[i] + (1 - alpha) * smooth[i - 1];
    }

    // 3. Rescale so the last value matches endPrice exactly
    final double scaleFactor =
        smooth.last != 0 ? endPrice / smooth.last : 1.0;

    return List.generate(
      points,
      (i) => FlSpot(i.toDouble(), smooth[i] * scaleFactor),
    );
  }

  void _onTimeRangeChanged(String range) {
    setState(() {
      _selectedTimeRange = range;
    });
  }

  Widget _buildVerticalNewsList(BuildContext context) {
    return Container(
      child: newsData.isEmpty
          ? Center(
              child: CircularProgressIndicator(
                color: const Color.fromARGB(255, 102, 38, 185),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.grey.shade300,
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
                                    color: Colors.grey.shade600,
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
                color: const Color.fromARGB(255, 102, 38, 185),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                color: const Color.fromARGB(255, 102, 38, 185),
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
  }Widget _buildSectionHeadernews(String title) {
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Spacer(),
          Text(
            'View All',
            style: TextStyle(
              fontSize: 14,
                color: const Color.fromARGB(255, 112, 97, 243),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 4),
          Icon(
            Icons.arrow_forward,
            color: Color.fromARGB(255, 112, 97, 243),
            size: 16,
          ),
        ],
      ),
    ),
  );
}

  void _showNewsDetail(Map<String, dynamic> newsItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            newsItem["title"] ?? "News Detail",
            style: TextStyle(color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                newsItem["summary"] ?? "No Summary Available",
                style: TextStyle(color: Colors.black87),
              ),
              SizedBox(height: 10),
              Text(
                "Sentiment Score: ${newsItem["sentiment_score"]}",
                style: TextStyle(color: Colors.black87),
              ),
              SizedBox(height: 10),
              newsItem["url"] != null
                  ? TextButton(
                      onPressed: () {
                        // Implement URL opening (e.g., using url_launcher package)
                      },
                      child: Text("Read More", style: TextStyle(color: Color.fromARGB(255, 112, 97, 243))),
                    )
                  : Container(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: Color.fromARGB(255, 112, 97, 243))),
            ),
          ],
        );
      },
    );
  }
// Performance metrics data
  final Map<String, dynamic> _performanceData = {
    'currentPrice': 225.50,
    'dayChange': 5.50,
    'percentageChange': 2.5,
    'marketCap': 3540000000000.0,
    'volume': 25000000.0,
    'peRatio': 28.5,
    'dividendYield': 0.6,
  };

  Future<void> fetchNews() async {
    final url = Uri.parse(
        "https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=AAPL&apikey=$apiKey");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        newsData = data["feed"] ?? [];
      });
    } else {
      print("Failed to load news");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  // title: Text(
  //   widget.stockName,
  //   style: TextStyle(color: Colors.black),
  // ),
  backgroundColor: Colors.white,
  elevation: 1,
  iconTheme: IconThemeData(color: Colors.black),

  actions: [


    IconButton(
  onPressed: () {
    // Navigate to TradingDashboard page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TradingDashboard(),
      ),
    );
  },
  icon: CircleAvatar(
    backgroundColor: Color.fromARGB(255, 112, 97, 243), // Purple circular background
    radius: 12, // Adjust circle size
    child: Icon(
      Icons.add,
      color: Colors.white, // Icon color inside the circle
      size: 14,
    ),
  ),
),

Stack(
  children: [
    IconButton(
      icon: Image.asset(
        'assets/Frame.png',
        width: 24,
        height: 24,
        fit: BoxFit.cover,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockAlertsScreen()),
        );
      },
    ),
    Positioned(
      right: 2,
      top: 0,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          '2',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  ],
),
  ],
),

      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 112, 97, 243)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Rate Limit Banner ────────────────────────────────
                  if (_apiRateLimited)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'API rate limit reached — showing sample data. Refresh in a minute.',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() => isLoading = true);
                            fetchStockAndEarningsData();
                          },
                          child: Icon(Icons.refresh, color: Colors.orange.shade700, size: 18),
                        ),
                      ]),
                    ),

                  StockGraph(
                    stockData: _activeStockData,
                    stockName: widget.stockName,
                  ),
                  SizedBox(height: 16),
                  TimeRangeSelector(
                    selectedRange: _selectedTimeRange,
                    onRangeChanged: _onTimeRangeChanged,
                  ),
                  SizedBox(height: 24),
                    PerformanceMetrics(
              currentPrice: _performanceData['currentPrice'],
              dayChange: _performanceData['dayChange'],
              percentageChange: _performanceData['percentageChange'],
              marketCap: _performanceData['marketCap'],
              volume: _performanceData['volume'],
              peRatio: _performanceData['peRatio'],
              dividendYield: _performanceData['dividendYield'],
            ),
            SizedBox(height: 24),
                  ExpertsRatingSection(),
                  SizedBox(height: 24), // Increased spacing
                  FinancialSection(
                    earningsData: earningsData,
                    quarterlyEarningsData: quarterlyEarningsData,
                    stockData: stockData,
                    returnOnEquityData: returnOnEquityData,
                    debtEquityRatioData: debtEquityRatioData,
                    netProfitMarginData: netProfitMarginData,
                  ),
           //       SizedBox(height: 24), // Increased spacing
           //       CompanySellHistorySection(),
                  // SizedBox(height: 24), // Increased spacing
                  // _buildRecommendationsSection(),
                  SizedBox(height: 24), // Increased spacing
                  _buildSectionHeadernews('Latest News'),
                  _buildVerticalNewsList(context),
                  SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: TradeButtons(),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRecommendationCard(
                'NFLX',
                'Netflix, Inc',
                '2,122.340',
                '-0.201%',
                Colors.red,
                false,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildRecommendationCard(
                'META',
                'Meta Platforms',
                '987.890',
                '+1.29%',
                Colors.blue,
                true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildRecommendationCard(
                'AMZN',
                'Amazon.com, Inc',
                '1,001.333',
                '-8.20%',
                Colors.orange,
                false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    String symbol,
    String name,
    String price,
    String change,
    Color tagColor,
    bool isPositive,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              symbol,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


class StockGraph extends StatefulWidget {
  final List<FlSpot> stockData;
  final String stockName;

  StockGraph({
    required this.stockData,
    required this.stockName,
  });

  @override
  _StockGraphState createState() => _StockGraphState();
}

class _StockGraphState extends State<StockGraph> {
  double selectedValue = 0;
  String selectedTime = "";
  double? touchX;
  double? touchY;
  bool showCandlestick = false;
  
  double zoomLevel = 1.0;
  double panOffset = 0.0;
  double maxZoom = 3.0;
  bool isZooming = false;
  
  CandlestickData? selectedCandlestick;
  double? selectedSpotX;

  @override
  void initState() {
    super.initState();
    if (widget.stockData.isNotEmpty) {
      selectedValue = widget.stockData.last.y;
    }
  }

  // ✅ Reset state when parent passes new stockData (time range change)
  @override
  void didUpdateWidget(covariant StockGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stockData != widget.stockData) {
      setState(() {
        selectedValue = widget.stockData.isNotEmpty ? widget.stockData.last.y : 0;
        selectedTime = "";
        touchX = null;
        touchY = null;
        selectedSpotX = null;
        selectedCandlestick = null;
        zoomLevel = 1.0;
        panOffset = 0.0;
      });
    }
  }

  // Fixed time formatting functions
  String getFormattedTime(double x) {
    final times = [
      "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
      "12:00 PM", "12:30 PM", "1:00 PM", "1:30 PM", "2:00 PM",
      "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM"
    ];
    int index = x.toInt().clamp(0, times.length - 1);
    return times[index];
  }

  String getFormattedDate(DateTime date) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String getFormattedTimeFromData(double x) {
    // Convert x index to a meaningful time format
    int index = x.toInt();
    if (index >= 0 && index < widget.stockData.length) {
      // For demonstration, create time stamps based on index
      DateTime baseTime = DateTime.now().subtract(Duration(days: widget.stockData.length - index - 1));
      return getFormattedDate(baseTime);
    }
    return getFormattedTime(x);
  }

  double calculateDayChange(double currentValue) {
    if (widget.stockData.isEmpty) return 0;
    return currentValue - widget.stockData.first.y;
  }

  double calculatePercentageChange(double currentValue) {
    if (widget.stockData.isEmpty || widget.stockData.first.y == 0) return 0;
    return ((currentValue - widget.stockData.first.y) / widget.stockData.first.y) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final dayChange = calculateDayChange(selectedValue);
    final percentageChange = calculatePercentageChange(selectedValue);
    final isPositive = dayChange >= 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.shade200,
        //     blurRadius: 8,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.stockName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              // Controls section
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.zoom_in, color: Colors.grey.shade600),
                    onPressed: () {
                      setState(() {
                        if (zoomLevel < maxZoom) {
                          zoomLevel += 0.5;
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.zoom_out, color: Colors.grey.shade600),
                    onPressed: () {
                      setState(() {
                        if (zoomLevel > 1.0) {
                          zoomLevel -= 0.5;
                        } else {
                          zoomLevel = 1.0;
                          panOffset = 0.0;
                        }
                      });
                    },
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        showCandlestick = !showCandlestick;
                        // Reset touch state when switching modes
                        selectedTime = "";
                        touchX = null;
                        touchY = null;
                        selectedCandlestick = null;
                      });
                    },
                    icon: Icon(
                      showCandlestick ? Icons.show_chart : Icons.candlestick_chart,
                      color: Colors.grey.shade600,
                    ),
                    label: Text(
                      showCandlestick ? 'Line' : 'Candlestick',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Price display
          Text(
            '\$${selectedValue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          
          // Performance indicators
          Container(
            child: Text(
              '${isPositive ? "+" : ""}\$${dayChange.toStringAsFixed(2)} (${isPositive ? "+" : ""}${percentageChange.toStringAsFixed(1)}%)',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Chart section with proper touch handling
          GestureDetector(
            onHorizontalDragStart: (details) {
              setState(() {
                isZooming = true;
              });
            },
            onHorizontalDragUpdate: (details) {
              if (zoomLevel > 1.0) {
                setState(() {
                  panOffset += details.delta.dx;
                  double maxPan = (widget.stockData.length * (zoomLevel - 1)).clamp(0.0, double.infinity);
                  panOffset = panOffset.clamp(-maxPan, 0.0);
                });
              }
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                isZooming = false;
              });
            },
            child: Stack(
  children: [
    // ==== CHART AREA ====
    Container(
      padding: EdgeInsets.all(16),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: showCandlestick
          ? _buildCandlestickChart(isPositive)
          : _buildLineChart(isPositive),
    ),

    // ==== TOP FIXED TIMESTAMP ====
    if (touchX != null && selectedTime.isNotEmpty)
      Positioned(
        top: 6,
        left: (touchX! - 60)
            .clamp(0.0, MediaQuery.of(context).size.width - 120),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            selectedTime,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

    // ==== CANDLESTICK INFO (ONLY WHEN ENABLED) ====
    if (selectedCandlestick != null && showCandlestick && touchX != null)
      Positioned(
        top: 36,
        left: (touchX! - 60)
            .clamp(0.0, MediaQuery.of(context).size.width - 120),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 120),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("O: \$${selectedCandlestick!.open.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 11)),
              Text("H: \$${selectedCandlestick!.high.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 11)),
              Text("L: \$${selectedCandlestick!.low.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 11)),
              Text("C: \$${selectedCandlestick!.close.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),

    // ==== ZOOM LABEL ====
    if (zoomLevel > 1.0)
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            "${zoomLevel.toStringAsFixed(1)}x",
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
      ),
  ],
),

          ),
        ],
      ),
    );
  }
Widget _buildLineChart(bool isPositive) {
  List<FlSpot> visibleData = [];
  if (zoomLevel > 1.0) {
    int totalPoints = widget.stockData.length;
    int visiblePoints = (totalPoints / zoomLevel).floor();
    
    int startIndex = (panOffset / zoomLevel).abs().floor();
    startIndex = startIndex.clamp(0, totalPoints - visiblePoints);
    
    List<FlSpot> zoomedData = widget.stockData.sublist(
      startIndex, 
      (startIndex + visiblePoints).clamp(0, totalPoints)
    );
    
    for (int i = 0; i < zoomedData.length; i++) {
      visibleData.add(FlSpot(i.toDouble(), zoomedData[i].y));
    }
  } else {
    visibleData = widget.stockData;
  }

  // ── Dynamic color: selected point vs first price ────────────
  // When user touches a point, compare that point to the first
  // price. If they haven't touched anything, compare last vs first.
  double firstValue = visibleData.isNotEmpty ? visibleData.first.y : 0;
  double comparisonValue = selectedValue; // changes on touch
  bool isCurrentPositive = comparisonValue >= firstValue;

  Color lineColor = isCurrentPositive ? Colors.green : Colors.red;
  Color gradientStartColor = lineColor.withOpacity(0.3);
  Color gradientMiddleColor = lineColor.withOpacity(0.1);
  Color gradientEndColor = lineColor.withOpacity(0.0);

  return LineChart(
    LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.shade300,
          strokeWidth: 0.5,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: visibleData,
          isCurved: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                gradientStartColor,
                gradientMiddleColor,
                gradientEndColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          dotData: FlDotData(show: false),
        ),
      ],
      lineTouchData: _getLineTouchData(),

      extraLinesData: ExtraLinesData(
        verticalLines: touchX == null
            ? []
            : [
                VerticalLine(
                  x: selectedSpotX ?? 0,
                  color: isCurrentPositive ? Colors.green : Colors.red,
                  strokeWidth: 3,
                  dashArray: [6, 4],
                ),
              ],
      ),
    ),
  );
}
  Widget _buildCandlestickChart(bool isPositive) {
    List<CandlestickData> candlestickData = [];
    
    if (widget.stockData.isNotEmpty) {
      for (int i = 0; i < widget.stockData.length; i++) {
        final value = widget.stockData[i].y;
        final open = value * (1 - 0.005 * (i % 3 == 0 ? 1 : -1));
        final close = value * (1 + 0.003 * (i % 2 == 0 ? 1 : -1));
        final high = value * (1 + 0.01);
        final low = value * (1 - 0.01);
        
        candlestickData.add(CandlestickData(
          time: DateTime.now().subtract(Duration(days: widget.stockData.length - i - 1)),
          open: open,
          high: high,
          low: low,
          close: close,
        ));
      }
    }
    
    List<CandlestickData> visibleCandlesticks = [];
    if (zoomLevel > 1.0) {
      int totalPoints = candlestickData.length;
      int visiblePoints = (totalPoints / zoomLevel).floor();
      
      int startIndex = (panOffset / zoomLevel).abs().floor();
      startIndex = startIndex.clamp(0, totalPoints - visiblePoints);
      
      visibleCandlesticks = candlestickData.sublist(
        startIndex, 
        (startIndex + visiblePoints).clamp(0, totalPoints)
      );
    } else {
      visibleCandlesticks = candlestickData;
    }

    return GestureDetector(
      onTapDown: (details) {
        _handleCandlestickTap(details.localPosition, visibleCandlesticks);
      },
      onPanUpdate: (details) {
        _handleCandlestickTap(details.localPosition, visibleCandlesticks);
      },
      onPanEnd: (details) {
        // Don't clear immediately on pan end for candlestick
      },
      child: Container(
        height: 220,
        child: CustomPaint(
          size: Size.infinite,
          painter: CandlestickPainter(
            candlestickData: visibleCandlesticks,
            textColor: const Color.fromARGB(221, 236, 230, 230),
            onCandlestickSelected: (candlestick, x, y) {
              setState(() {
                selectedCandlestick = candlestick;
                selectedValue = candlestick.close;
                selectedTime = getFormattedDate(candlestick.time);
                touchX = x;
                touchY = y;
              });
            },
          ),
        ),
      ),
    );
  }

  void _handleCandlestickTap(Offset localPosition, List<CandlestickData> candlesticks) {
    if (candlesticks.isEmpty) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final containerWidth = renderBox.size.width - 32; // Account for padding
    final candleWidth = containerWidth / candlesticks.length;
    
    int index = (localPosition.dx / candleWidth).floor();
    if (index >= 0 && index < candlesticks.length) {
      CandlestickData tapped = candlesticks[index];
      setState(() {
        selectedCandlestick = tapped;
        selectedValue = tapped.close;
        selectedTime = getFormattedDate(tapped.time);
        touchX = localPosition.dx;
        touchY = localPosition.dy;
      });
    }
  }

  LineTouchData _getLineTouchData() {
  return LineTouchData(
    enabled: true,
    handleBuiltInTouches: true,
  touchSpotThreshold: 10,
    touchTooltipData: LineTouchTooltipData(
      getTooltipItems: (_) => [],
      getTooltipColor: (spot) => Colors.transparent,
    ),

    getTouchedSpotIndicator: (barData, indexes) {
      return indexes.map((i) {
        return TouchedSpotIndicatorData(
          FlLine(
            color: Colors.transparent, // hide default short vertical line
          ),
          FlDotData(
            show: false,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: Colors.black,
                strokeWidth: 3,
                strokeColor: Colors.white,
              );
            },
          ),
        );
      }).toList();
    },

   touchCallback: (event, response) {
  // ON MOVE / TAP DOWN → update instantly
  if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
    final spot = response.lineBarSpots!.first;
    setState(() {
      selectedValue = spot.y;
      selectedTime = getFormattedTimeFromData(spot.x);
      touchX = event.localPosition?.dx;
      selectedSpotX = spot.x;
    });
  }

  // ON RELEASE → clear instantly, no delay
  if (event is FlPanEndEvent || event is FlTapUpEvent) {
    setState(() {
      selectedSpotX = null;
      touchX = null;
      selectedTime = "";
    });
  }
}

  );
}
}




class CandlestickPainter extends CustomPainter {
  final List<CandlestickData> candlestickData;
  final Color textColor;
  final Function(CandlestickData, double, double)? onCandlestickSelected;
  late Size _size;
  
  CandlestickPainter({
    required this.candlestickData,
    required this.textColor,
    this.onCandlestickSelected,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    _size = size;
    
    if (candlestickData.isEmpty) return;
    
    final double width = size.width;
    final double height = size.height;
    final int dataLength = candlestickData.length;
    
    double minPrice = double.infinity;
    double maxPrice = -double.infinity;
    
    for (var data in candlestickData) {
      if (data.low < minPrice) minPrice = data.low;
      if (data.high > maxPrice) maxPrice = data.high;
    }
    
    final padding = (maxPrice - minPrice) * 0.1;
    minPrice -= padding;
    maxPrice += padding;
    
    final double verticalScale = height / (maxPrice - minPrice);
    final double candleWidth = width / dataLength * 0.8;
    final double spacing = width / dataLength * 0.2 / 2;
    
    double priceToY(double price) => height - (price - minPrice) * verticalScale;
    
    // Draw grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;
      
    int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      double y = height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    
    // Draw candlesticks
    for (int i = 0; i < dataLength; i++) {
      final data = candlestickData[i];
      final bool isBullish = data.close >= data.open;
      final Color candleColor = isBullish ? Colors.green : Colors.red;
      
      final double x = i * (candleWidth + spacing * 2) + spacing;
      final double openY = priceToY(data.open);
      final double closeY = priceToY(data.close);
      final double highY = priceToY(data.high);
      final double lowY = priceToY(data.low);
      
      // Draw wick
      final Paint wickPaint = Paint()
        ..color = candleColor
        ..strokeWidth = 1.5;
      
      canvas.drawLine(
        Offset(x + candleWidth / 2, highY),
        Offset(x + candleWidth / 2, lowY),
        wickPaint,
      );
      
      // Draw body
      final Paint bodyPaint = Paint()
        ..color = candleColor
        ..style = PaintingStyle.fill;
      
      final bodyRect = Rect.fromLTRB(
        x,
        isBullish ? closeY : openY,
        x + candleWidth,
        isBullish ? openY : closeY,
      );
      
      canvas.drawRect(bodyRect, bodyPaint);
      
      // Add subtle border for better visibility
      final Paint borderPaint = Paint()
        ..color = candleColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
        
      canvas.drawRect(bodyRect, borderPaint);
    }
    
    // Draw price labels
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    
    textPainter.text = TextSpan(
      text: '\${maxPrice.toStringAsFixed(2)}',
      style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, 0));
    
    textPainter.text = TextSpan(
      text: '\${minPrice.toStringAsFixed(2)}',
      style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, height - textPainter.height));
    
    double middlePrice = (maxPrice + minPrice) / 2;
    textPainter.text = TextSpan(
      text: '\${middlePrice.toStringAsFixed(2)}',
      style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, height / 2 - textPainter.height / 2));
  }
  
  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) => 
    oldDelegate.candlestickData != candlestickData;
    
  @override
  bool? hitTest(Offset position) {
    if (candlestickData.isEmpty) return null;
    
    final double width = _size.width;
    final int dataLength = candlestickData.length;
    final double candleWidth = width / dataLength * 0.8;
    final double spacing = width / dataLength * 0.2 / 2;
    
    for (int i = 0; i < dataLength; i++) {
      final data = candlestickData[i];
      final double x = i * (candleWidth + spacing * 2) + spacing;
      
      if (position.dx >= x && position.dx <= x + candleWidth) {
        if (onCandlestickSelected != null) {
          onCandlestickSelected!(data, position.dx, position.dy);
        }
        return true;
      }
    }
    
    return null;
  }
}










class TimeRangeSelector extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  const TimeRangeSelector({
    Key? key,
    required this.selectedRange,
    required this.onRangeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ["1D", "5D", "1M", "6M", "YTD", "1Y", "5Y", "MAX"].map((label) {
            bool isSelected = selectedRange == label;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextButton(
                onPressed: () => onRangeChanged(label),
                style: TextButton.styleFrom(
                  backgroundColor: isSelected ? Colors.green : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class TradeButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Expanded(
        //   child: ElevatedButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => SellPage()),
        //       );
        //     },
        //     child: Text("SELL 140.23", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.red,
        //       padding: EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //     ),
        //   ),
        // ),
        // SizedBox(width: 16),
        // Expanded(
        //   child: ElevatedButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => BuyPage()),
        //       );
        //     },
        //     child: Text("BUY 140.13", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Colors.green,
        //       padding: EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

// Performance and Key Statistics Section - UPDATED DESIGN
class PerformanceMetrics extends StatelessWidget {
  final double currentPrice;
  final double dayChange;
  final double percentageChange;
  final double marketCap;
  final double volume;
  final double peRatio;
  final double dividendYield;

  const PerformanceMetrics({
    Key? key,
    required this.currentPrice,
    required this.dayChange,
    required this.percentageChange,
    required this.marketCap,
    required this.volume,
    required this.peRatio,
    required this.dividendYield,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPositive = dayChange >= 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.shade200,
        //     blurRadius: 4,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance & Key Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
         
          
          // Main Price and Change - Updated with black border
          // Container(
          //   padding: EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.black, width: 1),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Column(
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Text(
          //             'Current Price',
          //             style: TextStyle(
          //               fontSize: 14,
          //               color: Colors.grey.shade600,
          //             ),
          //           ),
          //           SizedBox(height: 4),
          //           Text(
          //             '\$${currentPrice.toStringAsFixed(2)}',
          //             style: TextStyle(
          //               fontSize: 24,
          //               fontWeight: FontWeight.bold,
          //               color: Colors.black,
          //             ),
          //           ),
          //         ],
          //       ),
          //       Column(
          //         crossAxisAlignment: CrossAxisAlignment.end,
          //         children: [
          //           Text(
          //             'Today\'s Change',
          //             style: TextStyle(
          //               fontSize: 14,
          //               color: Colors.grey.shade600,
          //             ),
          //           ),
          //           SizedBox(height: 4),
          //           Text(
          //             '${isPositive ? "+" : ""}\$${dayChange.toStringAsFixed(2)} (${isPositive ? "+" : ""}${percentageChange.toStringAsFixed(2)}%)',
          //             style: TextStyle(
          //               fontSize: 18,
          //               fontWeight: FontWeight.bold,
          //               color: isPositive ? Colors.green : Colors.red,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          // SizedBox(height: 20),
          
          // Performance Overview Section - UPDATED DESIGN
           Container(
          //   padding: EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     color: Colors.white,
          //  //   borderRadius: BorderRadius.circular(16),
          //    // border: Border.all(color: Colors.black, width: 1),
          //     // boxShadow: [
          //     //   BoxShadow(
          //     //     color: Colors.grey.shade200,
          //     //     blurRadius: 8,
          //     //     offset: Offset(0, 2),
          //     //   ),
          //     // ],
          //   ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                // 1st: Volume & Avg Volume
                _buildPerformanceRow("Volume", "1001", "AVG Volume", "167.58M"),
                Divider(color: Colors.grey.shade300, height: 24),
                // 2nd: Open & Previous Close
                _buildPerformanceRow("Open", "188.01", "Prev. Close", "Rp4,600.00"),
                Divider(color: Colors.grey.shade300, height: 24),
                // 3rd: RVOL (Relative Volume)
                _buildPerformanceRow("RVOL", "-", "Relative Volume", "-"),
                Divider(color: Colors.grey.shade300, height: 24),
                // 4th: Today's High & Low
                _buildPerformanceRow("Today's Low", "188.51", "Today's High", "189.51"),
                Divider(color: Colors.grey.shade300, height: 24),
                // 5th: 52 Week Low & High
                _buildPerformanceRow("52 Week Low", "168.21", "52 Week High", "189.51"),
                Divider(color: Colors.grey.shade300, height: 24),
                // Day Range
                _buildPerformanceRow("Day Range", "Rp4,560.00", "Year Range", "Rp3,960.00"),
                Divider(color: Colors.grey.shade300, height: 24),
                // Market Cap & P/E Ratio
                _buildPerformanceRow("Market Cap", "694.707 IDR", "P/E Ratio", "15.50"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label1, String value1, String label2, String value2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1, 
                  style: TextStyle(
                    color: Colors.grey.shade600, 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )
                ),
                SizedBox(height: 4),
                Text(
                  value1, 
                  style: TextStyle(
                    color: Colors.black, 
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label2, 
                  style: TextStyle(
                    color: Colors.grey.shade600, 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )
                ),
                SizedBox(height: 4),
                Text(
                  value2, 
                  style: TextStyle(
                    color: Colors.black, 
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }
}








class ExpertsRatingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.shade200,
        //     blurRadius: 8,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Experts rating", 
            style: TextStyle(
              color: Colors.black, 
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )
          ),
          SizedBox(height: 20),
          _buildRatingBar("Buy", 83.0, Colors.green),
          SizedBox(height: 16),
          _buildRatingBar("Hold", 0.02, Colors.orange),
          SizedBox(height: 16),
          _buildRatingBar("Sell", 17.08, Colors.red),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double percentage, Color color) {
    return Row(
      children: [
        Container(
          width: 60,
          child: Text(
            label, 
            style: TextStyle(
              color: Colors.grey.shade700, 
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Container(
          width: 50,
          child: Text(
            "${percentage.toStringAsFixed(1)}%", 
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.black, 
              fontSize: 14,
              fontWeight: FontWeight.bold,
            )
          ),
        ),
      ],
    );
  }
}

class FinancialSection extends StatelessWidget {
  final List<FlSpot> earningsData;
  final List<FlSpot> quarterlyEarningsData;
  final List<FlSpot> stockData;
  final List<FlSpot> returnOnEquityData;
  final List<FlSpot> debtEquityRatioData;
  final List<FlSpot> netProfitMarginData;

  FinancialSection({
    required this.earningsData,
    required this.quarterlyEarningsData,
    required this.stockData,
    required this.returnOnEquityData,
    required this.debtEquityRatioData,
    required this.netProfitMarginData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.grey.shade200,
        //     blurRadius: 8,
        //     offset: Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Financial Overview", 
            style: TextStyle(
              color: Colors.black, 
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )
          ),
          SizedBox(height: 20),
          _buildFinancialChart(),
          SizedBox(height: 20),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildFinancialChart() {
    return _buildMetricChart("Earnings & Stock Prices", [
      LineChartBarData(
        spots: earningsData, 
        color: Colors.green,
        barWidth: 2,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: quarterlyEarningsData, 
        color: Colors.green,
        barWidth: 2,
        dotData: FlDotData(show: false),
      ),
      LineChartBarData(
        spots: stockData, 
        color: Colors.green,
        barWidth: 2,
        dotData: FlDotData(show: false),
      ),
    ]);
  }

  Widget _buildPerformanceMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetricChart("Return on Equity (ROE) %", [
          LineChartBarData(
            spots: returnOnEquityData, 
            color: Colors.orange,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ]),
        SizedBox(height: 20),
        _buildMetricChart("Debt/Equity Ratio", [
          LineChartBarData(
            spots: debtEquityRatioData, 
            color: Color.fromARGB(255, 112, 97, 243),
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ]),
        SizedBox(height: 20),
        _buildMetricChart("Net Profit Margin (QoQ) %", [
          LineChartBarData(
            spots: netProfitMarginData, 
            color: Colors.teal,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ]),
      ],
    );
  }

  Widget _buildMetricChart(String title, List<LineChartBarData> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: TextStyle(
            color: Colors.grey.shade700, 
            fontSize: 16,
            fontWeight: FontWeight.w600,
          )
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: lines,
              lineTouchData: LineTouchData(
                enabled: true,
                // ✅ Large threshold = responds anywhere on the chart
                touchSpotThreshold: 9999,
                handleBuiltInTouches: true,
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  return spotIndexes.map((idx) => TouchedSpotIndicatorData(
                    FlLine(
                      color: Colors.black54,
                      strokeWidth: 1.5,
                      dashArray: [4, 3],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, i) => FlDotCirclePainter(
                        radius: 4,
                        color: bar.color ?? Colors.green,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  )).toList();
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.black87,
                  tooltipRoundedRadius: 6,
                  getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                    s.y.toStringAsFixed(2),
                    const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  )).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// class CompanySellHistorySection extends StatelessWidget {
//   final List<Map<String, String>> transactionHistory = [
//     {"date": "2024-03-01", "volume": "100", "high": "Rp4,600.00", "low": "Rp4,550.00", "price": "Rp4,580.00"},
//     {"date": "2024-03-02", "volume": "50", "high": "Rp4,610.00", "low": "Rp4,560.00", "price": "Rp4,590.00"},
//     {"date": "2024-03-03", "volume": "200", "high": "Rp4,620.00", "low": "Rp4,570.00", "price": "Rp4,600.00"},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 8,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "User Transaction History", 
//             style: TextStyle(
//               color: Colors.black, 
//               fontSize: 20, 
//               fontWeight: FontWeight.bold
//             )
//           ),
//           SizedBox(height: 20),
//           ...transactionHistory.asMap().entries.map((entry) {
//             int index = entry.key;
//             Map<String, String> transaction = entry.value;
//             return Column(
//               children: [
//                 _buildTransactionRow(transaction),
//                 if (index < transactionHistory.length - 1)
//                   Divider(color: Colors.grey.shade300, height: 24),
//               ],
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTransactionRow(Map<String, String> transaction) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Date: ${transaction['date']}", 
//                   style: TextStyle(
//                     color: Colors.grey.shade600, 
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                   )
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   "Volume: ${transaction['volume']} Shares", 
//                   style: TextStyle(
//                     color: Colors.black, 
//                     fontSize: 15, 
//                     fontWeight: FontWeight.bold
//                   )
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 "Price: ${transaction['price']}", 
//                 style: TextStyle(
//                   color: Colors.black, 
//                   fontSize: 15, 
//                   fontWeight: FontWeight.bold
//                 )
//               ),
//               SizedBox(height: 4),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   "Completed",
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontSize: 11,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//}