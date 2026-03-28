/// Domain models for authentication — Issue #12

class User {
  final String id;
  final String email;
  final String displayName;
  final bool emailVerified;
  final bool onboardingCompleted;
  final List<String> instruments;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    this.emailVerified = false,
    this.onboardingCompleted = false,
    this.instruments = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        emailVerified: json['emailVerified'] as bool? ?? false,
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
        'emailVerified': emailVerified,
        'onboardingCompleted': onboardingCompleted,
        'instruments': instruments,
      };

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    bool? emailVerified,
    bool? onboardingCompleted,
    List<String>? instruments,
  }) =>
      User(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        emailVerified: emailVerified ?? this.emailVerified,
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
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresIn: json['expiresIn'] as int? ?? 900,
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
