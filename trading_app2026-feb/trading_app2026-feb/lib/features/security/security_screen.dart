import 'package:flutter/material.dart';
import 'package:test_project/features/security/secure_storage_service.dart';
import 'package:test_project/features/security/set_pin_screen.dart';
import 'package:test_project/features/security/biometric_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _appLockEnabled = await SecureStorageService.isAppLockEnabled();
    _biometricEnabled = await SecureStorageService.isBiometricEnabled();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Security & App Lock', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: _loading 
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("App Protection", "Secure your account using a PIN or biometrics."),
                  _buildSectionCard([
                    _buildToggleTile(
                      icon: Icons.lock_outline,
                      title: "Enable App Lock",
                      subtitle: "Require PIN to open app",
                      value: _appLockEnabled,
                      onChanged: _toggleAppLock,
                    ),
                    _buildDivider(),
                    _buildToggleTile(
                      icon: Icons.face_unlock_outlined,
                      title: "Use Biometrics",
                      subtitle: "Fingerprint or Face ID",
                      value: _biometricEnabled,
                      onChanged: _appLockEnabled ? _toggleBiometric : null,
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  _buildHeader("Credentials", "Manage your access codes."),
                  _buildSectionCard([
                    _buildNavTile(
                      icon: Icons.password_outlined,
                      title: "Change PIN",
                      enabled: _appLockEnabled,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPinScreen())),
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: TextStyle(color: _primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
      ]),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      const SizedBox(height: 12),
    ]);
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({required IconData icon, required String title, required String subtitle, required bool value, ValueChanged<bool>? onChanged}) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: _primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      activeColor: _primaryColor,
      onChanged: onChanged,
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required bool enabled, required VoidCallback onTap}) {
    return ListTile(
      enabled: enabled,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: enabled ? _primaryColor.withOpacity(0.1) : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: enabled ? _primaryColor : Colors.grey, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => Divider(color: Colors.grey[300], height: 1, indent: 65);

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      final hasPin = await SecureStorageService.hasPin();
      if (!hasPin) {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SetPinScreen()));
        if (result != true) return;
      }
    }
    await SecureStorageService.setAppLockEnabled(value);
    setState(() => _appLockEnabled = value);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final available = await BiometricService.isAvailable();
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric not available')));
        return;
      }
    }
    await SecureStorageService.setBiometricEnabled(value);
    setState(() => _biometricEnabled = value);
  }
}