import 'package:flutter/material.dart';

// 1. Transaction Model to manage data
class Transaction {
  final String stock;
  final int quantity;
  final double price;
  final String type; // Buy, Sell, Dividend, Reward, etc.
  final String status; // Completed, Pending, Cancelled
  final String date;
  final String category; // Used for filtering (Orders, Dividends, etc.)

  Transaction({
    required this.stock,
    required this.quantity,
    required this.price,
    required this.type,
    required this.status,
    required this.date,
    required this.category,
  });
}

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Primary Purple Color from your design
  final Color primaryColor = const Color.fromARGB(255, 114, 70, 192);
  
  String selectedFilter = 'All types';

  // 2. Dummy Data (Matches categories from your image)
  final List<Transaction> transactions = [
    Transaction(stock: 'AAPL', quantity: 10, price: 150.5, type: 'Buy', status: 'Completed', date: '2025-03-20', category: 'Orders'),
    Transaction(stock: 'NVDA', quantity: 1, price: 0.02, type: 'Dividend', status: 'Completed', date: '2025-03-26', category: 'Dividends'),
    Transaction(stock: 'TSLA', quantity: 5, price: 650.3, type: 'Sell', status: 'Pending', date: '2025-03-20', category: 'Orders'),
    Transaction(stock: 'GOOGL', quantity: 1, price: 91.59, type: 'Market Buy', status: 'Completed', date: '2025-03-16', category: 'Stocks & ETFs'),
    Transaction(stock: 'MSFT', quantity: 8, price: 320.75, type: 'Buy', status: 'Completed', date: '2025-03-19', category: 'Orders'),
    Transaction(stock: 'NEE', quantity: 1, price: 0.85, type: 'Dividend', status: 'Completed', date: '2025-03-15', category: 'Dividends'),
    Transaction(stock: 'AMZN', quantity: 2, price: 3240.50, type: 'Sell', status: 'Completed', date: '2025-03-17', category: 'Orders'),
    Transaction(stock: 'LENDING', quantity: 0, price: 0.03, type: 'Payment', status: 'Completed', date: '2025-03-04', category: 'Stock lending'),
    Transaction(stock: 'META', quantity: 12, price: 225.80, type: 'Buy', status: 'Pending', date: '2025-03-16', category: 'Orders'),
    Transaction(stock: 'DEPOSIT', quantity: 1, price: 572.00, type: 'Transfer', status: 'Completed', date: '2025-03-01', category: 'Transfers'),
  ];

  // Logic to filter the list
  List<Transaction> get filteredList {
    if (selectedFilter == 'All types') return transactions;
    return transactions.where((item) => item.category == selectedFilter).toList();
  }

  // 3. Filter Bottom Sheet (Same as your image)
  void _showFilterMenu() {
    final List<String> filterOptions = [
      'All types', 'Orders', 'Stocks & ETFs', 'Transfers', 'Dividends', 'Rewards', 'Stock lending'
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Transaction type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...filterOptions.map((option) => ListTile(
                title: Text(option),
                trailing: Icon(
                  selectedFilter == option ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selectedFilter == option ? primaryColor : Colors.grey,
                ),
                onTap: () {
                  setState(() => selectedFilter = option);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Order History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        actions: [Icon(Icons.info_outline, color: primaryColor), const SizedBox(width: 15)],
      ),
      body: Column(
        children: [
          // Top Filter Chips Row
          Container(
            height: 60,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildFilterChip('All accounts', false),
                const SizedBox(width: 10),
                _buildFilterChip(selectedFilter, true, onTap: _showFilterMenu),
              ],
            ),
          ),
          
          // Scrollable List
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey(selectedFilter),
                padding: const EdgeInsets.all(16),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  // Add Section Headers for "Past 30 Days"
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        _buildOrderItem(item),
                      ],
                    );
                  }
                  return _buildOrderItem(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, {VoidCallback? onTap}) {
    return ActionChip(
      onPressed: onTap ?? () {},
      backgroundColor: Colors.white,
      shape: StadiumBorder(side: BorderSide(color: Colors.grey[300]!)),
      label: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Transaction t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Purple Box for Stock Symbol
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(t.stock, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Text(t.type, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                  ],
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: t.status == 'Completed' ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(t.status, style: TextStyle(color: t.status == 'Completed' ? Colors.green[700] : Colors.orange[700], fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn('Quantity', t.quantity.toString()),
                _buildInfoColumn('Price', '\$${t.price.toStringAsFixed(2)}'),
                _buildInfoColumn('Date', t.date),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}