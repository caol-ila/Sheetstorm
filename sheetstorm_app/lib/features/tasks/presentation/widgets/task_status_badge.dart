import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';

/// Farbkodierter Status-Badge für Aufgaben.
/// Rot = Offen, Gelb = In Bearbeitung, Grün = Erledigt
class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({required this.status, super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TaskStatus.open => ('Offen', AppColors.error),
      TaskStatus.inProgress => ('In Bearbeitung', AppColors.warning),
      TaskStatus.done => ('Erledigt', AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
