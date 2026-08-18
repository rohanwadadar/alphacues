
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class TwoFactorAuthenticationPage extends StatefulWidget {
//   const TwoFactorAuthenticationPage({Key? key}) : super(key: key);

//   @override
//   State<TwoFactorAuthenticationPage> createState() => _TwoFactorAuthenticationPageState();
// }

// class _TwoFactorAuthenticationPageState extends State<TwoFactorAuthenticationPage> {
//   bool _is2FAEnabled = false;
//   String _verificationMethod = 'SMS';
//   final List<String> _recoveryCode = [
//     'A5B2C', '7DE3F', 'G9H4I', 'J8K1L',
//     'M6N7O', 'P2Q3R', 'S5T9U', 'V4W6X'
//   ];
//   final TextEditingController _codeController = TextEditingController();
//   bool _isVerifyingCode = false;

//   @override
//   void dispose() {
//     _codeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: const Text('Two-Factor Authentication', style: TextStyle(color: Colors.white)),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Secure Your Account',
//               style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Two-factor authentication adds an extra layer of security to your account by requiring access to your phone in addition to your password.',
//               style: TextStyle(color: Colors.grey[400], fontSize: 14),
//             ),
//             const SizedBox(height: 24),
//             SwitchListTile(
//               title: const Text(
//                 'Enable Two-Factor Authentication',
//                 style: TextStyle(color: Colors.white),
//               ),
//               subtitle: Text(
//                 _is2FAEnabled 
//                     ? 'Two-factor authentication is enabled'
//                     : 'Two-factor authentication is disabled',
//                 style: TextStyle(color: Colors.grey[400]),
//               ),
//               value: _is2FAEnabled,
//               onChanged: (value) {
//                 if (value && !_is2FAEnabled) {
//                   _showSetupDialog();
//                 } else if (!value && _is2FAEnabled) {
//                   _showDisableConfirmation();
//                 } else {
//                   setState(() {
//                     _is2FAEnabled = value;
//                   });
//                 }
//               },
//               activeColor: Colors.blue,
//               contentPadding: const EdgeInsets.symmetric(horizontal: 0),
//               tileColor: Colors.transparent,
//             ),
//             if (_is2FAEnabled) ...[
//               const SizedBox(height: 24),
//               const Divider(color: Colors.grey),
//               const SizedBox(height: 24),
//               const Text(
//                 'Verification Method',
//                 style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               _buildRadioOption('SMS', 'Receive verification codes via text message'),
//               _buildRadioOption('Authenticator App', 'Use an authenticator app like Google Authenticator'),
//               const SizedBox(height: 24),
//               const Divider(color: Colors.grey),
//               const SizedBox(height: 24),
//               _buildRecoveryCodesSection(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRadioOption(String title, String subtitle) {
//     return RadioListTile<String>(
//       title: Text(title, style: const TextStyle(color: Colors.white)),
//       subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
//       value: title,
//       groupValue: _verificationMethod,
//       onChanged: (value) {
//         setState(() {
//           _verificationMethod = value!;
//         });
//       },
//       activeColor: Colors.blue,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 0),
//     );
//   }

//   Widget _buildRecoveryCodesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text(
//               'Recovery Codes',
//               style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             TextButton.icon(
//               icon: const Icon(Icons.refresh, color: Colors.blue, size: 16),
//               label: const Text('Generate New Codes', style: TextStyle(color: Colors.blue)),
//               onPressed: () {
//                 // In a real app, you would generate new recovery codes here
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('New recovery codes generated'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'If you lose access to your phone, you can sign in with recovery codes. Keep these in a safe place.',
//           style: TextStyle(color: Colors.grey[400], fontSize: 14),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.grey[900],
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey[800]!),
//           ),
//           child: Column(
//             children: [
//               GridView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   childAspectRatio: 3,
//                   crossAxisSpacing: 8,
//                   mainAxisSpacing: 8,
//                 ),
//                 itemCount: _recoveryCode.length,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[800],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _recoveryCode[index],
//                           style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.copy, color: Colors.grey, size: 16),
//                           onPressed: () {
//                             Clipboard.setData(ClipboardData(text: _recoveryCode[index]));
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('Code copied to clipboard'),
//                                 duration: Duration(seconds: 1),
//                               ),
//                             );
//                           },
//                           constraints: const BoxConstraints(),
//                           padding: EdgeInsets.zero,
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton.icon(
//                 icon: const Icon(Icons.download),
//                 label: const Text('Download Codes'),
//                 onPressed: () {
//                   // In a real app, this would download the recovery codes
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Recovery codes downloaded'),
//                       backgroundColor: Colors.green,
//                     ),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   minimumSize: const Size(double.infinity, 40),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   void _showSetupDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             return AlertDialog(
//               backgroundColor: Colors.grey[900],
//               title: Text(
//                 _isVerifyingCode 
//                     ? 'Enter Verification Code'
//                     : 'Set Up Two-Factor Authentication',
//                 style: const TextStyle(color: Colors.white),
//               ),
//               content: SingleChildScrollView(
//                 child: _isVerifyingCode
//                     ? Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'Enter the 6-digit code sent to your device',
//                             style: TextStyle(color: Colors.grey[400]),
//                           ),
//                           const SizedBox(height: 16),
//                           TextField(
//                             controller: _codeController,
//                             decoration: InputDecoration(
//                               labelText: 'Verification Code',
//                               labelStyle: TextStyle(color: Colors.grey[400]),
//                               enabledBorder: OutlineInputBorder(
//                                 borderSide: BorderSide(color: Colors.grey[800]!),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               focusedBorder: OutlineInputBorder(
//                                 borderSide: const BorderSide(color: Colors.blue),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               filled: true,
//                               fillColor: Colors.grey[800],
//                             ),
//                             style: const TextStyle(color: Colors.white),
//                             keyboardType: TextInputType.number,
//                             inputFormatters: [
//                               FilteringTextInputFormatter.digitsOnly,
//                               LengthLimitingTextInputFormatter(6),
//                             ],
//                           ),
//                         ],
//                       )
//                     : Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             'We\'ll send you a verification code to set up two-factor authentication.',
//                             style: TextStyle(color: Colors.grey[400]),
//                           ),
//                           const SizedBox(height: 16),
//                           ListTile(
//                             title: const Text('Phone Number', style: TextStyle(color: Colors.white)),
//                             subtitle: const Text('+1 (***) ***-5678', style: TextStyle(color: Colors.grey)),
//                             leading: const Icon(Icons.phone, color: Colors.grey),
//                             contentPadding: EdgeInsets.zero,
//                           ),
//                         ],
//                       ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     setState(() {
//                       _is2FAEnabled = false;
//                       _isVerifyingCode = false;
//                     });
//                   },
//                   child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_isVerifyingCode) {
//                       // Verify the code logic would go here
//                       Navigator.pop(context);
//                       setState(() {
//                         _is2FAEnabled = true;
//                         _isVerifyingCode = false;
//                       });
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Two-factor authentication enabled successfully'),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                     } else {
//                       setDialogState(() {
//                         _isVerifyingCode = true;
//                       });
//                     }
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                     foregroundColor: Colors.white,
//                   ),
//                   child: Text(_isVerifyingCode ? 'Verify' : 'Send Code'),
//                 ),
//               ],
//             );
//           }
//         );
//       },
//     );
//   }

//   void _showDisableConfirmation() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: const Text('Disable Two-Factor Authentication?', style: TextStyle(color: Colors.white)),
//         content: Text(
//           'This will make your account less secure. Are you sure you want to disable two-factor authentication?',
//           style: TextStyle(color: Colors.grey[400]),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 _is2FAEnabled = false;
//               });
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Two-factor authentication disabled'),
//                   backgroundColor: Colors.orange,
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Disable'),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TwoFactorAuthenticationPage extends StatefulWidget {
  const TwoFactorAuthenticationPage({Key? key}) : super(key: key);

  @override
  State<TwoFactorAuthenticationPage> createState() => _TwoFactorAuthenticationPageState();
}

class _TwoFactorAuthenticationPageState extends State<TwoFactorAuthenticationPage> {
  bool _is2FAEnabled = false;
  String _verificationMethod = 'SMS';
  final List<String> _recoveryCode = [
    'A5B2C', '7DE3F', 'G9H4I', 'J8K1L',
    'M6N7O', 'P2Q3R', 'S5T9U', 'V4W6X'
  ];
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifyingCode = false;

  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Two-Factor Authentication',
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
              'Secure Your Account',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Two-factor authentication adds an extra layer of security to your account by requiring access to your phone in addition to your password.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Enable Two-Factor Authentication',
                  style: TextStyle(color: Colors.black),
                ),
                subtitle: Text(
                  _is2FAEnabled 
                      ? 'Two-factor authentication is enabled'
                      : 'Two-factor authentication is disabled',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                value: _is2FAEnabled,
                onChanged: (value) {
                  if (value && !_is2FAEnabled) {
                    _showSetupDialog();
                  } else if (!value && _is2FAEnabled) {
                    _showDisableConfirmation();
                  } else {
                    setState(() {
                      _is2FAEnabled = value;
                    });
                  }
                },
                activeColor: _primaryColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                tileColor: Colors.transparent,
              ),
            ),
            if (_is2FAEnabled) ...[
              const SizedBox(height: 24),
              const Text(
                'Verification Method',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _buildRadioOption('SMS', 'Receive verification codes via text message'),
                    Divider(color: Colors.grey[300]),
                    _buildRadioOption('Authenticator App', 'Use an authenticator app like Google Authenticator'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildRecoveryCodesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, String subtitle) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: Colors.black)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      value: title,
      groupValue: _verificationMethod,
      onChanged: (value) {
        setState(() {
          _verificationMethod = value!;
        });
      },
      activeColor: _primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildRecoveryCodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recovery Codes',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              icon: Icon(Icons.refresh, color: _primaryColor, size: 16),
              label: Text(
                'Generate New Codes',
                style: TextStyle(color: _primaryColor),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('New recovery codes generated'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'If you lose access to your phone, you can sign in with recovery codes. Keep these in a safe place.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _recoveryCode.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _recoveryCode[index],
                          style: const TextStyle(
                            color: Colors.black,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, color: Colors.grey[600], size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _recoveryCode[index]));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Download Codes'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recovery codes downloaded'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(
                _isVerifyingCode 
                    ? 'Enter Verification Code'
                    : 'Set Up Two-Factor Authentication',
                style: const TextStyle(color: Colors.black),
              ),
              content: SingleChildScrollView(
                child: _isVerifyingCode
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Enter the 6-digit code sent to your device',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Verification Code',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: _primaryColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            style: const TextStyle(color: Colors.black),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'We\'ll send you a verification code to set up two-factor authentication.',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: const Text(
                              'Phone Number',
                              style: TextStyle(color: Colors.black),
                            ),
                            subtitle: Text(
                              '+1 (***) ***-5678',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            leading: Icon(Icons.phone, color: Colors.grey[600]),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _is2FAEnabled = false;
                      _isVerifyingCode = false;
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_isVerifyingCode) {
                      Navigator.pop(context);
                      setState(() {
                        _is2FAEnabled = true;
                        _isVerifyingCode = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Two-factor authentication enabled successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setDialogState(() {
                        _isVerifyingCode = true;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isVerifyingCode ? 'Verify' : 'Send Code'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Disable Two-Factor Authentication?',
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          'This will make your account less secure. Are you sure you want to disable two-factor authentication?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _is2FAEnabled = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Two-factor authentication disabled'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}