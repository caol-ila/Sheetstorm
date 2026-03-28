/// Config repository — combines API + local storage + resolution — Issue #35
///
/// Implements the override chain: Gerät > Nutzer > Kapelle > System-Default
/// with Policy blocking support.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/config/data/services/config_api_service.dart';
import 'package:sheetstorm/features/config/data/services/config_local_storage.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';

part 'config_repository.g.dart';

@Riverpod(keepAlive: true)
ConfigRepository configRepository(Ref ref) {
  return ConfigRepository(
    api: ref.read(configApiServiceProvider),
    local: ref.read(configLocalStorageProvider),
  );
}

class ConfigRepository {
  ConfigRepository({
    required ConfigApiService api,
    required ConfigLocalStorage local,
  })  : _api = api,
        _local = local;

  final ConfigApiService _api;
  final ConfigLocalStorage _local;

  // ─── Config Resolution ────────────────────────────────────────────────────

  /// Resolve a config value following: Gerät > Nutzer > Kapelle > System-Default
  /// with Policy blocking.
  Future<ResolvedConfigValue> resolveConfig(
    String key, {
    String? bandId,
  }) async {
    final systemDefault = ConfigKeys.getDefault(key);

    // Get values from each level
    final deviceValue = await _local.getDeviceConfig(key);

    dynamic userValue;
    final userCache = await _local.getCachedConfig(
      key,
      ConfigLevel.user,
    );
    userValue = userCache?.value;

    dynamic bandValue;
    if (bandId != null) {
      final bandCache = await _local.getCachedConfig(
        key,
        ConfigLevel.band,
        referenceId: bandId,
      );
      bandValue = bandCache?.value;
    }

    // Check policies
    bool isLocked = false;
    if (bandId != null) {
      final policies = await _local.getCachedPolicies(bandId);
      isLocked = _isPolicyLocked(key, policies);
    }

    // Resolve: if locked, use band value; otherwise follow override chain
    dynamic effectiveValue;
    ConfigLevel source;

    if (isLocked) {
      effectiveValue = bandValue ?? systemDefault;
      source = bandValue != null ? ConfigLevel.band : ConfigLevel.band;
    } else if (deviceValue != null) {
      effectiveValue = deviceValue;
      source = ConfigLevel.device;
    } else if (userValue != null) {
      effectiveValue = userValue;
      source = ConfigLevel.user;
    } else if (bandValue != null) {
      effectiveValue = bandValue;
      source = ConfigLevel.band;
    } else {
      effectiveValue = systemDefault;
      source = ConfigLevel.band;
    }

    return ResolvedConfigValue(
      key: key,
      value: effectiveValue,
      source: source,
      isLocked: isLocked,
      bandDefault: bandValue,
      userValue: userValue,
      deviceValue: deviceValue,
      systemDefault: systemDefault,
    );
  }

  /// Check whether a key is blocked by a policy.
  bool _isPolicyLocked(String key, Map<String, ConfigPolicy> policies) {
    // Map config keys to their controlling policies
    const policyMap = {
      'user.language': 'policy.force_locale',
      'user.theme': 'policy.force_dark_mode',
      'nutzer.ai.api_key': 'policy.allow_user_ai_keys',
      'nutzer.ai.provider': 'policy.allow_user_ai_keys',
      'device.tuner.tuning_pitch': 'policy.force_tuning_pitch',
    };

    final policyKey = policyMap[key];
    if (policyKey == null) return false;

    final policy = policies[policyKey];
    if (policy == null) return false;

    // force_locale, force_kammerton: enforced = true means locked
    if (policyKey == 'policy.force_locale' ||
        policyKey == 'policy.force_tuning_pitch') {
      return policy.value == true;
    }

    // force_dark_mode: non-null means enforced
    if (policyKey == 'policy.force_dark_mode') {
      return policy.value != null;
    }

    // allow_user_ai_keys: false means locked
    if (policyKey == 'policy.allow_user_ai_keys') {
      return policy.value == false;
    }

    return false;
  }

  // ─── Load All ─────────────────────────────────────────────────────────────

  /// Load all config from server and cache locally.
  Future<void> loadBandConfig(String bandId) async {
    try {
      final data = await _api.getBandConfig(bandId);
      for (final entry in data.entries) {
        await _local.cacheConfig(
          entry.key,
          ConfigLevel.band,
          entry.value,
          referenceId: bandId,
        );
      }
    } catch (_) {
      // Offline: use cached data
    }
  }

  Future<void> loadUserConfig() async {
    try {
      final data = await _api.getNutzerConfig();
      for (final entry in data.entries) {
        final value = entry.value is Map ? entry.value['value'] : entry.value;
        final version =
            entry.value is Map ? (entry.value['version'] as int? ?? 1) : 1;
        await _local.cacheConfig(
          entry.key,
          ConfigLevel.user,
          value,
          version: version,
        );
      }
    } catch (_) {
      // Offline: use cached data
    }
  }

  Future<void> loadPolicies(String bandId) async {
    try {
      final policies = await _api.getBandPolicies(bandId);
      await _local.cachePolicies(bandId, policies);
    } catch (_) {
      // Offline: use cached policies
    }
  }

  // ─── Write Operations ─────────────────────────────────────────────────────

  /// Set a Kapelle config value (admin only).
  Future<void> setBandConfig(
    String bandId,
    String key,
    dynamic value,
  ) async {
    await _local.cacheConfig(
      key,
      ConfigLevel.band,
      value,
      referenceId: bandId,
    );
    try {
      await _api.putBandConfig(bandId, key, value);
    } catch (_) {
      // Will sync later
    }
  }

  /// Reset a Kapelle config value to system default.
  Future<void> resetBandConfig(String bandId, String key) async {
    await _local.clearCache(ConfigLevel.band, referenceId: bandId);
    try {
      await _api.deleteBandConfig(bandId, key);
    } catch (_) {
      // Will sync later
    }
  }

  /// Set a Nutzer config value.
  Future<void> setUserConfig(String key, dynamic value) async {
    final existing = await _local.getCachedConfig(key, ConfigLevel.user);
    final newVersion = (existing?.version ?? 0) + 1;

    await _local.cacheConfig(key, ConfigLevel.user, value, version: newVersion);

    // Queue for sync
    await _local.addPendingSyncEntry(PendingSyncEntry(
      key: key,
      value: value,
      version: newVersion,
      timestamp: DateTime.now(),
    ));

    try {
      await _api.putNutzerConfig(key, value);
      // Clear from pending queue on success
    } catch (_) {
      // Will sync later via delta-sync
    }
  }

  /// Reset a Nutzer config value (fall back to Kapelle/Default).
  Future<void> resetUserConfig(String key) async {
    final prefs = await _local.getCachedConfig(key, ConfigLevel.user);
    if (prefs != null) {
      await _local.cacheConfig(key, ConfigLevel.user, null);
    }
    try {
      await _api.deleteNutzerConfig(key);
    } catch (_) {
      // Will sync later
    }
  }

  /// Set a Gerät config value (local only, never synced).
  Future<void> setDeviceConfig(String key, dynamic value) async {
    await _local.setDeviceConfig(key, value);
  }

  /// Reset a Gerät config value.
  Future<void> resetDeviceConfig(String key) async {
    await _local.removeGeraetConfig(key);
  }

  /// Set a policy value (admin only).
  Future<void> setPolicy(
    String bandId,
    String key,
    dynamic value,
  ) async {
    final policies = await _local.getCachedPolicies(bandId);
    policies[key] = ConfigPolicy(
      key: key,
      value: value,
      enforced: value is bool ? value : value != null,
      updatedAt: DateTime.now(),
    );
    await _local.cachePolicies(bandId, policies);

    try {
      await _api.putPolicy(bandId, key, value);
    } catch (_) {
      // Will sync later
    }
  }

  // ─── Sync ─────────────────────────────────────────────────────────────────

  /// Delta-sync: push pending changes, pull server changes.
  Future<void> syncUserConfig() async {
    final pending = await _local.getPendingSyncEntries();
    if (pending.isEmpty) return;

    try {
      final result = await _api.syncUserConfig(pending);
      await _local.clearPendingSyncEntries();

      // Apply server changes that won conflicts
      final serverChanges = result['server_changes'] as List<dynamic>? ?? [];
      for (final change in serverChanges) {
        final data = change as Map<String, dynamic>;
        await _local.cacheConfig(
          data['key'] as String,
          ConfigLevel.user,
          data['value'],
          version: data['version'] as int? ?? 1,
        );
      }
    } catch (_) {
      // Will retry next time
    }
  }

  // ─── Policies Getter ──────────────────────────────────────────────────────

  Future<Map<String, ConfigPolicy>> getPolicies(String bandId) async {
    return _local.getCachedPolicies(bandId);
  }
}
