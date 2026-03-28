import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sheetstorm/features/annotationen/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotationen/data/models/stamp_catalog.dart';

/// Renders persisted annotations onto the sheet music page.
///
/// Uses relative coordinates (0.0–1.0) scaled to the actual canvas size.
/// Annotations are batched by level for efficient rendering.
class AnnotationPainter extends CustomPainter {
  AnnotationPainter({
    required this.annotations,
    required this.layerVisibility,
    this.repaintNotifier,
  }) : super(repaint: repaintNotifier);

  final List<Annotation> annotations;
  final LayerVisibility layerVisibility;
  final ChangeNotifier? repaintNotifier;

  @override
  void paint(Canvas canvas, Size size) {
    if (annotations.isEmpty) return;

    // Render in z-order: Orchester → Stimme → Privat (private on top)
    _paintLevel(canvas, size, AnnotationLevel.orchester);
    _paintLevel(canvas, size, AnnotationLevel.stimme);
    _paintLevel(canvas, size, AnnotationLevel.privat);
  }

  void _paintLevel(Canvas canvas, Size size, AnnotationLevel level) {
    if (!layerVisibility.isVisible(level)) return;

    final levelAnnotations =
        annotations.where((a) => a.level == level).toList();
    if (levelAnnotations.isEmpty) return;

    for (final annotation in levelAnnotations) {
      switch (annotation.tool) {
        case AnnotationTool.pencil:
          _paintStroke(canvas, size, annotation);
        case AnnotationTool.highlighter:
          _paintStroke(canvas, size, annotation);
        case AnnotationTool.text:
          _paintText(canvas, size, annotation);
        case AnnotationTool.stamp:
          _paintStamp(canvas, size, annotation);
        case AnnotationTool.eraser:
          break; // Eraser has no visual output
        case AnnotationTool.selection:
          break; // Selection handles are rendered separately
      }
      // Draw level indicator border
      _paintLevelBorder(canvas, size, annotation);
    }
  }

  void _paintStroke(Canvas canvas, Size size, Annotation annotation) {
    if (annotation.points.length < 2) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = annotation.level.color.withOpacity(annotation.opacity);

    final path = ui.Path();
    final first = annotation.points.first;
    path.moveTo(first.x * size.width, first.y * size.height);

    for (var i = 1; i < annotation.points.length; i++) {
      final p = annotation.points[i];
      final prev = annotation.points[i - 1];

      // Pressure-sensitive stroke width
      final pressure = p.pressure.clamp(0.2, 1.0);
      paint.strokeWidth = annotation.strokeWidth * pressure;

      // Smooth curves using quadratic bezier for natural feel
      if (i < annotation.points.length - 1) {
        final next = annotation.points[i + 1];
        final midX = (p.x + next.x) / 2 * size.width;
        final midY = (p.y + next.y) / 2 * size.height;
        path.quadraticBezierTo(
          p.x * size.width,
          p.y * size.height,
          midX,
          midY,
        );
      } else {
        path.lineTo(p.x * size.width, p.y * size.height);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _paintText(Canvas canvas, Size size, Annotation annotation) {
    if (annotation.text == null || annotation.text!.isEmpty) return;

    final textStyle = TextStyle(
      color: annotation.level.color,
      fontSize: 14.0 * (size.width / 400), // Scale with page size
      fontWeight: FontWeight.w500,
      fontFamily: 'Inter',
    );

    final textSpan = TextSpan(text: annotation.text!, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 3,
    );

    textPainter.layout(maxWidth: size.width * 0.3);

    final offset = Offset(
      annotation.bbox.x * size.width,
      annotation.bbox.y * size.height,
    );

    // Background for readability
    final bgRect = Rect.fromLTWH(
      offset.dx - 2,
      offset.dy - 1,
      textPainter.width + 4,
      textPainter.height + 2,
    );
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      bgPaint,
    );

    textPainter.paint(canvas, offset);
  }

  void _paintStamp(Canvas canvas, Size size, Annotation annotation) {
    if (annotation.stampValue == null) return;

    final stamp = annotation.stampCategory != null
        ? StampCatalog.find(annotation.stampCategory!, annotation.stampValue!)
        : null;

    final displayText = stamp?.display ?? annotation.stampValue!;

    final textStyle = TextStyle(
      color: annotation.level.color,
      fontSize: 18.0 * (size.width / 400),
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
      fontStyle: FontStyle.italic,
    );

    final textSpan = TextSpan(text: displayText, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final cx = annotation.bbox.x * size.width +
        (annotation.bbox.width * size.width) / 2;
    final cy = annotation.bbox.y * size.height +
        (annotation.bbox.height * size.height) / 2;

    final offset = Offset(
      cx - textPainter.width / 2,
      cy - textPainter.height / 2,
    );

    // Semi-transparent background
    final bgRect = Rect.fromLTWH(
      offset.dx - 4,
      offset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
      bgPaint,
    );

    textPainter.paint(canvas, offset);
  }

  /// Subtiler farbiger Rand für Ebenen-Erkennung (UX-Spec §2.5)
  void _paintLevelBorder(Canvas canvas, Size size, Annotation annotation) {
    // Only for text and stamp annotations (strokes are already colored)
    if (annotation.tool != AnnotationTool.text &&
        annotation.tool != AnnotationTool.stamp) {
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = annotation.level.color.withOpacity(0.6);

    final rect = Rect.fromLTWH(
      annotation.bbox.x * size.width - 5,
      annotation.bbox.y * size.height - 3,
      annotation.bbox.width * size.width + 10,
      annotation.bbox.height * size.height + 6,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      paint,
    );
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) =>
      annotations != oldDelegate.annotations ||
      layerVisibility != oldDelegate.layerVisibility;
}
