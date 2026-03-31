// ─── Annotation Sync Models ──────────────────────────────────────────────────
//
// DTOs and operation models for the real-time annotation sync layer.
// Backend contract: src/Sheetstorm.Domain/Annotations/AnnotationModels.cs
// Enums serialize as int (ASP.NET Core default). Bbox fields are flat.

import 'dart:convert' as json_lib;

/// Operation type for annotation sync
enum AnnotationOpType {
  create,
  update,
  delete;

  String toJson() => name;

  static AnnotationOpType fromJson(String value) => switch (value) {
        'create' => AnnotationOpType.create,
        'update' => AnnotationOpType.update,
        'delete' => AnnotationOpType.delete,
        _ => throw ArgumentError('Unknown AnnotationOpType: $value'),
      };
}

/// Sync connection status
enum AnnotationSyncStatus {
  disconnected,
  connecting,
  connected,
  syncing,
  error,
}

// ─── Int↔String enum mapping (backend sends int) ────────────────────────────

const _toolNames = ['pencil', 'highlighter', 'text', 'stamp'];
const _levelNames = ['private', 'voice', 'orchestra'];

String _toolFromInt(int i) => i < _toolNames.length ? _toolNames[i] : 'pencil';
int _toolToInt(String s) {
  final idx = _toolNames.indexOf(s);
  return idx >= 0 ? idx : 0;
}

String _levelFromInt(int i) =>
    i < _levelNames.length ? _levelNames[i] : 'private';
int _levelToInt(String s) {
  final idx = _levelNames.indexOf(s);
  return idx >= 0 ? idx : 0;
}

// ─── BBoxDto ────────────────────────────────────────────────────────────────

/// Bounding box — internal convenience, serialized as flat fields on the wire.
class BBoxDto {
  const BBoxDto({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

// ─── StrokePointDto ─────────────────────────────────────────────────────────

/// Stroke point DTO for wire format
class StrokePointDto {
  const StrokePointDto({
    required this.x,
    required this.y,
    this.pressure = 0.5,
  });

  final double x;
  final double y;
  final double pressure;

  factory StrokePointDto.fromJson(Map<String, dynamic> json) => StrokePointDto(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        pressure: (json['pressure'] as num?)?.toDouble() ?? 0.5,
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'pressure': pressure,
      };
}

// ─── AnnotationElementDto ───────────────────────────────────────────────────

/// Wire DTO for a single annotation element (from/to server).
/// Backend uses flat bboxX/Y/Width/Height, int enums, and points as JSON string.
class AnnotationElementDto {
  const AnnotationElementDto({
    required this.id,
    required this.annotationId,
    required this.tool,
    required this.level,
    required this.bbox,
    this.points,
    this.text,
    this.stampCategory,
    this.stampValue,
    required this.opacity,
    required this.strokeWidth,
    required this.version,
    required this.isDeleted,
    this.createdByMusicianId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String annotationId;
  /// Stored as lowercase string internally (pencil/highlighter/text/stamp)
  final String tool;
  /// Stored as lowercase string internally (private/voice/orchestra)
  final String level;
  final BBoxDto bbox;
  final List<StrokePointDto>? points;
  final String? text;
  final String? stampCategory;
  final String? stampValue;
  final double opacity;
  final double strokeWidth;
  final int version;
  final bool isDeleted;
  final String? createdByMusicianId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AnnotationElementDto.fromJson(Map<String, dynamic> json) {
    // Backend sends points as a JSON string, not a list
    List<StrokePointDto>? points;
    final rawPoints = json['points'];
    if (rawPoints is String && rawPoints.isNotEmpty) {
      final decoded = json_lib.jsonDecode(rawPoints) as List<dynamic>;
      points = decoded
          .map((p) => StrokePointDto.fromJson(p as Map<String, dynamic>))
          .toList();
    } else if (rawPoints is List) {
      // Accept list format too for test flexibility
      points = rawPoints
          .map((p) => StrokePointDto.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    // Backend sends tool/level as int
    final toolValue = json['tool'];
    final levelValue = json['level'];

    return AnnotationElementDto(
      id: json['id'] as String,
      annotationId: json['annotationId'] as String,
      tool: toolValue is int ? _toolFromInt(toolValue) : toolValue as String,
      level:
          levelValue is int ? _levelFromInt(levelValue) : levelValue as String,
      bbox: BBoxDto(
        x: (json['bboxX'] as num).toDouble(),
        y: (json['bboxY'] as num).toDouble(),
        width: (json['bboxWidth'] as num).toDouble(),
        height: (json['bboxHeight'] as num).toDouble(),
      ),
      points: points,
      text: json['text'] as String?,
      stampCategory: json['stampCategory'] as String?,
      stampValue: json['stampValue'] as String?,
      opacity: (json['opacity'] as num).toDouble(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      version: (json['version'] as num).toInt(),
      isDeleted: json['isDeleted'] as bool,
      createdByMusicianId: json['createdByMusicianId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'annotationId': annotationId,
        'tool': _toolToInt(tool),
        'level': _levelToInt(level),
        'bboxX': bbox.x,
        'bboxY': bbox.y,
        'bboxWidth': bbox.width,
        'bboxHeight': bbox.height,
        'points': points != null
            ? json_lib.jsonEncode(points!.map((p) => p.toJson()).toList())
            : null,
        'text': text,
        'stampCategory': stampCategory,
        'stampValue': stampValue,
        'opacity': opacity,
        'strokeWidth': strokeWidth,
        'version': version,
        'isDeleted': isDeleted,
        'createdByMusicianId': createdByMusicianId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

// ─── AnnotationOp ───────────────────────────────────────────────────────────

/// A single annotation operation (for op-log sync)
class AnnotationOp {
  const AnnotationOp({
    required this.id,
    required this.type,
    required this.elementId,
    required this.annotationId,
    required this.userId,
    required this.timestamp,
    required this.version,
    this.data,
  });

  final String id;
  final AnnotationOpType type;
  final String elementId;
  final String annotationId;
  final String userId;
  final DateTime timestamp;
  final int version;
  final Map<String, dynamic>? data;

  factory AnnotationOp.fromJson(Map<String, dynamic> json) => AnnotationOp(
        id: json['id'] as String,
        type: AnnotationOpType.fromJson(json['type'] as String),
        elementId: json['elementId'] as String,
        annotationId: json['annotationId'] as String,
        userId: json['userId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        version: json['version'] as int? ?? 0,
        data: json['data'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toJson(),
        'elementId': elementId,
        'annotationId': annotationId,
        'userId': userId,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'version': version,
        if (data != null) 'data': data,
      };

  /// LWW conflict resolution: newer timestamp wins;
  /// equal timestamps → higher version wins.
  static AnnotationOp resolveConflict(AnnotationOp a, AnnotationOp b) {
    final cmp = a.timestamp.compareTo(b.timestamp);
    if (cmp != 0) return cmp > 0 ? a : b;
    return a.version >= b.version ? a : b;
  }

  /// Two ops conflict when they target the same element but come from
  /// different users with the same base version.
  static bool isConflict(AnnotationOp a, AnnotationOp b) {
    if (a.elementId != b.elementId) return false;
    if (a.userId == b.userId) return false;
    return a.version == b.version;
  }
}

// ─── SyncVersion ────────────────────────────────────────────────────────────

/// Tracks the last known server sync version for delta pulls
class SyncVersion {
  const SyncVersion({
    required this.version,
    required this.lastSyncedAt,
  });

  final int version;
  final DateTime lastSyncedAt;

  factory SyncVersion.initial() => SyncVersion(
        version: 0,
        lastSyncedAt: DateTime.utc(1970),
      );

  factory SyncVersion.fromJson(Map<String, dynamic> json) => SyncVersion(
        version: json['version'] as int,
        lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastSyncedAt': lastSyncedAt.toUtc().toIso8601String(),
      };
}

// ─── ElementChangeNotification ──────────────────────────────────────────────

/// Notification sent via SignalR when an element changes.
/// Backend uses `changeType` (string), not `type`.
class ElementChangeNotification {
  const ElementChangeNotification({
    required this.changeType,
    this.element,
    this.elementId,
    this.annotationId,
  });

  /// One of: 'create', 'update', 'delete'
  final String changeType;
  final AnnotationElementDto? element;
  final String? elementId;
  final String? annotationId;

  factory ElementChangeNotification.fromJson(Map<String, dynamic> json) {
    final elementJson = json['element'] as Map<String, dynamic>?;
    return ElementChangeNotification(
      changeType: json['changeType'] as String,
      element: elementJson != null
          ? AnnotationElementDto.fromJson(elementJson)
          : null,
      elementId: json['elementId'] as String?,
      annotationId: json['annotationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'changeType': changeType,
        if (element != null) 'element': element!.toJson(),
        if (elementId != null) 'elementId': elementId,
        if (annotationId != null) 'annotationId': annotationId,
      };
}
