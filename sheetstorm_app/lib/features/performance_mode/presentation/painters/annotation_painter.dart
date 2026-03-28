import 'package:flutter/material.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

/// CustomPainter for annotation overlays (Spec §3.2).
///
/// Renders SVG paths and text annotations using relative coordinates (x%, y%).
/// Independent layer — no re-render of PDF needed when annotations change.
class AnnotationPainter extends CustomPainter {
  const AnnotationPainter({
    required this.annotations,
    required this.visibleLayers,
    this.isNightMode = false,
  });

  final List<SheetAnnotation> annotations;
  final Set<AnnotationLayer> visibleLayers;
  final bool isNightMode;

  @override
  void paint(Canvas canvas, Size size) {
    for (final annotation in annotations) {
      if (!visibleLayers.contains(annotation.layer)) continue;

      final color = isNightMode
          ? annotation.layer.nightModeColor
          : (annotation.color ?? annotation.layer.color);

      final paint = Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromLTWH(
        annotation.relativeX * size.width,
        annotation.relativeY * size.height,
        annotation.relativeWidth * size.width,
        annotation.relativeHeight * size.height,
      );

      if (annotation.svgPath != null) {
        // Simplified SVG path rendering — in production, parse SVG path data
        canvas.drawRect(rect, paint);
      }

      if (annotation.text != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: annotation.text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(maxWidth: rect.width);
        textPainter.paint(canvas, rect.topLeft);
      }
    }
  }

  @override
  bool shouldRepaint(AnnotationPainter oldDelegate) {
    return oldDelegate.annotations != annotations ||
        oldDelegate.visibleLayers != visibleLayers ||
        oldDelegate.isNightMode != isNightMode;
  }
}
