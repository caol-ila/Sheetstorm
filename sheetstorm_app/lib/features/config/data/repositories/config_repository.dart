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
    String? kapelleId,
  }) async {
    final systemDefault = ConfigKeys.getDefault(key);

    // Get values from each level
    final geraetWert = await _local.getGeraetConfig(key);

    dynamic nutzerWert;
    final nutzerCache = await _local.getCachedConfig(
      key,
      ConfigEbene.nutzer,
    );
    nutzerWert = nutzerCache?.wert;

    dynamic kapelleWert;
    if (kapelleId != null) {
      final kapelleCache = await _local.getCachedConfig(
        key,
        ConfigEbene.kapelle,
        referenzId: kapelleId,
      );
      kapelleWert = kapelleCache?.wert;
    }

    // Check policies
    bool istGesperrt = false;
    if (kapelleId != null) {
      final policies = await _local.getCachedPolicies(kapelleId);
      istGesperrt = _isPolicyLocked(key, policies);
    }

    // Resolve: if locked, use kapelle value; otherwise follow override chain
    dynamic effectiveWert;
    ConfigEbene herkunft;

    if (istGesperrt) {
      effectiveWert = kapelleWert ?? systemDefault;
      herkunft = kapelleWert != null ? ConfigEbene.kapelle : ConfigEbene.kapelle;
    } else if (geraetWert != null) {
      effectiveWert = geraetWert;
      herkunft = ConfigEbene.geraet;
    } else if (nutzerWert != null) {
      effectiveWert = nutzerWert;
      herkunft = ConfigEbene.nutzer;
    } else if (kapelleWert != null) {
      effectiveWert = kapelleWert;
      herkunft = ConfigEbene.kapelle;
    } else {
      effectiveWert = systemDefault;
      herkunft = ConfigEbene.kapelle;
    }

    return ResolvedConfigValue(
      schluessel: key,
      wert: effectiveWert,
      herkunft: herkunft,
      istGesperrt: istGesperrt,
      kapelleDefault: kapelleWert,
      nutzerWert: nutzerWert,
      geraetWert: geraetWert,
      systemDefault: systemDefault,
    );
  }

  /// Check whether a key is blocked by a policy.
  bool _isPolicyLocked(String key, Map<String, ConfigPolicy> policies) {
    // Map config keys to their controlling policies
    const policyMap = {
      'nutzer.sprache': 'policy.force_locale',
      'nutzer.theme': 'policy.force_dark_mode',
      'nutzer.ai.api_key': 'policy.allow_user_ai_keys',
      'nutzer.ai.provider': 'policy.allow_user_ai_keys',
      'geraet.tuner.kammerton': 'policy.force_kammerton',
    };

    final policyKey = policyMap[key];
    if (policyKey == null) return false;

    final policy = policies[policyKey];
    if (policy == null) return false;

    // force_locale, force_kammerton: enforced = true means locked
    if (policyKey == 'policy.force_locale' ||
        policyKey == 'policy.force_kammerton') {
      return policy.wert == true;
    }

    // force_dark_mode: non-null means enforced
    if (policyKey == 'policy.force_dark_mode') {
      return policy.wert != null;
    }

    // allow_user_ai_keys: false means locked
    if (policyKey == 'policy.allow_user_ai_keys') {
      return policy.wert == false;
    }

    return false;
  }

  // ─── Load All ─────────────────────────────────────────────────────────────

  /// Load all config from server and cache locally.
  Future<void> loadKapelleConfig(String kapelleId) async {
    try {
      final data = await _api.getKapelleConfig(kapelleId);
      for (final entry in data.entries) {
        await _local.cacheConfig(
          entry.key,
          ConfigEbene.kapelle,
          entry.value,
          referenzId: kapelleId,
        );
      }
    } catch (_) {
      // Offline: use cached data
    }
  }

  Future<void> loadNutzerConfig() async {
    try {
      final data = await _api.getNutzerConfig();
      for (final entry in data.entries) {
        final value = entry.value is Map ? entry.value['wert'] : entry.value;
        final version =
            entry.value is Map ? (entry.value['version'] as int? ?? 1) : 1;
        await _local.cacheConfig(
          entry.key,
          ConfigEbene.nutzer,
          value,
          version: version,
        );
      }
    } catch (_) {
      // Offline: use cached data
    }
  }

  Future<void> loadPolicies(String kapelleId) async {
    try {
      final policies = await _api.getKapellePolicies(kapelleId);
      await _local.cachePolicies(kapelleId, policies);
    } catch (_) {
      // Offline: use cached policies
    }
  }

  // ─── Write Operations ─────────────────────────────────────────────────────

  /// Set a Kapelle config value (admin only).
  Future<void> setKapelleConfig(
    String kapelleId,
    String key,
    dynamic wert,
  ) async {
    await _local.cacheConfig(
      key,
      ConfigEbene.kapelle,
      wert,
      referenzId: kapelleId,
    );
    try {
      await _api.putKapelleConfig(kapelleId, key, wert);
    } catch (_) {
      // Will sync later
    }
  }

  /// Reset a Kapelle config value to system default.
  Future<void> resetKapelleConfig(String kapelleId, String key) async {
    await _local.clearCache(ConfigEbene.kapelle, referenzId: kapelleId);
    try {
      await _api.deleteKapelleConfig(kapelleId, key);
    } catch (_) {
      // Will sync later
    }
  }

  /// Set a Nutzer config value.
  Future<void> setNutzerConfig(String key, dynamic wert) async {
    final existing = await _local.getCachedConfig(key, ConfigEbene.nutzer);
    final newVersion = (existing?.version ?? 0) + 1;

    await _local.cacheConfig(key, ConfigEbene.nutzer, wert, version: newVersion);

    // Queue for sync
    await _local.addPendingSyncEntry(PendingSyncEntry(
      schluessel: key,
      wert: wert,
      version: newVersion,
      timestamp: DateTime.now(),
    ));

    try {
      await _api.putNutzerConfig(key, wert);
      // Clear from pending queue on success
    } catch (_) {
      // Will sync later via delta-sync
    }
  }

  /// Reset a Nutzer config value (fall back to Kapelle/Default).
  Future<void> resetNutzerConfig(String key) async {
    final prefs = await _local.getCachedConfig(key, ConfigEbene.nutzer);
    if (prefs != null) {
      await _local.cacheConfig(key, ConfigEbene.nutzer, null);
    }
    try {
      await _api.deleteNutzerConfig(key);
    } catch (_) {
      // Will sync later
    }
  }

  /// Set a Gerät config value (local only, never synced).
  Future<void> setGeraetConfig(String key, dynamic wert) async {
    await _local.setGeraetConfig(key, wert);
  }

  /// Reset a Gerät config value.
  Future<void> resetGeraetConfig(String key) async {
    await _local.removeGeraetConfig(key);
  }

  /// Set a policy value (admin only).
  Future<void> setPolicy(
    String kapelleId,
    String key,
    dynamic wert,
  ) async {
    final policies = await _local.getCachedPolicies(kapelleId);
    policies[key] = ConfigPolicy(
      schluessel: key,
      wert: wert,
      enforced: wert is bool ? wert : wert != null,
      aktualisiertAm: DateTime.now(),
    );
    await _local.cachePolicies(kapelleId, policies);

    try {
      await _api.putPolicy(kapelleId, key, wert);
    } catch (_) {
      // Will sync later
    }
  }

  // ─── Sync ─────────────────────────────────────────────────────────────────

  /// Delta-sync: push pending changes, pull server changes.
  Future<void> syncNutzerConfig() async {
    final pending = await _local.getPendingSyncEntries();
    if (pending.isEmpty) return;

    try {
      final result = await _api.syncNutzerConfig(pending);
      await _local.clearPendingSyncEntries();

      // Apply server changes that won conflicts
      final serverChanges = result['server_changes'] as List<dynamic>? ?? [];
      for (final change in serverChanges) {
        final data = change as Map<String, dynamic>;
        await _local.cacheConfig(
          data['schluessel'] as String,
          ConfigEbene.nutzer,
          data['wert'],
          version: data['version'] as int? ?? 1,
        );
      }
    } catch (_) {
      // Will retry next time
    }
  }

  // ─── Policies Getter ──────────────────────────────────────────────────────

  Future<Map<String, ConfigPolicy>> getPolicies(String kapelleId) async {
    return _local.getCachedPolicies(kapelleId);
  }
}
