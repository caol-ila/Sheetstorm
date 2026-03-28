import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/auth/data/models/auth_models.dart';

part 'auth_service.g.dart';

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();

/// Pure HTTP layer for auth endpoints. Uses its own Dio instance
/// (no auth interceptor) to avoid circular dependencies.
class AuthService {
  static const _baseUrl = 'https://api.sheetstorm.app/v1';

  final Dio _dio;

  AuthService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  Future<AuthResponse> login(String email, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data!);
  }

  Future<AuthResponse> register(
    String email,
    String password,
    String displayName,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );
    return AuthResponse.fromJson(res.data!);
  }

  Future<AuthTokens> refreshToken(String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthTokens.fromJson(res.data!);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> validateGuestToken(String token) async {
    await _dio.post<void>(
      '/auth/guest-token/validate',
      data: {'token': token},
    );
  }

  Future<void> verifyEmail(String token) async {
    await _dio.post<void>('/auth/email-verify/$token');
  }

  Future<void> resendVerificationEmail(String email) async {
    await _dio.post<void>(
      '/auth/email-verify/resend',
      data: {'email': email},
    );
  }

  Future<void> completeOnboarding({
    String? instrument,
    String? kapelleId,
    String? defaultVoice,
    String? theme,
  }) async {
    await _dio.patch<void>(
      '/users/me/onboarding',
      data: {
        if (instrument != null) 'instrument': instrument,
        if (kapelleId != null) 'kapelleId': kapelleId,
        if (defaultVoice != null) 'defaultVoice': defaultVoice,
        if (theme != null) 'theme': theme,
        'onboardingCompleted': true,
      },
    );
  }
}
