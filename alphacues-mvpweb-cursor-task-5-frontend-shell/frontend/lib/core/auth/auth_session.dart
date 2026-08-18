import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_models.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/device_registration.dart';
import '../../features/auth/domain/auth_user.dart';
import '../network/api_client.dart';
import '../realtime/socket_client.dart';
import 'auth_token_store.dart';
import 'user_scope.dart';

export '../../features/auth/domain/auth_user.dart' show AuthUser;

/// Session lifecycle: unauthenticated, loading (hydration), or authenticated.
enum AuthStatus { unauthenticated, loading, authenticated }

/// Authenticated session with the current user profile.
class AuthSession {
  const AuthSession({required this.user});

  final AuthUser user;
}

/// Canonical auth state consumed by routing and feature providers.
class AuthState {
  const AuthState({required this.status, this.session});

  final AuthStatus status;
  final AuthSession? session;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && session != null;

  bool get isLoading => status == AuthStatus.loading;

  static const unauthenticated = AuthState(status: AuthStatus.unauthenticated);

  static const loading = AuthState(status: AuthStatus.loading);
}

class AuthSessionNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.loading;

  /// Restores session from secure storage (also used in tests).
  Future<void> bootstrapSession() => _hydrateFromStorage();

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  AuthTokenStore get _tokenStore => ref.read(authTokenStoreProvider);

  Future<SendOtpResult> sendOtp(String email) {
    return _repository.sendOtp(email: email.trim().toLowerCase());
  }

  Future<void> verifyOtp({
    required String email,
    required String challengeId,
    required String otpCode,
  }) async {
    final result = await _repository.verifyOtp(
      email: email.trim().toLowerCase(),
      challengeId: challengeId,
      otpCode: otpCode,
    );
    await _persistAndAuthenticate(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user,
    );
    await ref.read(deviceRegistrationProvider).registerBestEffort();
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Always clear local session even when the API call fails.
    }
    await _clearSession();
  }

  /// Used by the Dio interceptor for single-flight refresh.
  Future<bool> refreshTokensSilent() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    try {
      final result = await _repository.refresh(refreshToken: refreshToken);
      await _tokenStore.writeTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> handleAuthFailure() async {
    await _clearSession();
  }

  Future<void> _hydrateFromStorage() async {
    final access = await _tokenStore.readAccessToken();
    final refresh = await _tokenStore.readRefreshToken();
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      state = AuthState.unauthenticated;
      return;
    }

    try {
      final user = await _repository.getMe(skipTokenRefresh: true);
      state = AuthState(
        status: AuthStatus.authenticated,
        session: AuthSession(user: user),
      );
      ref.read(socketClientProvider).connect();
    } catch (_) {
      await _tokenStore.clear();
      state = AuthState.unauthenticated;
    }
  }

  Future<void> _persistAndAuthenticate({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    await _tokenStore.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    state = AuthState(
      status: AuthStatus.authenticated,
      session: AuthSession(user: user),
    );
    ref.read(socketClientProvider).connect();
  }

  Future<void> _clearSession() async {
    await _tokenStore.clear();
    ref.read(socketClientProvider).disconnect();
    invalidateUserScopedProviders(ref);
    state = AuthState.unauthenticated;
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, AuthState>(
  AuthSessionNotifier.new,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStore = ref.watch(authTokenStoreProvider);
  final notifier = ref.read(authSessionProvider.notifier);
  return ApiClient(
    dio: ApiClient.createBaseDio(),
    tokenStore: tokenStore,
    refreshTokens: notifier.refreshTokensSilent,
    onAuthFailure: notifier.handleAuthFailure,
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});
