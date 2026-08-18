import 'package:flutter/material.dart';
import 'package:test_project/features/profile/profile.dart'; // 👈 Make sure profile.dart exists

void main() {
  runApp(const AccountPage());
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        listTileTheme: const ListTileThemeData(iconColor: Colors.white),
      ),
      home: const AccountHomeScreen(),
    );
  }
}

class AccountHomeScreen extends StatelessWidget {
  const AccountHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
        ),
        title: const Text('Account Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildSectionHeader('Trading & Demat Details'),
          _buildSectionCard('Trading Controls', context),
          _buildSectionCard('DIS', context),
          _buildSectionCard('Demat Details', context),
          _buildSectionCard('Unique Client Code', context),
          _buildSectionCard('Demat Acc Number/BOID', context),
          _buildSectionCard('DP ID', context),
          _buildSectionCard('Depository Participant (Groww)', context),
          _buildSectionCard('Depository Name - CDSL', context),

          _buildSectionHeader('Account Actions'),
          _buildSectionCard('Nominees - Not Added', context),
          _buildSectionCard('Account Related Forms', context),
          _buildSectionCard('KYC, Account Opening Form', context),
          _buildSectionCard('Segments - BSE/NSE/F&O', context),
          _buildSectionCard('Close Demat & Trading Account', context),
          _buildSectionCard('UPI Settings', context),

          _buildSectionHeader('Security & Support'),
          _buildSectionCard('Report Suspicious Activity', context),
          _buildSectionCard('SEBI Related Documents', context),
          _buildSectionCard('Risk Policy', context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, BuildContext context) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceholderPage(title: title),
          ),
        );
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title content goes here.',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
