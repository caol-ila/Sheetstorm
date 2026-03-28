import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

/// Sichtbarkeitsebene — Farbe = Reichweite (UX-Spec §2)
enum AnnotationLevel {
  /// 🔵 Nur für mich
  privat,

  /// 🟢 Alle mit gleicher Stimme
  stimme,

  /// 🟠 Alle Kapellenmitglieder
  orchester;

  Color get color => switch (this) {
        AnnotationLevel.privat => AppColors.annotationPrivate,
        AnnotationLevel.stimme => AppColors.annotationStimme,
        AnnotationLevel.orchester => AppColors.annotationOrchester,
      };

  String get label => switch (this) {
        AnnotationLevel.privat => 'Privat',
        AnnotationLevel.stimme => 'Stimme',
        AnnotationLevel.orchester => 'Orchester',
      };

  String get description => switch (this) {
        AnnotationLevel.privat => 'nur für mich',
        AnnotationLevel.stimme => 'alle mit gleicher Stimme',
        AnnotationLevel.orchester => 'alle Kapellenmitglieder',
      };

  String get iconChar => switch (this) {
        AnnotationLevel.privat => '👤',
        AnnotationLevel.stimme => '🎵',
        AnnotationLevel.orchester => '🎼',
      };
}

/// Annotations-Werkzeug (UX-Spec §3)
enum AnnotationTool {
  pencil,
  highlighter,
  text,
  stamp,
  eraser,
  selection;

  String get label => switch (this) {
        AnnotationTool.pencil => 'Stift',
        AnnotationTool.highlighter => 'Textmarker',
        AnnotationTool.text => 'Text',
        AnnotationTool.stamp => 'Stempel',
        AnnotationTool.eraser => 'Radierer',
        AnnotationTool.selection => 'Auswahl',
      };
}

/// Stift-Dicke Voreinstellungen (UX-Spec §3.2)
enum StrokeThickness {
  fine(1.5),
  normal(3.0),
  thick(5.0),
  veryThick(8.0);

  const StrokeThickness(this.width);
  final double width;
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

/// Bounding Box mit relativen Koordinaten (% der Seitengröße)
class BBox {
  const BBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  BBox copyWith({double? x, double? y, double? width, double? height}) =>
      BBox(
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BBox &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// Einzelner Punkt eines Freihand-Strichs
class StrokePoint {
  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
  });

  /// Relative X-Koordinate (0.0–1.0 = % der Seitenbreite)
  final double x;

  /// Relative Y-Koordinate (0.0–1.0 = % der Seitenhöhe)
  final double y;

  /// Druckstärke (0.0–1.0), default 0.5 für Finger
  final double pressure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokePoint &&
          x == other.x &&
          y == other.y &&
          pressure == other.pressure;

  @override
  int get hashCode => Object.hash(x, y, pressure);
}

// ─── Annotation Base ──────────────────────────────────────────────────────────

/// Basis für alle Annotation-Typen
@immutable
class Annotation {
  const Annotation({
    required this.id,
    required this.level,
    required this.tool,
    required this.pageIndex,
    required this.bbox,
    required this.createdAt,
    this.points = const [],
    this.text,
    this.stampCategory,
    this.stampValue,
    this.opacity = 1.0,
    this.strokeWidth = 3.0,
  });

  final String id;
  final AnnotationLevel level;
  final AnnotationTool tool;
  final int pageIndex;
  final BBox bbox;
  final DateTime createdAt;

  /// Freihand-Punkte (für pencil, highlighter, eraser)
  final List<StrokePoint> points;

  /// Text-Inhalt (für text tool, max 200 Zeichen)
  final String? text;

  /// Stempel-Kategorie (dynamik, artikulation, atem, navigation)
  final String? stampCategory;

  /// Stempel-Wert (pp, mf, ff, etc.)
  final String? stampValue;

  /// Opazität (1.0 = voll, 0.4 = Textmarker)
  final double opacity;

  /// Strichdicke
  final double strokeWidth;

  /// SVG-Pfaddaten aus Punkten generieren
  String get svgPath {
    if (points.isEmpty) return '';
    final buffer = StringBuffer();
    buffer.write('M${_fmt(points.first.x)},${_fmt(points.first.y)}');
    for (var i = 1; i < points.length; i++) {
      buffer.write(' L${_fmt(points[i].x)},${_fmt(points[i].y)}');
    }
    return buffer.toString();
  }

  static String _fmt(double v) => v.toStringAsFixed(4);

  /// Berechne BBox aus Punkten
  static BBox computeBBox(List<StrokePoint> points) {
    if (points.isEmpty) {
      return const BBox(x: 0, y: 0, width: 0, height: 0);
    }
    var minX = points.first.x;
    var minY = points.first.y;
    var maxX = points.first.x;
    var maxY = points.first.y;
    for (final p in points) {
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
    return BBox(x: minX, y: minY, width: maxX - minX, height: maxY - minY);
  }

  Annotation copyWith({
    String? id,
    AnnotationLevel? level,
    AnnotationTool? tool,
    int? pageIndex,
    BBox? bbox,
    DateTime? createdAt,
    List<StrokePoint>? points,
    String? text,
    String? stampCategory,
    String? stampValue,
    double? opacity,
    double? strokeWidth,
  }) =>
      Annotation(
        id: id ?? this.id,
        level: level ?? this.level,
        tool: tool ?? this.tool,
        pageIndex: pageIndex ?? this.pageIndex,
        bbox: bbox ?? this.bbox,
        createdAt: createdAt ?? this.createdAt,
        points: points ?? this.points,
        text: text ?? this.text,
        stampCategory: stampCategory ?? this.stampCategory,
        stampValue: stampValue ?? this.stampValue,
        opacity: opacity ?? this.opacity,
        strokeWidth: strokeWidth ?? this.strokeWidth,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Annotation && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ─── Annotation State ─────────────────────────────────────────────────────────

/// Layer-Sichtbarkeit pro Stück
class LayerVisibility {
  const LayerVisibility({
    this.privat = true,
    this.stimme = true,
    this.orchester = true,
  });

  final bool privat;
  final bool stimme;
  final bool orchester;

  bool isVisible(AnnotationLevel level) => switch (level) {
        AnnotationLevel.privat => privat,
        AnnotationLevel.stimme => stimme,
        AnnotationLevel.orchester => orchester,
      };

  LayerVisibility toggle(AnnotationLevel level) => switch (level) {
        AnnotationLevel.privat =>
          LayerVisibility(privat: !privat, stimme: stimme, orchester: orchester),
        AnnotationLevel.stimme =>
          LayerVisibility(privat: privat, stimme: !stimme, orchester: orchester),
        AnnotationLevel.orchester =>
          LayerVisibility(privat: privat, stimme: stimme, orchester: !orchester),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayerVisibility &&
          privat == other.privat &&
          stimme == other.stimme &&
          orchester == other.orchester;

  @override
  int get hashCode => Object.hash(privat, stimme, orchester);
}

// ─── Undo/Redo Commands ───────────────────────────────────────────────────────

enum UndoActionType { add, remove }

/// Einzelne Undo-fähige Aktion
class UndoAction {
  const UndoAction({
    required this.type,
    required this.annotation,
  });

  final UndoActionType type;
  final Annotation annotation;
}
