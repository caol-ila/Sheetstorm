import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/features/cloud_sync/data/services/sync_service.dart';

part 'sync_notifier.g.dart';

@Riverpod(keepAlive: true)
class SyncNotifier extends _$SyncNotifier {
  @override
  SyncState build() => const SyncState();

  // ─── Connectivity ───────────────────────────────────────────────────────────

  void setOffline() {
    state = state.copyWith(status: SyncStatus.offline);
  }

  void setOnline() {
    if (state.status == SyncStatus.offline) {
      state = state.copyWith(status: SyncStatus.idle, clearError: true);
    }
  }

  // ─── Full sync cycle ────────────────────────────────────────────────────────

  /// Runs a full sync: fetches server state, then pulls remote changes.
  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing, clearError: true);
    try {
      final service = ref.read(syncServiceProvider);

      final remoteState = await service.getSyncState();
      final pullResult = await service.pull(state.currentVersion);

      state = state.copyWith(
        status: SyncStatus.synced,
        lastSyncAt: DateTime.now(),
        currentVersion: pullResult.currentVersion,
        pendingServerChanges: remoteState.pendingServerChanges,
      );
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        state = state.copyWith(
          status: SyncStatus.offline,
          errorMessage: 'Keine Verbindung zum Server',
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.message ?? e.toString(),
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ─── Push ───────────────────────────────────────────────────────────────────

  /// Pushes local deltas to the server. Returns PushResponse or null on error.
  Future<PushResponse?> push(List<SyncDelta> deltas) async {
    try {
      final service = ref.read(syncServiceProvider);
      final result = await service.push(state.currentVersion, deltas);

      final newStatus = result.conflicts.isNotEmpty
          ? SyncStatus.conflict
          : state.status;

      state = state.copyWith(
        currentVersion: result.newVersion,
        conflicts: result.conflicts.isNotEmpty
            ? result.conflicts
            : state.conflicts,
        status: newStatus,
      );
      return result;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        state = state.copyWith(
          status: SyncStatus.offline,
          errorMessage: 'Keine Verbindung zum Server',
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.message ?? e.toString(),
        );
      }
      return null;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  // ─── Pull ───────────────────────────────────────────────────────────────────

  /// Pulls remote changes since last known version.
  Future<bool> pull() async {
    try {
      final service = ref.read(syncServiceProvider);
      final result = await service.pull(state.currentVersion);
      state = state.copyWith(
        lastSyncAt: DateTime.now(),
        currentVersion: result.currentVersion,
        status: SyncStatus.synced,
        clearError: true,
      );
      return true;
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        state = state.copyWith(
          status: SyncStatus.offline,
          errorMessage: 'Keine Verbindung zum Server',
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.message ?? e.toString(),
        );
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ─── Conflict resolution ────────────────────────────────────────────────────

  /// Dismisses a conflict (LWW already resolved server-side).
  void resolveConflict(String entityId) {
    final updated =
        state.conflicts.where((c) => c.entityId != entityId).toList();
    final newStatus = updated.isEmpty && state.status == SyncStatus.conflict
        ? SyncStatus.synced
        : state.status;
    state = state.copyWith(conflicts: updated, status: newStatus);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static bool _isNetworkError(DioException e) =>
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout;
}
