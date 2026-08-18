import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/core/auth/auth_token_store.dart';
import 'package:frontend/core/auth/user_scope.dart';
import 'package:frontend/core/realtime/socket_client.dart';

import 'auth_test_helpers.dart';
import 'mock_http_adapter.dart';

void main() {
  group('AuthSessionNotifier', () {
    test('send OTP success', () async {
      final adapter = MockHttpAdapter(
        responses: [
          MockResponse(
            body: {
              'success': true,
              'data': {
                'challengeId': 'challenge-1',
                'emailMasked': 't***@test.com',
                'expiresIn': 300,
              },
              'error': null,
              'requestId': 'r1',
            },
            statusCode: 201,
          ),
        ],
      );
      final container = createAuthTestContainer(adapter: adapter);
      addTearDown(container.dispose);

      final result = await container
          .read(authSessionProvider.notifier)
          .sendOtp('test@example.com');

      expect(result.challengeId, 'challenge-1');
      expect(adapter.requests.single.path, '/api/v1/auth/send-otp');
    });

    test('verify OTP success persists tokens and authenticates', () async {
      final adapter = MockHttpAdapter(
        responses: [
          MockResponse(
            body: {
              'success': true,
              'data': {
                'accessToken': 'access-1',
                'refreshToken': 'refresh-1',
                'expiresIn': 900,
                'user': {
                  'userId': '42',
                  'email': 'test@example.com',
                  'name': 'Test',
                  'avatarUrl': null,
                },
              },
              'error': null,
              'requestId': 'r2',
            },
          ),
        ],
      );
      final store = InMemoryAuthTokenStore();
      final container = createAuthTestContainer(
        adapter: adapter,
        tokenStore: store,
      );
      addTearDown(container.dispose);

      await container
          .read(authSessionProvider.notifier)
          .verifyOtp(
            email: 'test@example.com',
            challengeId: 'challenge-1',
            otpCode: '123456',
          );
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authSessionProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.session!.user.userId, '42');
      expect(await store.readAccessToken(), 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');
      expect(container.read(socketClientProvider).isConnected, isTrue);
    });

    test(
      'cold-start rehydration calls /auth/me and restores session',
      () async {
        final adapter = MockHttpAdapter(
          responses: [
            MockResponse(
              body: {
                'success': true,
                'data': {
                  'userId': '99',
                  'email': 'user@example.com',
                  'name': 'User',
                  'avatarUrl': null,
                },
                'error': null,
                'requestId': 'r3',
              },
            ),
          ],
        );
        final store = InMemoryAuthTokenStore();
        await store.writeTokens(
          accessToken: 'stored-access',
          refreshToken: 'stored-refresh',
        );

        final container = createAuthTestContainer(
          adapter: adapter,
          tokenStore: store,
        );
        addTearDown(container.dispose);

        await container.read(authSessionProvider.notifier).bootstrapSession();
        await Future<void>.delayed(Duration.zero);

        final state = container.read(authSessionProvider);
        expect(state.isAuthenticated, isTrue);
        expect(state.session!.user.userId, '99');
        final meCalls = adapter.requests.where(
          (r) => r.path == '/api/v1/auth/me',
        );
        expect(meCalls.length, 1);
      },
    );

    test(
      'cold-start rehydration clears stale tokens on /auth/me failure',
      () async {
        final adapter = MockHttpAdapter(
          responses: [
            MockResponse(
              body: {
                'success': false,
                'data': null,
                'error': {
                  'code': 'UNAUTHORIZED',
                  'message': 'Unauthorized',
                  'details': {},
                },
                'requestId': 'r4',
              },
              statusCode: 401,
            ),
          ],
        );
        final store = InMemoryAuthTokenStore();
        await store.writeTokens(
          accessToken: 'bad-access',
          refreshToken: 'bad-refresh',
        );

        final container = createAuthTestContainer(
          adapter: adapter,
          tokenStore: store,
        );
        addTearDown(container.dispose);

        await container.read(authSessionProvider.notifier).bootstrapSession();

        final state = container.read(authSessionProvider);
        expect(state.status, AuthStatus.unauthenticated);
        expect(await store.readAccessToken(), isNull);
        expect(await store.readRefreshToken(), isNull);
      },
    );

    test('single-flight refresh lock uses one refresh call', () async {
      final adapter = MockHttpAdapter(
        responses: [
          MockResponse(
            body: {
              'success': false,
              'data': null,
              'error': {
                'code': 'TOKEN_EXPIRED',
                'message': 'Expired',
                'details': {},
              },
              'requestId': 'r5',
            },
            statusCode: 401,
          ),
          MockResponse(
            body: {
              'success': false,
              'data': null,
              'error': {
                'code': 'TOKEN_EXPIRED',
                'message': 'Expired',
                'details': {},
              },
              'requestId': 'r6',
            },
            statusCode: 401,
          ),
          MockResponse(
            body: {
              'success': true,
              'data': {
                'accessToken': 'new-access',
                'refreshToken': 'new-refresh',
                'expiresIn': 900,
              },
              'error': null,
              'requestId': 'r7',
            },
          ),
          MockResponse(
            body: {
              'success': true,
              'data': {'ok': true},
              'error': null,
              'requestId': 'r8',
            },
          ),
          MockResponse(
            body: {
              'success': true,
              'data': {'ok': true},
              'error': null,
              'requestId': 'r9',
            },
          ),
        ],
      );
      final store = InMemoryAuthTokenStore();
      await store.writeTokens(
        accessToken: 'expired-access',
        refreshToken: 'refresh-1',
      );

      final container = createAuthTestContainer(
        adapter: adapter,
        tokenStore: store,
      );
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);

      await Future.wait([
        dio.get<dynamic>('/api/v1/protected-a'),
        dio.get<dynamic>('/api/v1/protected-b'),
      ]);

      final refreshCalls = adapter.requests
          .where((r) => r.path.contains('/auth/refresh'))
          .length;
      expect(refreshCalls, 1);
      expect(await store.readAccessToken(), 'new-access');
    });

    test(
      'logout calls /auth/logout, clears tokens, and invalidates scope',
      () async {
        var scopedBuilds = 0;
        final scopedProvider = Provider<int>((ref) {
          scopedBuilds++;
          return scopedBuilds;
        });

        final adapter = MockHttpAdapter(
          responses: [
            MockResponse(
              body: {
                'success': true,
                'data': {'success': true},
                'error': null,
                'requestId': 'r10',
              },
            ),
          ],
        );
        final store = InMemoryAuthTokenStore();
        await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

        final container = createAuthTestContainer(
          adapter: adapter,
          tokenStore: store,
        );
        addTearDown(container.dispose);

        userScopedProviderKeys.add(scopedProvider);
        addTearDown(userScopedProviderKeys.clear);

        container.read(authSessionProvider.notifier).state = AuthState(
          status: AuthStatus.authenticated,
          session: const AuthSession(
            user: AuthUser(userId: '1', email: 'a@b.com'),
          ),
        );

        expect(container.read(scopedProvider), 1);

        await container.read(authSessionProvider.notifier).logout();

        expect(
          adapter.requests.where((r) => r.path == '/api/v1/auth/logout').length,
          1,
        );
        expect(await store.readAccessToken(), isNull);
        expect(container.read(authSessionProvider).isAuthenticated, isFalse);
        expect(container.read(socketClientProvider).isConnected, isFalse);
        expect(container.read(scopedProvider), 2);
      },
    );
  });
}
