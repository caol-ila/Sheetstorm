import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/auth/data/models/auth_models.dart';

part 'token_storage.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage();

/// Platform-aware token persistence.
///
/// - **Web**: Uses [SharedPreferences] (localStorage-backed). The browser
///   sandbox is the security boundary; `FlutterSecureStorage` uses the
///   Web Crypto API (`SubtleCrypto`) which throws `OperationError` in
///   incognito mode and under certain browser security policies.
/// - **Mobile/Desktop**: Uses [FlutterSecureStorage] (hardware-backed
///   keychain / EncryptedSharedPreferences).
///
/// All operations are wrapped in try-catch so a storage failure never
/// crashes the app — callers receive `null` / silent failures instead.
class TokenStorage {
  static const _secureStorage = FlutterSecureStorage();

  static const _kAccessToken = 'ss_access_token';
  static const _kRefreshToken = 'ss_refresh_token';
  static const _kAccessTokenExpiry = 'ss_access_token_expiry';
  static const _kUser = 'ss_user';

  // ── Write helpers ─────────────────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  Future<void> _deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_kAccessToken),
        prefs.remove(_kRefreshToken),
        prefs.remove(_kAccessTokenExpiry),
        prefs.remove(_kUser),
      ]);
    } else {
      await _secureStorage.deleteAll();
    }
  }

  // ── Public API ────────────────────────────────────────────────────────

  Future<void> saveTokens(AuthTokens tokens) async {
    try {
      final expiresAt = DateTime.now()
          .add(Duration(seconds: tokens.expiresIn))
          .millisecondsSinceEpoch
          .toString();
      await Future.wait([
        _write(_kAccessToken, tokens.accessToken),
        _write(_kRefreshToken, tokens.refreshToken),
        _write(_kAccessTokenExpiry, expiresAt),
      ]);
    } catch (e) {
      debugPrint('[TokenStorage] saveTokens failed: $e');
    }
  }

  /// Returns `true` when the stored access token is expired or missing.
  /// Uses a 60-second safety margin to account for clock skew.
  Future<bool> isAccessTokenExpired() async {
    try {
      final raw = await _read(_kAccessTokenExpiry);
      if (raw == null) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(int.parse(raw));
      return DateTime.now()
          .isAfter(expiresAt.subtract(const Duration(seconds: 60)));
    } catch (e) {
      debugPrint('[TokenStorage] isAccessTokenExpired failed: $e');
      return true;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _read(_kAccessToken);
    } catch (e) {
      debugPrint('[TokenStorage] getAccessToken failed: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _read(_kRefreshToken);
    } catch (e) {
      debugPrint('[TokenStorage] getRefreshToken failed: $e');
      return null;
    }
  }

  Future<void> saveUser(User user) async {
    try {
      await _write(_kUser, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('[TokenStorage] saveUser failed: $e');
    }
  }

  Future<User?> getUser() async {
    try {
      final raw = await _read(_kUser);
      if (raw == null) return null;
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[TokenStorage] getUser failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _deleteAll();
    } catch (e) {
      debugPrint('[TokenStorage] clear failed: $e');
    }
  }
}
