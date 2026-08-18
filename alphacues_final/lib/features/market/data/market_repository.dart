import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../features/watchlist/data/watchlist_repository.dart'
    show ServiceUnavailableException, watchlistSymbolPattern;

/// Uppercase ticker: `^[A-Z][A-Z0-9._-]{0,14}$`
final marketSymbolPattern = watchlistSymbolPattern;

/// Maps UI range chips to API `timeframe` query values.
const Map<String, String> kRangeToTimeframe = {
  '1D': '5min',
  '1W': '30min',
  '1M': '1hour',
  '3M': '1day',
  '6M': '1day',
  '1Y': '1day',
  '5Y': '1week',
  'MAX': '1month',
};

class Bar {
  const Bar({
    required this.timeStamp,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.closePrice,
    required this.volume,
  });

  final String timeStamp;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double closePrice;
  final int volume;

  factory Bar.fromJson(Map<String, dynamic> json) {
    return Bar(
      timeStamp: json['timeStamp'] as String,
      openPrice: (json['openPrice'] as num).toDouble(),
      highPrice: (json['highPrice'] as num).toDouble(),
      lowPrice: (json['lowPrice'] as num).toDouble(),
      closePrice: (json['closePrice'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Bar &&
            timeStamp == other.timeStamp &&
            openPrice == other.openPrice &&
            highPrice == other.highPrice &&
            lowPrice == other.lowPrice &&
            closePrice == other.closePrice &&
            volume == other.volume;
  }

  @override
  int get hashCode => Object.hash(
    timeStamp,
    openPrice,
    highPrice,
    lowPrice,
    closePrice,
    volume,
  );
}
class SymbolNotFoundException implements Exception {
  const SymbolNotFoundException([
    this.message = 'Symbol not found',
  ]);

  final String message;

  @override
  String toString() => message;
}

class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.lastPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.asOf,
  });

  final String symbol;
  final double lastPrice;
  final double changeAmount;
  final double changePercent;
  final String asOf;

  factory MarketQuote.fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      symbol: (json['symbol'] as String).toUpperCase(),
      lastPrice: (json['lastPrice'] as num).toDouble(),
      changeAmount: (json['changeAmount'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      asOf: json['asOf'] as String,
    );
  }

  MarketQuote copyWith({
    String? symbol,
    double? lastPrice,
    double? changeAmount,
    double? changePercent,
    String? asOf,
  }) {
    return MarketQuote(
      symbol: symbol ?? this.symbol,
      lastPrice: lastPrice ?? this.lastPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercent: changePercent ?? this.changePercent,
      asOf: asOf ?? this.asOf,
    );
  }
}

class MarketFundamentals {
  const MarketFundamentals({
    required this.symbol,
    required this.fields,
  });

  final String symbol;
  final Map<String, dynamic> fields;

  factory MarketFundamentals.fromJson(Map<String, dynamic> json) {
    final symbol = (json['symbol'] as String?)?.toUpperCase() ?? '';
    final fields = Map<String, dynamic>.from(json)
      ..remove('symbol');
    return MarketFundamentals(symbol: symbol, fields: fields);
  }

  List<MapEntry<String, dynamic>> get displayEntries {
    return fields.entries
        .where((entry) => entry.value != null)
        .toList();
  }
}

class MarketSearchResult {
  const MarketSearchResult({
    required this.symbol,
    required this.name,
    required this.exchange,
  });

  final String symbol;
  final String name;
  final String exchange;

  factory MarketSearchResult.fromJson(Map<String, dynamic> json) {
    return MarketSearchResult(
      symbol: (json['symbol'] as String).toUpperCase(),
      name: json['name'] as String,
      exchange: json['exchange'] as String,
    );
  }
}

class SymbolDetailSnapshot {
  const SymbolDetailSnapshot({
    required this.quote,
    required this.fundamentals,
    required this.fetchedAt,
  });

  final MarketQuote quote;
  final MarketFundamentals fundamentals;
  final DateTime fetchedAt;
}

class MarketRepository {
  MarketRepository(this._dio);

  final Dio _dio;

  Future<MarketQuote> getQuote(String symbol) async {
    final normalized = symbol.trim().toUpperCase();
    if (!marketSymbolPattern.hasMatch(normalized)) {
      throw const SymbolNotFoundException();
    }

    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/market/quote',
        queryParameters: {'symbol': normalized},
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return MarketQuote.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<MarketFundamentals> getFundamentals(String symbol) async {
    final normalized = symbol.trim().toUpperCase();
    if (!marketSymbolPattern.hasMatch(normalized)) {
      throw const SymbolNotFoundException();
    }

    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/market/fundamentals',
        queryParameters: {'symbol': normalized},
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return MarketFundamentals.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<SymbolDetailSnapshot> getSymbolDetail(String symbol) async {
    final quote = await getQuote(symbol);
    final fundamentals = await getFundamentals(symbol);
    return SymbolDetailSnapshot(
      quote: quote,
      fundamentals: fundamentals,
      fetchedAt: DateTime.now().toUtc(),
    );
  }

  Future<List<Bar>> fetchBars(String symbol, String range) async {
    
    final normalized = symbol.trim().toUpperCase();
    if (!marketSymbolPattern.hasMatch(normalized)) {
      throw const SymbolNotFoundException();
    }

    final timeframe = kRangeToTimeframe[range];
    if (timeframe == null) {
      throw ApiException(
        message: 'Invalid chart range.',
        code: 'INVALID_RANGE',
      );
    }

    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/market/bars',
        queryParameters: {
          'symbol': normalized,
          'timeframe': timeframe,
          'range': range,
        },
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      final data = envelope.data;
      if (data == null) {
        return const [];
      }
      final rawBars = data['bars'];
      if (rawBars is! List) {
        return const [];
      }
      return rawBars
          .whereType<Map<String, dynamic>>()
          .map(Bar.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }
  Future<List<MarketSearchResult>> searchSymbols(String query, {int limit = 10}) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const [];
    }
    
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/market/search',
        queryParameters: {'q': q, 'limit': limit},
      );
      final envelope = parseEnvelope<List<dynamic>?>(
        response.data,
        parseData: (json) => json as List<dynamic>?,
      );
      final data = envelope.data;
      print('SEARCH RESPONSE for query "$q": ${response.data}');
      if (data == null || data.isEmpty) {
        return const [];
      }
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map(MarketSearchResult.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Exception _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    final apiError = _parseApiError(error.response?.data);
    final message = apiError?.message ?? 'Request failed.';
    final code = apiError?.code;

    if (status == 404) {
      return const SymbolNotFoundException();
    }

    switch (status) {
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

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(ref.watch(dioProvider));
});
