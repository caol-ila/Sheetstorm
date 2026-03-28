import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sheetstorm/features/annotationen/data/models/annotation_models.dart';

/// Renders the active stroke being drawn right now.
///
/// Separated from [AnnotationPainter] for 60fps performance —
/// only this painter repaints during active drawing, while the
/// stored annotations remain in their own repaint boundary.
class DrawingPainter extends CustomPainter {
  DrawingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.opacity,
    required this.tool,
    super.repaint,
  });

  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;
  final double opacity;
  final AnnotationTool tool;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      // Draw a dot for single point
      if (points.length == 1) {
        final p = points.first;
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(opacity)
          ..isAntiAlias = true;
        canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height),
          strokeWidth * p.pressure.clamp(0.2, 1.0) / 2,
          paint,
        );
      }
      return;
    }

    if (tool == AnnotationTool.eraser) {
      _paintEraser(canvas, size);
    } else {
      _paintStroke(canvas, size);
    }
  }

  void _paintStroke(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = color.withOpacity(opacity);

    // For highlighter: wider, semi-transparent with flat cap
    if (tool == AnnotationTool.highlighter) {
      paint.strokeCap = StrokeCap.butt;
      paint.blendMode = BlendMode.multiply;
    }

    // Draw segments with pressure-variable width
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];

      final pressure = curr.pressure.clamp(0.2, 1.0);
      paint.strokeWidth = strokeWidth * pressure;

      canvas.drawLine(
        Offset(prev.x * size.width, prev.y * size.height),
        Offset(curr.x * size.width, curr.y * size.height),
        paint,
      );
    }
  }

  void _paintEraser(Canvas canvas, Size size) {
    // Visual eraser cursor — dashed circle at current position
    if (points.isEmpty) return;
    final last = points.last;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.grey.withOpacity(0.7);

    canvas.drawCircle(
      Offset(last.x * size.width, last.y * size.height),
      strokeWidth * 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true; // Always repaint during active drawing
}
