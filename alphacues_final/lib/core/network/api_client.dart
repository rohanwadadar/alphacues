import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/auth_token_store.dart';
import '../config/app_config.dart';
import 'api_envelope.dart';
import 'api_error.dart';

const _skipAuthExtra = 'skipAuth';
const _skipRefreshRetryExtra = 'skipRefreshRetry';

/// Dio client with bearer auth and single-flight token refresh on 401.
class ApiClient {
  ApiClient({
    required Dio dio,
    required AuthTokenStore tokenStore,
    required Future<bool> Function() refreshTokens,
    required Future<void> Function() onAuthFailure,
  }) : _dio = dio,
       _tokenStore = tokenStore,
       _refreshTokens = refreshTokens,
       _onAuthFailure = onAuthFailure {
    _dio.interceptors.add(
      _AuthInterceptor(
        tokenStore: _tokenStore,
        refreshTokens: _refreshTokens,
        onAuthFailure: _onAuthFailure,
        dio: _dio,
      ),
    );
  }

  final Dio _dio;
  final AuthTokenStore _tokenStore;
  final Future<bool> Function() _refreshTokens;
  final Future<void> Function() _onAuthFailure;

  Dio get dio => _dio;

  static Dio createBaseDio({String? baseUrl}) {
    final config = AppConfig.instance;
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }
}

/// Parses a JSON map response into [ApiEnvelope] or throws [ApiException].
ApiEnvelope<T> parseEnvelope<T>(
  dynamic responseData, {
  required T? Function(dynamic json) parseData,
}) {
  if (responseData is! Map<String, dynamic>) {
    throw const ApiException(message: 'Invalid response format.');
  }
  final envelope = ApiEnvelope<T>.fromJson(responseData, parseData: parseData);
  if (!envelope.success) {
    final error = envelope.error;
    throw ApiException(
      message: error?.message ?? 'Request failed.',
      code: error?.code,
      details: error?.details,
    );
  }
  return envelope;
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor({
    required this.tokenStore,
    required this.refreshTokens,
    required this.onAuthFailure,
    required this.dio,
  });

  final AuthTokenStore tokenStore;
  final Future<bool> Function() refreshTokens;
  final Future<void> Function() onAuthFailure;
  final Dio dio;

  Completer<bool>? _refreshLock;
  bool _recentlyRefreshed = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[_skipAuthExtra] != true) {
      final token = await tokenStore.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;

    if (status != 401) {
      return handler.next(err);
    }

    if (options.extra[_skipRefreshRetryExtra] == true) {
      return handler.next(err);
    }

    final path = options.path;
    if (path.contains('/auth/refresh') ||
        path.contains('/auth/send-otp') ||
        path.contains('/auth/verify-otp')) {
      return handler.next(err);
    }

    try {
      final refreshed = await _singleFlightRefresh();
      if (!refreshed) {
        return handler.next(err);
      }

      final response = await _retry(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } finally {
      _recentlyRefreshed = false;
      _refreshLock = null;
    }
  }

  Future<bool> _singleFlightRefresh() async {
    final existing = _refreshLock;
    if (existing != null) {
      return existing.future;
    }
    if (_recentlyRefreshed) {
      return true;
    }

    final lock = Completer<bool>();
    _refreshLock = lock;
    try {
      final refreshed = await refreshTokens();
      if (!refreshed) {
        await onAuthFailure();
      } else {
        _recentlyRefreshed = true;
      }
      lock.complete(refreshed);
      return refreshed;
    } catch (_) {
      await onAuthFailure();
      lock.complete(false);
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final token = await tokenStore.readAccessToken();
    final headers = Map<String, dynamic>.from(options.headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return dio.fetch<dynamic>(options.copyWith(headers: headers));
  }
}

/// Posts refresh without triggering another refresh retry loop.
Future<Response<Map<String, dynamic>>> postRefresh(
  Dio dio, {
  required String refreshToken,
}) {
  return dio.post<Map<String, dynamic>>(
    '/api/v1/auth/refresh',
    data: {'refreshToken': refreshToken},
    options: Options(
      extra: {_skipAuthExtra: true, _skipRefreshRetryExtra: true},
    ),
  );
}
