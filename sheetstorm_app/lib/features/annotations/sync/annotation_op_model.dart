// ─── Annotation Sync Models ──────────────────────────────────────────────────
//
// DTOs and operation models for the real-time annotation sync layer.
// Wire format uses camelCase JSON keys per API convention.

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

// ─── BBoxDto ────────────────────────────────────────────────────────────────

/// Bounding box DTO for wire format
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

  factory BBoxDto.fromJson(Map<String, dynamic> json) => BBoxDto(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
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

/// Wire DTO for a single annotation element (from/to server)
class AnnotationElementDto {
  const AnnotationElementDto({
    required this.id,
    required this.annotationId,
    required this.tool,
    required this.level,
    required this.pageIndex,
    required this.bbox,
    this.points,
    this.text,
    this.stampCategory,
    this.stampValue,
    required this.opacity,
    required this.strokeWidth,
    required this.version,
    required this.isDeleted,
    this.userId,
    required this.createdAt,
    required this.changedAt,
  });

  final String id;
  final String annotationId;
  final String tool;
  final String level;
  final int pageIndex;
  final BBoxDto bbox;
  final List<StrokePointDto>? points;
  final String? text;
  final String? stampCategory;
  final String? stampValue;
  final double opacity;
  final double strokeWidth;
  final int version;
  final bool isDeleted;
  final String? userId;
  final DateTime createdAt;
  final DateTime changedAt;

  factory AnnotationElementDto.fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>?;
    return AnnotationElementDto(
      id: json['id'] as String,
      annotationId: json['annotationId'] as String,
      tool: json['tool'] as String,
      level: json['level'] as String,
      pageIndex: json['pageIndex'] as int,
      bbox: BBoxDto.fromJson(json['bbox'] as Map<String, dynamic>),
      points: pointsJson
          ?.map((p) => StrokePointDto.fromJson(p as Map<String, dynamic>))
          .toList(),
      text: json['text'] as String?,
      stampCategory: json['stampCategory'] as String?,
      stampValue: json['stampValue'] as String?,
      opacity: (json['opacity'] as num).toDouble(),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      version: json['version'] as int,
      isDeleted: json['isDeleted'] as bool,
      userId: json['userId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      changedAt: DateTime.parse(json['changedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'annotationId': annotationId,
        'tool': tool,
        'level': level,
        'pageIndex': pageIndex,
        'bbox': bbox.toJson(),
        'points': points?.map((p) => p.toJson()).toList(),
        'text': text,
        'stampCategory': stampCategory,
        'stampValue': stampValue,
        'opacity': opacity,
        'strokeWidth': strokeWidth,
        'version': version,
        'isDeleted': isDeleted,
        'userId': userId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'changedAt': changedAt.toUtc().toIso8601String(),
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

/// Notification sent via SignalR when an element changes
class ElementChangeNotification {
  const ElementChangeNotification({
    required this.type,
    this.element,
    this.elementId,
    this.annotationId,
  });

  final AnnotationOpType type;
  final AnnotationElementDto? element;
  final String? elementId;
  final String? annotationId;

  factory ElementChangeNotification.fromJson(Map<String, dynamic> json) {
    final elementJson = json['element'] as Map<String, dynamic>?;
    return ElementChangeNotification(
      type: AnnotationOpType.fromJson(json['type'] as String),
      element: elementJson != null
          ? AnnotationElementDto.fromJson(elementJson)
          : null,
      elementId: json['elementId'] as String?,
      annotationId: json['annotationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        if (element != null) 'element': element!.toJson(),
        if (elementId != null) 'elementId': elementId,
        if (annotationId != null) 'annotationId': annotationId,
      };
}
