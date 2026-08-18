import 'api_error.dart';

/// Shared API response envelope from the backend.
class ApiEnvelope<T> {
  const ApiEnvelope({
    required this.success,
    required this.data,
    required this.error,
    required this.requestId,
  });

  final bool success;
  final T? data;
  final ApiError? error;
  final String? requestId;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json, {
    required T? Function(dynamic json) parseData,
  }) {
    final rawData = json['data'];

    final rawError = json['error'];
    ApiError? error;
    if (rawError is Map<String, dynamic>) {
      error = ApiError.fromJson(rawError);
    }

    final requestId =
        json['requestId'] as String? ??
        (json['meta'] is Map<String, dynamic>
            ? (json['meta'] as Map<String, dynamic>)['requestId'] as String?
            : null);

    return ApiEnvelope<T>(
      success: json['success'] == true,
      data: parseData(rawData),
      error: error,
      requestId: requestId,
    );
  }

  Map<String, dynamic> toJson({required Object? Function(T? data) encodeData}) {
    return {
      'success': success,
      'data': encodeData(data),
      'error': error == null
          ? null
          : {
              'code': error!.code,
              'message': error!.message,
              if (error!.details.isNotEmpty) 'details': error!.details,
            },
      'requestId': requestId,
    };
  }
}
