/// Local storage service for configuration — Issue #35
///
/// Device settings use SharedPreferences (not synced).
/// Kapelle/Nutzer cache uses the Drift database.

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';

part 'config_local_storage.g.dart';

@Riverpod(keepAlive: true)
ConfigLocalStorage configLocalStorage(Ref ref) {
  return ConfigLocalStorage();
}

/// Manages local configuration storage.
///
/// - Geräte-Config: SharedPreferences (key prefix: `config.geraet.`)
/// - Kapelle/Nutzer cache: SharedPreferences (key prefix: `config.cache.`)
/// - Pending sync queue: SharedPreferences (key: `config.pending_sync`)
class ConfigLocalStorage {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── Geräte-Config ────────────────────────────────────────────────────────

  static const _geraetPrefix = 'config.geraet.';

  Future<dynamic> getDeviceConfig(String key) async {
    final prefs = await _getPrefs;
    final raw = prefs.getString('$_geraetPrefix$key');
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<void> setDeviceConfig(String key, dynamic value) async {
    final prefs = await _getPrefs;
    await prefs.setString('$_geraetPrefix$key', jsonEncode(value));
  }

  Future<void> removeGeraetConfig(String key) async {
    final prefs = await _getPrefs;
    await prefs.remove('$_geraetPrefix$key');
  }

  Future<Map<String, dynamic>> getAllGeraetConfig() async {
    final prefs = await _getPrefs;
    final result = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_geraetPrefix)) {
        final configKey = key.substring(_geraetPrefix.length);
        final raw = prefs.getString(key);
        if (raw != null) {
          result[configKey] = jsonDecode(raw);
        }
      }
    }
    return result;
  }

  // ─── Cache (Kapelle + Nutzer) ─────────────────────────────────────────────

  static const _cachePrefix = 'config.cache.';

  Future<void> cacheConfig(
    String key,
    ConfigLevel level,
    dynamic value, {
    String? referenceId,
    int version = 1,
  }) async {
    final prefs = await _getPrefs;
    final cacheKey = _buildCacheKey(key, level, referenceId);
    final entry = {
      'value': value,
      'level': level.name,
      'version': version,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(cacheKey, jsonEncode(entry));
  }

  Future<ConfigEntry?> getCachedConfig(
    String key,
    ConfigLevel level, {
    String? referenceId,
  }) async {
    final prefs = await _getPrefs;
    final cacheKey = _buildCacheKey(key, level, referenceId);
    final raw = prefs.getString(cacheKey);
    if (raw == null) return null;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return ConfigEntry(
      key: key,
      level: level,
      value: data['value'],
      version: data['version'] as int? ?? 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        data['updated_at'] as int,
      ),
      referenceId: referenceId,
    );
  }

  Future<Map<String, dynamic>> getAllCachedConfig(
    ConfigLevel level, {
    String? referenceId,
  }) async {
    final prefs = await _getPrefs;
    final prefix = '$_cachePrefix${level.name}.${referenceId ?? 'local'}.';
    final result = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(prefix)) {
        final configKey = key.substring(prefix.length);
        final raw = prefs.getString(key);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          result[configKey] = data['value'];
        }
      }
    }
    return result;
  }

  Future<void> clearCache(ConfigLevel level, {String? referenceId}) async {
    final prefs = await _getPrefs;
    final prefix = '$_cachePrefix${level.name}.${referenceId ?? 'local'}.';
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(prefix)) {
        await prefs.remove(key);
      }
    }
  }

  String _buildCacheKey(String key, ConfigLevel level, String? referenceId) =>
      '$_cachePrefix${level.name}.${referenceId ?? 'local'}.$key';

  // ─── Pending Sync Queue ───────────────────────────────────────────────────

  static const _pendingKey = 'config.pending_sync';

  Future<List<PendingSyncEntry>> getPendingSyncEntries() async {
    final prefs = await _getPrefs;
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final data = e as Map<String, dynamic>;
      return PendingSyncEntry(
        key: data['key'] as String,
        value: data['value'],
        version: data['version'] as int,
        timestamp: DateTime.parse(data['timestamp'] as String),
      );
    }).toList();
  }

  Future<void> addPendingSyncEntry(PendingSyncEntry entry) async {
    final entries = await getPendingSyncEntries();
    // Replace existing entry for same key
    entries.removeWhere((e) => e.key == entry.key);
    entries.add(entry);
    await _savePendingEntries(entries);
  }

  Future<void> clearPendingSyncEntries() async {
    final prefs = await _getPrefs;
    await prefs.remove(_pendingKey);
  }

  Future<void> _savePendingEntries(List<PendingSyncEntry> entries) async {
    final prefs = await _getPrefs;
    await prefs.setString(
      _pendingKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  // ─── Policies Cache ────────────────────────────────────────────────────────

  static const _policyPrefix = 'config.policy.';

  Future<void> cachePolicies(
    String bandId,
    Map<String, ConfigPolicy> policies,
  ) async {
    final prefs = await _getPrefs;
    final data = policies.map(
      (key, policy) => MapEntry(key, policy.toJson()),
    );
    await prefs.setString(
      '$_policyPrefix$bandId',
      jsonEncode(data),
    );
  }

  Future<Map<String, ConfigPolicy>> getCachedPolicies(
      String bandId) async {
    final prefs = await _getPrefs;
    final raw = prefs.getString('$_policyPrefix$bandId');
    if (raw == null) return {};

    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(
          key,
          ConfigPolicy.fromJson({
            'key': key,
            ...value as Map<String, dynamic>,
          }),
        ));
  }
}
