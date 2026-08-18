import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Import font awesome

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate back to main.dart
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              // Add action for chat
              print("Chat button tapped");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Section
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                      AssetImage('assets/images/profile_picture.png'), // Replace with actual path
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Fery Pratama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Last Updated On Sep 07 2024',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Account Section
              SectionTitle(title: 'Account'),
              ProfileOption(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  // Navigate to Edit Profile
                  print("Edit Profile tapped");
                },
              ),
              ProfileOption(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // Navigate to Change Password
                  print("Change Password tapped");
                },
              ),
              ProfileOption(
                icon: Icons.fingerprint,
                title: 'Biometric',
                trailing: Switch(
                  value: true, // Replace with actual state
                  onChanged: (value) {
                    // Handle biometric toggle
                    print("Biometric toggle switched to $value");
                  },
                  activeColor: Colors.blue,
                ),
              ),
              ProfileOption(
                icon: Icons.support_agent,
                title: 'Service Request',
                onTap: () {
                  // Navigate to Service Request
                  print("Service Request tapped");
                },
              ),
              ProfileOption(
                icon: Icons.shopping_bag_outlined,
                title: 'Orders',
                onTap: () {
                  // Navigate to Orders
                  print("Orders tapped");
                },
              ),
              ProfileOption(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Account details',
                onTap: () {
                  // Navigate to Account details
                  print("Account details tapped");
                },
              ),
              SizedBox(height: 20),

              // Other Section
              SectionTitle(title: 'Other'),
              ProfileOption(
                icon: Icons.description_outlined,
                title: 'Terms and Conditions',
                onTap: () {
                  // Navigate to Terms and Conditions
                  print("Terms and Conditions tapped");
                },
              ),
              ProfileOption(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  // Navigate to Privacy Policy
                  print("Privacy Policy tapped");
                },
              ),
              ProfileOption(
                icon: Icons.help_outline,
                title: 'FAQ',
                onTap: () {
                  // Navigate to FAQ
                  print("FAQ tapped");
                },
              ),
              ProfileOption(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {
                  // Handle Logout
                  print("Logout tapped");
                },
                textColor: Colors.red,
              ),
              SizedBox(height: 30),

              // Social Media Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'Our Social Media',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SocialMediaIcon(icon: FontAwesomeIcons.facebook),
                        SocialMediaIcon(icon: FontAwesomeIcons.instagram),
                        SocialMediaIcon(icon: FontAwesomeIcons.twitter),
                        SocialMediaIcon(icon: FontAwesomeIcons.whatsapp),
                        SocialMediaIcon(icon: FontAwesomeIcons.snapchat),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'App version 1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Function? onTap;
  final Color textColor;

  ProfileOption({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontSize: 16),
      ),
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap as void Function()?,
    );
  }
}

class SocialMediaIcon extends StatelessWidget {
  final IconData icon;

  SocialMediaIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
