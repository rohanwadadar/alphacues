import 'package:flutter/material.dart';

class MessagesPreferencesPage extends StatefulWidget {
  const MessagesPreferencesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPreferencesPage> createState() => _MessagesPreferencesPageState();
}

class _MessagesPreferencesPageState extends State<MessagesPreferencesPage> {
  // My account toggles
  bool _bankActivity = true;

  // My holdings toggles
  bool _investorUpdates = true;
  bool _orderStatus = true;

  // From = toggles
  bool _referrals = true;

  // IPOs toggles
  bool _ipoAccess = true;

  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  @override
  Widget build(BuildContext context) {
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
          'Messages on our App',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My account section
            _buildSection(
              title: 'My account',
              showInfo: true,
              children: [
                _buildSwitchTile(
                  title: 'Bank activity',
                  value: _bankActivity,
                  onChanged: (value) => setState(() => _bankActivity = value),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My holdings section
            _buildSection(
              title: 'My holdings',
              showInfo: true,
              children: [
                _buildSwitchTile(
                  title: 'Investor updates',
                  value: _investorUpdates,
                  onChanged: (value) => setState(() => _investorUpdates = value),
                ),
                Divider(color: Colors.grey[300], height: 1),
                _buildSwitchTile(
                  title: 'Order status',
                  value: _orderStatus,
                  onChanged: (value) => setState(() => _orderStatus = value),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // From app section
            _buildSection(
              title: 'From Our App',
              showInfo: true,
              children: [
                _buildSwitchTile(
                  title: 'Referrals',
                  value: _referrals,
                  onChanged: (value) => setState(() => _referrals = value),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // IPOs section
            _buildSection(
              title: 'IPOs',
              showInfo: true,
              children: [
                _buildSwitchTile(
                  title: 'IPO Access',
                  value: _ipoAccess,
                  onChanged: (value) => setState(() => _ipoAccess = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    bool showInfo = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showInfo) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                color: Colors.grey[600],
                size: 20,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
            ),
          ),
          Switch(
            value: value,
            activeColor: _primaryColor,
            activeTrackColor: _primaryColor.withOpacity(0.5),
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}