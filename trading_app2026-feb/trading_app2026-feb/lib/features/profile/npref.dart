import 'package:flutter/material.dart';
import 'package:test_project/features/wishlist/wishlist.dart';

// --- MAIN SCREEN (Called by profile.dart) ---
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notification Settings', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildCategoryTile(context, "Push Notifications", Icons.notifications_none, const PushNotificationsScreen()),
          const Divider(height: 1),
          _buildCategoryTile(context, "Email Notifications", Icons.mail_outline, const EmailNotificationsScreen()),
          const Divider(height: 1),
          _buildCategoryTile(context, "SMS Notifications", Icons.sms_outlined, const SmsNotificationsScreen()),
          const Divider(height: 1),
          _buildCategoryTile(context, "Promotions", Icons.local_offer_outlined, const PromotionsScreen()),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, String title, IconData icon, Widget screen) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)),
    );
  }
}

// --- PUSH NOTIFICATIONS SCREEN (Enhanced with Navigation) ---
class PushNotificationsScreen extends StatefulWidget {
  const PushNotificationsScreen({super.key});
  @override
  _PushNotificationsScreenState createState() => _PushNotificationsScreenState();
}

class _PushNotificationsScreenState extends State<PushNotificationsScreen> {
  bool bankActivity = true;
  bool investorUpdates = true;
  bool orderStatus = true;
  bool positionChanged = false;
  bool messages = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Push Notifications')),
      body: ListView(
        children: [
          const SectionHeader(title: "My account"),
          NavTile(
            title: "Bank activity", 
            subtitle: bankActivity ? "Enabled" : "Disabled",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BankActivityScreen())),
          ),
          
          const SectionHeader(title: "My holdings"),
          NavTile(
            title: "Stock price movements", 
            subtitle: "Enabled",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StockPriceMovementsScreen())),
          ),
          const Divider(height: 1, indent: 16),
          NavTile(
            title: "Investor updates", 
            subtitle: investorUpdates ? "Enabled" : "Disabled",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InvestorUpdatesScreen())),
          ),
          const Divider(height: 1, indent: 16),
          NavTile(
            title: "Order status", 
            subtitle: orderStatus ? "Enabled" : "Disabled",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderStatusScreen())),
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Position changed", value: positionChanged, onChanged: (v) => setState(() => positionChanged = v)),
          
          const SectionHeader(title: "Watchlists"),
          NavTile(
            title: "Price movements", 
            subtitle: "5% change or more",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WatchlistPriceMovementsScreen())),
          ),
          
          const SectionHeader(title: "Communication"),
          NavTile(
            title: "Messages", 
            subtitle: messages ? "Enabled" : "Disabled",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen())),
          ),
        ],
      ),
    );
  }
}

// --- BANK ACTIVITY SCREEN ---
class BankActivityScreen extends StatefulWidget {
  const BankActivityScreen({super.key});
  @override
  _BankActivityScreenState createState() => _BankActivityScreenState();
}

class _BankActivityScreenState extends State<BankActivityScreen> {
  bool deposits = true;
  bool withdrawals = true;
  bool transfers = true;
  bool recurringTransfers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bank Activity'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Get notified about transactions in your account',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          
          const SectionHeader(title: "Transactions"),
          ToggleTile(
            title: "Deposits", 
            subtitle: "When money is added to your account",
            value: deposits, 
            onChanged: (v) => setState(() => deposits = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Withdrawals", 
            subtitle: "When money is withdrawn",
            value: withdrawals, 
            onChanged: (v) => setState(() => withdrawals = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Transfers", 
            subtitle: "Bank transfers and ACH transactions",
            value: transfers, 
            onChanged: (v) => setState(() => transfers = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Recurring transfers", 
            subtitle: "Scheduled automatic transfers",
            value: recurringTransfers, 
            onChanged: (v) => setState(() => recurringTransfers = v)
          ),
        ],
      ),
    );
  }
}

// --- ORDER STATUS SCREEN ---
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});
  @override
  _OrderStatusScreenState createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  bool orderFilled = true;
  bool orderCancelled = true;
  bool partialFills = false;
  bool orderExpired = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Status'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Receive updates about your trade orders',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          
          const SectionHeader(title: "Order updates"),
          ToggleTile(
            title: "Order filled", 
            subtitle: "When your order is completely executed",
            value: orderFilled, 
            onChanged: (v) => setState(() => orderFilled = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Partial fills", 
            subtitle: "When part of your order is executed",
            value: partialFills, 
            onChanged: (v) => setState(() => partialFills = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Order cancelled", 
            subtitle: "When your order is cancelled",
            value: orderCancelled, 
            onChanged: (v) => setState(() => orderCancelled = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Order expired", 
            subtitle: "When your limit order expires",
            value: orderExpired, 
            onChanged: (v) => setState(() => orderExpired = v)
          ),
        ],
      ),
    );
  }
}

// --- INVESTOR UPDATES SCREEN ---
class InvestorUpdatesScreen extends StatefulWidget {
  const InvestorUpdatesScreen({super.key});
  @override
  _InvestorUpdatesScreenState createState() => _InvestorUpdatesScreenState();
}

class _InvestorUpdatesScreenState extends State<InvestorUpdatesScreen> {
  bool companyNews = true;
  bool shareholderMeetings = true;
  bool proxyVoting = false;
  bool corporateActions = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Investor Updates'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Stay informed about companies you invest in',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          
          const SectionHeader(title: "Company information"),
          ToggleTile(
            title: "Company news", 
            subtitle: "Press releases and major announcements",
            value: companyNews, 
            onChanged: (v) => setState(() => companyNews = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Shareholder meetings", 
            subtitle: "Annual and special meeting notices",
            value: shareholderMeetings, 
            onChanged: (v) => setState(() => shareholderMeetings = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Proxy voting", 
            subtitle: "Voting opportunities and deadlines",
            value: proxyVoting, 
            onChanged: (v) => setState(() => proxyVoting = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Corporate actions", 
            subtitle: "Stock splits, mergers, and acquisitions",
            value: corporateActions, 
            onChanged: (v) => setState(() => corporateActions = v)
          ),
        ],
      ),
    );
  }
}

// --- MESSAGES SCREEN ---
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool directMessages = true;
  bool supportReplies = true;
  bool systemAnnouncements = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Manage how you receive message notifications',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          
          const SectionHeader(title: "Message types"),
          ToggleTile(
            title: "Direct messages", 
            subtitle: "Messages from support and staff",
            value: directMessages, 
            onChanged: (v) => setState(() => directMessages = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Support replies", 
            subtitle: "Responses to your support tickets",
            value: supportReplies, 
            onChanged: (v) => setState(() => supportReplies = v)
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "System announcements", 
            subtitle: "Important platform updates",
            value: systemAnnouncements, 
            onChanged: (v) => setState(() => systemAnnouncements = v)
          ),
        ],
      ),
    );
  }
}

// --- STOCK PRICE MOVEMENTS SCREEN (My Holdings) ---
class StockPriceMovementsScreen extends StatefulWidget {
  const StockPriceMovementsScreen({super.key});
  @override
  _StockPriceMovementsScreenState createState() => _StockPriceMovementsScreenState();
}

class _StockPriceMovementsScreenState extends State<StockPriceMovementsScreen> {
  bool enabled = true;
  bool percent5 = true;
  bool percent10 = false;
  bool weekHigh52 = true;
  bool weekLow52 = true;
  bool overnightAlerts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stock Price Movements', style: TextStyle(fontSize: 18)),
            Text('My Holdings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Get notified when stocks in your portfolio experience significant price changes',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          
          ToggleTile(
            title: "Enable price movement alerts", 
            value: enabled, 
            onChanged: (v) => setState(() => enabled = v)
          ),
          
          const Divider(height: 32, thickness: 8, color: Color(0xFFF5F5F5)),
          
          const SectionHeader(title: "Price change alerts"),
          ToggleTile(
            title: "5% change or more", 
            value: percent5 && enabled, 
            onChanged: enabled ? (v) => setState(() => percent5 = v) : null
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "10% change or more", 
            value: percent10 && enabled, 
            onChanged: enabled ? (v) => setState(() => percent10 = v) : null
          ),
          
          const SectionHeader(title: "Milestone alerts"),
          ToggleTile(
            title: "52-week high", 
            value: weekHigh52 && enabled, 
            onChanged: enabled ? (v) => setState(() => weekHigh52 = v) : null
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "52-week low", 
            value: weekLow52 && enabled, 
            onChanged: enabled ? (v) => setState(() => weekLow52 = v) : null
          ),
          
          const SectionHeader(title: "Quiet hours"),
          ToggleTile(
            title: "Overnight alerts (8pm - 7am ET)", 
            subtitle: "Receive alerts during off-market hours",
            value: overnightAlerts && enabled, 
            onChanged: enabled ? (v) => setState(() => overnightAlerts = v) : null
          ),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Note: You\'ll receive at most one alert per stock per day to avoid notification overload',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WATCHLIST PRICE MOVEMENTS SCREEN ---
class WatchlistPriceMovementsScreen extends StatefulWidget {
  const WatchlistPriceMovementsScreen({super.key});
  @override
  _WatchlistPriceMovementsScreenState createState() => _WatchlistPriceMovementsScreenState();
}

class _WatchlistPriceMovementsScreenState extends State<WatchlistPriceMovementsScreen> {
  bool enabled = true;
  bool percent5 = true;
  bool percent10 = false;
  bool percent15 = false;
  bool weekHigh52 = false;
  bool weekLow52 = false;
  bool overnightAlerts = true;
  bool earningsAnnouncements = true;
  bool dividendAnnouncements = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Movements', style: TextStyle(fontSize: 18)),
            Text('Watchlists', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Get notified about significant changes for stocks on your watchlists',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          
          ToggleTile(
            title: "Enable watchlist alerts", 
            value: enabled, 
            onChanged: (v) => setState(() => enabled = v)
          ),
          
          const Divider(height: 32, thickness: 8, color: Color(0xFFF5F5F5)),
          
          const SectionHeader(title: "Price change alerts"),
          ToggleTile(
            title: "5% change or more", 
            value: percent5 && enabled, 
            onChanged: enabled ? (v) => setState(() => percent5 = v) : null
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "10% change or more", 
            value: percent10 && enabled, 
            onChanged: enabled ? (v) => setState(() => percent10 = v) : null
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "15% change or more", 
            value: percent15 && enabled, 
            onChanged: enabled ? (v) => setState(() => percent15 = v) : null
          ),
          
          const SectionHeader(title: "Milestone alerts"),
          ToggleTile(
            title: "52-week high", 
            value: weekHigh52 && enabled, 
            onChanged: enabled ? (v) => setState(() => weekHigh52 = v) : null
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "52-week low", 
            value: weekLow52 && enabled, 
            onChanged: enabled ? (v) => setState(() => weekLow52 = v) : null
          ),
          
          const SectionHeader(title: "Corporate events"),
          ToggleTile(
            title: "Earnings announcements", 
            subtitle: "Before market open or after close",
            value: earningsAnnouncements && enabled, 
            onChanged: enabled ? (v) => setState(() => earningsAnnouncements = v) : null
          ),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Dividend announcements", 
            value: dividendAnnouncements && enabled, 
            onChanged: enabled ? (v) => setState(() => dividendAnnouncements = v) : null
          ),
          
          const SectionHeader(title: "Quiet hours"),
          ToggleTile(
            title: "Overnight alerts (8pm - 7am ET)", 
            subtitle: "Receive alerts during off-market hours",
            value: overnightAlerts && enabled, 
            onChanged: enabled ? (v) => setState(() => overnightAlerts = v) : null
          ),
          
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: enabled ? () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const WatchlistSettingsScreen()
                ));
              } : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 114, 70, 192),
                side: const BorderSide(color: Color.fromARGB(255, 114, 70, 192)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Watchlist Settings'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// --- MANAGE WATCHLISTS SCREEN ---
class WatchlistSettingsScreen extends StatefulWidget {
  const WatchlistSettingsScreen({super.key});
  @override
  _WatchlistSettingsScreenState createState() => _WatchlistSettingsScreenState();
}

class _WatchlistSettingsScreenState extends State<WatchlistSettingsScreen> {
  final Map<String, bool> watchlists = {
    "My Main Watchlist": true,
    "Tech Stocks": true,
    "Dividend Kings": false,
    "Crypto & Blockchain": true,
    "Energy Sector": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Watchlist Settings'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choose which watchlists you want to receive notifications for',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          ...watchlists.keys.map((name) {
            return Column(
              children: [
                ToggleTile(
                  title: name,
                  value: watchlists[name]!,
                  onChanged: (v) => setState(() => watchlists[name] = v),
                ),
                if (name != watchlists.keys.last) const Divider(height: 1, indent: 16),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

// --- EMAIL NOTIFICATIONS SCREEN ---
class EmailNotificationsScreen extends StatefulWidget {
  const EmailNotificationsScreen({super.key});
  @override
  _EmailNotificationsScreenState createState() => _EmailNotificationsScreenState();
}

class _EmailNotificationsScreenState extends State<EmailNotificationsScreen> {
  bool bankActivity = true;
  bool investorUpdates = false;
  bool orderStatus = true;
  bool positionChanged = true;
  bool weeklyDigest = true;
  bool monthlyStatements = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Email Notifications')),
      body: ListView(
        children: [
          const SectionHeader(title: "My account"),
          ToggleTile(title: "Bank activity", value: bankActivity, onChanged: (v) => setState(() => bankActivity = v)),
          
          const SectionHeader(title: "My holdings"),
          ToggleTile(title: "Investor updates", value: investorUpdates, onChanged: (v) => setState(() => investorUpdates = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Order status", value: orderStatus, onChanged: (v) => setState(() => orderStatus = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Position changed", value: positionChanged, onChanged: (v) => setState(() => positionChanged = v)),
          
          const SectionHeader(title: "IPOs"),
          const ToggleTile(title: "IPO Access", value: true, onChanged: null),
          
          const SectionHeader(title: "Reports"),
          ToggleTile(title: "Weekly portfolio digest", value: weeklyDigest, onChanged: (v) => setState(() => weeklyDigest = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Monthly statements", value: monthlyStatements, onChanged: (v) => setState(() => monthlyStatements = v)),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// --- SMS NOTIFICATIONS SCREEN ---
class SmsNotificationsScreen extends StatefulWidget {
  const SmsNotificationsScreen({super.key});
  @override
  _SmsNotificationsScreenState createState() => _SmsNotificationsScreenState();
}

class _SmsNotificationsScreenState extends State<SmsNotificationsScreen> {
  bool otpAlerts = true;
  bool accountAlerts = false;
  bool largeTransactions = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('SMS Notifications')),
      body: ListView(
        children: [
          const SectionHeader(title: "Security"),
          ToggleTile(title: "OTP Alerts", value: otpAlerts, onChanged: (v) => setState(() => otpAlerts = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Account Alerts", value: accountAlerts, onChanged: (v) => setState(() => accountAlerts = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(
            title: "Large transactions", 
            subtitle: "Transfers over \$10,000",
            value: largeTransactions, 
            onChanged: (v) => setState(() => largeTransactions = v)
          ),
        ],
      ),
    );
  }
}

// --- PROMOTIONS SCREEN ---
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});
  @override
  _PromotionsScreenState createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  bool specialOffers = false;
  bool discounts = true;
  bool newFeatures = true;
  bool referralProgram = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Promotions')),
      body: ListView(
        children: [
          const SectionHeader(title: "Offers"),
          ToggleTile(title: "Special Offers", value: specialOffers, onChanged: (v) => setState(() => specialOffers = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Discount Alerts", value: discounts, onChanged: (v) => setState(() => discounts = v)),
          
          const SectionHeader(title: "Product updates"),
          ToggleTile(title: "New features", value: newFeatures, onChanged: (v) => setState(() => newFeatures = v)),
          const Divider(height: 1, indent: 16),
          ToggleTile(title: "Referral program", value: referralProgram, onChanged: (v) => setState(() => referralProgram = v)),
        ],
      ),
    );
  }
}

// --- DESIGN HELPER COMPONENTS ---

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(width: 4),
          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  
  const NavTile({
    super.key, 
    required this.title, 
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}

class ToggleTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ToggleTile({
    super.key, 
    required this.title, 
    required this.value, 
    this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 13, color: Colors.grey[600])) : null,
      value: value,
      onChanged: onChanged,
      activeColor: const Color.fromARGB(255, 114, 70, 192),
    );
  }
}
