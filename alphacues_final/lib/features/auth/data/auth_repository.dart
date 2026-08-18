import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<SendOtpResult> sendOtp({required String email}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/send-otp',
      data: {'email': email},
      options: Options(extra: {'skipAuth': true}),
    );
    final envelope = parseEnvelope(
      response.data,
      parseData: (json) => json == null ? null : SendOtpResult.fromJson(json),
    );
    return envelope.data!;
  }

  Future<VerifyOtpResult> verifyOtp({
    required String email,
    required String challengeId,
    required String otpCode,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/auth/verify-otp',
      data: {'email': email, 'otpChallengeId': challengeId, 'otpCode': otpCode},
      options: Options(extra: {'skipAuth': true}),
    );
    final envelope = parseEnvelope(
      response.data,
      parseData: (json) => json == null ? null : VerifyOtpResult.fromJson(json),
    );
    return envelope.data!;
  }

  Future<RefreshTokenResult> refresh({required String refreshToken}) async {
    final response = await postRefresh(_dio, refreshToken: refreshToken);
    final envelope = parseEnvelope(
      response.data,
      parseData: (json) =>
          json == null ? null : RefreshTokenResult.fromJson(json),
    );
    return envelope.data!;
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/api/v1/auth/logout');
  }

  Future<AuthUser> getMe({bool skipTokenRefresh = false}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/auth/me',
      options: Options(extra: {if (skipTokenRefresh) 'skipRefreshRetry': true}),
    );
    final envelope = parseEnvelope(
      response.data,
      parseData: (json) {
        if (json == null) return null;
        final user = json['user'];
        if (user is Map<String, dynamic>) {
          return AuthUser.fromJson(user);
        }
        return AuthUser.fromJson(json);
      },
    );
    return envelope.data!;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
