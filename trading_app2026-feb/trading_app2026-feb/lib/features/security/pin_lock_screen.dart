import 'package:flutter/material.dart';
import 'package:test_project/features/security/secure_storage_service.dart';
import 'package:test_project/features/security/biometric_service.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final List<String> _enteredPin = [];
  bool _error = false;

  static const Color primaryPurple = Color.fromARGB(255, 114, 70, 192);

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    if (!await SecureStorageService.isBiometricEnabled()) return;
    if (!await BiometricService.isAvailable()) return;

    final ok = await BiometricService.authenticate();
    if (ok && mounted) Navigator.pop(context, true);
  }

  void _addDigit(String digit) {
    if (_enteredPin.length >= 6) return;

    setState(() => _enteredPin.add(digit));

    if (_enteredPin.length == 6) {
      _verifyPin();
    }
  }

  void _removeDigit() {
    if (_enteredPin.isEmpty) return;
    setState(() => _enteredPin.removeLast());
  }

  Future<void> _verifyPin() async {
    final savedPin = await SecureStorageService.getPin();
    if (_enteredPin.join() == savedPin) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _error = true;
        _enteredPin.clear();
      });
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _error = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              const Text(
                'Enter Passcode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Unlock to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              /// 🔘 DOT INDICATORS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_error ? Colors.red : primaryPurple)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),

              const Spacer(),

              /// 🔢 KEYPAD
              _buildKeypad(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map(_keyButton).toList(),
            ),
          ),

        /// ✅ PERFECTLY CENTERED ZERO ROW
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70), // left spacer
              _keyButton('0'),
              IconButton(
                icon: const Icon(Icons.backspace_outlined),
                color: Colors.black87,
                iconSize: 26,
                onPressed: _removeDigit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keyButton(String digit) {
    return GestureDetector(
      onTap: () => _addDigit(digit),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryPurple.withOpacity(0.12),
          border: Border.all(color: primaryPurple.withOpacity(0.4)),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
