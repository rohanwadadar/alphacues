// // // // //white theme 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Import your existing pages
import 'package:test_project/features/profile/edit_profile.dart';
import 'package:test_project/features/wishlist/wishlist.dart';
import 'package:test_project/features/trading/topup.dart';
import 'package:test_project/features/trading/order.dart';
import 'package:test_project/features/profile/pinfo.dart';
import 'package:test_project/features/trading/tax.dart';
import 'package:test_project/features/profile/change_password.dart';
import 'package:test_project/features/security/two_factor.dart';
import 'package:test_project/features/profile/privacy.dart';
import 'package:test_project/features/profile/bio.dart';
import 'package:test_project/features/profile/npref.dart';
import 'package:test_project/features/trading/report.dart';
import 'package:test_project/features/profile/account.dart';
import 'package:test_project/features/trading/reward.dart';
import 'package:test_project/features/security/security_screen.dart';
import 'package:test_project/features/notifications/message_center.dart';
import 'package:test_project/features/profile/Investment_profile.dart';
// ---------------------------------------------------------------------------
// MAIN PROFILE SCREEN
// ---------------------------------------------------------------------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  int customerId = 1222;
  bool _layoutSwitchValue = false;

  @override
  void initState() {
    super.initState();
    fetchCustomerId();
  }

  Future<void> fetchCustomerId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      customerId = prefs.getInt('customerId') ?? 1222;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        //   onPressed: () => Navigator.of(context).pop(),
        // ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primaryColor, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Fery Pratama',
                      style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Last Updated: Sep 07, 2024',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // --- Account Section ---
                  _buildSectionCard(title: 'Account', children: [
                    _buildOptionTile(icon: Icons.person_outline, title: 'Edit Account', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.shopping_bag_outlined, title: 'Orders', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => OrderPage()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.trending_up, title: 'Investment', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InvestmentProfile()))),
                  ]),
                  const SizedBox(height: 16),
// Change Icons.invest to a valid icon like Icons.trending_up or Icons.show_chart

                  // --- Security Section ---
                  _buildSectionCard(title: 'Security', children: [
                    _buildOptionTile(icon: Icons.lock_outline, title: 'Change Password', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPage()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.fingerprint, title: 'Security & App Lock', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.shield_outlined, title: 'Two-Factor Authentication', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Settings', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacySettingsPage()))),
                  ]),
                  const SizedBox(height: 16),

                  // --- Financial Section (RESTORED) ---
                  _buildSectionCard(title: 'Financial', children: [
                    _buildOptionTile(icon: Icons.description_outlined, title: 'Tax Center', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaxCenter()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.assessment_outlined, title: 'Reports & Statements', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReportPage()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.emoji_events_outlined, title: 'Rewards', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RewardPage()))),
                  ]),
                  const SizedBox(height: 16),

                  // --- Communication Section ---
                  _buildSectionCard(title: 'Communication', children: [
                    _buildOptionTile(icon: Icons.email_outlined, title: 'Message Center', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesPreferencesPage()))),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.notifications_outlined, title: 'Notification Preferences', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationScreen()))),
                  ]),
                  const SizedBox(height: 16),

                  // --- App preference & Data usage Section ---
                  _buildSectionCard(
                    title: 'App preference & Data usage',
                    children: [
                      _buildOptionTile(
                        icon: Icons.data_usage_outlined,
                        title: 'Data Usage Settings',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DataUsageSettingsScreen())),
                      ),
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.tune_outlined,
                        title: 'App Preferences',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AppAppearanceScreen())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Preferences Section ---
                  _buildSectionCard(title: 'Preferences', children: [
                    _buildOptionTile(icon: Icons.featured_play_list_outlined, title: 'Feature Settings', onTap: () {}),
                    _buildDivider(),
                    _buildSwitchTile(icon: Icons.view_quilt, title: 'Layout', value: _layoutSwitchValue, onChanged: (v) => setState(() => _layoutSwitchValue = v)),
                  ]),
                  const SizedBox(height: 16),

                  // --- Support Section ---
                  _buildSectionCard(title: 'Support', children: [
                    _buildOptionTile(icon: Icons.help_outline, title: 'FAQ', onTap: () {}),
                    _buildDivider(),
                    _buildOptionTile(icon: Icons.support_agent, title: 'Contact Support', onTap: () {}),
                  ]),
                  const SizedBox(height: 16),

                  // --- Logout Button ---
                  _buildSectionCard(title: '', children: [
                    _buildOptionTile(icon: Icons.logout, title: 'Logout', onTap: () {}, textColor: Colors.red, iconColor: Colors.red),
                  ]),
                  const SizedBox(height: 24),
                  Text('App version 1.0.0', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (title.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              decoration: TextDecoration.underline,
              decorationColor: Colors.grey[300],
              decorationThickness: 2,
            ),
          ),
        ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(children: children),
      ),
    ]);
  }

  Widget _buildOptionTile({required IconData icon, required String title, required VoidCallback onTap, Color textColor = Colors.black, Color? iconColor}) {
    // If iconColor is explicitly set (e.g. red for logout), use it. Otherwise use neutral black-on-lightgrey.
    final bool isSpecialColor = iconColor != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSpecialColor ? iconColor!.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSpecialColor ? iconColor : Colors.black87,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
        ]),
      ),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(title, style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500))),
        Switch(value: value, activeColor: _primaryColor, onChanged: onChanged),
      ]),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.grey[200], height: 1, indent: 58);
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 1: DATA USAGE SETTINGS
// ---------------------------------------------------------------------------
class DataUsageSettingsScreen extends StatefulWidget {
  const DataUsageSettingsScreen({Key? key}) : super(key: key);
  @override
  _DataUsageSettingsScreenState createState() => _DataUsageSettingsScreenState();
}

class _DataUsageSettingsScreenState extends State<DataUsageSettingsScreen> {
  int _selectedAutoplayIndex = 0;
  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Data usage', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 24, 16, 16), child: Text('Autoplay videos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        _buildCheckTile(0, "On mobile data and Wi-Fi connections"),
        const Divider(height: 1, indent: 16),
        _buildCheckTile(1, "On Wi-Fi connections only"),
        const Divider(height: 1, indent: 16),
        _buildCheckTile(2, "Never autoplay videos"),
      ]),
    );
  }

  Widget _buildCheckTile(int index, String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: _selectedAutoplayIndex == index ? Icon(Icons.check, color: _primaryColor) : null,
      onTap: () => setState(() => _selectedAutoplayIndex = index),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-SCREEN 2: APP APPEARANCE SCREEN
// ---------------------------------------------------------------------------
class AppAppearanceScreen extends StatefulWidget {
  const AppAppearanceScreen({Key? key}) : super(key: key);
  @override
  _AppAppearanceScreenState createState() => _AppAppearanceScreenState();
}

class _AppAppearanceScreenState extends State<AppAppearanceScreen> {
  bool _accessibleColors = false;
  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('App appearance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        // Preview Graphic (Mimicking Robinhood)
        Container(
          height: 220,
          width: double.infinity,
          color: Colors.grey[50],
          child: Stack(alignment: Alignment.center, children: [
            Positioned(top: 40, left: 0, right: 0, child: CustomPaint(size: const Size(double.infinity, 80), painter: SimpleWavePainter(_primaryColor))),
            Positioned(bottom: 30, child: Container(
                width: 200, height: 48,
                decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(24)),
                alignment: Alignment.center,
                child: const Text('Trade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))),
          ]),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Theme', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          subtitle: Text('Market hours', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ),
        const Divider(height: 1, indent: 16),
        SwitchListTile(
          title: const Text('Accessible colors', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          subtitle: const Text('Best for red-green colorblindness', style: TextStyle(fontSize: 13, color: Colors.grey)),
          value: _accessibleColors,
          activeColor: _primaryColor,
          onChanged: (val) => setState(() => _accessibleColors = val),
        ),
      ]),
    );
  }
}

class SimpleWavePainter extends CustomPainter {
  final Color color;
  SimpleWavePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.1, size.width * 0.5, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.9, size.width, size.height * 0.3);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width, size.height * 0.3), 6, Paint()..color = color);
    canvas.drawCircle(Offset(size.width, size.height * 0.3), 12, Paint()..color = color.withOpacity(0.2));
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}














































// // // // import 'package:flutter/material.dart';
// // // // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // // // import 'package:test_project/features/profile/edit_profile.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // import 'package:test_project/features/wishlist/wishlist.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // import 'package:test_project/features/trading/topup.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // import 'package:test_project/features/trading/order.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // import 'package:test_project/features/profile/pinfo.dart';
// // // // import 'package:test_project/features/trading/tax.dart';
// // // // import 'package:test_project/features/profile/change_password.dart';
// // // // import 'package:test_project/features/security/two_factor.dart';
// // // // import 'package:test_project/features/profile/privacy.dart';
// // // // import 'package:test_project/features/profile/bio.dart';
// // // // import 'package:test_project/features/profile/npref.dart';  //notifcation preferance
// // // // import 'package:test_project/features/trading/report.dart';
// // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // import 'package:test_project/features/profile/account.dart';
// // // // import 'package:test_project/features/trading/reward.dart';

// // // // class ProfileScreen extends StatefulWidget {
// // // //   const ProfileScreen({Key? key}) : super(key: key);

// // // //   @override
// // // //   _ProfileScreenState createState() => _ProfileScreenState();
// // // // }

// // // // class _ProfileScreenState extends State<ProfileScreen> {
// // // //   int customerId = 1222;  // Default value

// // // //   @override
// // // //   void initState() {
// // // //     super.initState();
// // // //     fetchCustomerId();
// // // //   }

// // // //  Future<void> fetchCustomerId() async {
// // // //   final SharedPreferences prefs = await SharedPreferences.getInstance();
// // // //   setState(() {
// // // //     customerId = prefs.getInt('customerId') ?? 1222;  // Use stored ID, else default to 1222
// // // //   });
// // // // }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       backgroundColor: Colors.white,
// // // //       appBar: AppBar(
// // // //         backgroundColor: Colors.white,
// // // //         elevation: 1,
// // // //         shadowColor: Colors.grey.shade200,
// // // //         title: Text(
// // // //           'Profile',
// // // //           style: TextStyle(
// // // //             color: Colors.black,
// // // //             fontWeight: FontWeight.bold,
// // // //           ),
// // // //         ),
// // // //         centerTitle: true,
// // // //         leading: IconButton(
// // // //           icon: Icon(Icons.arrow_back, color: Colors.black),
// // // //           onPressed: () => Navigator.of(context).pop(),
// // // //         ),
// // // //         actions: [
// // // //           IconButton(
// // // //             icon: Icon(Icons.chat_bubble_outline, color: Color.fromARGB(255, 112, 97, 243)),
// // // //             onPressed: () {
// // // //               // Add action for chat
// // // //             },
// // // //           ),
// // // //         ],
// // // //       ),
// // // //       body: SingleChildScrollView(
// // // //         child: Padding(
// // // //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // //           child: Column(
// // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // //             children: [
// // // //               // Profile Header Section
// // // //               SizedBox(height: 20),
// // // //               Center(
// // // //                 child: Column(
// // // //                   children: [
// // // //                     Container(
// // // //                       decoration: BoxDecoration(
// // // //                         shape: BoxShape.circle,
// // // //                         border: Border.all(color: const Color.fromARGB(255, 142, 88, 228), width: 3),
// // // //                       ),
// // // //                       child: CircleAvatar(
// // // //                         radius: 50,
// // // //                         backgroundImage:
// // // //                         AssetImage('assets/images/profile.png'),
// // // //                       ),
// // // //                     ),
// // // //                     SizedBox(height: 10),
// // // //                     Text(
// // // //                       'Fery Pratama',
// // // //                       style: TextStyle(
// // // //                         color: Colors.black,
// // // //                         fontSize: 22,
// // // //                         fontWeight: FontWeight.bold,
// // // //                       ),
// // // //                     ),
// // // //                     SizedBox(height: 5),
// // // //                     Text(
// // // //                       'Last Updated On Sep 07 2024',
// // // //                       style: TextStyle(
// // // //                         color: Colors.grey.shade600,
// // // //                         fontSize: 14,
// // // //                       ),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //               SizedBox(height: 30),

// // // //               // About Section
// // // //               SectionTitle(title: 'About'),
// // // //               ProfileOption(
// // // //                 icon: Icons.person_outline,
// // // //                 title: 'Edit Profile',
// // // //                 onTap: () {
// // // //                   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => EditProfileScreen()),
// // // //                   );
// // // //                 },
// // // //               ),
// // // //            ProfileOption(
// // // //   icon: Icons.info_outline,
// // // //   title: 'Profile Information',
// // // //   onTap: () {
// // // //     if (customerId != null && customerId != 0) {  // Ensure it's valid
// // // //       Navigator.push(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (context) => ProfileInfoPage(customerId: customerId),
// // // //         ),
// // // //       );
// // // //     } else {
// // // //       print("Error: customerId is null or invalid");
// // // //     }
// // // //   },
// // // // ),

// // // //               // Activity & Orders Section
// // // //               SectionTitle(title: 'Activity & Orders'),
// // // //               ProfileOption(
// // // //                 icon: Icons.history,
// // // //                 title: 'Activity History',
// // // //                 onTap: () {
// // // //                   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => TopUpScreen()),
// // // //                   );
// // // //                 },
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.shopping_bag_outlined,
// // // //                 title: 'Orders',
// // // //                 onTap: () {
// // // //                   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => OrderPage()),
// // // //                   );

// // // //                 },
// // // //               ),

// // // //               // Security Section
// // // //               SectionTitle(title: 'Security'),
// // // //               ProfileOption(
// // // //                 icon: Icons.lock_outline,
// // // //                 title: 'Change Password',
// // // //                 onTap: () {  Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => ChangePasswordPage()),
// // // //                   );

// // // //                 },
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.fingerprint,
// // // //                 title: 'Enable Biometric Authentication',
// // // //                 onTap: () {  Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => BiometricAuthenticationPage()),
// // // //                   );
// // // //                   // Add biometric authentication setup here
// // // //                 },
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.shield_outlined,
// // // //                 title: 'Two-Factor Authentication',
// // // //                 onTap: () {
// // // //   Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()),
// // // //                   );
// // // //                 },
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.privacy_tip_outlined,
// // // //                 title: 'Privacy Settings',
// // // //                 onTap: () {  Navigator.push(
// // // //                     context,
// // // //                     MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
// // // //                   );

// // // //                 },
// // // //               ),

// // // //               // Watch Lists Section
// // // //               SectionTitle(title: 'Watch Lists'),
// // // //               ProfileOption(
// // // //                 icon: Icons.star_outline,
// // // //                 title: 'Manage Watch Lists',
// // // //                 onTap: () {
// // // //                   Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => TradingDashboard()),
// // // //                 );},
// // // //               ),

// // // //               // Tax Forms Section
// // // //               SectionTitle(title: 'Tax Forms'),
// // // //               ProfileOption(
// // // //                 icon: Icons.description_outlined,
// // // //                 title: 'Tax Center',
// // // //                 onTap: () {   Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => TaxCenter()),
// // // //                 );},
// // // //               ),

// // // //               // Communication Section
// // // //               SectionTitle(title: 'Communication'),
// // // //               ProfileOption(
// // // //                 icon: Icons.email_outlined,
// // // //                 title: 'Message Center',
// // // //                 onTap: () {},
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.notifications_outlined,
// // // //                 title: 'Notification Preferences & alerts',
// // // //                 onTap: () { Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => NotificationScreen()),
// // // //                 );},
// // // //               ),
 
// // // //               // Account Features Section
// // // //               SectionTitle(title: 'Account Features'),
// // // //               ProfileOption(
// // // //                 icon: Icons.featured_play_list_outlined,
// // // //                 title: 'Feature Settings',
// // // //                 onTap: () {},
// // // //               ),

// // // //               // Payments & Transfers Section
// // // //               SectionTitle(title: 'Payments & Transfers'),
// // // //               ProfileOption(
// // // //                 icon: Icons.payments_outlined,
// // // //                 title: 'Payment Methods',
// // // //                 onTap: ()  { Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => TopUpScreen()),
// // // //                 );},
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.swap_horiz,
// // // //                 title: 'Transfer Settings',
// // // //                 onTap: () {},
// // // //               ),

// // // //               // Brokerage & Trading Section
// // // //               SectionTitle(title: 'Brokerage & Trading'),
// // // //               ProfileOption(
// // // //                 icon: Icons.trending_up,
// // // //                 title: 'Trading Preferences',
// // // //                 onTap: () {},
// // // //               ),

// // // //               // Banks & Cards Section
// // // //               SectionTitle(title: 'Banks & Cards'),
// // // //               ProfileOption(
// // // //                 icon: Icons.credit_card,
// // // //                 title: 'Manage Debit Cards',
// // // //                 onTap: () {},
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.account_balance,
// // // //                 title: 'Linked Accounts & Banks',
// // // //                 onTap: () {Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => AccountPage()),
// // // //                 );},
// // // //               ),
  
// // // //              // Settings Section
// // // //               SectionTitle(title: 'Report'),
// // // //               ProfileOption(
// // // //                 icon: Icons.settings,
// // // //                 title: 'Report & Statements',
// // // //                 onTap: () { Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) => ReportPage()),
// // // //                 );},
// // // //               ),
              
// // // //               // Settings Section
// // // //               SectionTitle(title: 'Settings'),
// // // //               ProfileOption(
// // // //                 icon: Icons.settings,
// // // //                 title: 'General Settings',
// // // //                 onTap: () {},
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.view_quilt,
// // // //                 title: 'Layout',
// // // //                 trailing: Switch(
// // // //                   value: false,
// // // //                   onChanged: (value) {},
// // // //                   activeColor: Color.fromARGB(255, 112, 97, 243),
// // // //                 ),
// // // //               ),

// // // //               // Help Section
// // // //               SectionTitle(title: 'Get Help'),
// // // //               ProfileOption(
// // // //                 icon: Icons.help_outline,
// // // //                 title: 'FAQ',
// // // //                 onTap: () {},
// // // //               ),

// // // //               ProfileOption(
// // // //                 icon: Icons.emoji_events,
// // // //                 title: 'Rewards',
// // // //                 onTap: () { Navigator.push(
// // // //                   context,
// // // //                   MaterialPageRoute(builder: (context) =>RewardPage()),
// // // //                 );},
// // // //               ),
// // // //               ProfileOption(
// // // //                 icon: Icons.support_agent,
// // // //                 title: 'Contact Support',
// // // //                 onTap: () {},
// // // //               ),

// // // //               // Logout Option
// // // //               SizedBox(height: 20),
// // // //               ProfileOption(
// // // //                 icon: Icons.logout,
// // // //                 title: 'Logout',
// // // //                 onTap: () {},
// // // //                 textColor: Colors.red,
// // // //               ),

// // // //               SizedBox(height: 30),
// // // //               // Social Media Section
// // // //               Center(
// // // //                 child: Column(
// // // //                   children: [
// // // //                     Text(
// // // //                       'Our Social Media',
// // // //                       style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
// // // //                     ),
// // // //                     SizedBox(height: 10),
// // // //                     Row(
// // // //                       mainAxisAlignment: MainAxisAlignment.center,
// // // //                       children: [
// // // //                         SocialMediaIcon(icon: FontAwesomeIcons.facebook),
// // // //                         SocialMediaIcon(icon: FontAwesomeIcons.instagram),
// // // //                         SocialMediaIcon(icon: FontAwesomeIcons.twitter),
// // // //                         SocialMediaIcon(icon: FontAwesomeIcons.whatsapp),
// // // //                         SocialMediaIcon(icon: FontAwesomeIcons.snapchat),
// // // //                       ],
// // // //                     ),
// // // //                     SizedBox(height: 20),
// // // //                     Text(
// // // //                       'App version 1.0.0',
// // // //                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// // // //                     ),
// // // //                   ],
// // // //                 ),
// // // //               ),
// // // //             ],
// // // //           ),
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class SectionTitle extends StatelessWidget {
// // // //   final String title;

// // // //   SectionTitle({required this.title});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Padding(
// // // //       padding: EdgeInsets.symmetric(vertical: 10.0),
// // // //       child: Text(
// // // //         title,
// // // //         style: TextStyle(
// // // //           color: Colors.purple.shade700,
// // // //           fontSize: 14,
// // // //           fontWeight: FontWeight.bold,
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class ProfileOption extends StatelessWidget {
// // // //   final IconData icon;
// // // //   final String title;
// // // //   final Widget? trailing;
// // // //   final Function? onTap;
// // // //   final Color textColor;

// // // //   ProfileOption({
// // // //     required this.icon,
// // // //     required this.title,
// // // //     this.trailing,
// // // //     this.onTap,
// // // //     this.textColor = Colors.black,
// // // //   });

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Container(
// // // //       margin: EdgeInsets.only(bottom: 4),
// // // //       child: ListTile(
// // // //         contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // // //         leading: Container(
// // // //           padding: EdgeInsets.all(8),
// // // //           decoration: BoxDecoration(
// // // //             color: Colors.purple.shade50,
// // // //             borderRadius: BorderRadius.circular(8),
// // // //           ),
// // // //           child: Icon(icon, color: Colors.purple.shade600, size: 20),
// // // //         ),
// // // //         title: Text(
// // // //           title,
// // // //           style: TextStyle(color: textColor, fontSize: 16),
// // // //         ),
// // // //         trailing: trailing ??
// // // //             Icon(Icons.arrow_forward_ios, color: Colors.grey.shade500, size: 16),
// // // //         onTap: onTap as void Function()?,
// // // //         shape: RoundedRectangleBorder(
// // // //           borderRadius: BorderRadius.circular(8),
// // // //         ),
// // // //         tileColor: Colors.grey.shade50,
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // class SocialMediaIcon extends StatelessWidget {
// // // //   final IconData icon;

// // // //   SocialMediaIcon({required this.icon});

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Padding(
// // // //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
// // // //       child: Container(
// // // //         padding: EdgeInsets.all(8),
// // // //         decoration: BoxDecoration(
// // // //           color: Colors.purple.shade100,
// // // //           borderRadius: BorderRadius.circular(20),
// // // //         ),
// // // //         child: Icon(icon, color: Colors.purple.shade700, size: 20),
// // // //       ),
// // // //     );
// // // //   }
// // // // }

// // // // //dark theme 
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // // // // import 'package:test_project/features/profile/edit_profile.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // // import 'package:test_project/features/wishlist/wishlist.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // // import 'package:test_project/features/trading/topup.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // // import 'package:test_project/features/trading/order.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // // // import 'package:test_project/features/profile/pinfo.dart';
// // // // // import 'package:test_project/features/trading/tax.dart';
// // // // // import 'package:test_project/features/profile/change_password.dart';
// // // // // import 'package:test_project/features/security/two_factor.dart';
// // // // // import 'package:test_project/features/profile/privacy.dart';
// // // // // import 'package:test_project/features/profile/bio.dart';
// // // // // import 'package:test_project/features/profile/npref.dart';  //notifcation preferance
// // // // // import 'package:test_project/features/trading/report.dart';
// // // // // import 'package:shared_preferences/shared_preferences.dart';
// // // // // import 'package:test_project/features/profile/account.dart';
// // // // // import 'package:test_project/features/trading/reward.dart';

// // // // // class ProfileScreen extends StatefulWidget {
// // // // //   const ProfileScreen({Key? key}) : super(key: key);

// // // // //   @override
// // // // //   _ProfileScreenState createState() => _ProfileScreenState();
// // // // // }

// // // // // class _ProfileScreenState extends State<ProfileScreen> {
// // // // //   int customerId = 1222;  // Default value

// // // // //   @override
// // // // //   void initState() {
// // // // //     super.initState();
// // // // //     fetchCustomerId();
// // // // //   }

// // // // //  Future<void> fetchCustomerId() async {
// // // // //   final SharedPreferences prefs = await SharedPreferences.getInstance();
// // // // //   setState(() {
// // // // //     customerId = prefs.getInt('customerId') ?? 1222;  // Use stored ID, else default to 1222
// // // // //   });
// // // // // }


// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Scaffold(
// // // // //       backgroundColor: Color(0xFF0D0D0D),
// // // // //       appBar: AppBar(
// // // // //         backgroundColor: Colors.black,
// // // // //         elevation: 0,
// // // // //         title: Text(
// // // // //           'Profile',
// // // // //           style: TextStyle(
// // // // //             color: Colors.white,
// // // // //             fontWeight: FontWeight.bold,
// // // // //           ),
// // // // //         ),
// // // // //         centerTitle: true,
// // // // //         leading: IconButton(
// // // // //           icon: Icon(Icons.arrow_back, color: Colors.white),
// // // // //           onPressed: () => Navigator.of(context).pop(),
// // // // //         ),
// // // // //         actions: [
// // // // //           IconButton(
// // // // //             icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
// // // // //             onPressed: () {
// // // // //               // Add action for chat
// // // // //             },
// // // // //           ),
// // // // //         ],
// // // // //       ),
// // // // //       body: SingleChildScrollView(
// // // // //         child: Padding(
// // // // //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // // // //           child: Column(
// // // // //             crossAxisAlignment: CrossAxisAlignment.start,
// // // // //             children: [
// // // // //               // Profile Header Section
// // // // //               SizedBox(height: 20),
// // // // //               Center(
// // // // //                 child: Column(
// // // // //                   children: [
// // // // //                     CircleAvatar(
// // // // //                       radius: 50,
// // // // //                       backgroundImage:
// // // // //                       AssetImage('assets/images/profile.png'),
// // // // //                     ),
// // // // //                     SizedBox(height: 10),
// // // // //                     Text(
// // // // //                       'Fery Pratama',
// // // // //                       style: TextStyle(
// // // // //                         color: Colors.white,
// // // // //                         fontSize: 22,
// // // // //                         fontWeight: FontWeight.bold,
// // // // //                       ),
// // // // //                     ),
// // // // //                     SizedBox(height: 5),
// // // // //                     Text(
// // // // //                       'Last Updated On Sep 07 2024',
// // // // //                       style: TextStyle(
// // // // //                         color: Colors.grey,
// // // // //                         fontSize: 14,
// // // // //                       ),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //               SizedBox(height: 30),

// // // // //               // About Section
// // // // //               SectionTitle(title: 'About'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.person_outline,
// // // // //                 title: 'Edit Profile',
// // // // //                 onTap: () {
// // // // //                   Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => EditProfileScreen()),
// // // // //                   );
// // // // //                 },
// // // // //               ),
// // // // //            ProfileOption(
// // // // //   icon: Icons.info_outline,
// // // // //   title: 'Profile Information',
// // // // //   onTap: () {
// // // // //     if (customerId != null && customerId != 0) {  // Ensure it's valid
// // // // //       Navigator.push(
// // // // //         context,
// // // // //         MaterialPageRoute(
// // // // //           builder: (context) => ProfileInfoPage(customerId: customerId),
// // // // //         ),
// // // // //       );
// // // // //     } else {
// // // // //       print("Error: customerId is null or invalid");
// // // // //     }
// // // // //   },
// // // // // ),



// // // // //               // Activity & Orders Section
// // // // //               SectionTitle(title: 'Activity & Orders'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.history,
// // // // //                 title: 'Activity History',
// // // // //                 onTap: () {
// // // // //                   Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => TopUpScreen()),
// // // // //                   );
// // // // //                 },
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.shopping_bag_outlined,
// // // // //                 title: 'Orders',
// // // // //                 onTap: () {
// // // // //                   Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => OrderPage()),
// // // // //                   );

// // // // //                 },
// // // // //               ),


// // // // //               // Security Section
// // // // //               SectionTitle(title: 'Security'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.lock_outline,
// // // // //                 title: 'Change Password',
// // // // //                 onTap: () {  Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => ChangePasswordPage()),
// // // // //                   );

// // // // //                 },
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.fingerprint,
// // // // //                 title: 'Enable Biometric Authentication',
// // // // //                 onTap: () {  Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => BiometricAuthenticationPage()),
// // // // //                   );
// // // // //                   // Add biometric authentication setup here
// // // // //                 },
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.shield_outlined,
// // // // //                 title: 'Two-Factor Authentication',
// // // // //                 onTap: () {
// // // // //   Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()),
// // // // //                   );
// // // // //                 },
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.privacy_tip_outlined,
// // // // //                 title: 'Privacy Settings',
// // // // //                 onTap: () {  Navigator.push(
// // // // //                     context,
// // // // //                     MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
// // // // //                   );

// // // // //                 },
// // // // //               ),






// // // // //               // Watch Lists Section
// // // // //               SectionTitle(title: 'Watch Lists'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.star_outline,
// // // // //                 title: 'Manage Watch Lists',
// // // // //                 onTap: () {
// // // // //                   Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => TradingDashboard()),
// // // // //                 );},
// // // // //               ),



// // // // //               // Tax Forms Section
// // // // //               SectionTitle(title: 'Tax Forms'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.description_outlined,
// // // // //                 title: 'Tax Center',
// // // // //                 onTap: () {   Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => TaxCenter()),
// // // // //                 );},
// // // // //               ),

// // // // //               // Communication Section
// // // // //               SectionTitle(title: 'Communication'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.email_outlined,
// // // // //                 title: 'Message Center',
// // // // //                 onTap: () {},
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.notifications_outlined,
// // // // //                 title: 'Notification Preferences & alerts',
// // // // //                 onTap: () { Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => NotificationScreen()),
// // // // //                 );},
// // // // //               ),
 
// // // // //               // Account Features Section
// // // // //               SectionTitle(title: 'Account Features'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.featured_play_list_outlined,
// // // // //                 title: 'Feature Settings',
// // // // //                 onTap: () {},
// // // // //               ),

// // // // //               // Payments & Transfers Section
// // // // //               SectionTitle(title: 'Payments & Transfers'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.payments_outlined,
// // // // //                 title: 'Payment Methods',
// // // // //                 onTap: ()  { Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => TopUpScreen()),
// // // // //                 );},
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.swap_horiz,
// // // // //                 title: 'Transfer Settings',
// // // // //                 onTap: () {},
// // // // //               ),

// // // // //               // Brokerage & Trading Section
// // // // //               SectionTitle(title: 'Brokerage & Trading'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.trending_up,
// // // // //                 title: 'Trading Preferences',
// // // // //                 onTap: () {},
// // // // //               ),

// // // // //               // Banks & Cards Section
// // // // //               SectionTitle(title: 'Banks & Cards'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.credit_card,
// // // // //                 title: 'Manage Debit Cards',
// // // // //                 onTap: () {},
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.account_balance,
// // // // //                 title: 'Linked Accounts & Banks',
// // // // //                 onTap: () {Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => AccountPage()),
// // // // //                 );},
// // // // //               ),
  
  
// // // // //              // Settings Section
// // // // //               SectionTitle(title: 'Report'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.settings,
// // // // //                 title: 'Report & Statements',
// // // // //                 onTap: () { Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) => ReportPage()),
// // // // //                 );},
// // // // //               ),
              
              
              
// // // // //               // Settings Section
// // // // //               SectionTitle(title: 'Settings'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.settings,
// // // // //                 title: 'General Settings',
// // // // //                 onTap: () {},
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.view_quilt,
// // // // //                 title: 'Layout',
// // // // //                 trailing: Switch(
// // // // //                   value: false,
// // // // //                   onChanged: (value) {},
// // // // //                   activeColor: Colors.blue,
// // // // //                 ),
// // // // //               ),

// // // // //               // Help Section
// // // // //               SectionTitle(title: 'Get Help'),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.help_outline,
// // // // //                 title: 'FAQ',
// // // // //                 onTap: () {},
// // // // //               ),

            
// // // // //               ProfileOption(
// // // // //                 icon: Icons.emoji_events,
// // // // //                 title: 'Rewards',
// // // // //                 onTap: () { Navigator.push(
// // // // //                   context,
// // // // //                   MaterialPageRoute(builder: (context) =>RewardPage()),
// // // // //                 );},
// // // // //               ),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.support_agent,
// // // // //                 title: 'Contact Support',
// // // // //                 onTap: () {},
// // // // //               ),

// // // // //               // Logout Option
// // // // //               SizedBox(height: 20),
// // // // //               ProfileOption(
// // // // //                 icon: Icons.logout,
// // // // //                 title: 'Logout',
// // // // //                 onTap: () {},
// // // // //                 textColor: Colors.red,
// // // // //               ),

// // // // //               SizedBox(height: 30),
// // // // //               // Social Media Section
// // // // //               Center(
// // // // //                 child: Column(
// // // // //                   children: [
// // // // //                     Text(
// // // // //                       'Our Social Media',
// // // // //                       style: TextStyle(color: Colors.grey, fontSize: 14),
// // // // //                     ),
// // // // //                     SizedBox(height: 10),
// // // // //                     Row(
// // // // //                       mainAxisAlignment: MainAxisAlignment.center,
// // // // //                       children: [
// // // // //                         SocialMediaIcon(icon: FontAwesomeIcons.facebook),
// // // // //                         SocialMediaIcon(icon: FontAwesomeIcons.instagram),
// // // // //                         SocialMediaIcon(icon: FontAwesomeIcons.twitter),
// // // // //                         SocialMediaIcon(icon: FontAwesomeIcons.whatsapp),
// // // // //                         SocialMediaIcon(icon: FontAwesomeIcons.snapchat),
// // // // //                       ],
// // // // //                     ),
// // // // //                     SizedBox(height: 20),
// // // // //                     Text(
// // // // //                       'App version 1.0.0',
// // // // //                       style: TextStyle(color: Colors.grey, fontSize: 12),
// // // // //                     ),
// // // // //                   ],
// // // // //                 ),
// // // // //               ),
// // // // //             ],
// // // // //           ),
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class SectionTitle extends StatelessWidget {
// // // // //   final String title;

// // // // //   SectionTitle({required this.title});

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Padding(
// // // // //       padding: EdgeInsets.symmetric(vertical: 10.0),
// // // // //       child: Text(
// // // // //         title,
// // // // //         style: TextStyle(
// // // // //           color: Colors.grey,
// // // // //           fontSize: 14,
// // // // //           fontWeight: FontWeight.bold,
// // // // //         ),
// // // // //       ),
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class ProfileOption extends StatelessWidget {
// // // // //   final IconData icon;
// // // // //   final String title;
// // // // //   final Widget? trailing;
// // // // //   final Function? onTap;
// // // // //   final Color textColor;

// // // // //   ProfileOption({
// // // // //     required this.icon,
// // // // //     required this.title,
// // // // //     this.trailing,
// // // // //     this.onTap,
// // // // //     this.textColor = Colors.white,
// // // // //   });

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return ListTile(
// // // // //       contentPadding: EdgeInsets.zero,
// // // // //       leading: Icon(icon, color: Colors.white),
// // // // //       title: Text(
// // // // //         title,
// // // // //         style: TextStyle(color: textColor, fontSize: 16),
// // // // //       ),
// // // // //       trailing: trailing ??
// // // // //           Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
// // // // //       onTap: onTap as void Function()?,
// // // // //     );
// // // // //   }
// // // // // }

// // // // // class SocialMediaIcon extends StatelessWidget {
// // // // //   final IconData icon;

// // // // //   SocialMediaIcon({required this.icon});

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Padding(
// // // // //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
// // // // //       child: Icon(icon, color: Colors.white, size: 24),
// // // // //     );
// // // // //   }
// // // // // }

// // // //white theme 

// // // import 'package:flutter/material.dart';
// // // import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// // // import 'package:test_project/features/profile/edit_profile.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // import 'package:test_project/features/wishlist/wishlist.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // import 'package:test_project/features/trading/topup.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // import 'package:test_project/features/trading/order.dart'; // Assuming EditProfileScreen is in edit_profile.dart
// // // import 'package:test_project/features/profile/pinfo.dart';
// // // import 'package:test_project/features/trading/tax.dart';
// // // import 'package:test_project/features/profile/change_password.dart';
// // // import 'package:test_project/features/security/two_factor.dart';
// // // import 'package:test_project/features/profile/privacy.dart';
// // // import 'package:test_project/features/profile/bio.dart';
// // // import 'package:test_project/features/profile/npref.dart';  //notifcation preferance
// // // import 'package:test_project/features/trading/report.dart';
// // // import 'package:shared_preferences/shared_preferences.dart';
// // // import 'package:test_project/features/profile/account.dart';
// // // import 'package:test_project/features/trading/reward.dart';
// // // import 'package:test_project/features/security/security_screen.dart';
// // // import 'package:test_project/features/notifications/message_center.dart';


// // // class ProfileScreen extends StatefulWidget {
// // //   const ProfileScreen({Key? key}) : super(key: key);

// // //   @override
// // //   _ProfileScreenState createState() => _ProfileScreenState();
// // // }

// // // class _ProfileScreenState extends State<ProfileScreen> {
// // //   int customerId = 1222;  // Default value

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     fetchCustomerId();
// // //   }

// // //  Future<void> fetchCustomerId() async {
// // //   final SharedPreferences prefs = await SharedPreferences.getInstance();
// // //   setState(() {
// // //     customerId = prefs.getInt('customerId') ?? 1222;  // Use stored ID, else default to 1222
// // //   });
// // // }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       appBar: AppBar(
// // //         backgroundColor: Colors.white,
// // //         elevation: 1,
// // //         shadowColor: Colors.grey.shade200,
// // //         title: Text(
// // //           'Profile',
// // //           style: TextStyle(
// // //             color: Colors.black,
// // //             fontWeight: FontWeight.bold,
// // //           ),
// // //         ),
// // //         centerTitle: true,
// // //         leading: IconButton(
// // //           icon: Icon(Icons.arrow_back, color: Colors.black),
// // //           onPressed: () => Navigator.of(context).pop(),
// // //         ),
// // //         actions: [
// // //           IconButton(
// // //             icon: Icon(Icons.chat_bubble_outline, color: Color.fromARGB(255, 114, 70, 192)),
// // //             onPressed: () {
// // //               // Add action for chat
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //       body: SingleChildScrollView(
// // //         child: Padding(
// // //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.start,
// // //             children: [
// // //               // Profile Header Section
// // //               SizedBox(height: 20),
// // //               Center(
// // //                 child: Column(
// // //                   children: [
// // //                     Container(
// // //                       decoration: BoxDecoration(
// // //                         shape: BoxShape.circle,
// // //                         border: Border.all(color: Color.fromARGB(255, 114, 70, 192), width: 3),
// // //                       ),
// // //                       child: CircleAvatar(
// // //                         radius: 50,
// // //                         backgroundImage:
// // //                         AssetImage('assets/images/profile.png'),
// // //                       ),
// // //                     ),
// // //                     SizedBox(height: 10),
// // //                     Text(
// // //                       'Fery Pratama',
// // //                       style: TextStyle(
// // //                         color: Colors.black,
// // //                         fontSize: 22,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                     SizedBox(height: 5),
// // //                     Text(
// // //                       'Last Updated On Sep 07 2024',
// // //                       style: TextStyle(
// // //                         color: Colors.grey.shade600,
// // //                         fontSize: 14,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //               SizedBox(height: 30),

// // //               // About Section
// // //               SectionTitle(title: 'About'),
// // //               ProfileOption(
// // //                 icon: Icons.person_outline,
// // //                 title: 'Edit Profile',
// // //                 onTap: () {
// // //                   Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => EditProfileScreen()),
// // //                   );
// // //                 },
// // //               ),
// // // //            ProfileOption(
// // // //   icon: Icons.info_outline,
// // // //   title: 'Profile Information',
// // // //   onTap: () {
// // // //     if (customerId != null && customerId != 0) {  // Ensure it's valid
// // // //       Navigator.push(
// // // //         context,
// // // //         MaterialPageRoute(
// // // //           builder: (context) => ProfileInfoPage(customerId: customerId),
// // // //         ),
// // // //       );
// // // //     } else {
// // // //       print("Error: customerId is null or invalid");
// // // //     }
// // // //   },
// // // // ),

// // //               // Activity & Orders Section
// // //               SectionTitle(title: 'Activity & Orders'),
// // //               // ProfileOption(
// // //               //   icon: Icons.history,
// // //               //   title: 'Activity History',
// // //               //   onTap: () {
// // //               //     Navigator.push(
// // //               //       context,
// // //               //       MaterialPageRoute(builder: (context) => TopUpScreen()),
// // //               //     );
// // //               //   },
// // //               // ),
// // //               ProfileOption(
// // //                 icon: Icons.shopping_bag_outlined,
// // //                 title: 'Orders',
// // //                 onTap: () {
// // //                   Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => OrderPage()),
// // //                   );

// // //                 },
// // //               ),

// // //               // Security Section
// // //               SectionTitle(title: 'Security'),
// // //               ProfileOption(
// // //                 icon: Icons.lock_outline,
// // //                 title: 'Change Password',
// // //                 onTap: () {  Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => ChangePasswordPage()),
// // //                   );

// // //                 },
// // //               ),
// // //              ProfileOption(
// // //   icon: Icons.fingerprint,
// // //   title: 'Security & App Lock',
// // //   onTap: () {
// // //     Navigator.push(
// // //       context,
// // //       MaterialPageRoute(
// // //         builder: (context) => const SecurityScreen(),
// // //       ),
// // //     );
// // //   },
// // // ),

// // //               ProfileOption(
// // //                 icon: Icons.shield_outlined,
// // //                 title: 'Two-Factor Authentication',
// // //                 onTap: () {
// // //   Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()),
// // //                   );
// // //                 },
// // //               ),
// // //               ProfileOption(
// // //                 icon: Icons.privacy_tip_outlined,
// // //                 title: 'Privacy Settings',
// // //                 onTap: () {  Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
// // //                   );

// // //                 },
// // //               ),

// // //               // Watch Lists Section
// // //               SectionTitle(title: 'Watch Lists'),
// // //               ProfileOption(
// // //                 icon: Icons.star_outline,
// // //                 title: 'Manage Watch Lists',
// // //                 onTap: () {
// // //                   Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => TradingDashboard()),
// // //                 );},
// // //               ),

// // //               // Tax Forms Section
// // //               SectionTitle(title: 'Tax Forms'),
// // //               ProfileOption(
// // //                 icon: Icons.description_outlined,
// // //                 title: 'Tax Center',
// // //                 onTap: () {   Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => TaxCenter()),
// // //                 );},
// // //               ),

// // //               // Communication Section
// // //               SectionTitle(title: 'Communication'),
// // //               ProfileOption(
// // //                 icon: Icons.email_outlined,
// // //                 title: 'Message Center',
// // //                 onTap: () { 
                  
// // //                   Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => MessagesPreferencesPage()),
// // //                 );
// // //                 },
// // //               ),
// // //               ProfileOption(
// // //                 icon: Icons.notifications_outlined,
// // //                 title: 'Notification Preferences & alerts',
// // //                 onTap: () { Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => NotificationScreen()),
// // //                 );},
// // //               ),
 
// // //               // Account Features Section
// // //               SectionTitle(title: 'Account Features'),
// // //               ProfileOption(
// // //                 icon: Icons.featured_play_list_outlined,
// // //                 title: 'Feature Settings',
// // //                 onTap: () {},
// // //               ),

// // //               // Payments & Transfers Section
// // //               SectionTitle(title: 'Payments & Transfers'),
// // //               ProfileOption(
// // //                 icon: Icons.payments_outlined,
// // //                 title: 'Payment Methods',
// // //                 onTap: ()  { Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => TopUpScreen()),
// // //                 );},
// // //               ),
// // //               ProfileOption(
// // //                 icon: Icons.swap_horiz,
// // //                 title: 'Transfer Settings',
// // //                 onTap: () {},
// // //               ),

// // //               // Brokerage & Trading Section
// // //               SectionTitle(title: 'Brokerage & Trading'),
// // //               ProfileOption(
// // //                 icon: Icons.trending_up,
// // //                 title: 'Trading Preferences',
// // //                 onTap: () {},
// // //               ),

// // //               // Banks & Cards Section
// // //               SectionTitle(title: 'Banks & Cards'),
// // //               ProfileOption(
// // //                 icon: Icons.credit_card,
// // //                 title: 'Manage Debit Cards',
// // //                 onTap: () {},
// // //               ),
// // //               ProfileOption(
// // //                 icon: Icons.account_balance,
// // //                 title: 'Linked Accounts & Banks',
// // //                 onTap: () {Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => AccountPage()),
// // //                 );},
// // //               ),
  
// // //              // Settings Section
// // //               SectionTitle(title: 'Report'),
// // //               ProfileOption(
// // //                 icon: Icons.settings,
// // //                 title: 'Report & Statements',
// // //                 onTap: () { Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) => ReportPage()),
// // //                 );},
// // //               ),
              
// // //               // Settings Section
// // //               SectionTitle(title: 'Settings'),
// // //               ProfileOption(
// // //                 icon: Icons.settings,
// // //                 title: 'General Settings',
// // //                 onTap: () {},
// // //               ),
// // //               ProfileOption(
// // //                 icon: Icons.view_quilt,
// // //                 title: 'Layout',
// // //                 trailing: Switch(
// // //                   value: false,
// // //                   onChanged: (value) {},
// // //                   activeColor: Color.fromARGB(255, 114, 70, 192),
// // //                 ),
// // //               ),

// // //               // Help Section
// // //               SectionTitle(title: 'Get Help'),
// // //               ProfileOption(
// // //                 icon: Icons.help_outline,
// // //                 title: 'FAQ',
// // //                 onTap: () {},
// // //               ),

// // //               ProfileOption(
// // //                 icon: Icons.emoji_events,
// // //                 title: 'Rewards',
// // //                 onTap: () { Navigator.push(
// // //                   context,
// // //                   MaterialPageRoute(builder: (context) =>RewardPage()),
// // //                 );},
// // //               ),
// // //               ProfileOption(
// // //                 icon: Icons.support_agent,
// // //                 title: 'Contact Support',
// // //                 onTap: () {},
// // //               ),

// // //               // Logout Option
// // //               SizedBox(height: 20),
// // //               ProfileOption(
// // //                 icon: Icons.logout,
// // //                 title: 'Logout',
// // //                 onTap: () {},
// // //                 textColor: Colors.red,
// // //               ),

// // //               SizedBox(height: 30),
// // //               // Social Media Section
// // //               Center(
// // //                 child: Column(
// // //                   children: [
// // //                     Text(
// // //                       'Our Social Media',
// // //                       style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
// // //                     ),
// // //                     SizedBox(height: 10),
// // //                     Row(
// // //                       mainAxisAlignment: MainAxisAlignment.center,
// // //                       children: [
// // //                         SocialMediaIcon(icon: FontAwesomeIcons.facebook),
// // //                         SocialMediaIcon(icon: FontAwesomeIcons.instagram),
// // //                         SocialMediaIcon(icon: FontAwesomeIcons.twitter),
// // //                         SocialMediaIcon(icon: FontAwesomeIcons.whatsapp),
// // //                         SocialMediaIcon(icon: FontAwesomeIcons.snapchat),
// // //                       ],
// // //                     ),
// // //                     SizedBox(height: 20),
// // //                     Text(
// // //                       'App version 1.0.0',
// // //                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class SectionTitle extends StatelessWidget {
// // //   final String title;

// // //   SectionTitle({required this.title});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Padding(
// // //       padding: EdgeInsets.symmetric(vertical: 10.0),
// // //       child: Text(
// // //         title,
// // //         style: TextStyle(
// // //           color: Color.fromARGB(255, 114, 70, 192),
// // //           fontSize: 16,
// // //           fontWeight: FontWeight.bold,
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class ProfileOption extends StatelessWidget {
// // //   final IconData icon;
// // //   final String title;
// // //   final Widget? trailing;
// // //   final Function? onTap;
// // //   final Color textColor;

// // //   ProfileOption({
// // //     required this.icon,
// // //     required this.title,
// // //     this.trailing,
// // //     this.onTap,
// // //     this.textColor = Colors.black,
// // //   });

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       margin: EdgeInsets.only(bottom: 8),
// // //       child: Card(
// // //         color: Colors.grey[100],
// // //         elevation: 0,
// // //         child: ListTile(
// // //           contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// // //           leading: Container(
// // //             padding: EdgeInsets.all(8),
// // //             decoration: BoxDecoration(
// // //               color: Color.fromARGB(255, 114, 70, 192).withOpacity(0.1),
// // //               borderRadius: BorderRadius.circular(8),
// // //             ),
// // //             child: Icon(icon, color: Color.fromARGB(255, 114, 70, 192), size: 20),
// // //           ),
// // //           title: Text(
// // //             title,
// // //             style: TextStyle(color: textColor, fontSize: 16),
// // //           ),
// // //           trailing: trailing ??
// // //               Icon(Icons.arrow_forward_ios, color: Colors.grey.shade500, size: 16),
// // //           onTap: onTap as void Function()?,
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(8),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // class SocialMediaIcon extends StatelessWidget {
// // //   final IconData icon;

// // //   SocialMediaIcon({required this.icon});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Padding(
// // //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
// // //       child: Container(
// // //         padding: EdgeInsets.all(12),
// // //         decoration: BoxDecoration(
// // //           color: Color.fromARGB(255, 114, 70, 192).withOpacity(0.1),
// // //           borderRadius: BorderRadius.circular(20),
// // //         ),
// // //         child: Icon(icon, color: Color.fromARGB(255, 114, 70, 192), size: 20),
// // //       ),
// // //     );
// // //   }
// // // }








// // import 'package:flutter/material.dart';
// // import 'package:image_picker/image_picker.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'dart:io';

// // // Import all your existing pages
// // // Uncomment and adjust these imports based on your project structure
// //  import 'package:test_project/features/profile/edit_profile.dart';
// //  import 'package:test_project/features/wishlist/wishlist.dart';
// //  import 'package:test_project/features/trading/topup.dart';
// //  import 'package:test_project/features/trading/order.dart';
// // import 'package:test_project/features/profile/pinfo.dart';
// //  import 'package:test_project/features/trading/tax.dart';
// //  import 'package:test_project/features/profile/change_password.dart';
// //  import 'package:test_project/features/security/two_factor.dart';
// //  import 'package:test_project/features/profile/privacy.dart';
// //  import 'package:test_project/features/profile/bio.dart';
// //  import 'package:test_project/features/profile/npref.dart';
// //  import 'package:test_project/features/trading/report.dart';
// //  import 'package:test_project/features/profile/account.dart';
// // import 'package:test_project/features/trading/reward.dart';
// // import 'package:test_project/features/security/security_screen.dart';
// //  import 'package:test_project/features/notifications/message_center.dart';


// // class ProfileScreen extends StatefulWidget {
// //   const ProfileScreen({Key? key}) : super(key: key);

// //   @override
// //   _ProfileScreenState createState() => _ProfileScreenState();
// // }

// // class _ProfileScreenState extends State<ProfileScreen> {
// //   final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);
// //   File? _profileImage;
// //   final ImagePicker _picker = ImagePicker();
// //   int customerId = 1222;
// //   bool _layoutSwitchValue = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchCustomerId();
// //   }

// //   Future<void> fetchCustomerId() async {
// //     final SharedPreferences prefs = await SharedPreferences.getInstance();
// //     setState(() {
// //       customerId = prefs.getInt('customerId') ?? 1222;
// //     });
// //   }

// //   Future<void> _pickImage() async {
// //     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
// //     if (image != null) {
// //       setState(() {
// //         _profileImage = File(image.path);
// //       });
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey[50],
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         title: const Text(
// //           'Profile',
// //           style: TextStyle(
// //             color: Colors.black,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 20,
// //           ),
// //         ),
// //         centerTitle: true,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
// //           onPressed: () => Navigator.of(context).pop(),
// //         ),
// //       ),
// //       body: SingleChildScrollView(
// //         child: Column(
// //           children: [
// //             // Profile Header Card
// //             Container(
// //               width: double.infinity,
// //               color: Colors.white,
// //               padding: const EdgeInsets.symmetric(vertical: 24),
// //               child: Column(
// //                 children: [
// //                   GestureDetector(
// //                     onTap: _pickImage,
// //                     child: Stack(
// //                       children: [
// //                         Container(
// //                           decoration: BoxDecoration(
// //                             shape: BoxShape.circle,
// //                             border: Border.all(color: _primaryColor, width: 3),
// //                           ),
// //                           child: CircleAvatar(
// //                             radius: 50,
// //                             backgroundColor: Colors.grey[200],
// //                             backgroundImage: _profileImage != null
// //                                 ? FileImage(_profileImage!)
// //                                 : const AssetImage('assets/images/profile.png')
// //                                     as ImageProvider,
// //                           ),
// //                         ),
// //                         Positioned(
// //                           bottom: 0,
// //                           right: 0,
// //                           child: Container(
// //                             padding: const EdgeInsets.all(6),
// //                             decoration: BoxDecoration(
// //                               color: _primaryColor,
// //                               shape: BoxShape.circle,
// //                               border: Border.all(color: Colors.white, width: 2),
// //                             ),
// //                             child: const Icon(
// //                               Icons.camera_alt,
// //                               color: Colors.white,
// //                               size: 18,
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                   const SizedBox(height: 16),
// //                   const Text(
// //                     'Fery Pratama',
// //                     style: TextStyle(
// //                       color: Colors.black,
// //                       fontSize: 22,
// //                       fontWeight: FontWeight.bold,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 6),
// //                   Text(
// //                     'Last Updated: Sep 07, 2024',
// //                     style: TextStyle(
// //                       color: Colors.grey[600],
// //                       fontSize: 13,
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),

// //             const SizedBox(height: 16),

// //             // Profile Options
// //             Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16),
// //               child: Column(
// //                 children: [
// //                   // Account Section
// //                   _buildSectionCard(
// //                     title: 'Account',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.person_outline,
// //                         title: 'Edit Profile',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => EditProfileScreen()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.shopping_bag_outlined,
// //                         title: 'Orders',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => OrderPage()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.star_outline,
// //                         title: 'Manage Watch Lists',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => TradingDashboard()),
// //                           );
// //                         },
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   // Security Section
// //                   _buildSectionCard(
// //                     title: 'Security',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.lock_outline,
// //                         title: 'Change Password',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => ChangePasswordPage()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.fingerprint,
// //                         title: 'Security & App Lock',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => const SecurityScreen()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.shield_outlined,
// //                         title: 'Two-Factor Authentication',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.privacy_tip_outlined,
// //                         title: 'Privacy Settings',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
// //                           );
// //                         },
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   // Financial Section
// //                   _buildSectionCard(
// //                     title: 'Financial',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.description_outlined,
// //                         title: 'Tax Center',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => TaxCenter()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.assessment_outlined,
// //                         title: 'Reports & Statements',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => ReportPage()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.emoji_events_outlined,
// //                         title: 'Rewards',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => RewardPage()),
// //                           );
// //                         },
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   // Communication Section
// //                   _buildSectionCard(
// //                     title: 'Communication',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.email_outlined,
// //                         title: 'Message Center',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => MessagesPreferencesPage()),
// //                           );
// //                         },
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.notifications_outlined,
// //                         title: 'Notification Preferences',
// //                         onTap: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(builder: (context) => NotificationScreen()),
// //                           );
// //                         },
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   // Preferences Section
// //                   _buildSectionCard(
// //                     title: 'Preferences',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.featured_play_list_outlined,
// //                         title: 'Feature Settings',
// //                         onTap: () {},
// //                       ),
// //                       _buildDivider(),
// //                       _buildSwitchTile(
// //                         icon: Icons.view_quilt,
// //                         title: 'Layout',
// //                         value: _layoutSwitchValue,
// //                         onChanged: (value) {
// //                           setState(() {
// //                             _layoutSwitchValue = value;
// //                           });
// //                         },
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   // Support Section
// //                   _buildSectionCard(
// //                     title: 'Support',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.help_outline,
// //                         title: 'FAQ',
// //                         onTap: () {},
// //                       ),
// //                       _buildDivider(),
// //                       _buildOptionTile(
// //                         icon: Icons.support_agent,
// //                         title: 'Contact Support',
// //                         onTap: () {},
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 16),

// //                   // Logout Button
// //                   _buildSectionCard(
// //                     title: '',
// //                     children: [
// //                       _buildOptionTile(
// //                         icon: Icons.logout,
// //                         title: 'Logout',
// //                         onTap: () {
// //                           // Add logout functionality
// //                           showDialog(
// //                             context: context,
// //                             builder: (context) => AlertDialog(
// //                               title: const Text('Logout'),
// //                               content: const Text('Are you sure you want to logout?'),
// //                               actions: [
// //                                 TextButton(
// //                                   onPressed: () => Navigator.pop(context),
// //                                   child: const Text('Cancel'),
// //                                 ),
// //                                 TextButton(
// //                                   onPressed: () {
// //                                     // Perform logout
// //                                     Navigator.pop(context);
// //                                   },
// //                                   child: const Text(
// //                                     'Logout',
// //                                     style: TextStyle(color: Colors.red),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           );
// //                         },
// //                         textColor: Colors.red,
// //                         iconColor: Colors.red,
// //                       ),
// //                     ],
// //                   ),

// //                   const SizedBox(height: 24),

// //                   // App Version
// //                   Text(
// //                     'App version 1.0.0',
// //                     style: TextStyle(
// //                       color: Colors.grey[500],
// //                       fontSize: 12,
// //                     ),
// //                   ),

// //                   const SizedBox(height: 24),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSectionCard({
// //     required String title,
// //     required List<Widget> children,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         if (title.isNotEmpty)
// //           Padding(
// //             padding: const EdgeInsets.only(left: 4, bottom: 8),
// //             child: Text(
// //               title,
// //               style: TextStyle(
// //                 color: _primaryColor,
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.bold,
// //                 letterSpacing: 0.5,
// //               ),
// //             ),
// //           ),
// //         Container(
// //           decoration: BoxDecoration(
// //             color: Colors.white,
// //             borderRadius: BorderRadius.circular(12),
// //             border: Border.all(color: Colors.grey[300]!),
// //           ),
// //           child: Column(children: children),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildOptionTile({
// //     required IconData icon,
// //     required String title,
// //     required VoidCallback onTap,
// //     Color textColor = Colors.black,
// //     Color? iconColor,
// //   }) {
// //     return InkWell(
// //       onTap: onTap,
// //       borderRadius: BorderRadius.circular(12),
// //       child: Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
// //         child: Row(
// //           children: [
// //             Container(
// //               padding: const EdgeInsets.all(8),
// //               decoration: BoxDecoration(
// //                 color: (iconColor ?? _primaryColor).withOpacity(0.1),
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: Icon(
// //                 icon,
// //                 color: iconColor ?? _primaryColor,
// //                 size: 20,
// //               ),
// //             ),
// //             const SizedBox(width: 14),
// //             Expanded(
// //               child: Text(
// //                 title,
// //                 style: TextStyle(
// //                   color: textColor,
// //                   fontSize: 15,
// //                   fontWeight: FontWeight.w500,
// //                 ),
// //               ),
// //             ),
// //             Icon(
// //               Icons.arrow_forward_ios,
// //               color: Colors.grey[400],
// //               size: 16,
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSwitchTile({
// //     required IconData icon,
// //     required String title,
// //     required bool value,
// //     required Function(bool) onChanged,
// //   }) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //       child: Row(
// //         children: [
// //           Container(
// //             padding: const EdgeInsets.all(8),
// //             decoration: BoxDecoration(
// //               color: _primaryColor.withOpacity(0.1),
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             child: Icon(
// //               icon,
// //               color: _primaryColor,
// //               size: 20,
// //             ),
// //           ),
// //           const SizedBox(width: 14),
// //           Expanded(
// //             child: Text(
// //               title,
// //               style: const TextStyle(
// //                 color: Colors.black,
// //                 fontSize: 15,
// //                 fontWeight: FontWeight.w500,
// //               ),
// //             ),
// //           ),
// //           Switch(
// //             value: value,
// //             activeColor: _primaryColor,
// //             activeTrackColor: _primaryColor.withOpacity(0.5),
// //             inactiveThumbColor: Colors.grey[400],
// //             inactiveTrackColor: Colors.grey[300],
// //             onChanged: onChanged,
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildDivider() {
// //     return Divider(
// //       color: Colors.grey[300],
// //       height: 1,
// //       indent: 58,
// //     );
// //   }
// // }









// //  11/01/2026

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io';

// // Import all your existing pages
// import 'package:test_project/features/profile/edit_profile.dart';
// import 'package:test_project/features/wishlist/wishlist.dart';
// import 'package:test_project/features/trading/topup.dart';
// import 'package:test_project/features/trading/order.dart';
// import 'package:test_project/features/profile/pinfo.dart';
// import 'package:test_project/features/trading/tax.dart';
// import 'package:test_project/features/profile/change_password.dart';
// import 'package:test_project/features/security/two_factor.dart';
// import 'package:test_project/features/profile/privacy.dart';
// import 'package:test_project/features/profile/bio.dart';
// import 'package:test_project/features/profile/npref.dart';
// import 'package:test_project/features/trading/report.dart';
// import 'package:test_project/features/profile/account.dart';
// import 'package:test_project/features/trading/reward.dart';
// import 'package:test_project/features/security/security_screen.dart';
// import 'package:test_project/features/notifications/message_center.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);

//   @override
//   _ProfileScreenState createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);
//   File? _profileImage;
//   final ImagePicker _picker = ImagePicker();
//   int customerId = 1222;
//   bool _layoutSwitchValue = false;

//   @override
//   void initState() {
//     super.initState();
//     fetchCustomerId();
//   }

//   Future<void> fetchCustomerId() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       customerId = prefs.getInt('customerId') ?? 1222;
//     });
//   }

//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       setState(() {
//         _profileImage = File(image.path);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Profile',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Profile Header Card
//             Container(
//               width: double.infinity,
//               color: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 24),
//               child: Column(
//                 children: [
//                   GestureDetector(
//                     onTap: _pickImage,
//                     child: Stack(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(color: _primaryColor, width: 3),
//                           ),
//                           child: CircleAvatar(
//                             radius: 50,
//                             backgroundColor: Colors.grey[200],
//                             backgroundImage: _profileImage != null
//                                 ? FileImage(_profileImage!)
//                                 : const AssetImage('assets/images/profile.png')
//                                     as ImageProvider,
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 0,
//                           right: 0,
//                           child: Container(
//                             padding: const EdgeInsets.all(6),
//                             decoration: BoxDecoration(
//                               color: _primaryColor,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white, width: 2),
//                             ),
//                             child: const Icon(
//                               Icons.camera_alt,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Fery Pratama',
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'Last Updated: Sep 07, 2024',
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 13,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Profile Options
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Column(
//                 children: [
//                   // Account Section
//                   _buildSectionCard(
//                     title: 'Account',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.person_outline,
//                         title: 'Edit Profile',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => EditProfileScreen()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.shopping_bag_outlined,
//                         title: 'Orders',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => OrderPage()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       // _buildOptionTile(
//                       //   icon: Icons.star_outline,
//                       //   title: 'Manage Watch Lists',
//                       //   onTap: () {
//                       //     Navigator.push(
//                       //       context,
//                       //       MaterialPageRoute(builder: (context) => TradingDashboard()),
//                       //     );
//                       //   },
//                       // ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Security Section
//                   _buildSectionCard(
//                     title: 'Security',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.lock_outline,
//                         title: 'Change Password',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => ChangePasswordPage()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.fingerprint,
//                         title: 'Security & App Lock',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const SecurityScreen()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.shield_outlined,
//                         title: 'Two-Factor Authentication',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => TwoFactorAuthenticationPage()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.privacy_tip_outlined,
//                         title: 'Privacy Settings',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
//                           );
//                         },
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Financial Section
//                   _buildSectionCard(
//                     title: 'Financial',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.description_outlined,
//                         title: 'Tax Center',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => TaxCenter()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.assessment_outlined,
//                         title: 'Reports & Statements',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => ReportPage()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.emoji_events_outlined,
//                         title: 'Rewards',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => RewardPage()),
//                           );
//                         },
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Communication Section
//                   _buildSectionCard(
//                     title: 'Communication',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.email_outlined,
//                         title: 'Message Center',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => MessagesPreferencesPage()),
//                           );
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.notifications_outlined,
//                         title: 'Notification Preferences',
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => NotificationScreen()),
//                           );
//                         },
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // -----------------------------------------------------------
//                   // App preference & Data usage Section (Backlog/Not for now)
//                   // -----------------------------------------------------------
//                   _buildSectionCard(
//                     title: 'App preference & Data usage',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.data_usage_outlined,
//                         title: 'Data Usage Settings',
//                         onTap: () {
//                           // TODO: Implement navigation in future
//                         },
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.tune_outlined,
//                         title: 'App Preferences',
//                         onTap: () {
//                           // TODO: Implement navigation in future
//                         },
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Preferences Section
//                   _buildSectionCard(
//                     title: 'Preferences',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.featured_play_list_outlined,
//                         title: 'Feature Settings',
//                         onTap: () {},
//                       ),
//                       _buildDivider(),
//                       _buildSwitchTile(
//                         icon: Icons.view_quilt,
//                         title: 'Layout',
//                         value: _layoutSwitchValue,
//                         onChanged: (value) {
//                           setState(() {
//                             _layoutSwitchValue = value;
//                           });
//                         },
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Support Section
//                   _buildSectionCard(
//                     title: 'Support',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.help_outline,
//                         title: 'FAQ',
//                         onTap: () {},
//                       ),
//                       _buildDivider(),
//                       _buildOptionTile(
//                         icon: Icons.support_agent,
//                         title: 'Contact Support',
//                         onTap: () {},
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 16),

//                   // Logout Button
//                   _buildSectionCard(
//                     title: '',
//                     children: [
//                       _buildOptionTile(
//                         icon: Icons.logout,
//                         title: 'Logout',
//                         onTap: () {
//                           showDialog(
//                             context: context,
//                             builder: (context) => AlertDialog(
//                               title: const Text('Logout'),
//                               content: const Text('Are you sure you want to logout?'),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () => Navigator.pop(context),
//                                   child: const Text('Cancel'),
//                                 ),
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.pop(context);
//                                   },
//                                   child: const Text(
//                                     'Logout',
//                                     style: TextStyle(color: Colors.red),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                         textColor: Colors.red,
//                         iconColor: Colors.red,
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 24),

//                   // App Version
//                   Text(
//                     'App version 1.0.0',
//                     style: TextStyle(
//                       color: Colors.grey[500],
//                       fontSize: 12,
//                     ),
//                   ),

//                   const SizedBox(height: 24),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // --- Helper Methods ---

//   Widget _buildSectionCard({
//     required String title,
//     required List<Widget> children,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         if (title.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(left: 4, bottom: 8),
//             child: Text(
//               title,
//               style: TextStyle(
//                 color: _primaryColor,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: 0.5,
//               ),
//             ),
//           ),
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: Column(children: children),
//         ),
//       ],
//     );
//   }

//   Widget _buildOptionTile({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color textColor = Colors.black,
//     Color? iconColor,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: (iconColor ?? _primaryColor).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 icon,
//                 color: iconColor ?? _primaryColor,
//                 size: 20,
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Text(
//                 title,
//                 style: TextStyle(
//                   color: textColor,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             Icon(
//               Icons.arrow_forward_ios,
//               color: Colors.grey[400],
//               size: 16,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSwitchTile({
//     required IconData icon,
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: _primaryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Icon(
//               icon,
//               color: _primaryColor,
//               size: 20,
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Text(
//               title,
//               style: const TextStyle(
//                 color: Colors.black,
//                 fontSize: 15,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Switch(
//             value: value,
//             activeColor: _primaryColor,
//             activeTrackColor: _primaryColor.withOpacity(0.5),
//             inactiveThumbColor: Colors.grey[400],
//             inactiveTrackColor: Colors.grey[300],
//             onChanged: onChanged,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDivider() {
//     return Divider(
//       color: Colors.grey[300],
//       height: 1,
//       indent: 58,
//     );
//   }
// }