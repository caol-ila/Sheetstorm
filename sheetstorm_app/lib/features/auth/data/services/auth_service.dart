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
      '/api/auth/login',
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
      '/api/auth/register',
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
      '/api/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthTokens.fromJson(res.data!);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<void>(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }

  Future<void> validateGuestToken(String token) async {
    await _dio.post<void>(
      '/api/auth/guest-token/validate',
      data: {'token': token},
    );
  }

  /// Verifies a user's email. Token is sent in the JSON body per backend contract.
  Future<void> verifyEmail(String token) async {
    await _dio.post<void>(
      '/api/auth/verify-email',
      data: {'token': token},
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post<void>(
      '/api/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    );
  }
}
