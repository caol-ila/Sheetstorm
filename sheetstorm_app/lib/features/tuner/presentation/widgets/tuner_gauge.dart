import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';

/// Visuelle Cent-Abweichungsanzeige (Zeigerinstrument).
///
/// Zeigt die Abweichung von -50 bis +50 Cent:
/// - Grüne Zone: ±5 Cent (perfekt gestimmt)
/// - Gelbe Zone: ±15 Cent (nah dran)
/// - Rote Zone: > ±15 Cent (verstimmt)
class TunerGauge extends StatelessWidget {
  const TunerGauge({
    super.key,
    required this.centDeviation,
  });

  final double centDeviation;

  /// Farbe basierend auf Cent-Abweichung.
  Color get tuneColor {
    final abs = centDeviation.abs();
    if (abs <= 5.0) return AppColors.success;
    if (abs <= 15.0) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = centDeviation.clamp(-50.0, 50.0);

    return Semantics(
      label: _semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: CustomPaint(
              painter: _GaugePainter(
                centDeviation: clamped,
                tuneColor: tuneColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          _ScaleLabels(),
        ],
      ),
    );
  }

  String get _semanticLabel {
    final abs = centDeviation.abs();
    final direction = centDeviation > 0 ? 'zu hoch' : 'zu tief';
    if (abs <= 5.0) return 'Perfekt gestimmt';
    if (abs <= 15.0) return '${abs.toStringAsFixed(0)} Cent $direction — nah dran';
    return '${abs.toStringAsFixed(0)} Cent $direction — verstimmt';
  }
}

// ─── Scale Labels ─────────────────────────────────────────────────────────────

class _ScaleLabels extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text('-50', style: TextStyle(fontSize: 10)),
        Text('-15', style: TextStyle(fontSize: 10)),
        Text('0', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        Text('+15', style: TextStyle(fontSize: 10)),
        Text('+50', style: TextStyle(fontSize: 10)),
      ],
    );
  }
}

// ─── Gauge Painter ────────────────────────────────────────────────────────────

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.centDeviation,
    required this.tuneColor,
  });

  final double centDeviation;
  final Color tuneColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.45;

    _drawArc(canvas, center, radius, size);
    _drawZoneMarkers(canvas, center, radius);
    _drawNeedle(canvas, center, radius, size);
    _drawCenterDot(canvas, center);
  }

  void _drawArc(Canvas canvas, Offset center, double radius, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _degreesToRadians(180),
      _degreesToRadians(180),
      false,
      paint,
    );
  }

  void _drawZoneMarkers(Canvas canvas, Offset center, double radius) {
    // Grüne Zone: ±5/50 * 90° = ±9°
    _drawZoneArc(canvas, center, radius, -9, 9, AppColors.success.withValues(alpha: 0.3));
    // Gelbe Zone: ±15/50 * 90° = ±27°
    _drawZoneArc(canvas, center, radius, -27, -9, AppColors.warning.withValues(alpha: 0.3));
    _drawZoneArc(canvas, center, radius, 9, 27, AppColors.warning.withValues(alpha: 0.3));
  }

  void _drawZoneArc(Canvas canvas, Offset center, double radius,
      double startDeg, double endDeg, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    final startRad = _degreesToRadians(270 + startDeg);
    final sweepRad = _degreesToRadians(endDeg - startDeg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      sweepRad,
      false,
      paint,
    );
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius, Size size) {
    // Mappe -50..+50 Cent auf -90°..+90° (0° = gerade nach oben = 270° in Dart)
    final angle = _degreesToRadians(270 + (centDeviation / 50.0) * 90.0);

    final needleTip = Offset(
      center.dx + (radius - 8) * math.cos(angle),
      center.dy + (radius - 8) * math.sin(angle),
    );

    final paint = Paint()
      ..color = tuneColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, paint);
  }

  void _drawCenterDot(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.0, paint);
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.centDeviation != centDeviation ||
      oldDelegate.tuneColor != tuneColor;
}

