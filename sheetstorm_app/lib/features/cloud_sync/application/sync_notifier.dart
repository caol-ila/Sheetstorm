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
      state = state.copyWith(status: SyncStatus.idle);
    }
  }

  // ─── Pending change tracking ────────────────────────────────────────────────

  void addPendingChange() {
    state = state.copyWith(pendingChanges: state.pendingChanges + 1);
  }

  // ─── Full sync cycle ────────────────────────────────────────────────────────

  /// Runs a full sync: fetches server state, then pulls remote deltas.
  /// Skips if a sync is already in progress.
  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;

    state = state.copyWith(status: SyncStatus.syncing);
    try {
      final service = ref.read(syncServiceProvider);

      final remoteState = await service.getSyncState();
      await service.pull(state.lastSyncAt);

      final newStatus = remoteState.conflicts.isNotEmpty
          ? SyncStatus.conflict
          : SyncStatus.synced;

      state = state.copyWith(
        status: newStatus,
        lastSyncAt: DateTime.now(),
        pendingChanges: remoteState.pendingChanges,
        conflicts: remoteState.conflicts,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ─── Push ───────────────────────────────────────────────────────────────────

  /// Pushes local deltas to the server.
  Future<bool> push(List<SyncDelta> deltas) async {
    try {
      final service = ref.read(syncServiceProvider);
      await service.push(deltas);
      final newPending =
          (state.pendingChanges - deltas.length).clamp(0, state.pendingChanges);
      state = state.copyWith(pendingChanges: newPending);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  // ─── Pull ───────────────────────────────────────────────────────────────────

  /// Pulls remote deltas since last sync.
  Future<bool> pull() async {
    try {
      final service = ref.read(syncServiceProvider);
      await service.pull(state.lastSyncAt);
      state = state.copyWith(
        lastSyncAt: DateTime.now(),
        status: SyncStatus.synced,
        errorMessage: null,
      );
      return true;
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
}
