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
  final String? activeBandId;

  const ConfigState({
    this.resolved = const {},
    this.policies = const {},
    this.pendingUndo,
    this.isLoading = false,
    this.error,
    this.activeBandId,
  });

  ConfigState copyWith({
    Map<String, ResolvedConfigValue>? resolved,
    Map<String, ConfigPolicy>? policies,
    ConfigUndoAction? pendingUndo,
    bool? clearUndo,
    bool? isLoading,
    String? error,
    bool? clearError,
    String? activeBandId,
  }) =>
      ConfigState(
        resolved: resolved ?? this.resolved,
        policies: policies ?? this.policies,
        pendingUndo: clearUndo == true ? null : (pendingUndo ?? this.pendingUndo),
        isLoading: isLoading ?? this.isLoading,
        error: clearError == true ? null : (error ?? this.error),
        activeBandId: activeBandId ?? this.activeBandId,
      );

  /// Get a resolved value, falling back to system default.
  T getValue<T>(String key) {
    final entry = resolved[key];
    if (entry != null) return entry.value as T;
    return ConfigKeys.getDefault(key) as T;
  }

  /// Check if a key is locked by policy.
  bool isLocked(String key) => resolved[key]?.isLocked ?? false;

  /// Get the level a value comes from.
  ConfigLevel? getHerkunft(String key) => resolved[key]?.source;
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
  Future<void> initialize({String? bandId}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load all config levels
      if (bandId != null) {
        await Future.wait([
          _repo.loadBandConfig(bandId),
          _repo.loadPolicies(bandId),
        ]);
      }
      await _repo.loadUserConfig();

      // Resolve all known keys
      final resolved = <String, ResolvedConfigValue>{};
      for (final keyDef in ConfigKeys.allKeys) {
        resolved[keyDef.key] = await _repo.resolveConfig(
          keyDef.key,
          bandId: bandId,
        );
      }

      // Load policies
      final policies = bandId != null
          ? await _repo.getPolicies(bandId)
          : <String, ConfigPolicy>{};

      state = ConfigState(
        resolved: resolved,
        policies: policies,
        activeBandId: bandId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load configuration',
      );
    }
  }

  /// Update a config value with auto-save and undo support.
  Future<void> updateConfig(
    String key,
    dynamic newValue, {
    ConfigLevel? level,
  }) async {
    final keyDef = ConfigKeys.lookup(key);
    final targetEbene = level ?? keyDef?.level ?? ConfigLevel.user;
    final oldResolved = state.resolved[key];
    final oldValue = oldResolved?.value;

    // Cancel any pending undo
    _undoTimer?.cancel();

    // Store undo action
    final undoAction = ConfigUndoAction(
      key: key,
      level: targetEbene,
      oldValue: oldValue,
      newValue: newValue,
      timestamp: DateTime.now(),
    );

    // Write to appropriate level
    switch (targetEbene) {
      case ConfigLevel.band:
        if (state.activeBandId != null) {
          await _repo.setBandConfig(
              state.activeBandId!, key, newValue);
        }
      case ConfigLevel.user:
        await _repo.setUserConfig(key, newValue);
      case ConfigLevel.device:
        await _repo.setDeviceConfig(key, newValue);
    }

    // Re-resolve this key
    final newResolved = await _repo.resolveConfig(
      key,
      bandId: state.activeBandId,
    );

    final updatedMap = Map<String, ResolvedConfigValue>.from(state.resolved);
    updatedMap[key] = newResolved;

    state = state.copyWith(
      resolved: updatedMap,
      pendingUndo: undoAction,
    );

    // Auto-dismiss undo after 5 seconds
    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (state.pendingUndo?.key == key) {
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
    switch (undoAction.level) {
      case ConfigLevel.band:
        if (state.activeBandId != null) {
          if (undoAction.oldValue != null) {
            await _repo.setBandConfig(
              state.activeBandId!,
              undoAction.key,
              undoAction.oldValue,
            );
          } else {
            await _repo.resetBandConfig(
                state.activeBandId!, undoAction.key);
          }
        }
      case ConfigLevel.user:
        if (undoAction.oldValue != null) {
          await _repo.setUserConfig(
              undoAction.key, undoAction.oldValue);
        } else {
          await _repo.resetUserConfig(undoAction.key);
        }
      case ConfigLevel.device:
        if (undoAction.oldValue != null) {
          await _repo.setDeviceConfig(
              undoAction.key, undoAction.oldValue);
        } else {
          await _repo.resetDeviceConfig(undoAction.key);
        }
    }

    // Re-resolve
    final newResolved = await _repo.resolveConfig(
      undoAction.key,
      bandId: state.activeBandId,
    );

    final updatedMap = Map<String, ResolvedConfigValue>.from(state.resolved);
    updatedMap[undoAction.key] = newResolved;

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
    ConfigLevel level,
  ) async {
    await updateConfig(key, value, level: level);
  }

  /// Reset an override: remove the value at the specified level.
  Future<void> resetToParent(String key, ConfigLevel level) async {
    _undoTimer?.cancel();

    final oldResolved = state.resolved[key];

    switch (level) {
      case ConfigLevel.user:
        await _repo.resetUserConfig(key);
      case ConfigLevel.device:
        await _repo.resetDeviceConfig(key);
      case ConfigLevel.band:
        if (state.activeBandId != null) {
          await _repo.resetBandConfig(state.activeBandId!, key);
        }
    }

    // Re-resolve
    final newResolved = await _repo.resolveConfig(
      key,
      bandId: state.activeBandId,
    );

    final updatedMap = Map<String, ResolvedConfigValue>.from(state.resolved);
    updatedMap[key] = newResolved;

    state = state.copyWith(
      resolved: updatedMap,
      pendingUndo: ConfigUndoAction(
        key: key,
        level: level,
        oldValue: oldResolved?.value,
        newValue: null,
        timestamp: DateTime.now(),
      ),
    );

    _undoTimer = Timer(const Duration(seconds: 5), () {
      if (state.pendingUndo?.key == key) {
        state = state.copyWith(clearUndo: true);
      }
    });
  }

  /// Toggle a policy on/off (admin only).
  Future<void> togglePolicy(String policyKey, dynamic value) async {
    if (state.activeBandId == null) return;
    await _repo.setPolicy(state.activeBandId!, policyKey, value);

    // Reload policies and re-resolve all affected keys
    await _repo.loadPolicies(state.activeBandId!);
    final policies = await _repo.getPolicies(state.activeBandId!);

    // Re-resolve all keys that might be affected
    final resolved = <String, ResolvedConfigValue>{};
    for (final keyDef in ConfigKeys.allKeys) {
      resolved[keyDef.key] = await _repo.resolveConfig(
        keyDef.key,
        bandId: state.activeBandId,
      );
    }

    state = state.copyWith(
      resolved: resolved,
      policies: policies,
    );
  }

  /// Switch Kapelle context (for multi-Kapelle users).
  Future<void> switchBand(String bandId) async {
    await initialize(bandId: bandId);
  }

  /// Trigger delta-sync with server.
  Future<void> sync() async {
    try {
      await _repo.syncUserConfig();
    } catch (_) {
      // Silent failure, will retry
    }
  }
}
