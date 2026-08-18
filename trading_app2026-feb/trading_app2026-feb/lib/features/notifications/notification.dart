import 'package:flutter/material.dart';
import 'package:test_project/features/profile/npref.dart';  
enum NotificationCategory {
  fedPolicies,
  geopolitical,
  majorEvents,
  earnings,
  productLaunch,
  internalRules,
  alertSettings,
}

class NotificationItem {
  final String symbol;
  final String message;
  final String time;
  final NotificationCategory category;

  NotificationItem({
    required this.symbol,
    required this.message,
    required this.time,
    required this.category,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Set<NotificationCategory> selectedCategories = {};
  String sortOption = 'Recent First';
  bool showFilters = false;
  String searchQuery = "";

  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  final List<NotificationItem> allNotifications = [
    NotificationItem(
      symbol: 'FED',
      message: 'Federal Reserve announces 0.25% interest rate cut',
      time: '15m',
      category: NotificationCategory.fedPolicies,
    ),
    NotificationItem(
      symbol: 'SPY',
      message: 'Market rallies 2% on inflation data',
      time: '1h',
      category: NotificationCategory.fedPolicies,
    ),
    NotificationItem(
      symbol: 'OIL',
      message: 'Crude oil rises 8% amid geopolitical tension',
      time: '2h',
      category: NotificationCategory.geopolitical,
    ),
    NotificationItem(
      symbol: 'AAPL',
      message: 'Apple beats earnings expectations',
      time: '6h',
      category: NotificationCategory.earnings,
    ),
    NotificationItem(
      symbol: 'TSLA',
      message: 'Tesla unveils new EV model',
      time: '10h',
      category: NotificationCategory.productLaunch,
    ),
    NotificationItem(
      symbol: 'NVDA',
      message: 'Bullish breakout detected',
      time: '20m',
      category: NotificationCategory.internalRules,
    ),
    NotificationItem(
      symbol: 'BTC',
      message: 'Bitcoin reached your alert price',
      time: '30m',
      category: NotificationCategory.alertSettings,
    ),
  ];

  String getCategoryName(NotificationCategory category) {
    return category
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => " ${m[0]}")
        .trim();
  }

  List<NotificationItem> getFilteredNotifications() {
    var filtered = allNotifications
        .where((n) =>
            n.message.toLowerCase().contains(searchQuery.toLowerCase()) ||
            n.symbol.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    if (selectedCategories.isNotEmpty) {
      filtered = filtered.where((n) => selectedCategories.contains(n.category)).toList();
    }

    if (sortOption == 'Oldest First') filtered = filtered.reversed.toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = getFilteredNotifications();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: _primaryColor),
            onPressed: () {
              MaterialPageRoute(
         builder: (context) => NotificationScreen(),
    );
              // Navigate to notification preferences
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                border: InputBorder.none,
                hintText: "Search notifications...",
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),

          // Filter and Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Filter Button
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => showFilters = !showFilters),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: showFilters ? _primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: showFilters ? _primaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune,
                            color: showFilters ? Colors.white : _primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: showFilters ? Colors.white : _primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButton<String>(
                    value: sortOption,
                    items: ['Recent First', 'Oldest First']
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text(v, style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    underline: const SizedBox(),
                    isDense: true,
                    onChanged: (v) => setState(() => sortOption = v!),
                    icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter Chips
          if (showFilters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: NotificationCategory.values.map((c) {
                  bool selected = selectedCategories.contains(c);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? selectedCategories.remove(c) : selectedCategories.add(c);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? _primaryColor.withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? _primaryColor : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        getCategoryName(c),
                        style: TextStyle(
                          color: selected ? _primaryColor : Colors.black87,
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Notifications List
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (_, index) {
                      final n = filteredNotifications[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Unread Indicator
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Symbol Badge
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  n.symbol.toUpperCase(),
                                  style: TextStyle(
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        n.symbol,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        n.time,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    n.message,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      getCategoryName(n.category),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}