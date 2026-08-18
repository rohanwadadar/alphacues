import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    this.alertId,
    required this.userId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String notificationId;
  final String? alertId;
  final String userId;
  final String title;
  final String body;
  final bool isRead;
  final String createdAt;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      alertId: alertId,
      userId: userId,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      alertId: json['alertId'] as String?,
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );
  }

  factory NotificationModel.fromSocketPayload(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notificationId'] as String,
      alertId: json['alertId'] as String?,
      userId: '',
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: false,
      createdAt: json['createdAt'] as String,
    );
  }
}

class NotificationServiceUnavailableException implements Exception {
  const NotificationServiceUnavailableException([
    this.message = 'Service is temporarily unavailable. Showing cached data.',
  ]);

  final String message;

  @override
  String toString() => message;
}

List<NotificationModel> _parseNotificationList(Map<String, dynamic>? json) {
  if (json == null) {
    return const [];
  }
  final rawItems = json['items'] ?? json['notifications'];
  if (rawItems is List) {
    return rawItems
        .map(
          (e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
  return const [];
}

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<({List<NotificationModel> items, String? nextCursor})> listNotifications({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/notifications',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final envelope = parseEnvelope<List<NotificationModel>>(
        response.data,
        parseData: (json) => json == null ? null : _parseNotificationList(json),
      );

      String? nextCursor;
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final meta = raw['meta'];
        if (meta is Map<String, dynamic>) {
          nextCursor = meta['nextCursor'] as String?;
        }
      }

      return (items: envelope.data ?? const [], nextCursor: nextCursor);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> markRead(String notificationId) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/notifications/$notificationId/read',
      );
      parseEnvelope<dynamic>(response.data, parseData: (_) => null);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> markAllRead() async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/notifications/read-all',
      );
      parseEnvelope<dynamic>(response.data, parseData: (_) => null);
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
      case 503:
      case 504:
        return NotificationServiceUnavailableException(message);
      default:
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          return NotificationServiceUnavailableException(
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

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});
