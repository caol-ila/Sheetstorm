import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/attendance/data/models/attendance_models.dart';

class AttendanceChart extends StatelessWidget {
  const AttendanceChart({super.key, required this.trend});

  final AttendanceTrend trend;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anwesenheitstrend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: _buildSimpleLineChart(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Durchschnitt: ${trend.averagePercentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLineChart() {
    if (trend.dataPoints.isEmpty) {
      return const Center(child: Text('Keine Daten verfügbar'));
    }

    return CustomPaint(
      painter: _LineChartPainter(trend.dataPoints),
      size: const Size(double.infinity, 200),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<TrendDataPoint> dataPoints;

  _LineChartPainter(this.dataPoints);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final maxPercentage = 100.0;
    final stepX = size.width / (dataPoints.length - 1).clamp(1, double.infinity);

    final path = Path();
    for (var i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final y = size.height - (dataPoints[i].percentage / maxPercentage * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }

    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
