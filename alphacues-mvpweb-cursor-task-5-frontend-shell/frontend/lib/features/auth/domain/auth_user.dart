/// Authenticated user profile from auth endpoints.
class AuthUser {
  const AuthUser({
    required this.userId,
    required this.email,
    this.name,
    this.avatarUrl,
  });

  final Object userId;
  final String email;
  final String? name;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId'] as Object,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    if (name != null) 'name': name,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };
}
