import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';

// ─── ConflictInfo ───────────────────────────────────────────────────────────

/// Tracks the most recent LWW conflict for UI display
class ConflictInfo {
  const ConflictInfo({
    required this.elementId,
    required this.winnerUserId,
    required this.loserUserId,
    required this.resolvedAt,
  });

  final String elementId;
  final String winnerUserId;
  final String loserUserId;
  final DateTime resolvedAt;
}

// ─── State ──────────────────────────────────────────────────────────────────

class AnnotationSyncState {
  const AnnotationSyncState({
    this.status = AnnotationSyncStatus.disconnected,
    this.offlineQueue = const [],
    this.syncVersion = const _DefaultSyncVersion(),
    this.error,
    this.remoteElements = const [],
    this.activeEditors = const {},
    this.lastConflict,
  });

  final AnnotationSyncStatus status;
  final List<AnnotationOp> offlineQueue;
  final SyncVersion syncVersion;
  final String? error;
  final List<AnnotationElementDto> remoteElements;

  /// Map of userId → elementId for users currently editing
  final Map<String, String> activeEditors;
  final ConflictInfo? lastConflict;

  bool get isOnline =>
      status == AnnotationSyncStatus.connected ||
      status == AnnotationSyncStatus.syncing;

  int get pendingOpsCount => offlineQueue.length;

  AnnotationSyncState copyWith({
    AnnotationSyncStatus? status,
    List<AnnotationOp>? offlineQueue,
    SyncVersion? syncVersion,
    String? error,
    bool clearError = false,
    List<AnnotationElementDto>? remoteElements,
    Map<String, String>? activeEditors,
    ConflictInfo? lastConflict,
    bool clearConflict = false,
  }) =>
      AnnotationSyncState(
        status: status ?? this.status,
        offlineQueue: offlineQueue ?? this.offlineQueue,
        syncVersion: syncVersion ?? this.syncVersion,
        error: clearError ? null : (error ?? this.error),
        remoteElements: remoteElements ?? this.remoteElements,
        activeEditors: activeEditors ?? this.activeEditors,
        lastConflict:
            clearConflict ? null : (lastConflict ?? this.lastConflict),
      );
}

/// Sentinel class for default SyncVersion in const constructors
class _DefaultSyncVersion implements SyncVersion {
  const _DefaultSyncVersion();

  @override
  int get version => 0;

  @override
  DateTime get lastSyncedAt => DateTime.utc(1970);

  @override
  Map<String, dynamic> toJson() => {
        'version': version,
        'lastSyncedAt': lastSyncedAt.toUtc().toIso8601String(),
      };
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class AnnotationSyncNotifier extends Notifier<AnnotationSyncState> {
  @override
  AnnotationSyncState build() => const AnnotationSyncState();

  // ── Status ─────────────────────────────────────────────────────────────

  void setStatus(AnnotationSyncStatus status) {
    state = state.copyWith(status: status);
  }

  void setError(String message) {
    state = state.copyWith(
      status: AnnotationSyncStatus.error,
      error: message,
    );
  }

  void clearError() {
    state = state.copyWith(
      status: AnnotationSyncStatus.disconnected,
      clearError: true,
    );
  }

  // ── Offline Queue ──────────────────────────────────────────────────────

  void enqueueOp(AnnotationOp op) {
    state = state.copyWith(offlineQueue: [...state.offlineQueue, op]);
  }

  void clearQueue() {
    state = state.copyWith(offlineQueue: []);
  }

  /// Returns all queued ops and clears the queue
  List<AnnotationOp> dequeueOps() {
    final ops = List<AnnotationOp>.from(state.offlineQueue);
    state = state.copyWith(offlineQueue: []);
    return ops;
  }

  // ── Remote Element Application ─────────────────────────────────────────

  void applyRemoteAdd(AnnotationElementDto element) {
    if (state.remoteElements.any((e) => e.id == element.id)) return;
    state = state.copyWith(
      remoteElements: [...state.remoteElements, element],
    );
  }

  void applyRemoteUpdate(AnnotationElementDto element) {
    final idx = state.remoteElements.indexWhere((e) => e.id == element.id);
    if (idx == -1) return;

    // Ignore older versions
    if (element.version <= state.remoteElements[idx].version) return;

    final updated = [...state.remoteElements];
    updated[idx] = element;
    state = state.copyWith(remoteElements: updated);
  }

  void applyRemoteDelete(String elementId) {
    final updated =
        state.remoteElements.where((e) => e.id != elementId).toList();
    if (updated.length == state.remoteElements.length) return;
    state = state.copyWith(remoteElements: updated);
  }

  // ── Bulk Sync ──────────────────────────────────────────────────────────

  void applyBulkSync(List<AnnotationElementDto> elements, int version) {
    final alive = elements.where((e) => !e.isDeleted).toList();
    state = state.copyWith(
      remoteElements: alive,
      syncVersion: SyncVersion(
        version: version,
        lastSyncedAt: DateTime.now().toUtc(),
      ),
    );
  }

  // ── SyncVersion ────────────────────────────────────────────────────────

  void updateSyncVersion(int version) {
    state = state.copyWith(
      syncVersion: SyncVersion(
        version: version,
        lastSyncedAt: DateTime.now().toUtc(),
      ),
    );
  }

  // ── Active Editors (Presence) ──────────────────────────────────────────

  void setActiveEditor(String userId, String elementId) {
    state = state.copyWith(
      activeEditors: {...state.activeEditors, userId: elementId},
    );
  }

  void removeActiveEditor(String userId) {
    final editors = Map<String, String>.from(state.activeEditors);
    editors.remove(userId);
    state = state.copyWith(activeEditors: editors);
  }

  void clearActiveEditors() {
    state = state.copyWith(activeEditors: {});
  }

  // ── Conflict Tracking ─────────────────────────────────────────────────

  void recordConflict(ConflictInfo conflict) {
    state = state.copyWith(lastConflict: conflict);
  }

  void dismissConflict() {
    state = state.copyWith(clearConflict: true);
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final annotationSyncNotifierProvider =
    NotifierProvider<AnnotationSyncNotifier, AnnotationSyncState>(
  () => AnnotationSyncNotifier(),
);
