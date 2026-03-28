/// Config Notifier — state management for the 3-level config system — Issue #35
///
/// Manages resolved config state, auto-save, undo, and sync.

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/config/data/repositories/config_repository.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';

part 'config_notifier.g.dart';

/// State for the configuration system.
class ConfigState {
  final Map<String, ResolvedConfigValue> resolved;
  final Map<String, ConfigPolicy> policies;
  final ConfigUndoAction? pendingUndo;
  final bool isLoading;
  final String? error;
  final String? activeKapelleId;

  const ConfigState({
    this.resolved = const {},
    this.policies = const {},
    this.pendingUndo,
    this.isLoading = false,
    this.error,
    this.activeKapelleId,
  });

  ConfigState copyWith({
    Map<String, ResolvedConfigValue>? resolved,
    Map<String, ConfigPolicy>? policies,
    ConfigUndoAction? pendingUndo,
    bool? clearUndo,
    bool? isLoading,
    String? error,
    bool? clearError,
    String? activeKapelleId,
  }) =>
      ConfigState(
        resolved: resolved ?? this.resolved,
        policies: policies ?? this.policies,
        pendingUndo: clearUndo == true ? null : (pendingUndo ?? this.pendingUndo),
        isLoading: isLoading ?? this.isLoading,
        error: clearError == true ? null : (error ?? this.error),
        activeKapelleId: activeKapelleId ?? this.activeKapelleId,
      );

  /// Get a resolved value, falling back to system default.
  T getValue<T>(String key) {
    final entry = resolved[key];
    if (entry != null) return entry.wert as T;
    return ConfigKeys.getDefault(key) as T;
  }

  /// Check if a key is locked by policy.
  bool isLocked(String key) => resolved[key]?.istGesperrt ?? false;

  /// Get the level a value comes from.
  ConfigEbene? getHerkunft(String key) => resolved[key]?.herkunft;
}

@Riverpod(keepAlive: true)
class ConfigNotifier extends _$ConfigNotifier {
  Timer? _undoTimer;
  Timer? _syncTimer;

  @override
  ConfigState build() {
    ref.onDispose(() {
      _undoTimer?.cancel();
      _syncTimer?.cancel();
    });
    // Start periodic sync every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => sync());
    return const ConfigState(isLoading: true);
  }

  ConfigRepository get _repo => ref.read(configRepositoryProvider);

  /// Initialize config for a given Kapelle context.
  Future<void> initialize({String? kapelleId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load all config levels
      if (kapelleId != null) {
        await Future.wait([
          _repo.loadKapelleConfig(kapelleId),
          _repo.loadPolicies(kapelleId),
        ]);
      }
      await _repo.loadNutzerConfig();

      // Resolve all known keys
      final resolved = <String, ResolvedConfigValue>{};
      for (final keyDef in ConfigKeys.allKeys) {
        resolved[keyDef.schluessel] = await _repo.resolveConfig(
          keyDef.schluessel,
          kapelleId: kapelleId,
        );
      }

      // Load policies
      final policies = kapelleId != null
          ? await _repo.getPolicies(kapelleId)
          : <String, ConfigPolicy>{};

      state = ConfigState(
        resolved: resolved,
        policies: policies,
        activeKapelleId: kapelleId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Konfiguration konnte nicht geladen werden',
      );
    }
  }

  /// Update a config value with auto-save and undo support.
  Future<void> updateConfig(
    String key,
    dynamic newValue, {
    ConfigEbene? ebene,
  }) async {
    final keyDef = ConfigKeys.lookup(key);
    final targetEbene = ebene ?? keyDef?.ebene ?? ConfigEbene.nutzer;
    final oldResolved = state.resolved[key];
    final oldValue = oldResolved?.wert;

    // Cancel any pending undo
    _undoTimer?.cancel();

    // Store undo action
    final undoAction = ConfigUndoAction(
      schluessel: key,
      ebene: targetEbene,
      alterWert: oldValue,
      neuerWert: newValue,
      zeitstempel: DateTime.now(),
    );

    // Write to appropriate level
    switch (targetEbene) {
      case ConfigEbene.kapelle:
        if (state.activeKapelleId != null) {
          await _repo.setKapelleConfig(
              state.activeKapelleId!, key, newValue);
        }
      case ConfigEbene.nutzer:
        await _repo.setNutzerConfig(key, newValue);
      case ConfigEbene.geraet:
        await _repo.setGeraetConfig(key, newValue);
    }

    // Re-resolve this key
    final newResolved = await _repo.resolveConfig(
      key,
      kapelleId: state.activeKapelleId,
    );

    final updatedMap = Map<String, ResolvedConfigValue>.from(state.resolved);
    updatedMap[key] = newResolved;

    state = state.copyWith(
      resolved: updatedMap,
      pendingUndo: undoAction,
    );

    // Auto-dismiss undo after 5 seconds
    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (state.pendingUndo?.schluessel == key) {
        state = state.copyWith(clearUndo: true);
      }
    });
  }

  /// Undo the last config change.
  Future<void> undo() async {
    final undoAction = state.pendingUndo;
    if (undoAction == null) return;

    _undoTimer?.cancel();

    // Restore old value
    switch (undoAction.ebene) {
      case ConfigEbene.kapelle:
        if (state.activeKapelleId != null) {
          if (undoAction.alterWert != null) {
            await _repo.setKapelleConfig(
              state.activeKapelleId!,
              undoAction.schluessel,
              undoAction.alterWert,
            );
          } else {
            await _repo.resetKapelleConfig(
                state.activeKapelleId!, undoAction.schluessel);
          }
        }
      case ConfigEbene.nutzer:
        if (undoAction.alterWert != null) {
          await _repo.setNutzerConfig(
              undoAction.schluessel, undoAction.alterWert);
        } else {
          await _repo.resetNutzerConfig(undoAction.schluessel);
        }
      case ConfigEbene.geraet:
        if (undoAction.alterWert != null) {
          await _repo.setGeraetConfig(
              undoAction.schluessel, undoAction.alterWert);
        } else {
          await _repo.resetGeraetConfig(undoAction.schluessel);
        }
    }

    // Re-resolve
    final newResolved = await _repo.resolveConfig(
      undoAction.schluessel,
      kapelleId: state.activeKapelleId,
    );

    final updatedMap = Map<String, ResolvedConfigValue>.from(state.resolved);
    updatedMap[undoAction.schluessel] = newResolved;

    state = state.copyWith(
      resolved: updatedMap,
      clearUndo: true,
    );
  }

  /// Dismiss the undo toast without undoing.
  void dismissUndo() {
    _undoTimer?.cancel();
    state = state.copyWith(clearUndo: true);
  }

  /// Override a setting: set it on a specific level (typically user or device).
  Future<void> overrideAtLevel(
    String key,
    dynamic value,
    ConfigEbene ebene,
  ) async {
    await updateConfig(key, value, ebene: ebene);
  }

  /// Reset an override: remove the value at the specified level.
  Future<void> resetToParent(String key, ConfigEbene ebene) async {
    _undoTimer?.cancel();

    final oldResolved = state.resolved[key];

    switch (ebene) {
      case ConfigEbene.nutzer:
        await _repo.resetNutzerConfig(key);
      case ConfigEbene.geraet:
        await _repo.resetGeraetConfig(key);
      case ConfigEbene.kapelle:
        if (state.activeKapelleId != null) {
          await _repo.resetKapelleConfig(state.activeKapelleId!, key);
        }
    }

    // Re-resolve
    final newResolved = await _repo.resolveConfig(
      key,
      kapelleId: state.activeKapelleId,
    );

    final updatedMap = Map<String, ResolvedConfigValue>.from(state.resolved);
    updatedMap[key] = newResolved;

    state = state.copyWith(
      resolved: updatedMap,
      pendingUndo: ConfigUndoAction(
        schluessel: key,
        ebene: ebene,
        alterWert: oldResolved?.wert,
        neuerWert: null,
        zeitstempel: DateTime.now(),
      ),
    );

    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (state.pendingUndo?.schluessel == key) {
        state = state.copyWith(clearUndo: true);
      }
    });
  }

  /// Toggle a policy on/off (admin only).
  Future<void> togglePolicy(String policyKey, dynamic value) async {
    if (state.activeKapelleId == null) return;
    await _repo.setPolicy(state.activeKapelleId!, policyKey, value);

    // Reload policies and re-resolve all affected keys
    await _repo.loadPolicies(state.activeKapelleId!);
    final policies = await _repo.getPolicies(state.activeKapelleId!);

    // Re-resolve all keys that might be affected
    final resolved = <String, ResolvedConfigValue>{};
    for (final keyDef in ConfigKeys.allKeys) {
      resolved[keyDef.schluessel] = await _repo.resolveConfig(
        keyDef.schluessel,
        kapelleId: state.activeKapelleId,
      );
    }

    state = state.copyWith(
      resolved: resolved,
      policies: policies,
    );
  }

  /// Switch Kapelle context (for multi-Kapelle users).
  Future<void> switchKapelle(String kapelleId) async {
    await initialize(kapelleId: kapelleId);
  }

  /// Trigger delta-sync with server.
  Future<void> sync() async {
    try {
      await _repo.syncNutzerConfig();
    } catch (_) {
      // Silent failure, will retry
    }
  }
}
