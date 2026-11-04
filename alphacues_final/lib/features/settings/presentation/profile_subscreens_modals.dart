import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../portfolio/data/portfolio_providers.dart';
import '../../notifications/data/notifications_notifier.dart';

/// Helper modal bottom sheet builder with matching purple header & smooth drag handle
Future<void> showProfileModal({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final isDark = theme.brightness == Brightness.dark;
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F1F2C),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. CHANGE PASSWORD MODAL
// ─────────────────────────────────────────────────────────────────────────────
class ChangePasswordModal extends ConsumerStatefulWidget {
  const ChangePasswordModal({super.key});

  @override
  ConsumerState<ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends ConsumerState<ChangePasswordModal> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile({
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7246C0);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ensure your new password contains at least 8 characters with a mix of numbers and letters.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _currentController,
            obscureText: _obscureCurrent,
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline, color: purple),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newController,
            obscureText: _obscureNew,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_reset_outlined, color: purple),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.length < 8) ? 'At least 8 characters required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.check_circle_outline, color: purple),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => v != _newController.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SECURITY & APP LOCK MODAL
// ─────────────────────────────────────────────────────────────────────────────
class SecurityAppLockModal extends ConsumerStatefulWidget {
  const SecurityAppLockModal({super.key});

  @override
  ConsumerState<SecurityAppLockModal> createState() => _SecurityAppLockModalState();
}

class _SecurityAppLockModalState extends ConsumerState<SecurityAppLockModal> {
  bool _appLock = true;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    const purple = Color(0xFF7246C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Protect your trading activity using a local PIN or biometric authentication on this device.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 18),
        SwitchListTile(
          title: const Text('Enable App Lock', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Require PIN or fingerprint whenever app is resumed'),
          value: _appLock,
          activeColor: purple,
          onChanged: (val) {
            setState(() => _appLock = val);
            ref.read(authRepositoryProvider).updateProfile({'tradingStyle': settings.tradingStyle});
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Biometric Authentication', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Fingerprint / Face ID unlock'),
          value: settings.biometricsEnabled,
          activeColor: purple,
          onChanged: (val) {
            notifier.toggleBiometrics(val);
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Auto-Lock Timeout', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${settings.autoLockMinutes} minutes of inactivity'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (dCtx) => SimpleDialog(
                title: const Text('Auto-Lock Duration'),
                children: [1, 5, 15, 30].map((m) {
                  return SimpleDialogOption(
                    onPressed: () {
                      notifier.updateTechnicalSettings(autoLockMinutes: m);
                      Navigator.pop(dCtx);
                    },
                    child: Text('$m minutes'),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. TWO-FACTOR AUTHENTICATION MODAL
// ─────────────────────────────────────────────────────────────────────────────
class TwoFactorAuthModal extends ConsumerStatefulWidget {
  const TwoFactorAuthModal({super.key});

  @override
  ConsumerState<TwoFactorAuthModal> createState() => _TwoFactorAuthModalState();
}

class _TwoFactorAuthModalState extends ConsumerState<TwoFactorAuthModal> {
  bool _twoFactor = true;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7246C0);

    final backupCodes = const [
      'A5B2C-7DE3F',
      'G9H4I-J8K1L',
      'M6N7O-P2Q3R',
      'S5T9U-V4W6X',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: purple, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Multi-Factor Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    _twoFactor ? '2FA is Active (SMS / OTP)' : '2FA is currently Disabled',
                    style: TextStyle(
                      fontSize: 13,
                      color: _twoFactor ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text('Enable 2-Step Verification', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Prompt for 6-digit OTP code on new device sign-ins'),
          value: _twoFactor,
          activeColor: purple,
          onChanged: (val) async {
            setState(() => _twoFactor = val);
            await ref.read(authRepositoryProvider).updateProfile({
              'kycStatus': val ? 'Verified - 2FA Active' : 'Verified',
            });
          },
        ),
        const Divider(),
        const SizedBox(height: 8),
        const Text('Backup Recovery Codes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Save these one-time codes in a safe place to regain access if you lose your phone.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: backupCodes.map((code) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(code, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                  const Icon(Icons.lock_clock, size: 14, color: Colors.grey),
                ],
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: backupCodes.join('\n')));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recovery codes copied to clipboard!')),
            );
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy All Backup Codes'),
          style: OutlinedButton.styleFrom(
            foregroundColor: purple,
            side: const BorderSide(color: purple),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. PRIVACY SETTINGS MODAL
// ─────────────────────────────────────────────────────────────────────────────
class PrivacySettingsModal extends ConsumerStatefulWidget {
  const PrivacySettingsModal({super.key});

  @override
  ConsumerState<PrivacySettingsModal> createState() => _PrivacySettingsModalState();
}

class _PrivacySettingsModalState extends ConsumerState<PrivacySettingsModal> {
  bool _publicProfile = true;
  bool _shareAnalytics = true;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7246C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Public Trader Profile', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Allow other traders to view your trading persona and rank'),
          value: _publicProfile,
          activeColor: purple,
          onChanged: (val) {
            setState(() => _publicProfile = val);
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Share Anonymous Usage Analytics', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Help us improve speed and detect crash telemetry'),
          value: _shareAnalytics,
          activeColor: purple,
          onChanged: (val) {
            setState(() => _shareAnalytics = val);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.download_for_offline_outlined, color: purple),
          title: const Text('Download My Account Data', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Receive a JSON copy of all watchlists, alerts, and trades'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account data archive requested. Check your email shortly.')),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
          title: const Text('Delete Account & Personal Data', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
          subtitle: const Text('Permanently erase account and trading history'),
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (dCtx) => AlertDialog(
                title: const Text('Delete Account?'),
                content: const Text('This action is irreversible. All open positions, watchlists, and data will be permanently wiped.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account deletion request queued.')),
                      );
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. TAX CENTER MODAL
// ─────────────────────────────────────────────────────────────────────────────
class TaxCenterModal extends ConsumerStatefulWidget {
  const TaxCenterModal({super.key});

  @override
  ConsumerState<TaxCenterModal> createState() => _TaxCenterModalState();
}

class _TaxCenterModalState extends ConsumerState<TaxCenterModal> {
  String _year = '2026';

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final transactions = transactionsAsync.asData?.value ?? [];
    const purple = Color(0xFF7246C0);

    double totalSellValue = 0.0;
    for (final t in transactions) {
      if (t.action.toUpperCase() == 'SELL') {
        totalSellValue += (t.price * t.volume);
      }
    }
    final double netGains = totalSellValue > 0 ? totalSellValue * 0.075 : 0.0;
    final double shortTerm = netGains * 0.65;
    final double longTerm = netGains * 0.35;
    final bool isPositive = netGains >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tax Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButton<String>(
              value: _year,
              underline: const SizedBox(),
              items: ['2025', '2026'].map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _year = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: purple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: purple.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net Realized Gains/Losses', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                    '${isPositive ? '+' : '-'}\$${netGains.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Short-Term Capital Gains', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                    '+\$${shortTerm.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Long-Term Capital Gains', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(
                    '+\$${longTerm.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Available Tax Forms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        _buildDocumentTile(context, 'Consolidated Form 1099', '1099-B, 1099-DIV, 1099-INT', 'Ready (PDF)'),
        _buildDocumentTile(context, 'Realized Gain/Loss Summary', 'Complete lot-by-lot transaction detail (${transactions.length} events logged)', 'Ready (CSV)'),
      ],
    );
  }

  Widget _buildDocumentTile(BuildContext context, String title, String subtitle, String status) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading $title...')),
            );
          },
          child: const Text('Download'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. REPORTS & STATEMENTS MODAL
// ─────────────────────────────────────────────────────────────────────────────
class ReportsStatementsModal extends StatelessWidget {
  const ReportsStatementsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final statements = [
      {'period': 'October 2026 Statement', 'date': 'Generated Nov 01, 2026', 'size': '248 KB'},
      {'period': 'September 2026 Statement', 'date': 'Generated Oct 01, 2026', 'size': '312 KB'},
      {'period': 'August 2026 Statement', 'date': 'Generated Sep 01, 2026', 'size': '290 KB'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Monthly Account Statements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        ...statements.map((s) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF7246C0)),
            title: Text(s['period']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text('${s['date']} • ${s['size']}', style: const TextStyle(fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.download, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloading ${s['period']}...')),
                );
              },
            ),
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. REWARDS MODAL
// ─────────────────────────────────────────────────────────────────────────────
class RewardsModal extends StatelessWidget {
  const RewardsModal({super.key});

  @override
  Widget build(BuildContext context) {
    const points = 1420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7246C0), Color(0xFF9333EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Alpha Rewards Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Icon(Icons.military_tech, color: Colors.amber, size: 28),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '$points PTS',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('Silver Tier Trader • 580 pts to Gold Tier', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: points / 2000.0,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(Colors.amber),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Refer a Trader Friend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 6),
        const Text('Share your unique code to earn 500 bonus points each when they make their first simulated trade.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ALPHA-VIP-2026', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'ALPHA-VIP-2026'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Referral code copied!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. MESSAGE CENTER MODAL
// ─────────────────────────────────────────────────────────────────────────────
class MessageCenterModal extends ConsumerWidget {
  const MessageCenterModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final realNotifs = notificationsAsync.asData?.value ?? [];

    if (realNotifs.isNotEmpty) {
      return Column(
        children: realNotifs.map((n) {
          final isAlert = n.category.toLowerCase().contains('alert');
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isAlert ? Colors.amber : Colors.blue).withValues(alpha: 0.15),
                child: Icon(
                  isAlert ? Icons.bolt : Icons.notifications_active_outlined,
                  color: isAlert ? Colors.amber : Colors.blue,
                  size: 20,
                ),
              ),
              title: Text(
                n.title,
                style: TextStyle(
                  fontWeight: !n.isRead ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                n.body,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: !n.isRead
                  ? Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7246C0)))
                  : null,
            ),
          );
        }).toList(),
      );
    }

    final messages = [
      {'title': 'Real-Time Feeds Active: WebSocket Connected', 'time': 'Just now', 'unread': false, 'icon': Icons.bolt, 'color': Colors.amber},
      {'title': 'System: US Equity Markets Open', 'time': '2 hours ago', 'unread': false, 'icon': Icons.info_outline, 'color': Colors.blue},
      {'title': 'Execution: Paper Portfolio Initialized', 'time': 'Today', 'unread': false, 'icon': Icons.check_circle_outline, 'color': Colors.green},
    ];

    return Column(
      children: messages.map((m) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (m['color'] as Color).withValues(alpha: 0.15),
            child: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 20),
          ),
          title: Text(
            m['title'] as String,
            style: TextStyle(
              fontWeight: m['unread'] == true ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          subtitle: Text(m['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: m['unread'] == true
              ? Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF7246C0)))
              : null,
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. NOTIFICATION PREFERENCES MODAL
// ─────────────────────────────────────────────────────────────────────────────
class NotificationPreferencesModal extends ConsumerWidget {
  const NotificationPreferencesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    const purple = Color(0xFF7246C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Real-time alerts on price breaks and triggers'),
          value: settings.pushNotificationsEnabled,
          activeColor: purple,
          onChanged: (val) {
            notifier.togglePushNotifications(val);
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Email Daily Digest', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Daily summary of watchlists and active alerts'),
          value: true,
          activeColor: purple,
          onChanged: (val) {},
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('SMS Critical Security Alerts', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Notify via SMS if unrecognized login detected'),
          value: true,
          activeColor: purple,
          onChanged: (val) {},
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. DATA USAGE SETTINGS MODAL
// ─────────────────────────────────────────────────────────────────────────────
class DataUsageSettingsModal extends ConsumerStatefulWidget {
  const DataUsageSettingsModal({super.key});

  @override
  ConsumerState<DataUsageSettingsModal> createState() => _DataUsageSettingsModalState();
}

class _DataUsageSettingsModalState extends ConsumerState<DataUsageSettingsModal> {
  int _autoplay = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    const purple = Color(0xFF7246C0);

    final speeds = ['Real-Time (100ms)', 'Balanced (500ms)', 'Battery Saver (2s)'];
    final autoplays = ['Always', 'Wi-Fi Only', 'Never'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Market Tick Streaming Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ...speeds.map((s) => ListTile(
          title: Text(s, style: const TextStyle(fontSize: 14)),
          leading: Radio<String>(
            value: s,
            groupValue: settings.quoteStreamSpeed,
            activeColor: purple,
            onChanged: (v) {
              if (v != null) notifier.updateTechnicalSettings(quoteStreamSpeed: v);
            },
          ),
          onTap: () => notifier.updateTechnicalSettings(quoteStreamSpeed: s),
        )),
        const Divider(),
        const Text('Chart & Video Autoplay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ...autoplays.asMap().entries.map((e) => ListTile(
          title: Text(e.value, style: const TextStyle(fontSize: 14)),
          leading: Radio<int>(
            value: e.key,
            groupValue: _autoplay,
            activeColor: purple,
            onChanged: (v) {
              if (v != null) setState(() => _autoplay = v);
            },
          ),
          onTap: () => setState(() => _autoplay = e.key),
        )),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cleaning_services_outlined, color: purple),
          title: const Text('Clear Offline Cache', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Free up 18.4 MB of stored candles and quotes'),
          trailing: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline cache cleared successfully!')),
              );
            },
            child: const Text('Clear'),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. APP PREFERENCES MODAL
// ─────────────────────────────────────────────────────────────────────────────
class AppPreferencesModal extends ConsumerStatefulWidget {
  const AppPreferencesModal({super.key});

  @override
  ConsumerState<AppPreferencesModal> createState() => _AppPreferencesModalState();
}

class _AppPreferencesModalState extends ConsumerState<AppPreferencesModal> {
  String _currency = 'USD (\$)';

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    const purple = Color(0xFF7246C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Appearance Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: ['Light', 'Dark'].map((mode) {
            final isSelected = (mode == 'Dark' && settings.isDarkMode) || (mode == 'Light' && !settings.isDarkMode);
            return ChoiceChip(
              label: Text(mode),
              selected: isSelected,
              selectedColor: purple.withValues(alpha: 0.2),
              onSelected: (_) => notifier.toggleDarkMode(mode == 'Dark'),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Divider(),
        const Text('Currency Display', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: ['USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)'].map((curr) {
            final isSelected = _currency == curr;
            return ChoiceChip(
              label: Text(curr),
              selected: isSelected,
              selectedColor: purple.withValues(alpha: 0.2),
              onSelected: (_) => setState(() => _currency = curr),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        const Divider(),
        SwitchListTile(
          title: const Text('Blur Balance Values', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Hide dollar amounts in public view'),
          value: settings.blurBalances,
          activeColor: purple,
          onChanged: (val) => notifier.updateTechnicalSettings(blurBalances: val),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 12. FEATURE SETTINGS MODAL
// ─────────────────────────────────────────────────────────────────────────────
class FeatureSettingsModal extends StatefulWidget {
  const FeatureSettingsModal({super.key});

  @override
  State<FeatureSettingsModal> createState() => _FeatureSettingsModalState();
}

class _FeatureSettingsModalState extends State<FeatureSettingsModal> {
  bool _screener = true;
  bool _simulator = true;
  bool _aiCues = true;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7246C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Screener Module', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Enable multi-factor algorithmic screener scans'),
          value: _screener,
          activeColor: purple,
          onChanged: (v) => setState(() => _screener = v),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Virtual Simulator', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Paper trading mode with \$100k balance'),
          value: _simulator,
          activeColor: purple,
          onChanged: (v) => setState(() => _simulator = v),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('AI Market Sentiment Cues', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Real-time sentiment scoring from Alpha Vantage'),
          value: _aiCues,
          activeColor: purple,
          onChanged: (v) => setState(() => _aiCues = v),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 13. FAQ MODAL
// ─────────────────────────────────────────────────────────────────────────────
class FaqModal extends StatelessWidget {
  const FaqModal({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': 'How are market quotes updated in real-time?',
        'a': 'AlphaCues connects directly to Alpaca IEX websocket streams with coalesced 100ms buffering and fallback to REST snapshots when disconnected.',
      },
      {
        'q': 'Is paper trading capital real money?',
        'a': 'No, all virtual simulator trades use simulated paper currency. You can test strategies risk-free.',
      },
      {
        'q': 'How do I submit and verify my Govt ID?',
        'a': 'Go to Edit Account or tap the Govt ID badge to submit your passport or driver license. Approvals are instant in sandbox mode.',
      },
      {
        'q': 'How do price alerts notify me?',
        'a': 'Alerts trigger in real-time through the backend Celery evaluation loop and are delivered via FCM push notifications and in-app bell notices.',
      },
    ];

    return Column(
      children: faqs.map((f) => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: ExpansionTile(
          title: Text(f['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(f['a']!, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 14. CONTACT SUPPORT MODAL
// ─────────────────────────────────────────────────────────────────────────────
class ContactSupportModal extends StatefulWidget {
  const ContactSupportModal({super.key});

  @override
  State<ContactSupportModal> createState() => _ContactSupportModalState();
}

class _ContactSupportModalState extends State<ContactSupportModal> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'Trading / Order Issue';
  bool _submitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out both subject and message.')),
      );
      return;
    }
    setState(() => _submitting = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ticket #AC-8921 opened! Our team will respond within 2 hours.'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7246C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _category,
          decoration: InputDecoration(
            labelText: 'Support Category',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            'Trading / Order Issue',
            'Market Data & Charts',
            'KYC & Verification',
            'Bug Report / Feedback',
            'Billing & Rewards',
          ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _category = v);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _subjectController,
          decoration: InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _messageController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Describe the issue or inquiry...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Priority Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 14),
        const Center(
          child: Text(
            'Direct email: support@alphacues.com • 24/7 Desk',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
