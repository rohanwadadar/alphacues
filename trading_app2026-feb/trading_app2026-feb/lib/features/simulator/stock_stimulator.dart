// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';
// import 'package:test_project/features/trading/buy.dart';
// import 'package:test_project/features/trading/sell.dart';
// import 'package:test_project/features/news/newsmail.dart';
// import 'package:test_project/features/news/news.dart';
// import 'package:test_project/features/notifications/notification.dart';
// import 'package:test_project/features/wishlist/wishlist.dart';
// import 'package:test_project/features/simulator/simulator.dart';
// import 'package:test_project/features/notifications/alerts.dart';
// import 'package:test_project/features/trending/treanding.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Stock Tracker',
//       theme: ThemeData.light().copyWith(
//         scaffoldBackgroundColor: Colors.white,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.white,
//           elevation: 1,
//           foregroundColor: Colors.black,
//         ),
//         primaryColor: Color.fromARGB(255, 112, 97, 243),
//       ),
//       home: StockDetailsPage(stockName:  stock["name"]),
//     );
//   }
// }

// // Candlestick data model
// class CandlestickData {
//   final DateTime time;
//   final double open;
//   final double high;
//   final double low;
//   final double close;

//   CandlestickData({
//     required this.time, 
//     required this.open, 
//     required this.high, 
//     required this.low, 
//     required this.close
//   });
// }

// class StockSimulatorPage extends StatefulWidget {
//   final String stockName;

//   StockSimulatorPage({required this.stockName});

//   @override
//   _StockDetailsPageState createState() => _StockDetailsPageState();
// }

// class _StockDetailsPageState extends State<StockSimulatorPage> {
//   List<dynamic> newsData = [];
//   final String apiKey = 'CF7H37OIS5NWDTN3';
  
//   List<FlSpot> earningsData = [
//     FlSpot(1, 2.5), FlSpot(2, 3.0), FlSpot(3, 3.5), FlSpot(4, 4.2),
//     FlSpot(5, 4.8), FlSpot(6, 5.1), FlSpot(7, 5.5), FlSpot(8, 6.0),
//   ];

//   List<FlSpot> quarterlyEarningsData = [
//     FlSpot(1, 2.0), FlSpot(2, 2.8), FlSpot(3, 3.2), FlSpot(4, 3.6),
//     FlSpot(5, 4.0), FlSpot(6, 4.3), FlSpot(7, 4.7), FlSpot(8, 5.2),
//   ];

//   List<FlSpot> stockData = [
//     FlSpot(1, 150), FlSpot(2, 155), FlSpot(3, 160), FlSpot(4, 165),
//     FlSpot(5, 170), FlSpot(6, 175), FlSpot(7, 180), FlSpot(8, 190),
//   ];

//   List<FlSpot> returnOnEquityData = [
//     FlSpot(1, 12.5), FlSpot(2, 13.0), FlSpot(3, 14.2), FlSpot(4, 15.5),
//     FlSpot(5, 16.0), FlSpot(6, 16.8), FlSpot(7, 17.5), FlSpot(8, 18.0),
//   ];

//   List<FlSpot> debtEquityRatioData = [
//     FlSpot(1, 1.2), FlSpot(2, 1.4), FlSpot(3, 1.3), FlSpot(4, 1.5),
//     FlSpot(5, 1.6), FlSpot(6, 1.8), FlSpot(7, 1.7), FlSpot(8, 1.9),
//   ];

//   List<FlSpot> netProfitMarginData = [
//     FlSpot(1, 8.0), FlSpot(2, 8.5), FlSpot(3, 9.0), FlSpot(4, 9.8),
//     FlSpot(5, 10.5), FlSpot(6, 11.0), FlSpot(7, 11.8), FlSpot(8, 12.5),
//   ];

//   bool isLoading = true;

//   // Input Controllers for Simulator
//   final TextEditingController _amountController = TextEditingController(text: '10000');
//   final TextEditingController _growthController = TextEditingController(text: '12.5');
//   final TextEditingController _timePeriodController = TextEditingController(text: '5');
//   final TextEditingController _holdingPeriodController = TextEditingController(text: '3');
  
//   // Selected values
//   String _selectedCurrency = 'USD';
//   String _selectedTimeUnit = 'Years';
  
//   // Calculated results
//   double _totalProfit = 0;
//   double _finalAmount = 0;
//   double _totalReturn = 0;
//   List<FlSpot> _growthChart = [];
//   List<YearlyBreakdown> _yearlyBreakdown = [];
  
//   // Currency options
//   final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD'];
//   final List<String> _timeUnits = ['Years', 'Months'];

//   // Performance metrics data
//   final Map<String, dynamic> _performanceData = {
//     'currentPrice': 225.50,
//     'dayChange': 5.50,
//     'percentageChange': 2.5,
//     'marketCap': 3540000000000.0,
//     'volume': 25000000.0,
//     'peRatio': 28.5,
//     'dividendYield': 0.6,
//   };

//   // Financial overview data
//   final Map<String, dynamic> _financialData = {
//     'revenue': 383300000000.0,
//     'netIncome': 96950000000.0,
//     'profitMargin': 25.3,
//     'debtToEquity': 1.45,
//     'roe': 147.2,
//   };

//   @override
//   void initState() {
//     super.initState();
//     fetchStockAndEarningsData();
//     _calculateProfit();
//   }

//   Future<void> fetchStockAndEarningsData() async {
//     final String symbol = widget.stockName;
//     final String earningsUrl =
//         'https://www.alphavantage.co/query?function=EARNINGS&symbol=$symbol&apikey=$apiKey';
//     final String stockUrl =
//         'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$apiKey';

//     try {
//       final earningsResponse = await http.get(Uri.parse(earningsUrl));
//       final stockResponse = await http.get(Uri.parse(stockUrl));

//       if (earningsResponse.statusCode == 200 && stockResponse.statusCode == 200) {
//         final Map<String, dynamic> earningsDataJson = json.decode(earningsResponse.body);
//         final Map<String, dynamic> stockDataJson = json.decode(stockResponse.body);
//         final List<dynamic> annualEarnings = earningsDataJson['annualEarnings'];
//         final List<dynamic> quarterlyEarnings = earningsDataJson['quarterlyEarnings'];
//         final Map<String, dynamic> timeSeries = stockDataJson['Time Series (Daily)'];

//         List<FlSpot> tempAnnualData = [];
//         List<FlSpot> tempQuarterlyData = [];
//         List<FlSpot> tempStockData = [];
//         List<FlSpot> returnOnEquityData = [];
//         List<FlSpot> debtEquityRatioData = [];
//         List<FlSpot> netProfitMarginData = [];

//         int annualIndex = 0;
//         int quarterlyIndex = 0;
//         int stockIndex = 0;

//         for (var entry in annualEarnings.reversed) {
//           double eps = double.parse(entry['reportedEPS']);
//           tempAnnualData.add(FlSpot(annualIndex.toDouble(), eps));
//           annualIndex++;
//         }

//         for (var entry in quarterlyEarnings.reversed) {
//           double eps = double.parse(entry['reportedEPS']);
//           tempQuarterlyData.add(FlSpot(quarterlyIndex.toDouble(), eps));
//           quarterlyIndex++;
//         }

//         timeSeries.forEach((date, values) {
//           double closePrice = double.parse(values['4. close']);
//           tempStockData.add(FlSpot(stockIndex.toDouble(), closePrice));
//           stockIndex++;
//         });

//         setState(() {
//           earningsData = tempAnnualData;
//           quarterlyEarningsData = tempQuarterlyData;
//           stockData = tempStockData.reversed.toList();
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load stock or earnings data');
//       }
//     } catch (e) {
//       print('Error fetching data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _calculateProfit() {
//     double principal = double.tryParse(_amountController.text) ?? 0;
//     double growthRate = double.tryParse(_growthController.text) ?? 0;
//     double timePeriod = double.tryParse(_timePeriodController.text) ?? 0;
//     double holdingPeriod = double.tryParse(_holdingPeriodController.text) ?? 0;
    
//     if (principal <= 0 || growthRate <= 0 || timePeriod <= 0 || holdingPeriod <= 0) {
//       setState(() {
//         _totalProfit = 0;
//         _finalAmount = 0;
//         _totalReturn = 0;
//         _growthChart.clear();
//         _yearlyBreakdown.clear();
//       });
//       return;
//     }
    
//     // Convert time units if needed
//     double yearsForCalculation = _selectedTimeUnit == 'Months' ? timePeriod / 12 : timePeriod;
//     double holdingYears = _selectedTimeUnit == 'Months' ? holdingPeriod / 12 : holdingPeriod;
    
//     // Calculate compound interest for the holding period
//     double annualRate = growthRate / 100;
//     double finalAmount = principal * pow(1 + annualRate, holdingYears);
//     double totalProfit = finalAmount - principal;
//     double totalReturn = (totalProfit / principal) * 100;
    
//     // Generate chart data
//     List<FlSpot> chartData = [];
//     List<YearlyBreakdown> breakdown = [];
    
//     double dataPoints = min(holdingYears * 4, 20); // Max 20 points, quarterly if possible
//     double increment = holdingYears / dataPoints;
    
//     for (int i = 0; i <= dataPoints; i++) {
//       double years = i * increment;
//       double amount = principal * pow(1 + annualRate, years);
//       chartData.add(FlSpot(years, amount));
//     }
    
//     // Generate yearly breakdown
//     for (int year = 1; year <= holdingYears.ceil(); year++) {
//       if (year <= holdingYears) {
//         double yearAmount = principal * pow(1 + annualRate, year.toDouble());
//         double yearProfit = yearAmount - principal;
//         double yearReturn = (yearProfit / principal) * 100;
        
//         breakdown.add(YearlyBreakdown(
//           year: year,
//           amount: yearAmount,
//           profit: yearProfit,
//           returnPercentage: yearReturn,
//         ));
//       }
//     }
    
//     setState(() {
//       _finalAmount = finalAmount;
//       _totalProfit = totalProfit;
//       _totalReturn = totalReturn;
//       _growthChart = chartData;
//       _yearlyBreakdown = breakdown;
//     });
//   }

//   String _getCurrencySymbol(String currency) {
//     switch (currency) {
//       case 'USD': return '\$';
//       case 'EUR': return '€';
//       case 'GBP': return '£';
//       case 'INR': return '₹';
//       case 'JPY': return '¥';
//       case 'CAD': return 'C\$';
//       case 'AUD': return 'A\$';
//       default: return '\$';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: Text(
//           'Simulator',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 1,
//         iconTheme: IconThemeData(color: Colors.black),
//         actions: [
//           IconButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => TradingDashboard(),
//                 ),
//               );
//             },
//             icon: CircleAvatar(
//               backgroundColor: Color.fromARGB(255, 112, 97, 243),
//               radius: 12,
//               child: Icon(
//                 Icons.add,
//                 color: Colors.white,
//                 size: 14,
//               ),
//             ),
//           ),
//           Stack(
//             children: [
//               IconButton(
//                 icon: Image.asset(
//                   'assets/Frame.png',
//                   width: 24,
//                   height: 24,
//                   fit: BoxFit.cover,
//                 ),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => StockAlertsScreen()),
//                   );
//                 },
//               ),
//               Positioned(
//                 right: 2,
//                 top: 0,
//                 child: Container(
//                   padding: EdgeInsets.all(4),
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                   child: Text(
//                     '2',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 112, 97, 243)))
//           : SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   StockGraph(
//                     stockData: stockData,
//                     stockName: widget.stockName,
//                   ),
//                   SizedBox(height: 16),
//                   TimeRangeSelector(),
//                   SizedBox(height: 24),
//                   PerformanceMetrics(
//                     currentPrice: _performanceData['currentPrice'],
//                     dayChange: _performanceData['dayChange'],
//                     percentageChange: _performanceData['percentageChange'],
//                     marketCap: _performanceData['marketCap'],
//                     volume: _performanceData['volume'],
//                     peRatio: _performanceData['peRatio'],
//                     dividendYield: _performanceData['dividendYield'],
//                   ),
//                   SizedBox(height: 24),
                  
//                   // Financial Overview from Simulator
//                   FinancialOverview(
//                     revenue: _financialData['revenue'],
//                     netIncome: _financialData['netIncome'],
//                     profitMargin: _financialData['profitMargin'],
//                     debtToEquity: _financialData['debtToEquity'],
//                     roe: _financialData['roe'],
//                   ),
//                   SizedBox(height: 24),
                  
//                   // Investment Calculator Header
//                   Container(
//                     padding: EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(16),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.grey.shade200,
//                           blurRadius: 8,
//                           offset: Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Investment Growth Calculator',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           'Calculate your potential investment returns based on growth rate and time period',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: 16),
                  
//                   // Input Section
//                   _buildInputSection(),
//                   SizedBox(height: 24),
                  
//                   // Results Dashboard
//                   _buildResultsDashboard(),
//                   SizedBox(height: 24),
                  
//                   // Growth Chart
//                   _buildGrowthChart(),
//                   SizedBox(height: 24),
                  
//                   // Yearly Breakdown
//                   _buildYearlyBreakdown(),
//                   SizedBox(height: 24),
                  
//                   // Educational Note
//                   _buildEducationalNote(),
//                   SizedBox(height: 24),
//                 ],
//               ),
//             ),
//       bottomNavigationBar: Container(
//         padding: EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             top: BorderSide(color: Colors.grey.shade300, width: 1),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.shade200,
//               blurRadius: 4,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: TradeButtons(),
//       ),
//     );
//   }

//   Widget _buildInputSection() {
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
//             'Investment Parameters',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 20),
          
//           _buildInputField(
//             'Initial Investment Amount',
//             _amountController,
//             'Enter amount',
//             keyboardType: TextInputType.numberWithOptions(decimal: true),
//           ),
//           SizedBox(height: 16),
          
//           _buildDropdownField(
//             'Currency',
//             _selectedCurrency,
//             _currencies,
//             (value) => setState(() => _selectedCurrency = value!),
//           ),
//           SizedBox(height: 16),
          
//           _buildInputField(
//             'Expected Annual Growth Rate (%)',
//             _growthController,
//             'e.g., 12.5',
//             keyboardType: TextInputType.numberWithOptions(decimal: true),
//           ),
//           SizedBox(height: 16),
          
//           _buildInputField(
//             'Investment Time Period',
//             _timePeriodController,
//             'Enter time period',
//             keyboardType: TextInputType.number,
//           ),
//           SizedBox(height: 16),
          
//           _buildDropdownField(
//             'Time Unit',
//             _selectedTimeUnit,
//             _timeUnits,
//             (value) => setState(() => _selectedTimeUnit = value!),
//           ),
//           SizedBox(height: 16),
          
//           _buildInputField(
//             'Holding Period (${_selectedTimeUnit.toLowerCase()})',
//             _holdingPeriodController,
//             'How long will you hold?',
//             keyboardType: TextInputType.numberWithOptions(decimal: true),
//           ),
//           SizedBox(height: 20),
          
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _calculateProfit,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color.fromARGB(255, 112, 97, 243),
//                 padding: EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text(
//                 'Calculate Returns',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade700,
//           ),
//         ),
//         SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             hintText: hint,
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Color.fromARGB(255, 112, 97, 243), width: 2),
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//           ),
//           onChanged: (_) => _calculateProfit(),
//         ),
//       ],
//     );
//   }

//   Widget _buildDropdownField(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade700,
//           ),
//         ),
//         SizedBox(height: 8),
//         DropdownButtonFormField<String>(
//           value: value,
//           items: options.map((option) => DropdownMenuItem(
//             value: option,
//             child: Text(option),
//           )).toList(),
//           onChanged: (newValue) {
//             onChanged(newValue);
//             _calculateProfit();
//           },
//           decoration: InputDecoration(
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey.shade300),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Color.fromARGB(255, 112, 97, 243), width: 2),
//             ),
//             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildResultsDashboard() {
//     String currencySymbol = _getCurrencySymbol(_selectedCurrency);
    
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
//             'Investment Results',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 20),
          
//           Row(
//             children: [
//               Expanded(
//                 child: _buildResultCard(
//                   'Initial Investment',
//                   '$currencySymbol${double.tryParse(_amountController.text)?.toStringAsFixed(2) ?? '0.00'}',
//                   Colors.blue,
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _buildResultCard(
//                   'Final Amount',
//                   '$currencySymbol${_finalAmount.toStringAsFixed(2)}',
//                   Colors.green,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
          
//           Row(
//             children: [
//               Expanded(
//                 child: _buildResultCard(
//                   'Total Profit',
//                   '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
//                   _totalProfit >= 0 ? Colors.green : Colors.red,
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _buildResultCard(
//                   'Total Return',
//                   '${_totalReturn.toStringAsFixed(2)}%',
//                   _totalReturn >= 0 ? Colors.green : Colors.red,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildResultCard(String title, String value, Color color) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGrowthChart() {
//     if (_growthChart.isEmpty) {
//       return Container();
//     }
    
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
//             'Investment Growth Over Time',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 20),
          
//           Container(
//             height: 250,
//             child: LineChart(
//               LineChartData(
//                 gridData: FlGridData(
//                   show: true,
//                   drawVerticalLine: false,
//                   getDrawingHorizontalLine: (value) => FlLine(
//                     color: Colors.grey.shade300,
//                     strokeWidth: 0.5,
//                   ),
//                 ),
//                 titlesData: FlTitlesData(
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 60,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           '${_getCurrencySymbol(_selectedCurrency)}${(value / 1000).toStringAsFixed(0)}k',
//                           style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//                         );
//                       },
//                     ),
//                   ),
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, meta) {
//                         return Text(
//                           '${value.toStringAsFixed(1)}y',
//                           style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//                         );
//                       },
//                     ),
//                   ),
//                   topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 borderData: FlBorderData(show: false),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: _growthChart,
//                     isCurved: true,
//                     color: Color.fromARGB(255, 112, 97, 243),
//                     barWidth: 3,
//                     dotData: FlDotData(show: false),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       gradient: LinearGradient(
//                         colors: [
//                           Color.fromARGB(255, 112, 97, 243).withOpacity(0.3),
//                           Color.fromARGB(255, 112, 97, 243).withOpacity(0.1),
//                           Color.fromARGB(255, 112, 97, 243).withOpacity(0.0),
//                         ],
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                       ),
//                     ),
//                   ),
//                 ],
//                 lineTouchData: LineTouchData(
//                   enabled: true,
//                   touchTooltipData: LineTouchTooltipData(
//                     getTooltipColor: (touchedSpot) => Color.fromARGB(255, 112, 97, 243),
//                     getTooltipItems: (touchedSpots) {
//                       return touchedSpots.map((spot) {
//                         return LineTooltipItem(
//                           'Year ${spot.x.toStringAsFixed(1)}\n${_getCurrencySymbol(_selectedCurrency)}${spot.y.toStringAsFixed(0)}',
//                           TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                         );
//                       }).toList();
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildYearlyBreakdown() {
//     if (_yearlyBreakdown.isEmpty) {
//       return Container();
//     }
    
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
//             'Yearly Breakdown',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 20),
          
//           Container(
//             padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//             decoration: BoxDecoration(
//               color: Colors.grey.shade100,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Expanded(flex: 1, child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                 Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                 Expanded(flex: 2, child: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//                 Expanded(flex: 2, child: Text('Return %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
//               ],
//             ),
//           ),
          
//           Column(
//             children: _yearlyBreakdown.map((breakdown) => Container(
//               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//               decoration: BoxDecoration(
//                 border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(flex: 1, child: Text('${breakdown.year}', style: TextStyle(fontSize: 12))),
//                   Expanded(flex: 2, child: Text('${_getCurrencySymbol(_selectedCurrency)}${breakdown.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12))),
//                   Expanded(flex: 2, child: Text('${_getCurrencySymbol(_selectedCurrency)}${breakdown.profit.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.green))),
//                   Expanded(flex: 2, child: Text('${breakdown.returnPercentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.green))),
//                 ],
//               ),
//             )).toList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEducationalNote() {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
//               SizedBox(width: 8),
//               Text(
//                 'Important Disclaimer',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.orange.shade700,
//                   fontSize: 14,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 8),
//           Text(
//             'This calculator provides estimates based on compound growth. Actual investment returns may vary significantly due to market volatility, fees, taxes, and other factors. Past performance does not guarantee future results. Always consult with financial professionals before making investment decisions.',
//             style: TextStyle(
//               color: Colors.orange.shade700,
//               fontSize: 12,
//               height: 1.4,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // StockGraph Widget
// class StockGraph extends StatefulWidget {
//   final List<FlSpot> stockData;
//   final String stockName;

//   StockGraph({
//     required this.stockData,
//     required this.stockName,
//   });

//   @override
//   _StockGraphState createState() => _StockGraphState();
// }

// class _StockGraphState extends State<StockGraph> {
//   double selectedValue = 0;
//   String selectedTime = "";
//   double? touchX;
//   double? touchY;
//   bool showCandlestick = false;
  
//   double zoomLevel = 1.0;
//   double panOffset = 0.0;
//   double maxZoom = 3.0;
//   bool isZooming = false;
  
//   CandlestickData? selectedCandlestick;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.stockData.isNotEmpty) {
//       selectedValue = widget.stockData.last.y;
//     }
//   }

//   String getFormattedTime(double x) {
//     final times = [
//       "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
//       "12:00 PM", "12:30 PM", "1:00 PM", "1:30 PM", "2:00 PM",
//       "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM"
//     ];
//     int index = x.toInt().clamp(0, times.length - 1);
//     return times[index];
//   }

//   String getFormattedDate(DateTime date) {
//     List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
//     return "${months[date.month - 1]} ${date.day}, ${date.year}";
//   }

//   String getFormattedTimeFromData(double x) {
//     int index = x.toInt();
//     if (index >= 0 && index < widget.stockData.length) {
//       DateTime baseTime = DateTime.now().subtract(Duration(days: widget.stockData.length - index - 1));
//       return getFormattedDate(baseTime);
//     }
//     return getFormattedTime(x);
//   }

//   double calculateDayChange(double currentValue) {
//     if (widget.stockData.isEmpty) return 0;
//     return currentValue - widget.stockData.first.y;
//   }

//   double calculatePercentageChange(double currentValue) {
//     if (widget.stockData.isEmpty || widget.stockData.first.y == 0) return 0;
//     return ((currentValue - widget.stockData.first.y) / widget.stockData.first.y) * 100;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dayChange = calculateDayChange(selectedValue);
//     final percentageChange = calculatePercentageChange(selectedValue);
//     final isPositive = dayChange >= 0;

//     return Container(
//       padding: EdgeInsets.all(16),
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
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.stockName,
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     '',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey.shade600,
//                     ),
//                   ),
//                 ],
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     icon: Icon(Icons.zoom_in, color: Colors.grey.shade600),
//                     onPressed: () {
//                       setState(() {
//                         if (zoomLevel < maxZoom) {
//                           zoomLevel += 0.5;
//                         }
//                       });
//                     },
//                   ),
//                   IconButton(
//                     icon: Icon(Icons.zoom_out, color: Colors.grey.shade600),
//                     onPressed: () {
//                       setState(() {
//                         if (zoomLevel > 1.0) {
//                           zoomLevel -= 0.5;
//                         } else {
//                           zoomLevel = 1.0;
//                           panOffset = 0.0;
//                         }
//                       });
//                     },
//                   ),
//                   TextButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         showCandlestick = !showCandlestick;
//                         selectedTime = "";
//                         touchX = null;
//                         touchY = null;
//                         selectedCandlestick = null;
//                       });
//                     },
//                     icon: Icon(
//                       showCandlestick ? Icons.show_chart : Icons.candlestick_chart,
//                       color: Colors.grey.shade600,
//                     ),
//                     label: Text(
//                       showCandlestick ? 'Line' : 'Candlestick',
//                       style: TextStyle(color: Colors.grey.shade600),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           SizedBox(height: 20),
          
//           Text(
//             '\$${selectedValue.toStringAsFixed(2)}',
//             style: TextStyle(
//               fontSize: 36,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 8),
          
//           Container(
//             child: Text(
//               '${isPositive ? "+" : ""}\$${dayChange.toStringAsFixed(2)} (${isPositive ? "+" : ""}${percentageChange.toStringAsFixed(1)}%)',
//               style: TextStyle(
//                 color: isPositive ? Colors.green : Colors.red,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           SizedBox(height: 24),
          
//           GestureDetector(
//             onHorizontalDragStart: (details) {
//               setState(() {
//                 isZooming = true;
//               });
//             },
//             onHorizontalDragUpdate: (details) {
//               if (zoomLevel > 1.0) {
//                 setState(() {
//                   panOffset += details.delta.dx;
//                   double maxPan = (widget.stockData.length * (zoomLevel - 1)).clamp(0.0, double.infinity);
//                   panOffset = panOffset.clamp(-maxPan, 0.0);
//                 });
//               }
//             },
//             onHorizontalDragEnd: (details) {
//               setState(() {
//                 isZooming = false;
//               });
//             },
//             child: Stack(
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(16),
//                   height: 280,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: showCandlestick
//                       ? _buildCandlestickChart(isPositive)
//                       : _buildLineChart(isPositive),
//                 ),
//                 if (touchX != null && touchY != null && selectedTime.isNotEmpty)
//                   Positioned(
//                     left: (touchX! - 80).clamp(0.0, MediaQuery.of(context).size.width - 160),
//                     top: (touchY! - 80).clamp(0.0, 200.0),
//                     child: Container(
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.black.withOpacity(0.8),
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey.shade300),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             selectedTime,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             '\$${selectedValue.toStringAsFixed(2)}',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           if (selectedCandlestick != null && showCandlestick)
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 SizedBox(height: 4),
//                                 Text(
//                                   "O: \$${selectedCandlestick!.open.toStringAsFixed(2)}",
//                                   style: TextStyle(color: Colors.white, fontSize: 10),
//                                 ),
//                                 Text(
//                                   "H: \$${selectedCandlestick!.high.toStringAsFixed(2)}",
//                                   style: TextStyle(color: Colors.white, fontSize: 10),
//                                 ),
//                                 Text(
//                                   "L: \$${selectedCandlestick!.low.toStringAsFixed(2)}",
//                                   style: TextStyle(color: Colors.white, fontSize: 10),
//                                 ),
//                                 Text(
//                                   "C: \$${selectedCandlestick!.close.toStringAsFixed(2)}",
//                                   style: TextStyle(color: Colors.white, fontSize: 10),
//                                 ),
//                               ],
//                             ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 if (zoomLevel > 1.0)
//                   Positioned(
//                     top: 10,
//                     right: 10,
//                     child: Container(
//                       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.9),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         "${zoomLevel.toStringAsFixed(1)}x",
//                         style: TextStyle(color: Colors.white, fontSize: 10),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLineChart(bool isPositive) {
//     List<FlSpot> visibleData = [];
//     if (zoomLevel > 1.0) {
//       int totalPoints = widget.stockData.length;
//       int visiblePoints = (totalPoints / zoomLevel).floor();
      
//       int startIndex = (panOffset / zoomLevel).abs().floor();
//       startIndex = startIndex.clamp(0, totalPoints - visiblePoints);
      
//       List<FlSpot> zoomedData = widget.stockData.sublist(
//         startIndex, 
//         (startIndex + visiblePoints).clamp(0, totalPoints)
//       );
      
//       for (int i = 0; i < zoomedData.length; i++) {
//         visibleData.add(FlSpot(i.toDouble(), zoomedData[i].y));
//       }
//     } else {
//       visibleData = widget.stockData;
//     }

//     bool isOverallPositive = true;
//     if (visibleData.isNotEmpty && visibleData.length > 1) {
//       double firstValue = visibleData.first.y;
//       double lastValue = visibleData.last.y;
//       isOverallPositive = lastValue >= firstValue;
//     }

//     Color lineColor = isOverallPositive ? Colors.green : Colors.red;
//     Color gradientStartColor = isOverallPositive 
//         ? Colors.green.withOpacity(0.3) 
//         : Colors.red.withOpacity(0.3);
//     Color gradientMiddleColor = isOverallPositive 
//         ? Colors.green.withOpacity(0.1) 
//         : Colors.red.withOpacity(0.1);
//     Color gradientEndColor = isOverallPositive 
//         ? Colors.green.withOpacity(0.0) 
//         : Colors.red.withOpacity(0.0);

//     return LineChart(
//       LineChartData(
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: false,
//           drawHorizontalLine: true,
//           horizontalInterval: 10,
//           getDrawingHorizontalLine: (value) => FlLine(
//             color: Colors.grey.shade300,
//             strokeWidth: 0.5,
//           ),
//         ),
//         titlesData: FlTitlesData(
//           leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(show: false),
//         lineBarsData: [
//           LineChartBarData(
//             spots: visibleData,
//             isCurved: true,
//             color: lineColor,
//             barWidth: 3,
//             isStrokeCapRound: true,
//             belowBarData: BarAreaData(
//               show: true,
//               gradient: LinearGradient(
//                 colors: [
//                   gradientStartColor,
//                   gradientMiddleColor,
//                   gradientEndColor,
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//             dotData: FlDotData(show: false),
//           ),
//         ],
//         lineTouchData: _getLineTouchData(),
//       ),
//     );
//   }

//   Widget _buildCandlestickChart(bool isPositive) {
//     List<CandlestickData> candlestickData = [];
    
//     if (widget.stockData.isNotEmpty) {
//       for (int i = 0; i < widget.stockData.length; i++) {
//         final value = widget.stockData[i].y;
//         final open = value * (1 - 0.005 * (i % 3 == 0 ? 1 : -1));
//         final close = value * (1 + 0.003 * (i % 2 == 0 ? 1 : -1));
//         final high = value * (1 + 0.01);
//         final low = value * (1 - 0.01);
        
//         candlestickData.add(CandlestickData(
//           time: DateTime.now().subtract(Duration(days: widget.stockData.length - i - 1)),
//           open: open,
//           high: high,
//           low: low,
//           close: close,
//         ));
//       }
//     }
    
//     List<CandlestickData> visibleCandlesticks = [];
//     if (zoomLevel > 1.0) {
//       int totalPoints = candlestickData.length;
//       int visiblePoints = (totalPoints / zoomLevel).floor();
      
//       int startIndex = (panOffset / zoomLevel).abs().floor();
//       startIndex = startIndex.clamp(0, totalPoints - visiblePoints);
      
//       visibleCandlesticks = candlestickData.sublist(
//         startIndex, 
//         (startIndex + visiblePoints).clamp(0, totalPoints)
//       );
//     } else {
//       visibleCandlesticks = candlestickData;
//     }

//     return GestureDetector(
//       onTapDown: (details) {
//         _handleCandlestickTap(details.localPosition, visibleCandlesticks);
//       },
//       onPanUpdate: (details) {
//         _handleCandlestickTap(details.localPosition, visibleCandlesticks);
//       },
//       child: Container(
//         height: 220,
//         child: CustomPaint(
//           size: Size.infinite,
//           painter: CandlestickPainter(
//             candlestickData: visibleCandlesticks,
//             textColor: Colors.black87,
//             onCandlestickSelected: (candlestick, x, y) {
//               setState(() {
//                 selectedCandlestick = candlestick;
//                 selectedValue = candlestick.close;
//                 selectedTime = getFormattedDate(candlestick.time);
//                 touchX = x;
//                 touchY = y;
//               });
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleCandlestickTap(Offset localPosition, List<CandlestickData> candlesticks) {
//     if (candlesticks.isEmpty) return;
    
//     final RenderBox renderBox = context.findRenderObject() as RenderBox;
//     final containerWidth = renderBox.size.width - 32;
//     final candleWidth = containerWidth / candlesticks.length;
    
//     int index = (localPosition.dx / candleWidth).floor();
//     if (index >= 0 && index < candlesticks.length) {
//       CandlestickData tapped = candlesticks[index];
//       setState(() {
//         selectedCandlestick = tapped;
//         selectedValue = tapped.close;
//         selectedTime = getFormattedDate(tapped.time);
//         touchX = localPosition.dx;
//         touchY = localPosition.dy;
//       });
//     }
//   }

//   LineTouchData _getLineTouchData() {
//     return LineTouchData(
//       enabled: true,
//       handleBuiltInTouches: true,
//       touchTooltipData: LineTouchTooltipData(
//         showOnTopOfTheChartBoxArea: false,
//         getTooltipItems: (touchedSpots) {
//           return touchedSpots.map((spot) {
//             return LineTooltipItem(
//               '\${spot.y.toStringAsFixed(2)}',
//               TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//             );
//           }).toList();
//         },
//         getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
//       ),
//       getTouchedSpotIndicator: (barData, spotIndexes) {
//         return spotIndexes.map((index) {
//           return TouchedSpotIndicatorData(
//             FlLine(
//               color: Color.fromARGB(255, 112, 97, 243).withOpacity(0.5),
//               strokeWidth: 2,
//               dashArray: [5, 5],
//             ),
//             FlDotData(
//               show: true,
//               getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
//                 radius: 6,
//                 color: Color.fromARGB(255, 112, 97, 243),
//                 strokeWidth: 2,
//                 strokeColor: Colors.white,
//               ),
//             ),
//           );
//         }).toList();
//       },
//       touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
//         if (event is FlPanDownEvent ||
//             event is FlPanUpdateEvent ||
//             event is FlTapDownEvent) {
//           if (response?.lineBarSpots != null &&
//               response!.lineBarSpots!.isNotEmpty &&
//               event.localPosition != null) {
//             final spot = response.lineBarSpots![0];
//             setState(() {
//               selectedValue = spot.y;
//               selectedTime = getFormattedTimeFromData(spot.x);
//               touchX = event.localPosition?.dx;
//               touchY = event.localPosition?.dy;
//             });
//           }
//         } else if (event is FlPanEndEvent || event is FlTapUpEvent) {
//           Future.delayed(Duration(milliseconds: 2000), () {
//             if (mounted) {
//               setState(() {
//                 selectedValue = widget.stockData.last.y;
//                 selectedTime = "";
//                 touchX = null;
//                 touchY = null;
//               });
//             }
//           });
//         }
//       },
//     );
//   }
// }

// class CandlestickPainter extends CustomPainter {
//   final List<CandlestickData> candlestickData;
//   final Color textColor;
//   final Function(CandlestickData, double, double)? onCandlestickSelected;
//   late Size _size;
  
//   CandlestickPainter({
//     required this.candlestickData,
//     required this.textColor,
//     this.onCandlestickSelected,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     _size = size;
    
//     if (candlestickData.isEmpty) return;
    
//     final double width = size.width;
//     final double height = size.height;
//     final int dataLength = candlestickData.length;
    
//     double minPrice = double.infinity;
//     double maxPrice = -double.infinity;
    
//     for (var data in candlestickData) {
//       if (data.low < minPrice) minPrice = data.low;
//       if (data.high > maxPrice) maxPrice = data.high;
//     }
    
//     final padding = (maxPrice - minPrice) * 0.1;
//     minPrice -= padding;
//     maxPrice += padding;
    
//     final double verticalScale = height / (maxPrice - minPrice);
//     final double candleWidth = width / dataLength * 0.8;
//     final double spacing = width / dataLength * 0.2 / 2;
    
//     double priceToY(double price) => height - (price - minPrice) * verticalScale;
    
//     final Paint gridPaint = Paint()
//       ..color = Colors.grey.shade300
//       ..strokeWidth = 0.5;
      
//     int gridLines = 5;
//     for (int i = 0; i <= gridLines; i++) {
//       double y = height * i / gridLines;
//       canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
//     }
    
//     for (int i = 0; i < dataLength; i++) {
//       final data = candlestickData[i];
//       final bool isBullish = data.close >= data.open;
//       final Color candleColor = isBullish ? Colors.green : Colors.red;
      
//       final double x = i * (candleWidth + spacing * 2) + spacing;
//       final double openY = priceToY(data.open);
//       final double closeY = priceToY(data.close);
//       final double highY = priceToY(data.high);
//       final double lowY = priceToY(data.low);
      
//       final Paint wickPaint = Paint()
//         ..color = candleColor
//         ..strokeWidth = 1.5;
      
//       canvas.drawLine(
//         Offset(x + candleWidth / 2, highY),
//         Offset(x + candleWidth / 2, lowY),
//         wickPaint,
//       );
      
//       final Paint bodyPaint = Paint()
//         ..color = candleColor
//         ..style = PaintingStyle.fill;
      
//       final bodyRect = Rect.fromLTRB(
//         x,
//         isBullish ? closeY : openY,
//         x + candleWidth,
//         isBullish ? openY : closeY,
//       );
      
//       canvas.drawRect(bodyRect, bodyPaint);
      
//       final Paint borderPaint = Paint()
//         ..color = candleColor.withOpacity(0.8)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 0.5;
        
//       canvas.drawRect(bodyRect, borderPaint);
//     }
    
//     final TextPainter textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.left,
//     );
    
//     textPainter.text = TextSpan(
//       text: '\${maxPrice.toStringAsFixed(2)}',
//       style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(5, 0));
    
//     textPainter.text = TextSpan(
//       text: '\${minPrice.toStringAsFixed(2)}',
//       style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(5, height - textPainter.height));
    
//     double middlePrice = (maxPrice + minPrice) / 2;
//     textPainter.text = TextSpan(
//       text: '\${middlePrice.toStringAsFixed(2)}',
//       style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(5, height / 2 - textPainter.height / 2));
//   }
  
//   @override
//   bool shouldRepaint(covariant CandlestickPainter oldDelegate) => 
//     oldDelegate.candlestickData != candlestickData;
    
//   @override
//   bool? hitTest(Offset position) {
//     if (candlestickData.isEmpty) return null;
    
//     final double width = _size.width;
//     final int dataLength = candlestickData.length;
//     final double candleWidth = width / dataLength * 0.8;
//     final double spacing = width / dataLength * 0.2 / 2;
    
//     for (int i = 0; i < dataLength; i++) {
//       final data = candlestickData[i];
//       final double x = i * (candleWidth + spacing * 2) + spacing;
      
//       if (position.dx >= x && position.dx <= x + candleWidth) {
//         if (onCandlestickSelected != null) {
//           onCandlestickSelected!(data, position.dx, position.dy);
//         }
//         return true;
//       }
//     }
    
//     return null;
//   }
// }

// class TimeRangeSelector extends StatefulWidget {
//   @override
//   _TimeRangeSelectorState createState() => _TimeRangeSelectorState();
// }

// class _TimeRangeSelectorState extends State<TimeRangeSelector> {
//   String selectedRange = "1D";

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 8),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: ["1D", "5D", "1M", "6M", "YTD", "1Y", "5Y", "MAX"].map((label) {
//             bool isSelected = selectedRange == label;
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 4.0),
//               child: TextButton(
//                 onPressed: () {
//                   setState(() {
//                     selectedRange = label;
//                   });
//                 },
//                 style: TextButton.styleFrom(
//                   backgroundColor: isSelected ? Color.fromARGB(255, 112, 97, 243) : Colors.transparent,
//                   foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
//                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                 ),
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }

// class TradeButtons extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [],
//     );
//   }
// }

// class PerformanceMetrics extends StatelessWidget {
//   final double currentPrice;
//   final double dayChange;
//   final double percentageChange;
//   final double marketCap;
//   final double volume;
//   final double peRatio;
//   final double dividendYield;

//   const PerformanceMetrics({
//     Key? key,
//     required this.currentPrice,
//     required this.dayChange,
//     required this.percentageChange,
//     required this.marketCap,
//     required this.volume,
//     required this.peRatio,
//     required this.dividendYield,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final isPositive = dayChange >= 0;

//     return Container(
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 4,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Performance & Key Statistics',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 20),
          
//           Container(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SizedBox(height: 20),
//                 _buildPerformanceRow("Volume", "1001", "AVG Volume", "167.58M"),
//                 Divider(color: Colors.grey.shade300, height: 24),
//                 _buildPerformanceRow("Open", "188.01", "Prev. Close", "Rp4,600.00"),
//                 Divider(color: Colors.grey.shade300, height: 24),
//                 _buildPerformanceRow("RVOL", "-", "Relative Volume", "-"),
//                 Divider(color: Colors.grey.shade300, height: 24),
//                 _buildPerformanceRow("Today's Low", "188.51", "Today's High", "189.51"),
//                 Divider(color: Colors.grey.shade300, height: 24),
//                 _buildPerformanceRow("52 Week Low", "168.21", "52 Week High", "189.51"),
//                 Divider(color: Colors.grey.shade300, height: 24),
//                 _buildPerformanceRow("Day Range", "Rp4,560.00", "Year Range", "Rp3,960.00"),
//                 Divider(color: Colors.grey.shade300, height: 24),
//                 _buildPerformanceRow("Market Cap", "694.707 IDR", "P/E Ratio", "15.50"),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPerformanceRow(String label1, String value1, String label2, String value2) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label1, 
//                   style: TextStyle(
//                     color: Colors.grey.shade600, 
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                   )
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value1, 
//                   style: TextStyle(
//                     color: Colors.black, 
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                   )
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Text(
//                   label2, 
//                   style: TextStyle(
//                     color: Colors.grey.shade600, 
//                     fontSize: 13,
//                     fontWeight: FontWeight.w500,
//                   )
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value2, 
//                   style: TextStyle(
//                     color: Colors.black, 
//                     fontSize: 15,
//                     fontWeight: FontWeight.bold,
//                   )
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, Color color) {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatNumber(double number) {
//     if (number >= 1000000000) {
//       return '${(number / 1000000000).toStringAsFixed(2)}B';
//     } else if (number >= 1000000) {
//       return '${(number / 1000000).toStringAsFixed(2)}M';
//     } else if (number >= 1000) {
//       return '${(number / 1000).toStringAsFixed(2)}K';
//     }
//     return number.toStringAsFixed(2);
//   }
// }

// class FinancialOverview extends StatelessWidget {
//   final double revenue;
//   final double netIncome;
//   final double profitMargin;
//   final double debtToEquity;
//   final double roe;

//   const FinancialOverview({
//     Key? key,
//     required this.revenue,
//     required this.netIncome,
//     required this.profitMargin,
//     required this.debtToEquity,
//     required this.roe,
//   }) : super(key: key);

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
//             'Financial Overview',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           SizedBox(height: 20),
          
//           Row(
//             children: [
//               Expanded(
//                 child: _buildFinancialCard(
//                   'Revenue',
//                   '\${_formatNumber(revenue)}',
//                   Colors.blue,
//                   Icons.trending_up,
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _buildFinancialCard(
//                   'Net Income',
//                   '\${_formatNumber(netIncome)}',
//                   Colors.green,
//                   Icons.attach_money,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
          
//           Row(
//             children: [
//               Expanded(
//                 child: _buildFinancialCard(
//                   'Profit Margin',
//                   '${profitMargin.toStringAsFixed(1)}%',
//                   profitMargin > 15 ? Colors.green : Colors.orange,
//                   Icons.bar_chart,
//                 ),
//               ),
//               SizedBox(width: 12),
//               Expanded(
//                 child: _buildFinancialCard(
//                   'ROE',
//                   '${roe.toStringAsFixed(1)}%',
//                   roe > 15 ? Colors.green : Colors.orange,
//                   Icons.show_chart,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: 12),
          
//           Container(
//             width: double.infinity,
//             child: _buildFinancialCard(
//               'Debt to Equity',
//               debtToEquity.toStringAsFixed(2),
//               debtToEquity < 1.0 ? Colors.green : Colors.red,
//               Icons.balance,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFinancialCard(String title, String value, Color color, IconData icon) {
//     return Container(
//       padding: EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 24),
//           SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey.shade600,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: color,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatNumber(double number) {
//     if (number >= 1000000000) {
//       return '${(number / 1000000000).toStringAsFixed(2)}B';
//     } else if (number >= 1000000) {
//       return '${(number / 1000000).toStringAsFixed(2)}M';
//     }
//     return number.toStringAsFixed(2);
//   }
// }

// class YearlyBreakdown {
//   final int year;
//   final double amount;
//   final double profit;
//   final double returnPercentage;

//   YearlyBreakdown({
//     required this.year,
//     required this.amount,
//     required this.profit,
//     required this.returnPercentage,
//   });
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
import 'package:test_project/features/trending/treanding.dart';

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
      // Fixed: Use StockSimulatorPage with a default stock instead of undefined 'stock'
      home: StockSimulatorPage(stockName: 'AAPL'), // Default stock
    );
  }
}

// // Candlestick data model
// class CandlestickData {
//   final DateTime time;
//   final double open;
//   final double high;
//   final double low;
//   final double close;

//   CandlestickData({
//     required this.time, 
//     required this.open, 
//     required this.high, 
//     required this.low, 
//     required this.close
//   });
// }

class StockSimulatorPage extends StatefulWidget {
  final String stockName;

  StockSimulatorPage({required this.stockName});

  @override
  _StockSimulatorPageState createState() => _StockSimulatorPageState(); // Fixed class name
}

class _StockSimulatorPageState extends State<StockSimulatorPage> {
  List<dynamic> newsData = [];
  final String apiKey = 'CF7H37OIS5NWDTN3';
  
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

  // Input Controllers for Simulator
  final TextEditingController _amountController = TextEditingController(text: '10000');
  final TextEditingController _growthController = TextEditingController(text: '12.5');
  final TextEditingController _timePeriodController = TextEditingController(text: '5');
  final TextEditingController _holdingPeriodController = TextEditingController(text: '3');
  
  // Selected values
  String _selectedCurrency = 'USD';
  String _selectedTimeUnit = 'Years';
  
  // Calculated results
  double _totalProfit = 0;
  double _finalAmount = 0;
  double _totalReturn = 0;
  List<FlSpot> _growthChart = [];
  List<YearlyBreakdown> _yearlyBreakdown = [];
  
  // Currency options
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD'];
  final List<String> _timeUnits = ['Years', 'Months'];

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

  // Financial overview data
  final Map<String, dynamic> _financialData = {
    'revenue': 383300000000.0,
    'netIncome': 96950000000.0,
    'profitMargin': 25.3,
    'debtToEquity': 1.45,
    'roe': 147.2,
  };

  @override
  void initState() {
    super.initState();
    fetchStockAndEarningsData();
    _calculateProfit();
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
        final List<dynamic> annualEarnings = earningsDataJson['annualEarnings'];
        final List<dynamic> quarterlyEarnings = earningsDataJson['quarterlyEarnings'];
        final Map<String, dynamic> timeSeries = stockDataJson['Time Series (Daily)'];

        List<FlSpot> tempAnnualData = [];
        List<FlSpot> tempQuarterlyData = [];
        List<FlSpot> tempStockData = [];
        List<FlSpot> returnOnEquityData = [];
        List<FlSpot> debtEquityRatioData = [];
        List<FlSpot> netProfitMarginData = [];

        int annualIndex = 0;
        int quarterlyIndex = 0;
        int stockIndex = 0;

        for (var entry in annualEarnings.reversed) {
          double eps = double.parse(entry['reportedEPS']);
          tempAnnualData.add(FlSpot(annualIndex.toDouble(), eps));
          annualIndex++;
        }

        for (var entry in quarterlyEarnings.reversed) {
          double eps = double.parse(entry['reportedEPS']);
          tempQuarterlyData.add(FlSpot(quarterlyIndex.toDouble(), eps));
          quarterlyIndex++;
        }

        timeSeries.forEach((date, values) {
          double closePrice = double.parse(values['4. close']);
          tempStockData.add(FlSpot(stockIndex.toDouble(), closePrice));
          stockIndex++;
        });

        setState(() {
          earningsData = tempAnnualData;
          quarterlyEarningsData = tempQuarterlyData;
          stockData = tempStockData.reversed.toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load stock or earnings data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateProfit() {
    double principal = double.tryParse(_amountController.text) ?? 0;
    double growthRate = double.tryParse(_growthController.text) ?? 0;
    double timePeriod = double.tryParse(_timePeriodController.text) ?? 0;
    double holdingPeriod = double.tryParse(_holdingPeriodController.text) ?? 0;
    
    if (principal <= 0 || growthRate <= 0 || timePeriod <= 0 || holdingPeriod <= 0) {
      setState(() {
        _totalProfit = 0;
        _finalAmount = 0;
        _totalReturn = 0;
        _growthChart.clear();
        _yearlyBreakdown.clear();
      });
      return;
    }
    
    // Convert time units if needed
    double yearsForCalculation = _selectedTimeUnit == 'Months' ? timePeriod / 12 : timePeriod;
    double holdingYears = _selectedTimeUnit == 'Months' ? holdingPeriod / 12 : holdingPeriod;
    
    // Calculate compound interest for the holding period
    double annualRate = growthRate / 100;
    double finalAmount = principal * pow(1 + annualRate, holdingYears);
    double totalProfit = finalAmount - principal;
    double totalReturn = (totalProfit / principal) * 100;
    
    // Generate chart data
    List<FlSpot> chartData = [];
    List<YearlyBreakdown> breakdown = [];
    
    double dataPoints = min(holdingYears * 4, 20); // Max 20 points, quarterly if possible
    double increment = holdingYears / dataPoints;
    
    for (int i = 0; i <= dataPoints; i++) {
      double years = i * increment;
      double amount = principal * pow(1 + annualRate, years);
      chartData.add(FlSpot(years, amount));
    }
    
    // Generate yearly breakdown
    for (int year = 1; year <= holdingYears.ceil(); year++) {
      if (year <= holdingYears) {
        double yearAmount = principal * pow(1 + annualRate, year.toDouble());
        double yearProfit = yearAmount - principal;
        double yearReturn = (yearProfit / principal) * 100;
        
        breakdown.add(YearlyBreakdown(
          year: year,
          amount: yearAmount,
          profit: yearProfit,
          returnPercentage: yearReturn,
        ));
      }
    }
    
    setState(() {
      _finalAmount = finalAmount;
      _totalProfit = totalProfit;
      _totalReturn = totalReturn;
      _growthChart = chartData;
      _yearlyBreakdown = breakdown;
    });
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'INR': return '₹';
      case 'JPY': return '¥';
      case 'CAD': return 'C\$';
      case 'AUD': return 'A\$';
      default: return '\$';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
    
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TradingDashboard(),
                ),
              );
            },
            icon: CircleAvatar(
              backgroundColor: Color.fromARGB(255, 112, 97, 243),
              radius: 12,
              child: Icon(
                Icons.add,
                color: Colors.white,
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
        //           Text(
        //   'Simulator',
        //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 26),
        // ),
Padding(padding: EdgeInsets.only(left: 10), child: Text('Simulator', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 26))),

SizedBox(height: 20),
                  StockGraph(
                    stockData: stockData,
                    stockName: widget.stockName,
                  ),
                  SizedBox(height: 16),
                  TimeRangeSelector(),
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
                  
                  // Financial Overview from Simulator
                  // FinancialOverview(
                  //   revenue: _financialData['revenue'],
                  //   netIncome: _financialData['netIncome'],
                  //   profitMargin: _financialData['profitMargin'],
                  //   debtToEquity: _financialData['debtToEquity'],
                  //   roe: _financialData['roe'],
                  // ),
                  // SizedBox(height: 24),
                  
                  // Investment Calculator Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Investment Growth Calculator',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Calculate your potential investment returns based on growth rate and time period',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Input Section
                  _buildInputSection(),
                  SizedBox(height: 24),
                  
                  // Results Dashboard
                  _buildResultsDashboard(),
                  SizedBox(height: 24),
                  
                  // Growth Chart
                  _buildGrowthChart(),
                  SizedBox(height: 24),
                  
                  // Yearly Breakdown
                  _buildYearlyBreakdown(),
                  SizedBox(height: 24),
                  
                  // Educational Note
                  _buildEducationalNote(),
                  SizedBox(height: 24),
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
        ),
        child: TradeButtons(),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Parameters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          
          _buildInputField(
            'Initial Investment Amount',
            _amountController,
            'Enter amount',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16),
          
          _buildDropdownField(
            'Currency',
            _selectedCurrency,
            _currencies,
            (value) => setState(() => _selectedCurrency = value!),
          ),
          SizedBox(height: 16),
          
          _buildInputField(
            'Expected Annual Growth Rate (%)',
            _growthController,
            'e.g., 12.5',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 16),
          
          // _buildInputField(
          //   'Investment Time Period',
          //   _timePeriodController,
          //   'Enter time period',
          //   keyboardType: TextInputType.number,
          // ),
          SizedBox(height: 16),
          
          _buildDropdownField(
            'Time Unit',
            _selectedTimeUnit,
            _timeUnits,
            (value) => setState(() => _selectedTimeUnit = value!),
          ),
          SizedBox(height: 16),
          
          _buildInputField(
            'Holding Period (${_selectedTimeUnit.toLowerCase()})',
            _holdingPeriodController,
            'How long will you hold?',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculateProfit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 112, 97, 243),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Calculate Returns',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color.fromARGB(255, 112, 97, 243), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          onChanged: (_) => _calculateProfit(),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((option) => DropdownMenuItem(
            value: option,
            child: Text(option),
          )).toList(),
          onChanged: (newValue) {
            onChanged(newValue);
            _calculateProfit();
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color.fromARGB(255, 112, 97, 243), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsDashboard() {
    String currencySymbol = _getCurrencySymbol(_selectedCurrency);
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Investment Results',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  'Initial Investment',
                  '$currencySymbol${double.tryParse(_amountController.text)?.toStringAsFixed(2) ?? '0.00'}',
                     const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Final Amount',
                  '$currencySymbol${_finalAmount.toStringAsFixed(2)}',
                  const Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  'Total Profit',
                  '$currencySymbol${_totalProfit.toStringAsFixed(2)}',
                  _totalProfit >= 0 ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  'Total Return',
                  '${_totalReturn.toStringAsFixed(2)}%',
                  _totalReturn >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
Widget _buildGrowthChart() {
  if (_growthChart.isEmpty) {
    return Container();
  }
  
  return Container(
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Growth Over Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 20),
        
        Container(
          height: 250,
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
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${_getCurrencySymbol(_selectedCurrency)}${(value / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(1)}y',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _growthChart,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
                        Color.fromARGB(255, 243, 247, 243).withOpacity(0.3),
                        Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,

                // ⬇️ No tooltip text => bubble with "165" disappears
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) =>
                      const Color.fromARGB(255, 240, 235, 235),
                  getTooltipItems: (touchedSpots) {
                    // return empty list => nothing to draw
                    return <LineTooltipItem>[];
                  },
                ),

                // keep vertical dashed line + dot
                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((spotIndex) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        // color: Colors.green, // enable if you want colored line
                        strokeWidth: 2,
                        dashArray: [5, 5], // dashed vertical line
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 2,
                            // strokeColor: Colors.green,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildYearlyBreakdown() {
    if (_yearlyBreakdown.isEmpty) {
      return Container();
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yearly Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text('Return %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          
          Column(
            children: _yearlyBreakdown.map((breakdown) => Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text('${breakdown.year}', style: TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text('${_getCurrencySymbol(_selectedCurrency)}${breakdown.amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text('${_getCurrencySymbol(_selectedCurrency)}${breakdown.profit.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.green))),
                  Expanded(flex: 2, child: Text('${breakdown.returnPercentage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.green))),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalNote() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(59, 143, 142, 140),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromARGB(255, 0, 0, 0))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: const Color.fromARGB(255, 0, 0, 0), size: 20),
              SizedBox(width: 8),
              Text(
                'Important Disclaimer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 110, 106, 102),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'This calculator provides estimates based on compound growth. Actual investment returns may vary significantly due to market volatility, fees, taxes, and other factors. Past performance does not guarantee future results. Always consult with financial professionals before making investment decisions.',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 12,
              height: 1.4,
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

  /// For full-height vertical line on line chart
  double? selectedSpotX;

  @override
  void initState() {
    super.initState();
    if (widget.stockData.isNotEmpty) {
      selectedValue = widget.stockData.last.y;
    }
  }

  // Fixed time formatting functions
  String getFormattedTime(double x) {
    final times = [
      "9:30 AM",
      "10:00 AM",
      "10:30 AM",
      "11:00 AM",
      "11:30 AM",
      "12:00 PM",
      "12:30 PM",
      "1:00 PM",
      "1:30 PM",
      "2:00 PM",
      "2:30 PM",
      "3:00 PM",
      "3:30 PM",
      "4:00 PM"
    ];
    int index = x.toInt().clamp(0, times.length - 1);
    return times[index];
  }

  String getFormattedDate(DateTime date) {
    List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  String getFormattedTimeFromData(double x) {
    int index = x.toInt();
    if (index >= 0 && index < widget.stockData.length) {
      DateTime baseTime = DateTime.now()
          .subtract(Duration(days: widget.stockData.length - index - 1));
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
    return ((currentValue - widget.stockData.first.y) /
            widget.stockData.first.y) *
        100;
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // LEFT: name
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
              // RIGHT: controls
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
                        selectedSpotX = null;
                      });
                    },
                    icon: Icon(
                      showCandlestick
                          ? Icons.show_chart
                          : Icons.candlestick_chart,
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

          // Chart section
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
                  double maxPan = (widget.stockData.length *
                          (zoomLevel - 1))
                      .clamp(0.0, double.infinity);
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
                Container(
                  padding: EdgeInsets.all(16),
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                  child: showCandlestick
                      ? _buildCandlestickChart(isPositive)
                      : _buildLineChart(isPositive),
                ),

                // TIMESTAMP AT TOP
                if (selectedSpotX != null && selectedTime.isNotEmpty)
                  Positioned(
                    top: 6,
                    left: ((touchX ?? (MediaQuery.of(context).size.width / 2)) -
                            60)
                        .clamp(0.0,
                            MediaQuery.of(context).size.width - 120),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        selectedTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Zoom info
                if (zoomLevel > 1.0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 112, 97, 243)
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${zoomLevel.toStringAsFixed(1)}x",
                        style: TextStyle(
                            color: Colors.white, fontSize: 10),
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

  // ================== LINE CHART ==================
  Widget _buildLineChart(bool isPositive) {
    List<FlSpot> visibleData = [];

    if (zoomLevel > 1.0) {
      int totalPoints = widget.stockData.length;
      int visiblePoints = (totalPoints / zoomLevel).floor();

      int startIndex = (panOffset / zoomLevel).abs().floor();
      startIndex = startIndex.clamp(0, totalPoints - visiblePoints);

      List<FlSpot> zoomedData = widget.stockData.sublist(
        startIndex,
        (startIndex + visiblePoints).clamp(0, totalPoints),
      );

      for (int i = 0; i < zoomedData.length; i++) {
        visibleData.add(FlSpot(i.toDouble(), zoomedData[i].y));
      }
    } else {
      visibleData = widget.stockData;
    }

    bool isOverallPositive = true;
    if (visibleData.isNotEmpty && visibleData.length > 1) {
      double firstValue = visibleData.first.y;
      double lastValue = visibleData.last.y;
      isOverallPositive = lastValue >= firstValue;
    }

    Color lineColor = isOverallPositive ? Colors.green : Colors.red;
    Color gradientStartColor = isOverallPositive
        ? Colors.green.withOpacity(0.3)
        : Colors.red.withOpacity(0.3);
    Color gradientMiddleColor = isOverallPositive
        ? Colors.green.withOpacity(0.1)
        : Colors.red.withOpacity(0.1);
    Color gradientEndColor = isOverallPositive
        ? Colors.green.withOpacity(0.0)
        : Colors.red.withOpacity(0.0);

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
          leftTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

        // FULL-HEIGHT VERTICAL DASHED LINE
        extraLinesData: ExtraLinesData(
          verticalLines: selectedSpotX == null
              ? []
              : [
                  VerticalLine(
                    x: selectedSpotX!,
                    color: Colors.black,
                    strokeWidth: 3,
                    dashArray: [6, 4],
                  ),
                ],
        ),

        lineTouchData: _getLineTouchData(),
      ),
    );
  }

  // ================== CANDLE CHART ==================
  Widget _buildCandlestickChart(bool isPositive) {
    List<CandlestickData> candlestickData = [];

    if (widget.stockData.isNotEmpty) {
      for (int i = 0; i < widget.stockData.length; i++) {
        final value = widget.stockData[i].y;
        final open =
            value * (1 - 0.005 * (i % 3 == 0 ? 1 : -1));
        final close =
            value * (1 + 0.003 * (i % 2 == 0 ? 1 : -1));
        final high = value * (1 + 0.01);
        final low = value * (1 - 0.01);

        candlestickData.add(CandlestickData(
          time: DateTime.now()
              .subtract(Duration(days: widget.stockData.length - i - 1)),
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
        (startIndex + visiblePoints).clamp(0, totalPoints),
      );
    } else {
      visibleCandlesticks = candlestickData;
    }

    return GestureDetector(
      // ✅ All three gestures for full sensitivity: tap, drag-start, drag-move
      onTapDown: (details) =>
          _handleCandlestickTap(details.localPosition, visibleCandlesticks),
      onPanStart: (details) =>
          _handleCandlestickTap(details.localPosition, visibleCandlesticks),
      onPanUpdate: (details) =>
          _handleCandlestickTap(details.localPosition, visibleCandlesticks),
      onPanEnd: (_) {
        // Keep last selected value on lift
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

  void _handleCandlestickTap(
      Offset localPosition, List<CandlestickData> candlesticks) {
    if (candlesticks.isEmpty) return;

    // ✅ Use full container width and snap to nearest candle column
    // containerWidth excludes the 16px padding on each side
    final containerWidth = (context.findRenderObject() as RenderBox?)?.size.width ?? 300;
    final effectiveWidth = containerWidth - 32; // account for Container padding
    final slotWidth = effectiveWidth / candlesticks.length;

    // ✅ round() instead of floor() so touch between two candles snaps to nearest
    int index = (localPosition.dx / slotWidth).round();
    index = index.clamp(0, candlesticks.length - 1);

    final CandlestickData tapped = candlesticks[index];
    setState(() {
      selectedCandlestick = tapped;
      selectedValue = tapped.close;
      selectedTime = getFormattedDate(tapped.time);
      touchX = localPosition.dx;
      touchY = localPosition.dy;
    });
  }

  // ================== TOUCH CONFIG FOR LINE CHART ==================
  LineTouchData _getLineTouchData() {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      // ✅ Very large threshold — snaps to nearest point anywhere on chart
      touchSpotThreshold: 9999,
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (_) => [],
        getTooltipColor: (_) => Colors.transparent,
      ),
      getTouchedSpotIndicator: (barData, spotIndexes) {
        return spotIndexes.map((index) {
          return TouchedSpotIndicatorData(
            // Full-height dashed line drawn via ExtraLinesData; show a crisp dot here
            FlLine(
              color: Colors.black.withOpacity(0.6),
              strokeWidth: 1.5,
              dashArray: [5, 4],
            ),
            FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 5,
                color: bar.color ?? Colors.green,
                strokeWidth: 2.5,
                strokeColor: Colors.white,
              ),
            ),
          );
        }).toList();
      },
      touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
        // ✅ Respond on tap, pan-start AND pan-update for full drag sensitivity
        final isActive = event is FlTapDownEvent ||
            event is FlPanDownEvent ||
            event is FlPanUpdateEvent ||
            event is FlLongPressStart ||
            event is FlLongPressMoveUpdate;

        if (isActive &&
            response?.lineBarSpots != null &&
            response!.lineBarSpots!.isNotEmpty &&
            event.localPosition != null) {
          final spot = response.lineBarSpots!.first;
          setState(() {
            selectedValue = spot.y;
            selectedSpotX = spot.x;
            selectedTime = getFormattedTimeFromData(spot.x);
            touchX = event.localPosition!.dx;
          });
        }

        if (event is FlPanEndEvent ||
            event is FlTapUpEvent ||
            event is FlLongPressEnd) {
          setState(() {
            selectedSpotX = null;
            selectedTime = "";
            touchX = null;
            // reset value back to last point
            if (widget.stockData.isNotEmpty) {
              selectedValue = widget.stockData.last.y;
            }
          });
        }
      },
    );
  }
}

// ============ CANDLESTICK DATA + PAINTER (unchanged logic) ============
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
    required this.close,
  });
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

    double priceToY(double price) =>
        height - (price - minPrice) * verticalScale;

    // Grid lines
    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      double y = height * i / gridLines;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Candles
    for (int i = 0; i < dataLength; i++) {
      final data = candlestickData[i];
      final bool isBullish = data.close >= data.open;
      final Color candleColor = isBullish ? Colors.green : Colors.red;

      final double x = i * (candleWidth + spacing * 2) + spacing;
      final double openY = priceToY(data.open);
      final double closeY = priceToY(data.close);
      final double highY = priceToY(data.high);
      final double lowY = priceToY(data.low);

      // Wick
      final Paint wickPaint = Paint()
        ..color = candleColor
        ..strokeWidth = 1.5;

      canvas.drawLine(
        Offset(x + candleWidth / 2, highY),
        Offset(x + candleWidth / 2, lowY),
        wickPaint,
      );

      // Body
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

      // Border
      final Paint borderPaint = Paint()
        ..color = candleColor.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawRect(bodyRect, borderPaint);
    }

    // Price labels
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    textPainter.text = TextSpan(
      text: '\$${maxPrice.toStringAsFixed(2)}',
      style: TextStyle(
          color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(5, 0));

    textPainter.text = TextSpan(
      text: '\$${minPrice.toStringAsFixed(2)}',
      style: TextStyle(
          color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(5, height - textPainter.height));

    double middlePrice = (maxPrice + minPrice) / 2;
    textPainter.text = TextSpan(
      text: '\$${middlePrice.toStringAsFixed(2)}',
      style: TextStyle(
          color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(5, height / 2 - textPainter.height / 2));
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


// class CandlestickPainter extends CustomPainter {
//   final List<CandlestickData> candlestickData;
//   final Color textColor;
//   final Function(CandlestickData, double, double)? onCandlestickSelected;
//   late Size _size;
  
//   CandlestickPainter({
//     required this.candlestickData,
//     required this.textColor,
//     this.onCandlestickSelected,
//   });
  
//   @override
//   void paint(Canvas canvas, Size size) {
//     _size = size;
    
//     if (candlestickData.isEmpty) return;
    
//     final double width = size.width;
//     final double height = size.height;
//     final int dataLength = candlestickData.length;
    
//     double minPrice = double.infinity;
//     double maxPrice = -double.infinity;
    
//     for (var data in candlestickData) {
//       if (data.low < minPrice) minPrice = data.low;
//       if (data.high > maxPrice) maxPrice = data.high;
//     }
    
//     final padding = (maxPrice - minPrice) * 0.1;
//     minPrice -= padding;
//     maxPrice += padding;
    
//     final double verticalScale = height / (maxPrice - minPrice);
//     final double candleWidth = width / dataLength * 0.8;
//     final double spacing = width / dataLength * 0.2 / 2;
    
//     double priceToY(double price) => height - (price - minPrice) * verticalScale;
    
//     final Paint gridPaint = Paint()
//       ..color = Colors.grey.shade300
//       ..strokeWidth = 0.5;
      
//     int gridLines = 5;
//     for (int i = 0; i <= gridLines; i++) {
//       double y = height * i / gridLines;
//       canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
//     }
    
//     for (int i = 0; i < dataLength; i++) {
//       final data = candlestickData[i];
//       final bool isBullish = data.close >= data.open;
//       final Color candleColor = isBullish ? Colors.green : Colors.red;
      
//       final double x = i * (candleWidth + spacing * 2) + spacing;
//       final double openY = priceToY(data.open);
//       final double closeY = priceToY(data.close);
//       final double highY = priceToY(data.high);
//       final double lowY = priceToY(data.low);
      
//       final Paint wickPaint = Paint()
//         ..color = candleColor
//         ..strokeWidth = 1.5;
      
//       canvas.drawLine(
//         Offset(x + candleWidth / 2, highY),
//         Offset(x + candleWidth / 2, lowY),
//         wickPaint,
//       );
      
//       final Paint bodyPaint = Paint()
//         ..color = candleColor
//         ..style = PaintingStyle.fill;
      
//       final bodyRect = Rect.fromLTRB(
//         x,
//         isBullish ? closeY : openY,
//         x + candleWidth,
//         isBullish ? openY : closeY,
//       );
      
//       canvas.drawRect(bodyRect, bodyPaint);
      
//       final Paint borderPaint = Paint()
//         ..color = candleColor.withOpacity(0.8)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 0.5;
        
//       canvas.drawRect(bodyRect, borderPaint);
//     }
    
//     final TextPainter textPainter = TextPainter(
//       textDirection: TextDirection.ltr,
//       textAlign: TextAlign.left,
//     );
    
//     textPainter.text = TextSpan(
//       text: '\${maxPrice.toStringAsFixed(2)}',
//       style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(5, 0));
    
//     textPainter.text = TextSpan(
//       text: '\${minPrice.toStringAsFixed(2)}',
//       style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(5, height - textPainter.height));
    
//     double middlePrice = (maxPrice + minPrice) / 2;
//     textPainter.text = TextSpan(
//       text: '\${middlePrice.toStringAsFixed(2)}',
//       style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.w500),
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(5, height / 2 - textPainter.height / 2));
//   }
  
//   @override
//   bool shouldRepaint(covariant CandlestickPainter oldDelegate) => 
//     oldDelegate.candlestickData != candlestickData;
    
//   @override
//   bool? hitTest(Offset position) {
//     if (candlestickData.isEmpty) return null;
    
//     final double width = _size.width;
//     final int dataLength = candlestickData.length;
//     final double candleWidth = width / dataLength * 0.8;
//     final double spacing = width / dataLength * 0.2 / 2;
    
//     for (int i = 0; i < dataLength; i++) {
//       final data = candlestickData[i];
//       final double x = i * (candleWidth + spacing * 2) + spacing;
      
//       if (position.dx >= x && position.dx <= x + candleWidth) {
//         if (onCandlestickSelected != null) {
//           onCandlestickSelected!(data, position.dx, position.dy);
//         }
//         return true;
//       }
//     }
    
//     return null;
//   }
// }

class TimeRangeSelector extends StatefulWidget {
  @override
  _TimeRangeSelectorState createState() => _TimeRangeSelectorState();
}

class _TimeRangeSelectorState extends State<TimeRangeSelector> {
  String selectedRange = "1D";

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
                onPressed: () {
                  setState(() {
                    selectedRange = label;
                  });
                },
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
      children: [],
    );
  }
}

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
          SizedBox(height: 20),
          
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                _buildPerformanceRow("Volume", "1001", "AVG Volume", "167.58M"),
                Divider(color: Colors.grey.shade300, height: 24),
                _buildPerformanceRow("Open", "188.01", "Prev. Close", "Rp4,600.00"),
                Divider(color: Colors.grey.shade300, height: 24),
                _buildPerformanceRow("RVOL", "-", "Relative Volume", "-"),
                Divider(color: Colors.grey.shade300, height: 24),
                _buildPerformanceRow("Today's Low", "188.51", "Today's High", "189.51"),
                Divider(color: Colors.grey.shade300, height: 24),
                _buildPerformanceRow("52 Week Low", "168.21", "52 Week High", "189.51"),
                Divider(color: Colors.grey.shade300, height: 24),
                _buildPerformanceRow("Day Range", "Rp4,560.00", "Year Range", "Rp3,960.00"),
                Divider(color: Colors.grey.shade300, height: 24),
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

class FinancialOverview extends StatelessWidget {
  final double revenue;
  final double netIncome;
  final double profitMargin;
  final double debtToEquity;
  final double roe;

  const FinancialOverview({
    Key? key,
    required this.revenue,
    required this.netIncome,
    required this.profitMargin,
    required this.debtToEquity,
    required this.roe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Financial Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'Revenue',
                  '\${_formatNumber(revenue)}',
                  Colors.blue,
                  Icons.trending_up,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'Net Income',
                  '\${_formatNumber(netIncome)}',
                  Colors.green,
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildFinancialCard(
                  'Profit Margin',
                  '${profitMargin.toStringAsFixed(1)}%',
                  profitMargin > 15 ? Colors.green : Colors.orange,
                  Icons.bar_chart,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFinancialCard(
                  'ROE',
                  '${roe.toStringAsFixed(1)}%',
                  roe > 15 ? Colors.green : Colors.orange,
                  Icons.show_chart,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            child: _buildFinancialCard(
              'Debt to Equity',
              debtToEquity.toStringAsFixed(2),
              debtToEquity < 1.0 ? Colors.green : Colors.red,
              Icons.balance,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
    }
    return number.toStringAsFixed(2);
  }
}

class YearlyBreakdown {
  final int year;
  final double amount;
  final double profit;
  final double returnPercentage;

  YearlyBreakdown({
    required this.year,
    required this.amount,
    required this.profit,
    required this.returnPercentage,
  });
}