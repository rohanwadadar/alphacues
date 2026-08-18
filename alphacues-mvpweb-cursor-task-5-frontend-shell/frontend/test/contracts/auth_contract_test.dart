import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_envelope.dart';
import 'package:frontend/features/auth/data/auth_models.dart';

void main() {
  Map<String, dynamic> loadFixture(String name) {
    final file = File('test/contracts/$name');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  void assertCanonicalEnvelopeKeys(Map<String, dynamic> json) {
    expect(json.containsKey('success'), isTrue);
    expect(json.containsKey('data'), isTrue);
    expect(json.containsKey('error'), isTrue);
    expect(json.containsKey('requestId'), isTrue);
    expect(json['success'], isA<bool>());
    expect(json['requestId'], isA<String>());
    final error = json['error'];
    expect(error == null || error is Map<String, dynamic>, isTrue);
  }

  void assertEnvelopeRoundTrip<T>({
    required Map<String, dynamic> fixture,
    required T? Function(Map<String, dynamic>? json) parseData,
    required Object? Function(T? data) encodeData,
  }) {
    assertCanonicalEnvelopeKeys(fixture);

    final envelope = ApiEnvelope<T>.fromJson(fixture, parseData: parseData);
    expect(() => envelope, returnsNormally);

    final roundTripped = envelope.toJson(encodeData: encodeData);
    expect(roundTripped, fixture);
  }

  group('auth API contract fixtures', () {
    test('auth_send_otp_response.json', () {
      final fixture = loadFixture('auth_send_otp_response.json');
      final data = fixture['data'] as Map<String, dynamic>;

      expect(data.containsKey('challengeId'), isTrue);
      expect(data['challengeId'], isA<String>());

      assertEnvelopeRoundTrip<SendOtpResult>(
        fixture: fixture,
        parseData: (json) => json == null ? null : SendOtpResult.fromJson(json),
        encodeData: (data) => data?.toJson(),
      );

      final envelope = ApiEnvelope<SendOtpResult>.fromJson(
        fixture,
        parseData: (json) => json == null ? null : SendOtpResult.fromJson(json),
      );
      expect(
        envelope.data!.challengeId,
        '550e8400-e29b-41d4-a716-446655440000',
      );
    });

    test('auth_verify_otp_response.json', () {
      final fixture = loadFixture('auth_verify_otp_response.json');
      final data = fixture['data'] as Map<String, dynamic>;

      expect(data.containsKey('accessToken'), isTrue);
      expect(data.containsKey('refreshToken'), isTrue);
      expect(data.containsKey('expiresIn'), isTrue);

      final user = data['user'] as Map<String, dynamic>;
      expect(user.containsKey('userId'), isTrue);
      expect(user.containsKey('email'), isTrue);

      assertEnvelopeRoundTrip<VerifyOtpResult>(
        fixture: fixture,
        parseData: (json) =>
            json == null ? null : VerifyOtpResult.fromJson(json),
        encodeData: (data) => data?.toJson(),
      );

      final envelope = ApiEnvelope<VerifyOtpResult>.fromJson(
        fixture,
        parseData: (json) =>
            json == null ? null : VerifyOtpResult.fromJson(json),
      );
      expect(envelope.data!.accessToken, 'eyJhbGciOiJIUzI1NiJ9.example');
      expect(envelope.data!.refreshToken, 'eyJhbGciOiJIUzI1NiJ9.refresh');
      expect(envelope.data!.expiresIn, 900);
      expect(envelope.data!.user.userId, 1);
      expect(envelope.data!.user.email, 'user@example.com');
    });

    test('auth_refresh_response.json', () {
      final fixture = loadFixture('auth_refresh_response.json');
      final data = fixture['data'] as Map<String, dynamic>;

      expect(data.containsKey('accessToken'), isTrue);
      expect(data.containsKey('refreshToken'), isTrue);
      expect(data.containsKey('expiresIn'), isTrue);

      assertEnvelopeRoundTrip<RefreshTokenResult>(
        fixture: fixture,
        parseData: (json) =>
            json == null ? null : RefreshTokenResult.fromJson(json),
        encodeData: (data) => data?.toJson(),
      );
    });

    test('auth_logout_response.json', () {
      final fixture = loadFixture('auth_logout_response.json');

      assertEnvelopeRoundTrip<Object?>(
        fixture: fixture,
        parseData: (_) => null,
        encodeData: (_) => null,
      );

      final envelope = ApiEnvelope<Object?>.fromJson(
        fixture,
        parseData: (_) => null,
      );
      expect(envelope.data, isNull);
      expect(envelope.success, isTrue);
    });
  });
}
