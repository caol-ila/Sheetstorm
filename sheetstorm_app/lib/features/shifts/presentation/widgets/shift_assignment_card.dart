import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';

class ShiftAssignmentCard extends StatelessWidget {
  const ShiftAssignmentCard({
    super.key,
    required this.assignment,
    this.onRemove,
  });

  final ShiftAssignment assignment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: assignment.avatarUrl != null
              ? NetworkImage(assignment.avatarUrl!)
              : null,
          child: assignment.avatarUrl == null
              ? Text(assignment.musicianName[0])
              : null,
        ),
        title: Text(assignment.musicianName),
        subtitle: Row(
          children: [
            Icon(
              assignment.isSelfAssigned ? Icons.check_circle : Icons.admin_panel_settings,
              size: 14,
              color: assignment.isSelfAssigned ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              assignment.isSelfAssigned ? 'Selbst eingetragen' : 'Zugewiesen',
              style: TextStyle(
                color: assignment.isSelfAssigned ? AppColors.success : AppColors.primary,
              ),
            ),
          ],
        ),
        trailing: onRemove != null
            ? IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                onPressed: onRemove,
              )
            : null,
      ),
    );
  }
}
