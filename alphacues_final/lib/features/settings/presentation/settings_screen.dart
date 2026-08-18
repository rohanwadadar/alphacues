import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotificationsEnabled = true;
  bool _realtimeStreamEnabled = true;
  bool _darkThemeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authSessionProvider);
    final user = authState.session?.user;
    final userEmail = user?.email ?? 'trader@alphacues.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile & Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── 1. PROFILE HEADER CARD ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colorScheme.primary, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 46,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'T',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
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
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    userEmail.split('@').first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Active Alpaca Paper Trader',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
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
                  subtitle: userEmail,
                  onTap: () {},
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.lock_outline_rounded,
                  title: 'Security & Password',
                  subtitle: '2FA & Session Tokens Active',
                  onTap: () {},
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Alerts on price movements & market news',
                  value: _pushNotificationsEnabled,
                  onChanged: (val) => setState(() => _pushNotificationsEnabled = val),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 3. MARKET & DATA SOURCES SECTION ──────────────────────────
            _buildSectionGroup(
              context,
              title: 'Market Data & Integrations',
              children: [
                _buildTile(
                  context,
                  icon: Icons.ssid_chart_rounded,
                  title: 'Alpaca Markets API',
                  subtitle: 'Base URL: paper-api.alpaca.markets (Live)',
                  trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                  onTap: () {},
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.analytics_outlined,
                  title: 'AlphaVantage Fundamentals',
                  subtitle: 'Overview & Market Metrics Key Active',
                  trailing: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                  onTap: () {},
                ),
                _buildDivider(context),
                _buildSwitchTile(
                  context,
                  icon: Icons.bolt_rounded,
                  title: 'Real-Time WebSocket Stream',
                  subtitle: 'Live quotes & price updates',
                  value: _realtimeStreamEnabled,
                  onChanged: (val) => setState(() => _realtimeStreamEnabled = val),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.search_rounded,
                  title: 'Active U.S. Equities Screener',
                  subtitle: '14,230+ Stocks Indexed',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 4. APP PREFERENCES ─────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'App Preferences',
              children: [
                _buildSwitchTile(
                  context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Theme',
                  subtitle: 'Toggle dark contrast UI mode',
                  value: _darkThemeEnabled,
                  onChanged: (val) => setState(() => _darkThemeEnabled = val),
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear Cache & In-Memory Data',
                  subtitle: 'Reset cached asset snapshots',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cache cleared successfully.')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── 5. SUPPORT & HELP ──────────────────────────────────────────
            _buildSectionGroup(
              context,
              title: 'Support & Legal',
              children: [
                _buildTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center & FAQ',
                  onTap: () {},
                ),
                _buildDivider(context),
                _buildTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy & Data Security',
                  onTap: () {},
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

            // Version info
            Text(
              'AlphaCues Trading Platform v1.0.0',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

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
          color: colorScheme.primaryContainer.withOpacity(0.5),
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
          color: colorScheme.primaryContainer.withOpacity(0.5),
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
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
    );
  }
}
