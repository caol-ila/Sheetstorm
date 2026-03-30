import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, synced, conflict, offline, error }

// ─── SyncVersion ─────────────────────────────────────────────────────────────

/// Vector-clock versioning info for a sync delta.
class SyncVersion extends Equatable {
  const SyncVersion({
    required this.deviceId,
    required this.timestamp,
    this.vectorClock = const {},
  });

  final String deviceId;
  final DateTime timestamp;
  final Map<String, int> vectorClock;

  factory SyncVersion.fromJson(Map<String, dynamic> json) {
    final clock = (json['vectorClock'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    return SyncVersion(
      deviceId: json['deviceId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vectorClock: clock,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'timestamp': timestamp.toIso8601String(),
        'vectorClock': vectorClock,
      };

  @override
  List<Object?> get props => [deviceId, timestamp, vectorClock];
}

// ─── SyncDelta ────────────────────────────────────────────────────────────────

/// A single change unit for delta-sync.
class SyncDelta extends Equatable {
  const SyncDelta({
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.version,
    this.payload = const {},
  });

  final String entityType;
  final String entityId;

  /// One of: 'create', 'update', 'delete'
  final String operation;

  final SyncVersion version;
  final Map<String, dynamic> payload;

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      version: SyncVersion.fromJson(json['version'] as Map<String, dynamic>),
      payload: (json['payload'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'version': version.toJson(),
        'payload': payload,
      };

  @override
  List<Object?> get props => [entityType, entityId, operation, version, payload];
}

// ─── SyncConflict ─────────────────────────────────────────────────────────────

/// A detected sync conflict with LWW resolution metadata.
class SyncConflict extends Equatable {
  const SyncConflict({
    required this.entityType,
    required this.entityId,
    required this.localDelta,
    required this.serverDelta,
    required this.resolvedWith,
  });

  final String entityType;
  final String entityId;
  final SyncDelta localDelta;
  final SyncDelta serverDelta;

  /// 'server' or 'local' — which version was kept (Last-Write-Wins)
  final String resolvedWith;

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      localDelta: SyncDelta.fromJson(json['localDelta'] as Map<String, dynamic>),
      serverDelta:
          SyncDelta.fromJson(json['serverDelta'] as Map<String, dynamic>),
      resolvedWith: json['resolvedWith'] as String? ?? 'server',
    );
  }

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'localDelta': localDelta.toJson(),
        'serverDelta': serverDelta.toJson(),
        'resolvedWith': resolvedWith,
      };

  @override
  List<Object?> get props =>
      [entityType, entityId, localDelta, serverDelta, resolvedWith];
}

// ─── SyncState ────────────────────────────────────────────────────────────────

/// Local sync state tracked by SyncNotifier.
class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncAt,
    this.pendingChanges = 0,
    this.conflicts = const [],
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSyncAt;
  final int pendingChanges;
  final List<SyncConflict> conflicts;
  final String? errorMessage;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isOffline => status == SyncStatus.offline;
  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    int? pendingChanges,
    List<SyncConflict>? conflicts,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflicts: conflicts ?? this.conflicts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, lastSyncAt, pendingChanges, conflicts, errorMessage];
}

// ─── SyncStateResponse ────────────────────────────────────────────────────────

/// DTO from GET /api/sync/state
class SyncStateResponse {
  const SyncStateResponse({
    this.lastSyncAt,
    this.pendingChanges = 0,
    this.conflicts = const [],
  });

  final DateTime? lastSyncAt;
  final int pendingChanges;
  final List<SyncConflict> conflicts;

  factory SyncStateResponse.fromJson(Map<String, dynamic> json) {
    final lastSyncAtStr = json['lastSyncAt'] as String?;
    return SyncStateResponse(
      lastSyncAt: lastSyncAtStr != null ? DateTime.parse(lastSyncAtStr) : null,
      pendingChanges: json['pendingChanges'] as int? ?? 0,
      conflicts: (json['conflicts'] as List<dynamic>? ?? [])
          .map((c) => SyncConflict.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
