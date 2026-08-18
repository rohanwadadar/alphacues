import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/core/network/api_error.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/presentation/verify_otp_screen.dart';
import 'package:go_router/go_router.dart';

class _TestAuthSessionNotifier extends AuthSessionNotifier {
  _TestAuthSessionNotifier({
    Future<void> Function({
      required String email,
      required String challengeId,
      required String otpCode,
    })?
    onVerify,
    Future<SendOtpResult> Function(String email)? onSend,
  }) : _onVerify = onVerify,
       _onSend = onSend;

  final Future<void> Function({
    required String email,
    required String challengeId,
    required String otpCode,
  })?
  _onVerify;

  final Future<SendOtpResult> Function(String email)? _onSend;

  @override
  AuthState build() => AuthState.unauthenticated;

  @override
  Future<void> verifyOtp({
    required String email,
    required String challengeId,
    required String otpCode,
  }) async {
    final onVerify = _onVerify;
    if (onVerify != null) {
      await onVerify(email: email, challengeId: challengeId, otpCode: otpCode);
    }
  }

  @override
  Future<SendOtpResult> sendOtp(String email) async {
    final onSend = _onSend;
    if (onSend != null) {
      return onSend(email);
    }
    return const SendOtpResult(
      challengeId: 'new-challenge',
      emailMasked: 't***@test.com',
      expiresIn: 300,
    );
  }
}

Future<void> _pumpVerifyScreen(
  WidgetTester tester, {
  required Override authOverride,
  int expiresIn = 0,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const VerifyOtpScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [authOverride],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  router.go(
    '/verify-otp?email=test%40example.com&challengeId=abc&expiresIn=$expiresIn&masked=t***%40example.com',
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows OTP_EXPIRED error copy', (tester) async {
    await _pumpVerifyScreen(
      tester,
      authOverride: authSessionProvider.overrideWith(
        () => _TestAuthSessionNotifier(
          onVerify:
              ({required email, required challengeId, required otpCode}) async {
                throw const ApiException(
                  code: ApiError.otpExpired,
                  message: 'This code expired. Request a new one.',
                );
              },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('This code expired. Request a new one.'), findsOneWidget);
  });

  testWidgets('shows OTP_LOCKED locked account state', (tester) async {
    await _pumpVerifyScreen(
      tester,
      authOverride: authSessionProvider.overrideWith(
        () => _TestAuthSessionNotifier(
          onVerify:
              ({required email, required challengeId, required otpCode}) async {
                throw const ApiException(
                  code: ApiError.otpLocked,
                  message: 'Too many incorrect attempts. Try again later.',
                );
              },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(
      find.text('Too many incorrect attempts. Try again later.'),
      findsOneWidget,
    );
    expect(
      find.text('Your account is temporarily locked. Try again later.'),
      findsOneWidget,
    );
    final verifyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verify'),
    );
    expect(verifyButton.onPressed, isNull);
  });

  testWidgets('shows OTP_INVALID error copy', (tester) async {
    await _pumpVerifyScreen(
      tester,
      authOverride: authSessionProvider.overrideWith(
        () => _TestAuthSessionNotifier(
          onVerify:
              ({required email, required challengeId, required otpCode}) async {
                throw const ApiException(
                  code: ApiError.otpInvalid,
                  message: 'The verification code is incorrect.',
                );
              },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '000000');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('The verification code is incorrect.'), findsOneWidget);
  });

  testWidgets('resend countdown state disables resend until elapsed', (
    tester,
  ) async {
    await _pumpVerifyScreen(
      tester,
      expiresIn: 30,
      authOverride: authSessionProvider.overrideWith(
        () => _TestAuthSessionNotifier(
          onSend: (_) async => const SendOtpResult(
            challengeId: 'c2',
            emailMasked: 't***@test.com',
            expiresIn: 300,
          ),
        ),
      ),
    );

    expect(find.textContaining('Resend in'), findsOneWidget);
    final resendButton = tester.widget<TextButton>(
      find.ancestor(
        of: find.textContaining('Resend in'),
        matching: find.byType(TextButton),
      ),
    );
    expect(resendButton.onPressed, isNull);
  });
}
