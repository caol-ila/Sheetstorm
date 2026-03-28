import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/attendance/data/models/attendance_models.dart';

class RegisterBreakdown extends StatelessWidget {
  const RegisterBreakdown({super.key, required this.registers});

  final List<RegisterAttendance> registers;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anwesenheit pro Register',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            ...registers.map((register) => _buildRegisterCard(context, register)),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard(BuildContext context, RegisterAttendance register) {
    final color = _getPercentageColor(register.percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.people, color: color),
        ),
        title: Text(register.name),
        subtitle: Text('${register.memberCount} Mitglieder'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${register.percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: AppTypography.fontSizeLg,
              ),
            ),
            const SizedBox(width: 8),
            Icon(_getPercentageIcon(register.percentage),
                color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage > 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getPercentageIcon(double percentage) {
    if (percentage > 80) return Icons.check_circle;
    if (percentage >= 60) return Icons.warning;
    return Icons.cancel;
  }
}
