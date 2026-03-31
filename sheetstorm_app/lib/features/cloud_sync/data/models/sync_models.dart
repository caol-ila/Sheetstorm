import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, synced, conflict, offline, error }

// ─── SyncChangeEntry (received from server via pull) ─────────────────────────

/// Matches backend SyncChangeEntry from PullResponse.
class SyncChangeEntry extends Equatable {
  const SyncChangeEntry({
    required this.version,
    required this.entityType,
    required this.entityId,
    required this.operation,
    this.fieldName,
    this.newValue,
    this.fields,
    required this.changedAt,
  });

  final int version;
  final String entityType;
  final String entityId;
  final String operation;
  final String? fieldName;
  final String? newValue;
  final Map<String, String>? fields;
  final DateTime changedAt;

  factory SyncChangeEntry.fromJson(Map<String, dynamic> json) {
    return SyncChangeEntry(
      version: (json['version'] as num).toInt(),
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      fieldName: json['fieldName'] as String?,
      newValue: json['newValue'] as String?,
      fields: (json['fields'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }

  @override
  List<Object?> get props =>
      [version, entityType, entityId, operation, fieldName, newValue, fields, changedAt];
}

// ─── SyncDelta (sent to server via push) ─────────────────────────────────────

/// Matches backend PushChangeEntry.
class SyncDelta extends Equatable {
  const SyncDelta({
    required this.clientChangeId,
    required this.entityType,
    this.entityId,
    required this.operation,
    this.fieldName,
    this.newValue,
    this.fields,
    required this.changedAt,
  });

  final String clientChangeId;
  final String entityType;
  final String? entityId;
  final String operation;
  final String? fieldName;
  final String? newValue;
  final Map<String, String>? fields;
  final DateTime changedAt;

  Map<String, dynamic> toJson() => {
        'clientChangeId': clientChangeId,
        'entityType': entityType,
        if (entityId != null) 'entityId': entityId,
        'operation': operation,
        if (fieldName != null) 'fieldName': fieldName,
        if (newValue != null) 'newValue': newValue,
        if (fields != null) 'fields': fields,
        'changedAt': changedAt.toIso8601String(),
      };

  @override
  List<Object?> get props =>
      [clientChangeId, entityType, entityId, operation, fieldName, newValue, fields, changedAt];
}

// ─── AcceptedChange ─────────────────────────────────────────────────────────

/// Matches backend AcceptedChange from PushResponse.
class AcceptedChange {
  const AcceptedChange({
    required this.clientChangeId,
    required this.serverVersion,
    required this.serverEntityId,
  });

  final String clientChangeId;
  final int serverVersion;
  final String serverEntityId;

  factory AcceptedChange.fromJson(Map<String, dynamic> json) => AcceptedChange(
        clientChangeId: json['clientChangeId'] as String,
        serverVersion: (json['serverVersion'] as num).toInt(),
        serverEntityId: json['serverEntityId'] as String,
      );
}

// ─── SyncConflict ─────────────────────────────────────────────────────────────

/// Matches backend ConflictEntry from PushResponse.
class SyncConflict extends Equatable {
  const SyncConflict({
    required this.clientChangeId,
    required this.entityType,
    required this.entityId,
    this.fieldName,
    this.clientValue,
    this.serverValue,
    required this.serverChangedAt,
    required this.resolution,
  });

  final String clientChangeId;
  final String entityType;
  final String entityId;
  final String? fieldName;
  final String? clientValue;
  final String? serverValue;
  final DateTime serverChangedAt;
  final String resolution;

  factory SyncConflict.fromJson(Map<String, dynamic> json) => SyncConflict(
        clientChangeId: json['clientChangeId'] as String,
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        fieldName: json['fieldName'] as String?,
        clientValue: json['clientValue'] as String?,
        serverValue: json['serverValue'] as String?,
        serverChangedAt: DateTime.parse(json['serverChangedAt'] as String),
        resolution: json['resolution'] as String,
      );

  @override
  List<Object?> get props => [
        clientChangeId, entityType, entityId, fieldName,
        clientValue, serverValue, serverChangedAt, resolution,
      ];
}

// ─── PullResponse ───────────────────────────────────────────────────────────

/// Matches backend PullResponse.
class PullResponse {
  const PullResponse({
    required this.changes,
    required this.currentVersion,
    required this.hasMore,
  });

  final List<SyncChangeEntry> changes;
  final int currentVersion;
  final bool hasMore;

  factory PullResponse.fromJson(Map<String, dynamic> json) => PullResponse(
        changes: (json['changes'] as List<dynamic>)
            .map((e) => SyncChangeEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentVersion: (json['currentVersion'] as num).toInt(),
        hasMore: json['hasMore'] as bool,
      );
}

// ─── PushResponse ───────────────────────────────────────────────────────────

/// Matches backend PushResponse.
class PushResponse {
  const PushResponse({
    required this.accepted,
    required this.conflicts,
    required this.newVersion,
  });

  final List<AcceptedChange> accepted;
  final List<SyncConflict> conflicts;
  final int newVersion;

  factory PushResponse.fromJson(Map<String, dynamic> json) => PushResponse(
        accepted: (json['accepted'] as List<dynamic>)
            .map((e) => AcceptedChange.fromJson(e as Map<String, dynamic>))
            .toList(),
        conflicts: (json['conflicts'] as List<dynamic>)
            .map((e) => SyncConflict.fromJson(e as Map<String, dynamic>))
            .toList(),
        newVersion: (json['newVersion'] as num).toInt(),
      );
}

// ─── SyncState ────────────────────────────────────────────────────────────────

/// Local sync state tracked by SyncNotifier.
class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncAt,
    this.currentVersion = 0,
    this.pendingServerChanges = 0,
    this.conflicts = const [],
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSyncAt;
  final int currentVersion;
  final int pendingServerChanges;
  final List<SyncConflict> conflicts;
  final String? errorMessage;

  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isOffline => status == SyncStatus.offline;
  bool get isSyncing => status == SyncStatus.syncing;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncAt,
    int? currentVersion,
    int? pendingServerChanges,
    List<SyncConflict>? conflicts,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      currentVersion: currentVersion ?? this.currentVersion,
      pendingServerChanges: pendingServerChanges ?? this.pendingServerChanges,
      conflicts: conflicts ?? this.conflicts,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, lastSyncAt, currentVersion, pendingServerChanges, conflicts, errorMessage];
}

// ─── SyncStateResponse ────────────────────────────────────────────────────────

/// DTO from GET /api/sync/state — matches backend SyncStateResponse.
class SyncStateResponse {
  const SyncStateResponse({
    required this.currentVersion,
    this.lastSyncAt,
    this.pendingServerChanges = 0,
  });

  final int currentVersion;
  final DateTime? lastSyncAt;
  final int pendingServerChanges;

  factory SyncStateResponse.fromJson(Map<String, dynamic> json) {
    return SyncStateResponse(
      currentVersion: (json['currentVersion'] as num).toInt(),
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.parse(json['lastSyncAt'] as String)
          : null,
      pendingServerChanges:
          (json['pendingServerChanges'] as num?)?.toInt() ?? 0,
    );
  }
}
