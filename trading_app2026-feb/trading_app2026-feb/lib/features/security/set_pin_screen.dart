import 'package:flutter/material.dart';
import 'package:test_project/features/security/secure_storage_service.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _confirming = false;
  bool _error = false;
  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  void _addDigit(String digit) {
    final target = _confirming ? _confirmPin : _pin;
    if (target.length >= 6) return;

    setState(() => target.add(digit));

    if (target.length == 6) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _confirming ? _verifyPin() : setState(() => _confirming = true);
      });
    }
  }

  void _verifyPin() async {
    if (_pin.join() != _confirmPin.join()) {
      setState(() => _error = true);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _error = false;
        _pin.clear();
        _confirmPin.clear();
        _confirming = false;
      });
      return;
    }
    await SecureStorageService.savePin(_pin.join());
    await SecureStorageService.setAppLockEnabled(true);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final filledDots = _confirming ? _confirmPin.length : _pin.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(_confirming ? 'Confirm Passcode' : 'Create Passcode', 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 14, height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filledDots ? (_error ? Colors.red : _primaryColor) : Colors.grey[200],
              ),
            )),
          ),
          
          const Spacer(),

          // PERFECT GRID KEYPAD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox.shrink();
                if (index == 10) return _buildKey("0");
                if (index == 11) return IconButton(onPressed: () => setState(() => (_confirming ? _confirmPin : _pin).removeLast()), icon: const Icon(Icons.backspace_outlined));
                return _buildKey("${index + 1}");
              },
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _addDigit(label),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[50]),
        child: Text(label, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ),
    );
  }
}