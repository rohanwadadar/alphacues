import 'package:flutter/material.dart';
import 'package:test_project/features/stock/stock_details.dart'; // Import your stock details page

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Wishlist',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedWishlist,
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                  style: TextStyle(color: Colors.black, fontSize: 14),
                  items: wishlistOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
          ],
        ),
        SizedBox(height: 16),
        
        // Holdings Section (displays wishlist stocks)
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
        // Display stocks from selected wishlist
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
        
        // Show "See All" hint if there are more than 5 stocks
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
        
        // See All Button
        if (currentWishlistStocks.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: TextButton(
                onPressed: () {
                  _showAllStocks(currentWishlistStocks);
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.deepPurple[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.deepPurple[100]!),
                  ),
                ),
                child: Text(
                  'See All ${currentWishlistStocks.length} Stocks',
                  style: TextStyle(color: Colors.deepPurple),
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