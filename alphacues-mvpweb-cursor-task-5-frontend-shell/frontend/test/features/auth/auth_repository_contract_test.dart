import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_error.dart';

void main() {
  late Directory fixturesDir;

  setUpAll(() {
    fixturesDir = Directory('test/fixtures/contracts');
  });

  Map<String, dynamic> loadFixture(String name) {
    final file = File('${fixturesDir.path}/$name');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  group('contract fixtures', () {
    test('parse send-otp success fixture', () {
      final json = loadFixture('send-otp-success.json');
      final envelope = parseEnvelope(
        json,
        parseData: (data) => data == null ? null : SendOtpResult.fromJson(data),
      );
      expect(
        envelope.data!.challengeId,
        '8f38ef28-6b85-44c1-b1e5-06658ff52e4f',
      );
      expect(envelope.data!.expiresIn, 300);
    });

    test('parse verify-otp success fixture', () {
      final json = loadFixture('verify-otp-success.json');
      final envelope = parseEnvelope(
        json,
        parseData: (data) =>
            data == null ? null : VerifyOtpResult.fromJson(data),
      );
      expect(envelope.data!.accessToken, 'jwt');
      expect(envelope.data!.user.userId, '123');
      expect(envelope.data!.user.email, 'user@example.com');
    });

    test('parse OTP_INVALID error fixture', () {
      final json = loadFixture('otp-invalid.json');
      expect(
        () => parseEnvelope<Map<String, dynamic>>(
          json,
          parseData: (data) => data,
        ),
        throwsA(predicate<ApiException>((e) => e.code == ApiError.otpInvalid)),
      );
    });

    test('parse OTP_EXPIRED error fixture', () {
      final json = loadFixture('otp-expired.json');
      expect(
        () => parseEnvelope<Map<String, dynamic>>(
          json,
          parseData: (data) => data,
        ),
        throwsA(
          predicate<ApiException>(
            (e) =>
                e.code == ApiError.otpExpired && e.message.contains('expired'),
          ),
        ),
      );
    });

    test('parse OTP_LOCKED error fixture', () {
      final json = loadFixture('otp-locked.json');
      expect(
        () => parseEnvelope<Map<String, dynamic>>(
          json,
          parseData: (data) => data,
        ),
        throwsA(predicate<ApiException>((e) => e.code == ApiError.otpLocked)),
      );
    });
  });
}
