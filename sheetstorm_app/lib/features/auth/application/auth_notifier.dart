import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
  Future<void> _initializeAuth() async {
    final storage = ref.read(tokenStorageProvider);
    try {
      final accessToken = await storage.getAccessToken();
      final user = await storage.getUser();
      if (accessToken != null && user != null) {
        state = AuthAuthenticated(user);
      } else {
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
      state = AuthAuthenticated(response.user);
    } on DioException catch (e) {
      state = AuthError(_messageFromDioError(e));
    } catch (_) {
      state = const AuthError('Ein unbekannter Fehler ist aufgetreten.');
    }
  }

  /// Returns the [AuthResponse] so callers can navigate to onboarding.
  Future<AuthResponse?> register(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AuthLoading();
    try {
      final service = ref.read(authServiceProvider);
      final storage = ref.read(tokenStorageProvider);
      final response = await service.register(email, password, displayName);
      await storage.saveTokens(response.tokens);
      await storage.saveUser(response.user);
      state = AuthAuthenticated(response.user);
      return response;
    } on DioException catch (e) {
      state = AuthError(_messageFromDioError(e));
      return null;
    } catch (_) {
      state = const AuthError('Ein unbekannter Fehler ist aufgetreten.');
      return null;
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
  void onAuthError() {
    ref.read(tokenStorageProvider).clear();
    state = const AuthUnauthenticated();
  }

  /// Update local user record after onboarding completes.
  void markOnboardingCompleted() {
    final current = state;
    if (current is AuthAuthenticated) {
      state = AuthAuthenticated(current.user.copyWith(onboardingCompleted: true));
      ref.read(tokenStorageProvider).saveUser(
            current.user.copyWith(onboardingCompleted: true),
          );
    }
  }

  static String _messageFromDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('message')) {
      return data['message'] as String;
    }
    return switch (e.response?.statusCode) {
      400 => 'Ungültige Eingabe. Bitte überprüfe deine Daten.',
      401 => 'E-Mail oder Passwort falsch.',
      409 => 'Diese E-Mail-Adresse ist bereits registriert.',
      422 => 'Das Passwort erfüllt nicht die Mindestanforderungen.',
      _ => 'Ein Serverfehler ist aufgetreten. Bitte versuche es später.',
    };
  }
}
