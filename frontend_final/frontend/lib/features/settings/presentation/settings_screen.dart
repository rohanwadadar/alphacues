import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/alpha_cues_logo.dart';
import '../../../core/auth/auth_session_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../dashboard/presentation/widgets/dashboard_formatters.dart';
import '../../dashboard/presentation/widgets/notification_bell.dart';
import '../../onboarding/presentation/onboarding_guide_modal.dart';
import '../../portfolio/data/portfolio_providers.dart';
import '../../portfolio/presentation/portfolio_event_form_dialog.dart';
import '../data/settings_provider.dart';
import '../../watchlist/data/watchlist_providers.dart';
import 'govt_id_card_modal.dart';
import 'profile_subscreens_modals.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _compactLayout = false;
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
        actions: const [
          NotificationBell(),
          SizedBox(width: 8),
        ],
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

            // ── 2. DASHBOARD TRANSACTIONS SECTION ─────────────────────────
            const _DashboardTransactionsSection(),
            const SizedBox(height: 20),

            // ── 3. SECURITY ───────────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Security',
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
                  icon: Icons.password_rounded,
                  title: 'Change Password',
                  subtitle: 'Update account password & security key',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Change Password',
                    child: const ChangePasswordModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Security & App Lock',
                  subtitle: settings.biometricsEnabled ? 'Biometrics Active • Auto-lock set' : 'Configure PIN & Biometrics',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Security & App Lock',
                    child: const SecurityAppLockModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.phonelink_lock_rounded,
                  title: 'Two-Factor Authentication',
                  subtitle: 'Authenticator App, SMS & Security Codes',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Two-Factor Authentication',
                    child: const TwoFactorAuthModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.shield_outlined,
                  title: 'Privacy Settings',
                  subtitle: 'Balance masking, public profile & analytics',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Privacy Settings',
                    child: const PrivacySettingsModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.badge_outlined,
                  title: 'Government Identity & KYC Card',
                  subtitle: 'View verified regulatory credential',
                  onTap: () => GovtIdCardModal.show(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 4. FINANCIAL ──────────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Financial',
              children: [
                _buildTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Tax Center',
                  subtitle: 'Form 1099-B, realized gains & tax harvest',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Tax Center',
                    child: const TaxCenterModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.assessment_outlined,
                  title: 'Reports & Statements',
                  subtitle: 'Monthly statements, trade confirmations & PDF audits',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Reports & Statements',
                    child: const ReportsStatementsModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.card_giftcard_rounded,
                  title: 'Rewards',
                  subtitle: 'Alpha Tier benefits, trading rebates & bonus',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'AlphaCues Rewards',
                    child: const RewardsModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.tune_rounded,
                  title: 'Default Trade Sizing & Order Type',
                  subtitle: '\$${settings.defaultPositionSize.toStringAsFixed(0)} • ${settings.defaultOrderType} Order',
                  onTap: () => _showTradeExecutionSettingsDialog(context),
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

            // ── 5. COMMUNICATION ──────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Communication',
              children: [
                _buildTile(
                  context,
                  icon: Icons.mark_chat_unread_outlined,
                  title: 'Message Center',
                  subtitle: 'Direct support inbox, fill alerts & system notices',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Message Center',
                    child: const MessageCenterModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.tune_outlined,
                  title: 'Notification Preferences',
                  subtitle: 'Customize price triggers, news & execution bells',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Notification Preferences',
                    child: const NotificationPreferencesModal(),
                  ),
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Real-time price alerts & market cues',
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

            // ── 6. APP PREFERENCE & DATA USAGE ────────────────────────────
            _buildSectionGroup(
              context,
              title: 'App preference & Data usage',
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
                  icon: Icons.data_usage_rounded,
                  title: 'Data Usage Settings',
                  subtitle: 'Mobile data limits, chart resolution & cache policy',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Data Usage Settings',
                    child: const DataUsageSettingsModal(),
                  ),
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
                  icon: Icons.speed_rounded,
                  title: 'Quote Streaming & Data Speed',
                  subtitle: settings.quoteStreamSpeed,
                  onTap: () => _showStreamSpeedDialog(context),
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

            // ── 7. PREFERENCES ────────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Preferences',
              children: [
                _buildTile(
                  context,
                  icon: Icons.settings_suggest_outlined,
                  title: 'Feature Settings',
                  subtitle: 'Order defaults, quick trade & extended hours',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Feature Settings',
                    child: const FeatureSettingsModal(),
                  ),
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Layout',
                  subtitle: _compactLayout ? 'Compact card layout' : 'Standard card layout',
                  value: _compactLayout,
                  onChanged: (val) {
                    setState(() => _compactLayout = val);
                    _showSnackBar(
                      context,
                      val ? 'Compact layout enabled.' : 'Standard layout enabled.',
                    );
                  },
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
              ],
            ),
            const SizedBox(height: 20),

            // ── 8. SUPPORT ────────────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Support',
              children: [
                _buildTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'FAQ',
                  subtitle: 'Frequently asked questions & platform tutorials',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'AlphaCues FAQ',
                    child: const FaqModal(),
                  ),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Support',
                  subtitle: '24/7 Live Desk, Ticket submission & phone',
                  onTap: () => showProfileModal(
                    context: context,
                    title: 'Contact Support',
                    child: const ContactSupportModal(),
                  ),
                ),
                _buildDivider(context),
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

            // ── 9. LOGOUT ─────────────────────────────────────────────────
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

            // App version footer
            Text(
              'App version 1.0.0 (AlphaCues Build 2026.08)\n© 2026 AlphaCues Technologies Inc. All rights reserved.',
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
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

/// Transaction History Section displayed on the Profile/Settings screen.
/// Expandable card that opens to display all BUY & SELL trade executions.
class _DashboardTransactionsSection extends ConsumerStatefulWidget {
  const _DashboardTransactionsSection();

  @override
  ConsumerState<_DashboardTransactionsSection> createState() =>
      __DashboardTransactionsSectionState();
}

class __DashboardTransactionsSectionState
    extends ConsumerState<_DashboardTransactionsSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final transactionsAsync = ref.watch(portfolioTransactionsProvider);
    final watchlistsAsync = ref.watch(watchlistsProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          childrenPadding:
              const EdgeInsets.only(left: 18, right: 18, bottom: 18),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          title: Text(
            'Watchlist History',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Tap to view recent watchlist additions & removals',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Watchlist Activity',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
            const SizedBox(height: 10),
            transactionsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Error loading transactions: $err',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(portfolioTransactionsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions logged yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add symbols to your watchlist to see your activity history.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final event = transactions[i];
                    final isBuy = event.action.toUpperCase() == 'BUY';
                    final chipColor =
                        isBuy ? AppColors.positive : AppColors.negative;

                    String resolvedWatchlist = (event.watchlistName != null && event.watchlistName!.isNotEmpty)
                        ? event.watchlistName!
                        : '';
                    if (resolvedWatchlist.isEmpty) {
                      final watchlists = watchlistsAsync.valueOrNull ?? [];
                      if (watchlists.isNotEmpty) {
                        resolvedWatchlist = watchlists.first.name;
                      } else {
                        resolvedWatchlist = 'Tech Growth';
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: isBuy
                                      ? AppColors.positiveBackground
                                      : AppColors.negativeBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isBuy
                                      ? Icons.bookmark_add_rounded
                                      : Icons.bookmark_remove_rounded,
                                  color: chipColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      event.symbol,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: chipColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: chipColor.withValues(alpha: 0.3),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        isBuy ? 'ADD TO WATCHLIST' : 'REMOVE FROM WATCHLIST',
                                        style: TextStyle(
                                          color: chipColor,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${formatPrice(event.volume * event.price)}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    isBuy ? 'Date of Add:' : 'Date of Removed:',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: chipColor,
                                    ),
                                  ),
                                  Text(
                                    formatEventDate(event.timeStamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    formatAsOfTimestamp(event.timeStamp),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    PortfolioEventFormDialog.show(context,
                                        event: event);
                                  } else if (action == 'delete') {
                                    try {
                                      await ref
                                          .read(portfolioRepositoryProvider)
                                          .deleteEvent(event.eventId);
                                      ref.invalidate(
                                          portfolioTransactionsProvider);
                                      ref.invalidate(portfolioSummaryProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Transaction deleted')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text('Failed to delete: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_outlined, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit', style: TextStyle(fontSize: 13)),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_outline,
                                          size: 16, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete',
                                          style: TextStyle(
                                              fontSize: 13, color: Colors.red)),
                                    ]),
                                  ),
                                ],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            height: 1,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bookmarks_outlined,
                                          size: 13.5,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            isBuy
                                                ? 'Added to: $resolvedWatchlist'
                                                : 'Removed from: $resolvedWatchlist',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isBuy
                                          ? 'Date of Add: ${formatFullDateTime(event.timeStamp)}'
                                          : 'Date of Removed: ${formatFullDateTime(event.timeStamp)}',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${event.volume} ${event.volume == 1 ? "share" : "shares"} @ \$${formatPrice(event.price)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
