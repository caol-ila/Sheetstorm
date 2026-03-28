/// Domain models for authentication — Issue #12

class User {
  final String id;
  final String email;
  final String displayName;
  final bool onboardingCompleted;
  final List<String> instruments;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.onboardingCompleted = false,
    this.instruments = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
        instruments: (json['instruments'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'onboardingCompleted': onboardingCompleted,
        'instruments': instruments,
      };

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? onboardingCompleted,
    List<String>? instruments,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
        instruments: instruments ?? this.instruments,
      );
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 900,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        tokenType: json['token_type'] as String? ?? 'Bearer',
        expiresIn: json['expires_in'] as int? ?? 900,
      );
}

class AuthResponse {
  final User user;
  final AuthTokens tokens;

  const AuthResponse({required this.user, required this.tokens});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json),
      );
}
