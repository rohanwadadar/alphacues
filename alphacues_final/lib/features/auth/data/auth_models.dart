import '../domain/auth_user.dart';

class SendOtpResult {
  const SendOtpResult({
    required this.challengeId,
    this.emailMasked,
    this.expiresIn,
  });

  final String challengeId;
  final String? emailMasked;
  final int? expiresIn;

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      challengeId: (json['challengeId'] ?? json['otpChallengeId']) as String,
      emailMasked: json['emailMasked'] as String?,
      expiresIn: (json['expiresIn'] ?? json['expiresInSeconds']) as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'challengeId': challengeId,
    if (emailMasked != null) 'emailMasked': emailMasked,
    if (expiresIn != null) 'expiresIn': expiresIn,
  };
}

class VerifyOtpResult {
  const VerifyOtpResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  factory VerifyOtpResult.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] ?? json['expiresInSeconds']) as int,
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'user': user.toJson(),
  };
}

class RefreshTokenResult {
  const RefreshTokenResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  factory RefreshTokenResult.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] ?? json['expiresInSeconds']) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
  };
}
