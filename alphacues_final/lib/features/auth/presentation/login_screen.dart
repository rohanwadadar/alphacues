import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_error.dart';

// ─── Email Check Result ───────────────────────────────────────────────────────
enum _EmailStatus { idle, checking, existingUser, newUser, invalid }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _errorMessage;
  _EmailStatus _emailStatus = _EmailStatus.idle;
  Timer? _debounce;

  // Tracks which tab: 0 = Login, 1 = Register
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabController.index;
          _errorMessage = null;
          _emailStatus = _EmailStatus.idle;
        });
      }
    });
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onEmailChanged() {
    _debounce?.cancel();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailStatus = _EmailStatus.idle);
      return;
    }
    final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailPattern.hasMatch(email)) {
      setState(() => _emailStatus = _EmailStatus.invalid);
      return;
    }
    // Start debounce
    setState(() => _emailStatus = _EmailStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 700), () => _checkEmail(email));
  }

  Future<void> _checkEmail(String email) async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/v1/auth/check-email',
        data: {'email': email},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final exists = data?['exists'] as bool? ?? false;
      if (!mounted) return;
      setState(() {
        _emailStatus =
            exists ? _EmailStatus.existingUser : _EmailStatus.newUser;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _emailStatus = _EmailStatus.idle);
    }
  }

  String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email[0]}***${email.substring(at)}';
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (_emailStatus == _EmailStatus.newUser) {
      setState(() => _errorMessage =
          'This email is not registered. Please switch to "New User" tab.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final result =
          await ref.read(authSessionProvider.notifier).sendOtp(email);
      if (!mounted) return;
      final masked = result.emailMasked ?? _maskEmail(email);
      context.push(
        '${AppRoutes.verifyOtp}'
        '?email=${Uri.encodeComponent(email)}'
        '&challengeId=${Uri.encodeComponent(result.challengeId)}'
        '&expiresIn=${result.expiresIn ?? 300}'
        '&masked=${Uri.encodeComponent(masked)}'
        '&isNew=false',
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
          () => _errorMessage = 'Unable to send code. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_emailStatus == _EmailStatus.existingUser) {
      setState(() => _errorMessage =
          'This email is already registered. Please switch to "Sign In" tab.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final result = await ref
          .read(authSessionProvider.notifier)
          .sendOtpForNewUser(email);
      if (!mounted) return;
      final masked = result.emailMasked ?? _maskEmail(email);
      context.push(
        '${AppRoutes.verifyOtp}'
        '?email=${Uri.encodeComponent(email)}'
        '&challengeId=${Uri.encodeComponent(result.challengeId)}'
        '&expiresIn=${result.expiresIn ?? 300}'
        '&masked=${Uri.encodeComponent(masked)}'
        '&isNew=true',
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Unable to register. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 32,
            bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Logo & Branding ──────────────────────────────────────────
              _buildBranding(isDark, colorScheme),
              const SizedBox(height: 32),

              // ── Tab Bar ──────────────────────────────────────────────────
              _buildTabBar(colorScheme, isDark),
              const SizedBox(height: 28),

              // ── Form Card ────────────────────────────────────────────────
              _buildFormCard(theme, colorScheme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranding(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        // App Icon / Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_graph_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'AlphaCues',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : const Color(0xFF0D1B3E),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Intelligent Trading Signals & Screener',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.45),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.black.withValues(alpha: 0.4),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(text: '  Sign In  '),
          Tab(text: '  New User  '),
        ],
      ),
    );
  }

  Widget _buildFormCard(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab-specific header
            _buildFormHeader(theme, colorScheme),
            const SizedBox(height: 24),

            // Email field
            _buildEmailField(theme, colorScheme, isDark),
            const SizedBox(height: 12),

            // Email status indicator
            _buildEmailStatusBanner(colorScheme),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              _buildErrorBanner(_errorMessage!, colorScheme),
            ],
            const SizedBox(height: 24),

            // Submit button
            _buildSubmitButton(colorScheme),
            const SizedBox(height: 16),

            // Bottom hint
            _buildTabHint(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildFormHeader(ThemeData theme, ColorScheme colorScheme) {
    if (_activeTab == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.login_rounded,
                    color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Welcome Back',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your registered email to receive a secure one-time code.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Create Account',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a new email address to begin your KYC registration.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }
  }

  Widget _buildEmailField(
      ThemeData theme, ColorScheme colorScheme, bool isDark) {
    final statusColor = _getStatusColor(colorScheme);
    final hasBorder = _emailStatus != _EmailStatus.idle &&
        _emailStatus != _EmailStatus.checking;

    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.done,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'you@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
        suffixIcon: _buildEmailSuffix(colorScheme),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasBorder
                ? statusColor.withValues(alpha: 0.6)
                : colorScheme.outline.withValues(alpha: 0.4),
            width: hasBorder ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasBorder ? statusColor : colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        final email = value?.trim() ?? '';
        if (email.isEmpty) return 'Email is required';
        final emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailPattern.hasMatch(email)) return 'Enter a valid email';
        return null;
      },
      onFieldSubmitted: (_) =>
          _activeTab == 0 ? _submitLogin() : _submitRegister(),
    );
  }

  Widget? _buildEmailSuffix(ColorScheme colorScheme) {
    switch (_emailStatus) {
      case _EmailStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _EmailStatus.existingUser:
        return const Icon(Icons.person_rounded, color: Color(0xFF2563EB));
      case _EmailStatus.newUser:
        return const Icon(Icons.person_add_rounded, color: Color(0xFF10B981));
      case _EmailStatus.invalid:
        return Icon(Icons.error_outline_rounded,
            color: colorScheme.error.withValues(alpha: 0.7));
      case _EmailStatus.idle:
        return null;
    }
  }

  Color _getStatusColor(ColorScheme colorScheme) {
    switch (_emailStatus) {
      case _EmailStatus.existingUser:
        return const Color(0xFF2563EB);
      case _EmailStatus.newUser:
        return const Color(0xFF10B981);
      case _EmailStatus.invalid:
        return colorScheme.error;
      default:
        return colorScheme.outline;
    }
  }

  Widget _buildEmailStatusBanner(ColorScheme colorScheme) {
    switch (_emailStatus) {
      case _EmailStatus.existingUser:
        return _statusBanner(
          icon: Icons.verified_user_rounded,
          message: 'Existing account found — sign in with OTP.',
          color: const Color(0xFF2563EB),
          bg: const Color(0xFF2563EB).withValues(alpha: 0.08),
        );
      case _EmailStatus.newUser:
        if (_activeTab == 0) {
          return _statusBanner(
            icon: Icons.warning_amber_rounded,
            message:
                'Not registered. Switch to "New User" tab to create account.',
            color: const Color(0xFFEF4444),
            bg: const Color(0xFFEF4444).withValues(alpha: 0.08),
          );
        }
        return _statusBanner(
          icon: Icons.fiber_new_rounded,
          message: 'New email — registration will begin after OTP verification.',
          color: const Color(0xFF10B981),
          bg: const Color(0xFF10B981).withValues(alpha: 0.08),
        );
      case _EmailStatus.invalid:
        return _statusBanner(
          icon: Icons.error_outline_rounded,
          message: 'Enter a valid email address.',
          color: colorScheme.error,
          bg: colorScheme.error.withValues(alpha: 0.08),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _statusBanner({
    required IconData icon,
    required String message,
    required Color color,
    required Color bg,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color, fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cancel_outlined, color: colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    final isLogin = _activeTab == 0;
    final isDisabled = _isSubmitting ||
        _emailStatus == _EmailStatus.checking ||
        _emailStatus == _EmailStatus.invalid ||
        (isLogin && _emailStatus == _EmailStatus.newUser);

    final btnColor = isLogin ? colorScheme.primary : const Color(0xFF10B981);
    final btnLabel = isLogin ? 'Send Login Code' : 'Send Registration Code';
    final btnIcon = isLogin ? Icons.send_rounded : Icons.person_add_rounded;

    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: btnColor,
          disabledBackgroundColor: btnColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: isDisabled
            ? null
            : (isLogin ? _submitLogin : _submitRegister),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Icon(btnIcon, size: 20),
        label: Text(
          _isSubmitting ? 'Sending…' : btnLabel,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTabHint(ColorScheme colorScheme) {
    if (_activeTab == 0) {
      return Center(
        child: GestureDetector(
          onTap: () => _tabController.animateTo(1),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant, fontSize: 13),
              children: [
                const TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Register here',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: GestureDetector(
          onTap: () => _tabController.animateTo(0),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant, fontSize: 13),
              children: [
                const TextSpan(text: 'Already have an account? '),
                TextSpan(
                  text: 'Sign in',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
