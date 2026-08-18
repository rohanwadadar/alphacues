/// API error payload from the shared envelope.
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.details = const {},
  });

  final String code;
  final String message;
  final Map<String, dynamic> details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Something went wrong.',
      details: rawDetails is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawDetails)
          : const {},
    );
  }

  static const otpInvalid = 'OTP_INVALID';
  static const otpExpired = 'OTP_EXPIRED';
  static const otpLocked = 'OTP_LOCKED';
  static const unauthorized = 'UNAUTHORIZED';
  static const tokenExpired = 'TOKEN_EXPIRED';
}

/// Thrown when the API returns `success: false` or an unexpected shape.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code,
    this.statusCode,
    this.details,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Map<String, dynamic>? details;

  @override
  String toString() => 'ApiException($code, $statusCode): $message';
}
