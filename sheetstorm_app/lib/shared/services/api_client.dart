import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/features/auth/data/services/auth_service.dart';
import 'package:sheetstorm/features/auth/data/services/token_storage.dart';

part 'api_client.g.dart';

const String _baseUrl = 'https://api.sheetstorm.app/v1';

@riverpod
Dio apiClient(Ref ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final service = ref.read(authServiceProvider);

  final authInterceptor = _AuthInterceptor(
    tokenStorage: tokenStorage,
    authService: service,
    onAuthError: () => ref.read(authProvider.notifier).onAuthError(),
  );

  final dio = Dio(
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

  // Pass Dio reference to interceptor for request retry after token refresh
  authInterceptor.setDio(dio);

  dio.interceptors.addAll([
    authInterceptor,
    _LogInterceptor(),
  ]);

  return dio;
}

/// Injects Bearer token and handles automatic refresh on 401.
///
/// Uses a [Completer]-based mutex so that concurrent 401 responses trigger
/// only a single refresh request. Subsequent callers wait for the in-flight
/// refresh and then retry with the new access token. This prevents reuse
/// detection with family-based refresh token rotation.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required TokenStorage tokenStorage,
    required AuthService authService,
    required Future<void> Function() onAuthError,
  })  : _tokenStorage = tokenStorage,
        _authService = authService,
        _onAuthError = onAuthError;

  final TokenStorage _tokenStorage;
  final AuthService _authService;
  final Future<void> Function() _onAuthError;
  Dio? _dio;

  /// Guards concurrent refresh attempts — only one refresh in flight at a time.
  Completer<void>? _refreshCompleter;

  void setDio(Dio dio) => _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh for 401 on non-auth endpoints (avoid infinite loop)
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/')) {
      // Another request is already refreshing — wait for it, then retry.
      if (_refreshCompleter != null) {
        try {
          await _refreshCompleter!.future;
          final token = await _tokenStorage.getAccessToken();
          if (token != null && _dio != null) {
            final opts = err.requestOptions
              ..headers['Authorization'] = 'Bearer $token';
            final response = await _dio!.fetch<dynamic>(opts);
            handler.resolve(response);
            return;
          }
        } catch (_) {
          // Refresh failed — fall through to handler.next
        }
        handler.next(err);
        return;
      }

      // First caller — perform the refresh.
      _refreshCompleter = Completer<void>();
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null && _dio != null) {
        try {
          final tokens = await _authService.refreshToken(refreshToken);
          await _tokenStorage.saveTokens(tokens);
          _refreshCompleter!.complete();
          _refreshCompleter = null;

          // Retry original request with new access token
          final opts = err.requestOptions
            ..headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          final response = await _dio!.fetch<dynamic>(opts);
          handler.resolve(response);
          return;
        } catch (e) {
          // Refresh failed — force re-login
          await _tokenStorage.clear();
          _refreshCompleter!.completeError(e);
          _refreshCompleter = null;
          await _onAuthError();
        }
      } else {
        _refreshCompleter!.completeError(StateError('No refresh token'));
        _refreshCompleter = null;
        await _onAuthError();
      }
    }
    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }
}
