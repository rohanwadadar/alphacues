import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application configuration loaded from `--dart-define` flags.
class AppConfig {
  AppConfig._({
    required this.apiBaseUrl,
    required this.socketBaseUrl,
    required this.appEnv,
    required this.enableAnalytics,
    required this.enableScreener,
  });

  static AppConfig? _instance;

  /// Singleton instance. Must call [initialize] before [instance].
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'AppConfig.initialize() must be called before accessing instance',
      );
    }
    return config;
  }

  final String apiBaseUrl;
  final String socketBaseUrl;
  final String appEnv;
  final bool enableAnalytics;
  final bool enableScreener;

  /// Reads dart-define values and stores the singleton.
  static void initialize() {
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://127.0.0.1:5000',
    );
    const socketOverride = String.fromEnvironment('SOCKET_BASE_URL');
    const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const enableAnalytics = bool.fromEnvironment(
      'ENABLE_ANALYTICS',
      defaultValue: false,
    );
    const enableScreener = bool.fromEnvironment(
      'ENABLE_SCREENER',
      defaultValue: false,
    );

    final socketBaseUrl = socketOverride.isNotEmpty
        ? socketOverride
        : _deriveSocketUrl(apiBaseUrl);

    _instance = AppConfig._(
      apiBaseUrl: apiBaseUrl,
      socketBaseUrl: socketBaseUrl,
      appEnv: appEnv,
      enableAnalytics: enableAnalytics,
      enableScreener: enableScreener,
    );
  }

  /// Resets the singleton. For tests only.
  @visibleForTesting
  static void resetForTest({
    String apiBaseUrl = 'http://localhost:5000',
    String? socketBaseUrl,
    String appEnv = 'dev',
    bool enableAnalytics = false,
    bool enableScreener = false,
  }) {
    _instance = AppConfig._(
      apiBaseUrl: apiBaseUrl,
      socketBaseUrl: socketBaseUrl ?? _deriveSocketUrl(apiBaseUrl),
      appEnv: appEnv,
      enableAnalytics: enableAnalytics,
      enableScreener: enableScreener,
    );
  }

  static String _deriveSocketUrl(String apiBaseUrl) {
    final uri = Uri.parse(apiBaseUrl);
    return Uri(
      scheme: uri.scheme == 'https' ? 'https' : 'http',
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }
}

/// Riverpod provider #1 — application configuration singleton.
final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.instance);
