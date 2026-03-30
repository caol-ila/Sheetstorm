import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';
import 'package:sheetstorm/features/tasks/presentation/widgets/task_status_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    this.onTap,
    super.key,
  });

  final BandTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
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
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TaskStatusBadge(status: task.status),
                ],
              ),
              if (task.description != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _PriorityChip(priority: task.priority),
                  const Spacer(),
                  if (task.dueDate != null)
                    _DueDateChip(dueDate: task.dueDate!),
                ],
              ),
              if (task.assignees.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                _AssigneesRow(assignees: task.assignees),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Priority Chip ────────────────────────────────────────────────────────────

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (priority) {
      TaskPriority.niedrig => (Icons.arrow_downward, AppColors.textSecondary, 'Niedrig'),
      TaskPriority.mittel => (Icons.remove, AppColors.warning, 'Mittel'),
      TaskPriority.hoch => (Icons.arrow_upward, AppColors.error, 'Hoch'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Due Date Chip ────────────────────────────────────────────────────────────

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.dueDate});

  final DateTime dueDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final color = isOverdue ? AppColors.error : AppColors.textSecondary;
    final dateStr = DateFormat('d. MMM', 'de_DE').format(dueDate);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          dateStr,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─── Assignees Row ────────────────────────────────────────────────────────────

class _AssigneesRow extends StatelessWidget {
  const _AssigneesRow({required this.assignees});

  final List<TaskAssignee> assignees;

  @override
  Widget build(BuildContext context) {
    final displayCount = assignees.length > 3 ? 3 : assignees.length;
    final remainder = assignees.length - displayCount;

    return Row(
      children: [
        const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          assignees.take(displayCount).map((a) => a.name.split(' ').first).join(', ') +
              (remainder > 0 ? ' +$remainder' : ''),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
