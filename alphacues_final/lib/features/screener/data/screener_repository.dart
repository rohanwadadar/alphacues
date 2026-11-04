import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import 'screener_models.dart';

/// Repository that talks ONLY to the screener endpoints.
/// Endpoint contract (Task 18 backend):
///   POST /api/v1/screener/run         — execute a screen
///   GET  /api/v1/screener/strategies  — list saved strategies (cursor-paginated)
///   POST /api/v1/screener/strategies  — create saved strategy
///   DELETE /api/v1/screener/strategies/:id — delete strategy
class ScreenerRepository {
  ScreenerRepository(this._dio);

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Run scan — POST /api/v1/screener/run
  // ---------------------------------------------------------------------------
  Future<ScreenerScanResult> runScan({
    required ScreenerFilter filters,
    String sortBy = 'changePercent',
    String sortOrder = 'desc',
    int limit = 1000,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/screener/run',
        data: {
          'filters': filters.toJson(),
          'sort_by': sortBy.isNotEmpty ? sortBy : 'changePercent',
          'sort_order': sortOrder,
          'limit': limit,
        },
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return ScreenerScanResult.fromJson(envelope.data ?? const {});
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // List strategies — GET /api/v1/screener/strategies
  // Respects standard cursor pagination envelope (meta.nextCursor).
  // ---------------------------------------------------------------------------
  Future<ScreenerStrategyListResult> listStrategies({
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/screener/strategies',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'limit': limit,
        },
      );

      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        throw const ApiException(message: 'Invalid response format.');
      }

      // Parse items from data.items (backend wraps list in {items:[...]})
      final envelope = parseEnvelope<Map<String, dynamic>>(
        raw,
        parseData: (json) => json,
      );

      final itemsRaw = envelope.data?['items'];
      final items = itemsRaw is List
          ? itemsRaw
                .map(
                  (e) => ScreenerStrategy.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList()
          : const <ScreenerStrategy>[];

      // Extract nextCursor from meta
      String? nextCursor;
      final meta = raw['meta'];
      if (meta is Map<String, dynamic>) {
        nextCursor = meta['nextCursor'] as String?;
      }

      return ScreenerStrategyListResult(
        strategies: items,
        nextCursor: nextCursor,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Create strategy — POST /api/v1/screener/strategies
  // Payload: { name, filters } (plus optional sort_by / sort_order / description)
  // ---------------------------------------------------------------------------
  Future<ScreenerStrategy> createStrategy({
    required String name,
    required ScreenerFilter filters,
    String sortBy = 'changePercent',
    String sortOrder = 'desc',
    String? description,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/api/v1/screener/strategies',
        data: {
          'name': name,
          'filters': filters.toJson(),
          'sort_by': sortBy,
          'sort_order': sortOrder,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      final envelope = parseEnvelope<Map<String, dynamic>>(
        response.data,
        parseData: (json) => json,
      );
      return ScreenerStrategy.fromJson(envelope.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Delete strategy — DELETE /api/v1/screener/strategies/:id
  // ---------------------------------------------------------------------------
  Future<void> deleteStrategy(int strategyId) async {
    try {
      await _dio.delete<dynamic>('/api/v1/screener/strategies/$strategyId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return;
      }
      throw _mapDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------
  ApiException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    final rawData = error.response?.data;
    String message = 'Request failed.';
    String? code;

    if (rawData is Map<String, dynamic>) {
      final err = rawData['error'];
      if (err is Map<String, dynamic>) {
        message = err['message'] as String? ?? message;
        code = err['code'] as String?;
      }
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      code ??= 'SERVICE_UNAVAILABLE';
    }

    return ApiException(message: message, code: code, statusCode: status);
  }
}

/// Riverpod provider #7 (feature repository) — screenerRepositoryProvider.
/// Name is reserved in the plan's provider hierarchy alongside
/// dashboardRepositoryProvider, watchlistRepositoryProvider, etc.
final screenerRepositoryProvider = Provider<ScreenerRepository>((ref) {
  return ScreenerRepository(ref.watch(dioProvider));
});
