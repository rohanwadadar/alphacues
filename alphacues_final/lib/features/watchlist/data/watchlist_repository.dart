import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';

/// Uppercase ticker: `^[A-Z][A-Z0-9._-]{0,14}$`
final watchlistSymbolPattern = RegExp(r'^[A-Z][A-Z0-9._-]{0,14}$');

class Watchlist {
  const Watchlist({
    required this.watchlistId,
    required this.name,
    required this.symbolCount,
  });

  final String watchlistId;
  final String name;
  final int symbolCount;

  factory Watchlist.fromJson(Map<String, dynamic> json) {
    return Watchlist(
      watchlistId: json['watchlistId'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      symbolCount:
          json['symbolCount'] as int? ??
          json['count'] as int? ??
          (json['symbols'] is List ? (json['symbols'] as List).length : 0),
    );
  }
}

class WatchlistQuote {
  const WatchlistQuote({
    required this.lastPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.asOf,
  });

  final double lastPrice;
  final double changeAmount;
  final double changePercent;
  final String asOf;

  factory WatchlistQuote.fromJson(Map<String, dynamic> json) {
    return WatchlistQuote(
      lastPrice: (json['lastPrice'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['changeAmount'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
      asOf: json['asOf'] as String? ?? '',
    );
  }
}

class WatchlistItem {
  const WatchlistItem({required this.symbol, this.quantity, this.quote});

  final String symbol;
  final double? quantity;
  final WatchlistQuote? quote;
}

class WatchlistDetail {
  const WatchlistDetail({
    required this.watchlistId,
    required this.name,
    required this.items,
  });

  final String watchlistId;
  final String name;
  final List<WatchlistItem> items;

  List<String> get symbols => items.map((e) => e.symbol).toList();

  factory WatchlistDetail.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is List) {
      return WatchlistDetail(
        watchlistId: json['watchlistId'] as String? ?? json['id'] as String,
        name: json['name'] as String,
        items: rawItems.map((entry) {
          final map = Map<String, dynamic>.from(entry as Map);
          final quoteRaw = map['quote'] ?? (map.containsKey('lastPrice') ? map : null);
          return WatchlistItem(
            symbol: map['symbol'] as String,
            quantity: map['quantity'] != null ? (map['quantity'] as num).toDouble() : null,
            quote: quoteRaw is Map<String, dynamic>
                ? WatchlistQuote.fromJson(quoteRaw)
                : null,
          );
        }).toList(),
      );
    }

    final rawSymbols = json['symbols'];
    return WatchlistDetail(
      watchlistId: json['watchlistId'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      items: rawSymbols is List
          ? rawSymbols
                .map(
                  (e) => WatchlistItem(symbol: e.toString()),
                )
                .toList()
          : const [],
    );
  }
}

class WatchlistListResult {
  const WatchlistListResult({
    required this.watchlists,
    this.nextCursor,
  });

  final List<Watchlist> watchlists;
  final String? nextCursor;
}

class DuplicateSymbolException implements Exception {
  const DuplicateSymbolException([this.message = 'Symbol is already in this watchlist.']);

  final String message;

  @override
  String toString() => message;
}

class ValidationErrorException implements Exception {
  const ValidationErrorException(this.message, {this.field});

  final String message;
  final String? field;

  @override
  String toString() => message;
}

class RateLimitedException implements Exception {
  const RateLimitedException([
    this.message = 'Too many requests. Please wait a moment and try again.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class ServiceUnavailableException implements Exception {
  const ServiceUnavailableException([
    this.message = 'Service is temporarily unavailable. Showing cached data.',
  ]);

  final String message;

  @override
  String toString() => message;
}

class WatchlistRepository {
  WatchlistRepository(this._dio);

  final Dio _dio;

  Future<WatchlistListResult> listWatchlists({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/watchlist',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );
      final envelope = parseEnvelope<List<Watchlist>>(
        response.data,
        parseData: (json) {
          if (json == null) {
            return null;
          }
          final rawItems = json['items'] ?? json['watchlists'];
          if (rawItems is List) {
            return rawItems
                .map((e) => Watchlist.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
          return const <Watchlist>[];
        },
      );

      String? nextCursor;
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final meta = raw['meta'];
        if (meta is Map<String, dynamic>) {
          nextCursor = meta['nextCursor'] as String?;
        }
      }

      return WatchlistListResult(
        watchlists: envelope.data ?? const [],
        nextCursor: nextCursor,
      );
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<WatchlistDetail> getWatchlist(String watchlistId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/watchlist/$watchlistId',
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return WatchlistDetail.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Watchlist> createWatchlist(String name) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/watchlist',
        data: {'name': name},
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return Watchlist.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<Watchlist> renameWatchlist(String watchlistId, String name) async {
    try {
      final response = await _dio.put<dynamic>(
        '/api/v1/watchlist/$watchlistId',
        data: {'name': name},
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return Watchlist.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> deleteWatchlist(String watchlistId) async {
    try {
      final response = await _dio.delete<dynamic>(
        '/api/v1/watchlist/$watchlistId',
      );
      parseEnvelope<dynamic>(response.data, parseData: (_) => null);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> addSymbol(String watchlistId, String symbol, {double? quantity}) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/watchlist/$watchlistId/items',
        data: {
          'symbol': symbol,
          if (quantity != null) 'quantity': quantity,
        },
      );
      parseEnvelope<dynamic>(response.data, parseData: (_) => null);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<void> removeSymbol(String watchlistId, String symbol) async {
    try {
      final response = await _dio.delete<dynamic>(
        '/api/v1/watchlist/$watchlistId/items/$symbol',
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
      case 409:
        if (code == 'DUPLICATE_SYMBOL') {
          return DuplicateSymbolException(message);
        }
        return ApiException(message: message, code: code, statusCode: status);
      case 422:
        return ValidationErrorException(
          message,
          field: apiError?.details['field'] as String?,
        );
      case 429:
        return RateLimitedException(message);
      case 503:
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

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(ref.watch(dioProvider));
});
