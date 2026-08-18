import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/auth/auth_session.dart';
import 'package:frontend/core/auth/auth_token_store.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/realtime/socket_client.dart';
import 'package:frontend/features/auth/data/device_registration.dart';

import '../../core/realtime/fake_realtime_socket.dart';
import 'mock_http_adapter.dart';

ProviderContainer createAuthTestContainer({
  required MockHttpAdapter adapter,
  AuthTokenStore? tokenStore,
  List<Override> extraOverrides = const [],
}) {
  AppConfig.resetForTest();
  final dio = createTestDio(adapter);
  final store = tokenStore ?? InMemoryAuthTokenStore();

  late AuthSessionNotifier notifier;

  final apiClient = ApiClient(
    dio: dio,
    tokenStore: store,
    refreshTokens: () => notifier.refreshTokensSilent(),
    onAuthFailure: () => notifier.handleAuthFailure(),
  );

  final container = ProviderContainer(
    overrides: [
      authTokenStoreProvider.overrideWithValue(store),
      apiClientProvider.overrideWithValue(apiClient),
      dioProvider.overrideWithValue(dio),
      deviceRegistrationProvider.overrideWithValue(
        DeviceRegistrationService(
          dio: dio,
          messaging: null,
          packageInfoLoader: () async => throw UnsupportedError('test'),
        ),
      ),
      socketClientProvider.overrideWith((ref) {
        return SocketClient(
          config: AppConfig.instance,
          tokenStore: store,
          connectionNotifier: ref.read(
            socketConnectionStateProvider.notifier,
          ),
          onConnected: () {},
          socketFactory: ({required url, required auth}) =>
              FakeRealtimeSocket(),
          connectivity: null,
          watchConnectivity: false,
        );
      }),
      ...extraOverrides,
    ],
  );

  notifier = container.read(authSessionProvider.notifier);
  return container;
}
