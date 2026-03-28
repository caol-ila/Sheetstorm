import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/auth/data/models/auth_models.dart';

part 'token_storage.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage();

/// Wraps flutter_secure_storage for JWT access/refresh token persistence.
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccessToken = 'ss_access_token';
  static const _kRefreshToken = 'ss_refresh_token';
  static const _kAccessTokenExpiry = 'ss_access_token_expiry';
  static const _kUser = 'ss_user';

  Future<void> saveTokens(AuthTokens tokens) async {
    final expiresAt = DateTime.now()
        .add(Duration(seconds: tokens.expiresIn))
        .millisecondsSinceEpoch
        .toString();
    await Future.wait([
      _storage.write(key: _kAccessToken, value: tokens.accessToken),
      _storage.write(key: _kRefreshToken, value: tokens.refreshToken),
      _storage.write(key: _kAccessTokenExpiry, value: expiresAt),
    ]);
  }

  /// Returns `true` when the stored access token is expired or missing.
  /// Uses a 60-second safety margin to account for clock skew.
  Future<bool> isAccessTokenExpired() async {
    final raw = await _storage.read(key: _kAccessTokenExpiry);
    if (raw == null) return true;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
    return DateTime.now()
        .isAfter(expiresAt.subtract(const Duration(seconds: 60)));
  }

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> saveUser(User user) async {
    await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() => _storage.deleteAll();
}
