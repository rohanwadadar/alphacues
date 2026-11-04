import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app/router/app_router.dart';
import 'package:frontend/app/theme/app_theme.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/realtime/quote_subscription_manager.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/core/storage/secure_token_store.dart';
import 'package:frontend/features/market/presentation/symbol_detail_screen.dart';
import 'package:frontend/features/settings/data/settings_provider.dart';

import '../../core/realtime/fake_realtime_socket.dart';

class _NoopQuoteSubscriptionManager extends QuoteSubscriptionManager {
  @override
  Set<String> build() => {};

  @override
  void subscribeVisible(List<String> symbols) {}

  @override
  void unsubscribeHidden(List<String> symbols) {}
}

class _FixedAuthSessionNotifier extends AuthSessionNotifier {
  _FixedAuthSessionNotifier(this._state);

  final AuthState _state;

  @override
  AuthState build() => _state;

  @override
  Future<void> bootstrapSession() async {}
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier() : super() {
    state = state.copyWith(hasCompletedOnboarding: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('invalid symbol shows Symbol not found error state', (
    tester,
  ) async {
    AppConfig.resetForTest();
    final fakeSocket = FakeRealtimeSocket();
    final store = InMemorySecureTokenStore();
    await store.writeTokens(accessToken: 'access', refreshToken: 'refresh');

    final router = createAppRouter(isAuthenticated: true, enableScreener: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(
            () => _FixedAuthSessionNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                session: AuthSession(
                  user: AuthUser(userId: '1', email: 'test@example.com'),
                ),
              ),
            ),
          ),
          quoteSubscriptionManagerProvider.overrideWith(
            _NoopQuoteSubscriptionManager.new,
          ),
          secureTokenStoreProvider.overrideWithValue(store),
          socketClientProvider.overrideWith((ref) {
            return SocketClient(
              config: ref.watch(appConfigProvider),
              tokenStore: store,
              connectionNotifier: ref.read(
                socketConnectionStateProvider.notifier,
              ),
              onConnected: () {},
              socketFactory: ({required url, required auth}) => fakeSocket,
              connectivity: null,
              watchConnectivity: false,
            );
          }),
          settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );

    router.go('/symbols/INVALID!!!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Symbol not found'), findsOneWidget);
    expect(find.byType(SymbolDetailScreen), findsOneWidget);
  });
}
