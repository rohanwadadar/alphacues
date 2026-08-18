import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_error.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _inlineError;
  bool _isLocked = false;

  String _email = '';
  String _challengeId = '';
  String _emailMasked = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readRouteParams());
  }

  void _readRouteParams() {
    final state = GoRouterState.of(context);
    _email = state.uri.queryParameters['email'] ?? '';
    _challengeId = state.uri.queryParameters['challengeId'] ?? '';
    _emailMasked = state.uri.queryParameters['masked'] ?? _email;
    final expiresIn =
        int.tryParse(state.uri.queryParameters['expiresIn'] ?? '') ?? 300;
    _startCountdown(expiresIn);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining -= 1);
      }
    });
  }

  String _formatCountdown() {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _setApiError(ApiException error) {
    switch (error.code) {
      case ApiError.otpExpired:
        setState(() {
          _inlineError = error.message;
          _isLocked = false;
        });
      case ApiError.otpLocked:
        setState(() {
          _inlineError = error.message;
          _isLocked = true;
        });
      case ApiError.otpInvalid:
        setState(() {
          _inlineError = error.message;
          _isLocked = false;
        });
      default:
        setState(() => _inlineError = error.message);
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _inlineError = 'Enter the 6-digit code from your email.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      await ref
          .read(authSessionProvider.notifier)
          .verifyOtp(email: _email, challengeId: _challengeId, otpCode: code);

      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } on ApiException catch (e) {
      _setApiError(e);
    } catch (_) {
      setState(() => _inlineError = 'Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0 || _isLocked) return;

    setState(() {
      _isResending = true;
      _inlineError = null;
    });

    try {
      final result = await ref
          .read(authSessionProvider.notifier)
          .sendOtp(_email);
      setState(() {
        _challengeId = result.challengeId;
        if (result.emailMasked != null) {
          _emailMasked = result.emailMasked!;
        }
      });
      _startCountdown(result.expiresIn ?? 300);
    } on ApiException catch (e) {
      _setApiError(e);
    } catch (_) {
      setState(() => _inlineError = 'Unable to resend code. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canResend = _secondsRemaining == 0 && !_isLocked;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Verify your email', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a code to $_emailMasked',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _otpController,
                enabled: !_isLocked,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: '6-digit code',
                  border: const OutlineInputBorder(),
                  counterText: _secondsRemaining > 0
                      ? 'Expires in ${_formatCountdown()}'
                      : 'Code expired — resend to get a new one',
                ),
                onSubmitted: (_) => _verify(),
              ),
              if (_inlineError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _inlineError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              if (_isLocked) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your account is temporarily locked. Try again later.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting || _isLocked ? null : _verify,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: canResend && !_isResending ? _resend : null,
                  child: _isResending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          canResend
                              ? 'Resend code'
                              : 'Resend in ${_formatCountdown()}',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
