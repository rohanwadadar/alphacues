
// // biometric_authentication_page.dart
// import 'package:flutter/material.dart';

// class BiometricAuthenticationPage extends StatefulWidget {
//   const BiometricAuthenticationPage({Key? key}) : super(key: key);

//   @override
//   State<BiometricAuthenticationPage> createState() => _BiometricAuthenticationPageState();
// }

// class _BiometricAuthenticationPageState extends State<BiometricAuthenticationPage> {
//   bool _isBiometricEnabled = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: const Text('Biometric Authentication', style: TextStyle(color: Colors.white)),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Enable Biometric Authentication',
//               style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Use your fingerprint or face ID to securely access your account without entering your password each time.',
//               style: TextStyle(color: Colors.grey[400], fontSize: 16),
//             ),
//             const SizedBox(height: 24),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[900],
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 children: [
//                   const Icon(
//                     Icons.fingerprint,
//                     color: Colors.blue,
//                     size: 80,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text(
//                     'Quick and Secure Access',
//                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Use your device\'s biometric authentication for faster login',
//                     style: TextStyle(color: Colors.grey[400], fontSize: 14),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 24),
//             SwitchListTile(
//               title: const Text(
//                 'Enable Biometric Authentication',
//                 style: TextStyle(color: Colors.white),
//               ),
//               subtitle: Text(
//                 _isBiometricEnabled 
//                     ? 'Biometric authentication is enabled'
//                     : 'Biometric authentication is disabled',
//                 style: TextStyle(color: Colors.grey[400]),
//               ),
//               value: _isBiometricEnabled,
//               onChanged: (value) {
//                 setState(() {
//                   _isBiometricEnabled = value;
//                 });
//                 if (value) {
//                   _showBiometricConfirmationDialog();
//                 }
//               },
//               activeColor: Colors.blue,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 0),
//               tileColor: Colors.transparent,
//             ),
//             const SizedBox(height: 16),
//             const Divider(color: Colors.grey),
//             const SizedBox(height: 16),
//             Text(
//               'Note: Biometric authentication uses your device\'s secure storage and biometric sensors. Your biometric data never leaves your device.',
//               style: TextStyle(color: Colors.grey[500], fontSize: 14),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           child: const Text('Save Settings'),
//         ),
//       ),
//     );
//   }

//   void _showBiometricConfirmationDialog() {
//     showDialog(
//       context: context,
      
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: const Text('Verify Identity', style: TextStyle(color: Colors.white)),
//         content: const Text(
//           'Please verify your identity using your fingerprint or face ID to enable biometric authentication.',
//           style: TextStyle(color: Colors.grey),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 _isBiometricEnabled = false;
//               });
//             },
//             child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Here you would normally call a biometric authentication API
//               // For demo purposes, we'll just close the dialog
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Biometric authentication enabled successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//             ),
//             child: const Text('Verify'),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class BiometricAuthenticationPage extends StatefulWidget {
  const BiometricAuthenticationPage({Key? key}) : super(key: key);

  @override
  State<BiometricAuthenticationPage> createState() => _BiometricAuthenticationPageState();
}

class _BiometricAuthenticationPageState extends State<BiometricAuthenticationPage> {
  bool _isBiometricEnabled = false;

  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Biometric Authentication',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enable Biometric Authentication',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use your fingerprint or face ID to securely access your account without entering your password each time.',
              style: TextStyle(color: Colors.grey[700], fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: _primaryColor,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quick and Secure Access',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your device\'s biometric authentication for faster login',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Enable Biometric Authentication',
                  style: TextStyle(color: Colors.black),
                ),
                subtitle: Text(
                  _isBiometricEnabled 
                      ? 'Biometric authentication is enabled'
                      : 'Biometric authentication is disabled',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: _isBiometricEnabled,
                onChanged: (value) {
                  setState(() {
                    _isBiometricEnabled = value;
                  });
                  if (value) {
                    _showBiometricConfirmationDialog();
                  }
                },
                activeColor: _primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                tileColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: Biometric authentication uses your device\'s secure storage and biometric sensors. Your biometric data never leaves your device.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save Settings'),
        ),
      ),
    );
  }

  void _showBiometricConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Verify Identity',
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          'Please verify your identity using your fingerprint or face ID to enable biometric authentication.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isBiometricEnabled = false;
              });
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would normally call a biometric authentication API
              // For demo purposes, we'll just close the dialog
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Biometric authentication enabled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}