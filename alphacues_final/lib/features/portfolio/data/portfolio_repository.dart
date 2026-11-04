import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../dashboard/data/dashboard_repository.dart' show PortfolioSummary;
import '../../watchlist/data/watchlist_repository.dart'
    show ServiceUnavailableException;

/// Uppercase ticker: `^[A-Z][A-Z0-9._-]{0,14}$`
final portfolioSymbolPattern = RegExp(r'^[A-Z][A-Z0-9._-]{0,14}$');

class PortfolioPosition {
  const PortfolioPosition({
    required this.symbol,
    required this.volume,
    required this.totalPrice,
    required this.updatedAt,
    this.lastPrice,
    this.changeAmount,
    this.changePercent,
  });

  final String symbol;
  final int volume;
  final double totalPrice;
  final String updatedAt;
  final double? lastPrice;
  final double? changeAmount;
  final double? changePercent;

  PortfolioPosition copyWith({
    double? lastPrice,
    double? changeAmount,
    double? changePercent,
  }) {
    return PortfolioPosition(
      symbol: symbol,
      volume: volume,
      totalPrice: totalPrice,
      updatedAt: updatedAt,
      lastPrice: lastPrice ?? this.lastPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercent: changePercent ?? this.changePercent,
    );
  }

  factory PortfolioPosition.fromJson(Map<String, dynamic> json) {
    return PortfolioPosition(
      symbol: json['symbol'] as String,
      volume: (json['volume'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num? ?? json['total_price'] as num)
          .toDouble(),
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String,
      lastPrice: (json['lastPrice'] as num? ?? json['last_price'] as num?)
          ?.toDouble(),
      changeAmount:
          (json['changeAmount'] as num? ?? json['change_amount'] as num?)
              ?.toDouble(),
      changePercent:
          (json['changePercent'] as num? ?? json['change_percent'] as num?)
              ?.toDouble(),
    );
  }
}

class PortfolioOverview {
  const PortfolioOverview({required this.summary, required this.positions});

  final PortfolioSummary summary;
  final List<PortfolioPosition> positions;

  List<String> get symbols => positions.map((p) => p.symbol).toList();

  factory PortfolioOverview.fromJson(Map<String, dynamic> json) {
    final positionsRaw = json['positions'];
    final positions = positionsRaw is List
        ? positionsRaw
              .map(
                (entry) => PortfolioPosition.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList()
        : const <PortfolioPosition>[];

    return PortfolioOverview(
      summary: PortfolioSummary.fromJson(json),
      positions: positions,
    );
  }
}

class PortfolioEvent {
  const PortfolioEvent({
    required this.eventId,
    required this.timeStamp,
    required this.userId,
    required this.symbol,
    required this.action,
    required this.price,
    required this.volume,
  });

  final String eventId;
  final String timeStamp;
  final String userId;
  final String symbol;
  final String action;
  final double price;
  final int volume;

  factory PortfolioEvent.fromJson(Map<String, dynamic> json) {
    return PortfolioEvent(
      eventId: json['eventId'] as String? ?? json['event_id'] as String,
      timeStamp: json['timeStamp'] as String? ?? json['time_stamp'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      symbol: json['symbol'] as String,
      action: json['action'] as String,
      price: (json['price'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
    );
  }
}

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.timeStamp,
    required this.symbol,
    required this.quantity,
    required this.totalPrice,
  });

  final String timeStamp;
  final String symbol;
  final int quantity;
  final double totalPrice;

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioSnapshot(
      timeStamp: json['timeStamp'] as String? ?? json['time_stamp'] as String,
      symbol: json['symbol'] as String,
      quantity: (json['quantity'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num? ?? json['total_price'] as num)
          .toDouble(),
    );
  }
}

class PortfolioValidationErrorException implements Exception {
  const PortfolioValidationErrorException(
    this.message, {
    this.details = const {},
  });

  final String message;
  final Map<String, dynamic> details;

  @override
  String toString() => message;
}

class PortfolioRateLimitedException implements Exception {
  const PortfolioRateLimitedException([
    this.message = 'Too many requests. Please wait a moment and try again.',
  ]);

  final String message;

  @override
  String toString() => message;
}

String generatePortfolioIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');
  final b = bytes.map(hex).join();
  return '${b.substring(0, 8)}-${b.substring(8, 12)}-'
      '${b.substring(12, 16)}-${b.substring(16, 20)}-${b.substring(20)}';
}

/// Calendar-date equality in local time (year/month/day only).
bool isPortfolioEventDateToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

/// Serializes a local [DateTime] to ISO-8601 UTC without shifting calendar day.
String formatPortfolioEventTimestamp(DateTime localDateTime) {
  final local = DateTime(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
    localDateTime.hour,
    localDateTime.minute,
    localDateTime.second,
    localDateTime.millisecond,
    localDateTime.microsecond,
  );
  return local.toUtc().toIso8601String();
}

/// Reads `meta.nextCursor` from the top-level API envelope.
String? readPortfolioMetaNextCursor(dynamic responseData) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  final meta = responseData['meta'];
  if (meta is Map<String, dynamic>) {
    return meta['nextCursor'] as String?;
  }
  return null;
}

/// Parses `data.eventId` from a successful create-event response.
String parseCreatePortfolioEventId(Map<String, dynamic> data) {
  final eventId = data['eventId'] as String?;
  if (eventId == null || eventId.isEmpty) {
    throw const ApiException(message: 'Invalid response format.');
  }
  return eventId;
}

String portfolioErrorMessage(Object error) {
  if (error is PortfolioValidationErrorException) {
    return error.message;
  }
  if (error is PortfolioRateLimitedException) {
    return error.message;
  }
  if (error is ApiException) {
    return error.message;
  }
  if (error is ServiceUnavailableException) {
    return error.message;
  }
  return 'Request failed.';
}

List<PortfolioEvent> _parseEventList(Map<String, dynamic>? json) {
  if (json == null) {
    return const [];
  }
  final rawItems = json['items'] ?? json['transactions'] ?? json['events'];
  if (rawItems is List) {
    return rawItems
        .map(
          (e) => PortfolioEvent.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
  return const [];
}

List<PortfolioSnapshot> _parseSnapshotList(Map<String, dynamic>? json) {
  if (json == null) {
    return const [];
  }
  final rawItems = json['items'] ?? json['snapshots'] ?? json['history'];
  if (rawItems is List) {
    return rawItems
        .map(
          (e) =>
              PortfolioSnapshot.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
  if (json.values.every((value) => value is Map)) {
    return json.values
        .map(
          (e) =>
              PortfolioSnapshot.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
  return const [];
}

class PortfolioRepository {
  PortfolioRepository(this._dio);

  final Dio _dio;

  Future<PortfolioOverview> getPortfolioSummary() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/portfolio');
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return PortfolioOverview.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<List<PortfolioSnapshot>> getPortfolioHistory({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/portfolio/history',
        queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
      );
      final envelope = parseEnvelope<List<PortfolioSnapshot>>(
        response.data,
        parseData: (json) => json == null ? null : _parseSnapshotList(json),
      );
      return envelope.data ?? const [];
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<({List<PortfolioEvent> items, String? nextCursor})>
  getPortfolioTransactions({String? cursor, int limit = 20}) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/portfolio/transactions',
        queryParameters: {if (cursor != null) 'cursor': cursor, 'limit': limit},
      );
      final envelope = parseEnvelope<List<PortfolioEvent>>(
        response.data,
        parseData: (json) => json == null ? null : _parseEventList(json),
      );

      final nextCursor = readPortfolioMetaNextCursor(response.data);

      return (items: envelope.data ?? const [], nextCursor: nextCursor);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<String> createEvent({
    required String symbol,
    required String action,
    required int volume,
    required double price,
    required String timeStamp,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/portfolio/event',
        data: {
          'symbol': symbol,
          'action': action,
          'volume': volume,
          'price': price,
          'time_stamp': timeStamp,
        },
        options: Options(headers: {'Idempotency-Key': idempotencyKey}),
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return parseCreatePortfolioEventId(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<PortfolioEvent> updateEvent(
    String eventId, {
    required String symbol,
    required String action,
    required int volume,
    required double price,
    required String timeStamp,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/portfolio/event/$eventId',
        data: {
          'symbol': symbol,
          'action': action,
          'volume': volume,
          'price': price,
          'time_stamp': timeStamp,
        },
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return PortfolioEvent.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final response = await _dio.delete<dynamic>(
        '/api/v1/portfolio/event/$eventId',
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
      case 422:
        return PortfolioValidationErrorException(
          message,
          details: apiError?.details ?? const {},
        );
      case 429:
        return PortfolioRateLimitedException(message);
      case 503:
      case 504:
        return ServiceUnavailableException(message);
      default:
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          return ServiceUnavailableException(
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

final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return PortfolioRepository(ref.watch(dioProvider));
});
