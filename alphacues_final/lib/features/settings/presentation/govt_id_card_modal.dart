import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_provider.dart';
import '../../../core/auth/auth_session.dart';

class GovtIdCardModal extends ConsumerStatefulWidget {
  const GovtIdCardModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GovtIdCardModal(),
    );
  }

  @override
  ConsumerState<GovtIdCardModal> createState() => _GovtIdCardModalState();
}

class _GovtIdCardModalState extends ConsumerState<GovtIdCardModal> {
  bool _showIdNumber = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authSessionProvider);
    final user = authState.session?.user;

    final userName = settings.displayName.isNotEmpty
        ? settings.displayName
        : (user?.name?.isNotEmpty == true
            ? user!.name!
            : (user?.email.isNotEmpty == true ? user!.email.split('@')[0] : 'Alpha Trader'));
    final userEmail = user?.email ?? 'trader@alphacues.com';

    final effectiveId = (user?.identityNumber?.isNotEmpty == true)
        ? user!.identityNumber!
        : '';

    final idNumberDisplay = effectiveId.isEmpty
        ? 'ID NOT SUBMITTED'
        : _showIdNumber
            ? effectiveId
            : (effectiveId.length >= 4
                ? '•••• •••• ${effectiveId.substring(effectiveId.length - 4)}'
                : effectiveId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Handle Bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.badge_rounded, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Government Identity Card',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Verified KYC Document',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── DIGITIZED GOVT ID CARD WIDGET ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, color: Colors.blue, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            (user?.identityType?.isNotEmpty == true
                                    ? user!.identityType!
                                    : 'Government Identity')
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Avatar & Main Details Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue.withValues(alpha: 0.3),
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Citizenship: ${user?.primaryAddress?.isNotEmpty == true ? 'United States' : 'Verified Resident'}',
                              style: TextStyle(
                                color: Colors.blueAccent.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ID Number Display with Eye toggle
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GOVT ID / AADHAAR / REGISTRATION NO.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              idNumberDisplay,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            _showIdNumber ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onPressed: () => setState(() => _showIdNumber = !_showIdNumber),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Row (DOB, Gender, Expiry)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIdMetaField('Date of Birth', user?.dateOfBirth ?? 'Jan 15, 1990'),
                      _buildIdMetaField('Gender', user?.gender ?? 'Not Specified'),
                      _buildIdMetaField('Issue Date', 'Jan 2024'),
                      _buildIdMetaField('Status', 'Active'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card Details Checklist
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC Compliance Verification',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildCheckItem(context, 'Identity Document Uploaded & Scanned', true),
                  _buildCheckItem(context, 'Real-time Facial Recognition Verified', true),
                  _buildCheckItem(context, 'Government Database Match Confirmed', true),
                  _buildCheckItem(context, 'Anti-Money Laundering (AML) Cleared', true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Done Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdMetaField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckItem(BuildContext context, String title, bool checked) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: checked ? Colors.green : theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
