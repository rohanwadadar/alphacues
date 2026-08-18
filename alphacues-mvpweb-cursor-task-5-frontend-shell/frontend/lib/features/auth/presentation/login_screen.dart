import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_error.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email[0]}***${email.substring(at)}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await ref
          .read(authSessionProvider.notifier)
          .sendOtp(_emailController.text);

      if (!mounted) return;

      final email = _emailController.text.trim().toLowerCase();
      final masked = result.emailMasked ?? _maskEmail(email);
      final expiresIn = result.expiresIn ?? 300;
      context.push(
        '${AppRoutes.verifyOtp}?email=${Uri.encodeComponent(email)}'
        '&challengeId=${Uri.encodeComponent(result.challengeId)}'
        '&expiresIn=$expiresIn'
        '&masked=${Uri.encodeComponent(masked)}',
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to send code. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md +
                (MediaQuery.viewInsetsOf(context).bottom.isNaN
                    ? 0.0
                    : MediaQuery.viewInsetsOf(context).bottom),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  label: 'Sign in to Alpha Cues',
                  child: Text('Sign in', style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter your email to receive a one-time code.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  label: 'Email Address Input Field',
                  hint: 'Double tap to enter your email address for login verification',
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Email is required';
                      }
                      final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailPattern.hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    liveRegion: true,
                    label: 'Error message: $_errorMessage',
                    child: Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 48,
                  child: Semantics(
                    button: true,
                    enabled: !_isSubmitting,
                    label: _isSubmitting ? 'Sending code...' : 'Continue to verify code',
                    hint: 'Triggers sending a 6-digit verification code to your email',
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
