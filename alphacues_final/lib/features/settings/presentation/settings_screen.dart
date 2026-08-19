import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../onboarding/presentation/onboarding_guide_modal.dart';
import '../data/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const List<Color> _avatarColors = [
    Color(0xFF2563EB), // Blue
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Purple
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authSessionProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final user = authState.session?.user;
    final userEmail = user?.email ?? 'trader@alphacues.com';
    final avatarColor = _avatarColors[settings.avatarColorIndex % _avatarColors.length];

    return Scaffold(
      appBar: AppBar(
        title: const AlphaCuesFullLogo(),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // ── 1. RICH TRADER PROFILE HEADER CARD ────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showEditProfileSheet(context),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: avatarColor, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 44,
                            backgroundColor: avatarColor.withValues(alpha: 0.2),
                            child: Text(
                              settings.displayName.isNotEmpty
                                  ? settings.displayName[0].toUpperCase()
                                  : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'A'),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: avatarColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: avatarColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: colorScheme.surface, width: 2),
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    settings.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    settings.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trader Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, color: colorScheme.primary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Pro Level 12',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.green, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              settings.tradingStyle,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shield_outlined, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Risk: ${settings.riskTolerance}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 2. ACCOUNT & SECURITY SECTION ─────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Account & Security',
              children: [
                _buildTile(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile Information',
                  subtitle: '${settings.displayName} • ${settings.tradingStyle}',
                  onTap: () => _showEditProfileSheet(context),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.lock_outline_rounded,
                  title: 'Security & Biometrics',
                  subtitle: settings.biometricsEnabled ? 'FaceID / PIN Active' : '2FA Active',
                  onTap: () => _showSecurityDialog(context),
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Alerts on price movements & market cues',
                  value: settings.pushNotificationsEnabled,
                  onChanged: (val) {
                    settingsNotifier.togglePushNotifications(val);
                    _showSnackBar(
                      context,
                      val ? 'Push notifications enabled.' : 'Push notifications disabled.',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 3. ADVANCED TRADING & TECHNICAL EXECUTION ─────────────────
            _buildSectionGroup(
              context,
              title: 'Advanced Trading & Technical Execution',
              children: [
                _buildTile(
                  context,
                  icon: Icons.tune_rounded,
                  title: 'Default Trade Sizing & Order Type',
                  subtitle: '\$${settings.defaultPositionSize.toStringAsFixed(0)} • ${settings.defaultOrderType} Order',
                  onTap: () => _showTradeExecutionSettingsDialog(context),
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.show_chart_rounded,
                  title: 'Extended Hours Chart Data',
                  subtitle: 'Show pre-market (4:00 AM) & after-hours data',
                  value: settings.showExtendedHours,
                  onChanged: (val) {
                    settingsNotifier.updateTechnicalSettings(showExtendedHours: val);
                    _showSnackBar(
                      context,
                      val ? 'Extended hours data enabled.' : 'Extended hours data hidden.',
                    );
                  },
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.speed_rounded,
                  title: 'Quote Streaming & Data Speed',
                  subtitle: settings.quoteStreamSpeed,
                  onTap: () => _showStreamSpeedDialog(context),
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.visibility_off_outlined,
                  title: 'Privacy Mode (Blur Balances)',
                  subtitle: 'Blur portfolio values when switching apps',
                  value: settings.blurBalances,
                  onChanged: (val) {
                    settingsNotifier.updateTechnicalSettings(blurBalances: val);
                    _showSnackBar(
                      context,
                      val ? 'Privacy Mode enabled.' : 'Privacy Mode disabled.',
                    );
                  },
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.download_rounded,
                  title: 'Export Portfolio & Tax Reports',
                  subtitle: 'Download CSV / PDF transaction history',
                  onTap: () => _showExportReportsDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 4. ALPHACUES APP PREFERENCES ──────────────────────────────
            _buildSectionGroup(
              context,
              title: 'AlphaCues App Preferences',
              children: [
                _buildSwitchTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Theme',
                  subtitle: 'Toggle sleek dark contrast mode',
                  value: settings.isDarkMode,
                  onChanged: (val) {
                    settingsNotifier.toggleDarkMode(val);
                    _showSnackBar(
                      context,
                      val ? 'Dark mode enabled.' : 'Light mode enabled.',
                    );
                  },
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.attach_money_rounded,
                  title: 'Base Currency Display',
                  subtitle: 'USD (\$)',
                  onTap: () => _showCurrencyDialog(context),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Local Storage & Cache',
                  subtitle: 'Reset cached asset snapshots',
                  onTap: () => _showClearCacheDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 5. TERMS, LEGAL & MANUAL ──────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Terms, Legal & Feature Manual',
              children: [
                _buildTile(
                  context,
                  icon: Icons.auto_stories_rounded,
                  title: 'View App Onboarding Manual',
                  subtitle: 'Re-launch interactive feature walkthrough',
                  onTap: () => OnboardingGuideModal.show(context),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'AlphaCues Help Center & FAQ',
                  subtitle: 'Trading guides & platform FAQ',
                  onTap: () => _showHelpCenterSheet(context),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.gavel_rounded,
                  title: 'AlphaCues Terms of Service',
                  subtitle: 'User agreements & terms of use',
                  onTap: () => _showTermsOfServiceDialog(context),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy & Data Security',
                  subtitle: 'AES-256 Encryption & Data Standards',
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Financial Risk Disclaimer',
                  subtitle: 'Market risk disclosures & policies',
                  onTap: () => _showFinancialDisclaimerDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 6. LOGOUT BUTTON ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to log out of AlphaCues?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(authSessionProvider.notifier).logout();
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Version info & Copyright
            Text(
              'AlphaCues v2.4.0 (Build 2026.08)\n© 2026 AlphaCues Technologies Inc. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── MODALS & DIALOGS IMPLEMENTATIONS ──────────────────────────────────────

  void _showEditProfileSheet(BuildContext context) {
    final settings = ref.read(settingsProvider);
    final nameController = TextEditingController(text: settings.displayName);
    final bioController = TextEditingController(text: settings.bio);
    int selectedColorIndex = settings.avatarColorIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Edit Profile Information',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Avatar Accent Color', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(_avatarColors.length, (index) {
                      final color = _avatarColors[index];
                      final isSelected = selectedColorIndex == index;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColorIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: color,
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: settings.tradingStyle,
                    decoration: const InputDecoration(
                      labelText: 'Trading Strategy Style',
                      prefixIcon: Icon(Icons.bolt_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Swing Trader', child: Text('Swing Trader')),
                      DropdownMenuItem(value: 'Day Trader', child: Text('Day Trader')),
                      DropdownMenuItem(value: 'Value Investor', child: Text('Value Investor')),
                      DropdownMenuItem(value: 'Options Scalper', child: Text('Options Scalper')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateProfile(
                              displayName: nameController.text.trim(),
                              bio: bioController.text.trim(),
                              tradingStyle: val,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: settings.riskTolerance,
                    decoration: const InputDecoration(
                      labelText: 'Risk Tolerance Level',
                      prefixIcon: Icon(Icons.shield_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Conservative', child: Text('Conservative (Low Risk)')),
                      DropdownMenuItem(value: 'Moderate', child: Text('Moderate (Medium Risk)')),
                      DropdownMenuItem(value: 'Aggressive', child: Text('Aggressive (High Risk)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateProfile(
                              displayName: nameController.text.trim(),
                              bio: bioController.text.trim(),
                              riskTolerance: val,
                            );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () {
                        ref.read(settingsProvider.notifier).updateProfile(
                              displayName: nameController.text.trim(),
                              bio: bioController.text.trim(),
                              avatarColorIndex: selectedColorIndex,
                            );
                        Navigator.pop(ctx);
                        _showSnackBar(context, 'Profile information updated successfully!');
                      },
                      child: const Text('Save Profile Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSecurityDialog(BuildContext context) {
    final settings = ref.read(settingsProvider);
    bool biometrics = settings.biometricsEnabled;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Security & Privacy'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Biometric / PIN Lock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Require FaceID/TouchID on app start', style: TextStyle(fontSize: 12)),
                    value: biometrics,
                    onChanged: (val) {
                      setDialogState(() => biometrics = val);
                      ref.read(settingsProvider.notifier).toggleBiometrics(val);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.key_outlined, size: 20),
                    title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Update system login password', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showChangePasswordDialog(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.devices_outlined, size: 20),
                    title: const Text('Active Sessions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('1 Active Mobile Session (This Device)', style: TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (newPass.text != confirmPass.text) {
                  _showSnackBar(context, 'New passwords do not match.', isError: true);
                  return;
                }
                if (newPass.text.length < 6) {
                  _showSnackBar(context, 'Password must be at least 6 characters.', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                _showSnackBar(context, 'Password updated successfully!');
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showTradeExecutionSettingsDialog(BuildContext context) {
    final settings = ref.read(settingsProvider);
    final sizeController = TextEditingController(text: settings.defaultPositionSize.toStringAsFixed(0));
    String orderType = settings.defaultOrderType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.tune_rounded, color: Colors.deepPurple),
                  SizedBox(width: 10),
                  Text('Trade Execution'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default Position Size (\$)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: sizeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(prefixText: '\$ '),
                  ),
                  const SizedBox(height: 16),
                  const Text('Default Order Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Market', label: Text('Market')),
                      ButtonSegment(value: 'Limit', label: Text('Limit')),
                      ButtonSegment(value: 'Stop', label: Text('Stop')),
                    ],
                    selected: {orderType},
                    onSelectionChanged: (set) => setDialogState(() => orderType = set.first),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final size = double.tryParse(sizeController.text) ?? 1000.0;
                    ref.read(settingsProvider.notifier).updateTechnicalSettings(
                          defaultPositionSize: size,
                          defaultOrderType: orderType,
                        );
                    Navigator.pop(ctx);
                    _showSnackBar(context, 'Execution defaults updated successfully!');
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStreamSpeedDialog(BuildContext context) {
    final settings = ref.read(settingsProvider);
    final options = ['Real-Time (100ms)', 'High Speed (1s)', 'Battery Saver (15s)'];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.speed_rounded, color: Colors.blue),
              SizedBox(width: 10),
              Text('Quote Stream Speed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((opt) => RadioListTile<String>(
                      title: Text(opt, style: const TextStyle(fontSize: 14)),
                      value: opt,
                      groupValue: settings.quoteStreamSpeed,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).updateTechnicalSettings(quoteStreamSpeed: val);
                          Navigator.pop(ctx);
                          _showSnackBar(context, 'Quote streaming set to $val');
                        }
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showExportReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.download_rounded, color: Colors.green),
            SizedBox(width: 10),
            Text('Export Reports'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Export Format', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.table_chart_rounded, color: Colors.green),
              title: Text('CSV Transaction History'),
              subtitle: Text('Full log of executions & holdings'),
            ),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              title: Text('PDF Realized Tax Summary'),
              subtitle: Text('Yearly profit/loss overview report'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnackBar(context, 'Exported AlphaCues_Transactions_2026.csv successfully!');
            },
            child: const Text('Download CSV'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.attach_money_rounded, color: Colors.green),
            SizedBox(width: 10),
            Text('Base Currency'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              title: Text('USD - United States Dollar'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: Text('€', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              title: Text('EUR - Euro'),
            ),
            ListTile(
              leading: Text('£', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              title: Text('GBP - British Pound'),
            ),
            ListTile(
              leading: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              title: Text('INR - Indian Rupee'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save Selection'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: Colors.deepPurple),
            SizedBox(width: 10),
            Text('Terms of Service'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'AlphaCues Platform Terms of Service:\n\n'
            '1. Acceptance of Terms: By accessing AlphaCues, you agree to comply with all terms and conditions outlined herein.\n\n'
            '2. Account Usage: Accounts are non-transferable and strictly intended for personal trading and analytical use.\n\n'
            '3. Intellectual Property: All custom algorithms, visual cues, and interface components are proprietary property of AlphaCues Inc.\n\n'
            '4. Termination: AlphaCues reserves the right to suspend accounts violating community guidelines or engaging in fraudulent activities.\n\n'
            'Effective Date: August 2026.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Accept & Close'),
          ),
        ],
      ),
    );
  }

  void _showFinancialDisclaimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Financial Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'AlphaCues Risk & Financial Disclosure:\n\n'
            '• Financial Risk: Trading stocks, options, and financial instruments involves substantial risk of loss. Past performance does not guarantee future results.\n\n'
            '• Informational Use: Market data and AI signals provided by AlphaCues are for analytical and educational purposes only, not individualized investment advice.\n\n'
            '• Independent Judgement: Users are advised to conduct independent research and consult licensed financial advisors before making investment decisions.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear App Cache'),
        content: const Text('This will reset cached stock prices, market images, and local temporary data. Your account settings will remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              Navigator.pop(ctx);
              _showSnackBar(context, 'Cache and temporary data cleared successfully!');
            },
            child: const Text('Clear Now'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterSheet(BuildContext context) {
    final faqs = [
      {'q': 'How do I place paper trades?', 'a': 'Navigate to any stock detail page or Watchlist tab and tap "Buy" or "Sell". Select Market/Limit order and confirm.'},
      {'q': 'Is real-time data included?', 'a': 'Yes! Alpaca WebSocket feeds provide real-time quote and trade updates.'},
      {'q': 'How do alert notifications work?', 'a': 'You can set price target alerts under the Alerts tab. When triggered, push notifications will notify your device.'},
      {'q': 'Where do fundamentals come from?', 'a': 'Fundamentals data is sourced via AlphaVantage financial overview APIs.'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            final theme = Theme.of(context);
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Help Center & FAQ',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...faqs.map((faq) => ExpansionTile(
                      title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                          child: Text(faq['a']!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                        ),
                      ],
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showSnackBar(context, 'Support request submitted. Support team will email you shortly.');
                    },
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Contact AlphaCues Support'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Colors.blue),
            SizedBox(width: 10),
            Text('Privacy & Legal'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'AlphaCues Platform Data Security & Privacy Policy:\n\n'
            '1. Data Encryption: All API communication and stored tokens are secured using AES-256 TLS 1.3 standards.\n\n'
            '2. Account Confidentiality: We do not share your paper trading activities or personal data with third-party advertisers.\n\n'
            '3. SEC & Regulatory Standard Compliance: Market data feeds strictly adhere to exchange streaming terms.\n\n'
            'Version: 2026.1 Compliance release.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildSectionGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          elevation: 0.5,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
