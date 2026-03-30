// ─── Annotation Sync Converters ─────────────────────────────────────────────
//
// Conversions between local Annotation models and wire-format DTOs.

import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';

/// Convert AnnotationElementDto (wire) → Annotation (local)
Annotation dtoToAnnotation(AnnotationElementDto dto) {
  return Annotation(
    id: dto.id,
    level: levelFromString(dto.level),
    tool: toolFromString(dto.tool),
    pageIndex: dto.pageIndex,
    bbox: BBox(
      x: dto.bbox.x,
      y: dto.bbox.y,
      width: dto.bbox.width,
      height: dto.bbox.height,
    ),
    createdAt: dto.createdAt,
    points: dto.points
            ?.map((p) => StrokePoint(x: p.x, y: p.y, pressure: p.pressure))
            .toList() ??
        const [],
    text: dto.text,
    stampCategory: dto.stampCategory,
    stampValue: dto.stampValue,
    opacity: dto.opacity,
    strokeWidth: dto.strokeWidth,
  );
}

/// Convert Annotation (local) → AnnotationElementDto (wire)
AnnotationElementDto annotationToDto(
  Annotation a, {
  required String annotationId,
  required String userId,
  required int version,
}) {
  return AnnotationElementDto(
    id: a.id,
    annotationId: annotationId,
    tool: toolToString(a.tool),
    level: levelToString(a.level),
    pageIndex: a.pageIndex,
    bbox: BBoxDto(
      x: a.bbox.x,
      y: a.bbox.y,
      width: a.bbox.width,
      height: a.bbox.height,
    ),
    points: a.points.isEmpty
        ? null
        : a.points
            .map(
                (p) => StrokePointDto(x: p.x, y: p.y, pressure: p.pressure))
            .toList(),
    text: a.text,
    stampCategory: a.stampCategory,
    stampValue: a.stampValue,
    opacity: a.opacity,
    strokeWidth: a.strokeWidth,
    version: version,
    isDeleted: false,
    userId: userId,
    createdAt: a.createdAt,
    changedAt: DateTime.now().toUtc(),
  );
}

/// Parse annotation level from wire string
AnnotationLevel levelFromString(String s) => switch (s) {
      'private' => AnnotationLevel.private,
      'voice' => AnnotationLevel.voice,
      'orchestra' => AnnotationLevel.orchestra,
      _ => AnnotationLevel.private,
    };

/// Convert annotation level to wire string
String levelToString(AnnotationLevel l) => l.name;

/// Parse annotation tool from wire string
AnnotationTool toolFromString(String s) => switch (s) {
      'pencil' => AnnotationTool.pencil,
      'highlighter' => AnnotationTool.highlighter,
      'text' => AnnotationTool.text,
      'stamp' => AnnotationTool.stamp,
      'eraser' => AnnotationTool.eraser,
      'selection' => AnnotationTool.selection,
      _ => AnnotationTool.pencil,
    };

/// Convert annotation tool to wire string
String toolToString(AnnotationTool t) => t.name;

/// Whether this annotation level should be synced (private = no)
bool shouldSync(AnnotationLevel level) => level != AnnotationLevel.private;
