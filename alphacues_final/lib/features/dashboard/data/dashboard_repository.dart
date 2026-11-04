import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../features/watchlist/data/watchlist_repository.dart'
    show ServiceUnavailableException;

class MarketMover {
  const MarketMover({
    required this.symbol,
    required this.lastPrice,
    required this.changePercent,
  });

  final String symbol;
  final double lastPrice;
  final double changePercent;

  factory MarketMover.fromJson(Map<String, dynamic> json) {
    return MarketMover(
      symbol: (json['symbol'] as String).toUpperCase(),
      lastPrice: (json['lastPrice'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
    );
  }

  MarketMover copyWith({
    String? symbol,
    double? lastPrice,
    double? changePercent,
  }) {
    return MarketMover(
      symbol: symbol ?? this.symbol,
      lastPrice: lastPrice ?? this.lastPrice,
      changePercent: changePercent ?? this.changePercent,
    );
  }
}

class PortfolioSummary {
  const PortfolioSummary({
    required this.portfolioId,
    required this.totalValue,
    required this.availableBalance,
    required this.totalProfit,
    required this.totalReturn,
    required this.dayChange,
    required this.asOf,
  });

  final String portfolioId;
  final double totalValue;
  final double availableBalance;
  final double totalProfit;
  final double totalReturn;
  final double dayChange;
  final String asOf;

  PortfolioSummary copyWith({
    double? totalValue,
    double? totalProfit,
    double? totalReturn,
    double? dayChange,
    String? asOf,
  }) {
    return PortfolioSummary(
      portfolioId: portfolioId,
      totalValue: totalValue ?? this.totalValue,
      availableBalance: availableBalance,
      totalProfit: totalProfit ?? this.totalProfit,
      totalReturn: totalReturn ?? this.totalReturn,
      dayChange: dayChange ?? this.dayChange,
      asOf: asOf ?? this.asOf,
    );
  }

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      portfolioId: json['portfolioId'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
      totalProfit: (json['totalProfit'] as num).toDouble(),
      totalReturn: (json['totalReturn'] as num).toDouble(),
      dayChange: (json['dayChange'] as num).toDouble(),
      asOf: json['asOf'] as String,
    );
  }
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.topMovers,
    this.portfolio,
    required this.unreadNotificationCount,
    required this.fetchedAt,
  });

  final List<MarketMover> topMovers;
  final PortfolioSummary? portfolio;
  final int unreadNotificationCount;
  final DateTime fetchedAt;

  List<String> get moverSymbols =>
      topMovers.map((mover) => mover.symbol).toList();

  factory DashboardSnapshot.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final moversRaw = json['topMovers'] ?? json['movers'];
    final movers = moversRaw is List
        ? moversRaw
              .map(
                (entry) => MarketMover.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList()
        : const <MarketMover>[];

    final portfolioRaw = json['portfolio'] ?? json['portfolioSummary'];
    final portfolio = portfolioRaw is Map<String, dynamic>
        ? PortfolioSummary.fromJson(portfolioRaw)
        : null;

    final unread =
        json['unreadNotificationCount'] as int? ??
        json['unreadCount'] as int? ??
        0;

    return DashboardSnapshot(
      topMovers: movers,
      portfolio: portfolio,
      unreadNotificationCount: unread,
      fetchedAt: fetchedAt ?? DateTime.now().toUtc(),
    );
  }

  DashboardSnapshot copyWith({
    List<MarketMover>? topMovers,
    PortfolioSummary? portfolio,
    int? unreadNotificationCount,
    DateTime? fetchedAt,
  }) {
    return DashboardSnapshot(
      topMovers: topMovers ?? this.topMovers,
      portfolio: portfolio ?? this.portfolio,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSnapshot> getDashboard() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/dashboard');
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return DashboardSnapshot.fromJson(envelope.data!);
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/notifications',
        queryParameters: {'limit': 1, 'unreadOnly': true},
      );
      final envelope = parseEnvelope<dynamic>(
        response.data,
        parseData: (json) => json,
      );

      final data = envelope.data;
      if (data is List) {
        return data.length;
      } else if (data is Map<String, dynamic>) {
        final unread = data['unreadCount'] ?? data['count'];
        if (unread is int) return unread;
      }
      return 0;
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

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});
