import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';
import 'package:sheetstorm/features/shifts/presentation/widgets/open_shifts_badge.dart';

class ShiftSlot extends StatelessWidget {
  const ShiftSlot({
    super.key,
    required this.shift,
    required this.onTap,
    this.onSelfAssign,
    this.onRemoveSelfAssignment,
  });

  final Shift shift;
  final VoidCallback onTap;
  final VoidCallback? onSelfAssign;
  final VoidCallback? onRemoveSelfAssignment;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shift.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (shift.openSlots > 0)
                    OpenShiftsBadge(count: shift.openSlots),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${shift.assignedPeople}/${shift.requiredPeople} besetzt',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (shift.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  shift.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (shift.assignments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 4,
                  children: shift.assignments
                      .take(3)
                      .map((assignment) => Chip(
                            label: Text(
                              assignment.musicianName.split(' ').first,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                if (shift.assignments.length > 3)
                  Text(
                    '+${shift.assignments.length - 3} weitere',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (shift.isFull) return AppColors.success;
    if (shift.assignedPeople > 0) return AppColors.warning;
    return AppColors.error;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
