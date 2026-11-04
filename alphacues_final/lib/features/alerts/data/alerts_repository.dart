import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

/// Uppercase ticker: `^[A-Z][A-Z0-9._-]{0,14}$`
final alertSymbolPattern = RegExp(r'^[A-Z][A-Z0-9._-]{0,14}$');

class AlertModel {
  const AlertModel({
    required this.alertId,
    required this.userId,
    required this.symbol,
    required this.condition,
    required this.target,
    required this.isActive,
    required this.triggered,
    required this.cooldownSeconds,
    this.lastTriggeredAt,
    required this.createdAt,
    this.action,
    this.actionLabel,
  });

  final String alertId;
  final String userId;
  final String symbol;
  final String condition;
  final double target;
  final bool isActive;
  final bool triggered;
  final int cooldownSeconds;
  final String? lastTriggeredAt;
  final String createdAt;
  final String? action;
  final String? actionLabel;

  AlertModel copyWith({
    bool? isActive,
    bool? triggered,
    String? lastTriggeredAt,
    String? action,
    String? actionLabel,
  }) {
    return AlertModel(
      alertId: alertId,
      userId: userId,
      symbol: symbol,
      condition: condition,
      target: target,
      isActive: isActive ?? this.isActive,
      triggered: triggered ?? this.triggered,
      cooldownSeconds: cooldownSeconds,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      createdAt: createdAt,
      action: action ?? this.action,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['target'] ?? json['triggerPrice'] ?? 0;
    final parsedTarget = double.tryParse(rawTarget.toString()) ?? 0.0;
    final triggeredTime = json['lastTriggeredAt'] ?? json['triggeredAt'];
    final action = json['action'] as String?;
    final actionLabel = json['actionLabel'] as String?;

    return AlertModel(
      alertId: (json['alertId'] ?? json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      symbol: (json['symbol'] ?? '').toString(),
      condition: (json['condition'] ?? 'ABOVE').toString(),
      target: parsedTarget,
      isActive: json['isActive'] as bool? ?? false,
      triggered: json['triggered'] as bool? ??
          (action == 'TRIGGERED' || triggeredTime != null),
      cooldownSeconds: (json['cooldownSeconds'] as num?)?.toInt() ?? 0,
      lastTriggeredAt: triggeredTime?.toString(),
      createdAt: (json['createdAt'] ?? triggeredTime ?? '').toString(),
      action: action,
      actionLabel: actionLabel,
    );
  }
}

class AlertValidationErrorException implements Exception {
  const AlertValidationErrorException(this.message, {this.details = const {}});

  final String message;
  final Map<String, dynamic> details;

  @override
  String toString() => message;
}

class AlertRateLimitedException implements Exception {
  const AlertRateLimitedException([
    this.message = 'Too many requests. Please wait a moment and try again.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class AlertServiceUnavailableException implements Exception {
  const AlertServiceUnavailableException([
    this.message = 'Service is temporarily unavailable. Showing cached data.',
  ]);

  final String message;

  @override
  String toString() => message;
}

String _generateIdempotencyKey() {
  final random = Random.secure();
  ///final bytes = List<int>.generate(16, random.nextInt);
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final b = bytes.map(hex).join();
  return '${b.substring(0, 8)}-${b.substring(8, 12)}-'
      '${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20)}';
}

List<AlertModel> _parseAlertList(Map<String, dynamic>? json) {
  if (json == null) {
    return const [];
  }
  final rawItems = json['items'] ?? json['alerts'];
  if (rawItems is List) {
    return rawItems
        .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  return const [];
}

class AlertsRepository {
  AlertsRepository(this._dio);

  final Dio _dio;

  Future<List<AlertModel>> listAlerts() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/alerts');
      final envelope = parseEnvelope<List<AlertModel>>(
        response.data,
        parseData: (json) => json == null ? null : _parseAlertList(json),
      );
      return envelope.data ?? const [];
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<AlertModel> createAlert({
    required String symbol,
    required String condition,
    required double target,
    bool isActive = true,
    int cooldownSeconds = 0,
    List<String> notificationChannel = const ['IN_APP'],
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/alerts',
        data: {
          'symbol': symbol,
          'condition': condition,
          'target': target,
          ///'isActive': isActive,
          ///'cooldownSeconds': cooldownSeconds,
          ///'notificationChannel': notificationChannel,
        },
        options: Options(
          headers: {'Idempotency-Key': _generateIdempotencyKey()},
        ),
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return AlertModel.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<AlertModel> updateAlert(
    String alertId, {
    required String symbol,
    required String condition,
    required double target,
    bool isActive = true,
    int cooldownSeconds = 0,
    List<String> notificationChannel = const ['IN_APP'],
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/alerts/$alertId',
        data: {
          'symbol': symbol,
          'condition': condition,
          'target': target,
          ///'isActive': isActive,
          ///'cooldownSeconds': cooldownSeconds,
          ///'notificationChannel': notificationChannel,
        },
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return AlertModel.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      final response = await _dio.delete<dynamic>('/api/v1/alerts/$alertId');
      parseEnvelope<dynamic>(response.data, parseData: (_) => null);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<List<AlertModel>> getAlertHistory() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/alerts/history');
      final envelope = parseEnvelope<List<AlertModel>>(
        response.data,
        parseData: (json) => json == null ? null : _parseAlertList(json),
      );
      return envelope.data ?? const [];
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Exception _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    final apiError = _parseApiError(error.response?.data);
    final message = apiError?.message ?? 'Request failed.';
    final code = apiError?.code;

    switch (status) {
      case 422:
        return AlertValidationErrorException(
          message,
          details: apiError?.details ?? const {},
        );
      case 429:
        return AlertRateLimitedException(message);
      case 503:
      case 504:
        return AlertServiceUnavailableException(message);
      default:
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          return AlertServiceUnavailableException(
            'You appear to be offline. Showing cached data.',
          );
        }
        return ApiException(
          message: message,
          code: code,
          statusCode: status,
          details: apiError?.details,
        );
    }
  }

  ApiError? _parseApiError(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }
    if (data['success'] == false) {
      final rawError = data['error'];
      if (rawError is Map<String, dynamic>) {
        return ApiError.fromJson(rawError);
      }
    }
    return null;
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.watch(dioProvider));
});
