import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/core/config/app_config.dart';
import 'package:sheetstorm/features/auth/data/models/auth_models.dart';
import 'package:sheetstorm/features/auth/data/services/auth_service.dart';
import 'package:sheetstorm/features/auth/data/services/token_storage.dart';

part 'auth_notifier.g.dart';

// ─── Auth State ───────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

/// App is determining auth status (startup token check).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// No valid session; user must log in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User registered/logged in but email not yet confirmed.
class AuthEmailPendingVerification extends AuthState {
  final String email;
  const AuthEmailPendingVerification(this.email);
}

/// Valid session with user data.
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}

/// Transient error state — surfaces error messages to UI.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ─── Auth Notifier ────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _initializeAuth();
    return const AuthLoading();
  }

  /// Checks persisted tokens on app start.
  /// Attempts token refresh if access token is expired; logs out on failure.
  Future<void> _initializeAuth() async {
    final storage = ref.read(tokenStorageProvider);
    try {
      final user = await storage.getUser();
      if (user == null) {
        state = const AuthUnauthenticated();
        return;
      }

      final isExpired = await storage.isAccessTokenExpired();
      if (!isExpired) {
        state = _resolveAuthenticatedState(user);
        return;
      }

      // Access token expired — attempt silent refresh
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) {
        await storage.clear();
        state = const AuthUnauthenticated();
        return;
      }

      try {
        final service = ref.read(authServiceProvider);
        final newTokens = await service.refreshToken(refreshToken);
        await storage.saveTokens(newTokens);
        state = _resolveAuthenticatedState(user);
      } catch (_) {
        // Refresh failed (expired / revoked) → force logout
        await storage.clear();
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final service = ref.read(authServiceProvider);
      final storage = ref.read(tokenStorageProvider);
      final response = await service.login(email, password);
      await storage.saveTokens(response.tokens);
      await storage.saveUser(response.user);
      state = _resolveAuthenticatedState(response.user);
    } on DioException catch (e) {
      state = AuthError(_messageFromDioError(e));
    } catch (_) {
      state = const AuthError('Ein unbekannter Fehler ist aufgetreten.');
    }
  }

  /// Returns the [AuthResponse] so callers can navigate after registration.
  Future<AuthResponse?> sections(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AuthLoading();
    try {
      final service = ref.read(authServiceProvider);
      final storage = ref.read(tokenStorageProvider);
      final response = await service.sections(email, password, displayName);
      await storage.saveTokens(response.tokens);
      await storage.saveUser(response.user);
      state = _resolveAuthenticatedState(response.user);
      return response;
    } on DioException catch (e) {
      state = AuthError(_messageFromDioError(e));
      return null;
    } catch (_) {
      state = const AuthError('Ein unbekannter Fehler ist aufgetreten.');
      return null;
    }
  }

  /// Verifies a user's email with the token from the verification link.
  Future<void> verifyEmail(String token) async {
    state = const AuthLoading();
    try {
      final service = ref.read(authServiceProvider);
      await service.verifyEmail(token);
      final storage = ref.read(tokenStorageProvider);
      final user = await storage.getUser();
      if (user != null) {
        final verified = user.copyWith(emailVerified: true);
        await storage.saveUser(verified);
        state = AuthAuthenticated(verified);
      } else {
        state = const AuthUnauthenticated();
      }
    } on DioException catch (e) {
      state = AuthError(_messageFromDioError(e));
    } catch (_) {
      state = const AuthError('Ein unbekannter Fehler ist aufgetreten.');
    }
  }

  Future<void> forgotPassword(String email) async {
    final service = ref.read(authServiceProvider);
    await service.forgotPassword(email);
  }

  Future<void> logout() async {
    final storage = ref.read(tokenStorageProvider);
    await storage.clear();
    state = const AuthUnauthenticated();
  }

  /// Called by the API interceptor when a 401 cannot be recovered.
  Future<void> onAuthError() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AuthUnauthenticated();
  }

  /// Update local user record after onboarding completes.
  Future<void> markOnboardingCompleted() async {
    final current = state;
    if (current is AuthAuthenticated) {
      final updated = current.user.copyWith(onboardingCompleted: true);
      await ref.read(tokenStorageProvider).saveUser(updated);
      state = AuthAuthenticated(updated);
    }
  }

  /// Resolves the post-login/sections state based on email verification status.
  /// In dev mode (debug builds) email verification is skipped automatically.
  AuthState _resolveAuthenticatedState(User user) {
    if (!user.emailVerified && !AppConfig.devAutoVerifyEmail) {
      return AuthEmailPendingVerification(user.email);
    }
    return AuthAuthenticated(user);
  }

  static String _messageFromDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('message')) {
      return data['message'] as String;
    }
    return switch (e.response?.statusCode) {
      400 => 'Ungültige Eingabe. Bitte überprüfe deine Daten.',
      401 => 'E-Mail oder Passwort falsch.',
      403 => 'Bitte bestätige zuerst deine E-Mail-Adresse.',
      409 => 'Diese E-Mail-Adresse ist bereits registriert.',
      422 => 'Das Passwort erfüllt nicht die Mindestanforderungen.',
      _ => 'Ein Serverfehler ist aufgetreten. Bitte versuche es später.',
    };
  }
}
