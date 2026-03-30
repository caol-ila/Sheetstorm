import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';

/// Horizontale Filter-Bar für die Aufgabenliste.
/// Zeigt Tabs für: Alle | Offen | In Bearbeitung | Erledigt
class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final TaskStatus? selected;
  final ValueChanged<TaskStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Alle',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Offen',
            isSelected: selected == TaskStatus.offen,
            onTap: () => onSelected(TaskStatus.offen),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'In Bearbeitung',
            isSelected: selected == TaskStatus.inBearbeitung,
            onTap: () => onSelected(TaskStatus.inBearbeitung),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Erledigt',
            isSelected: selected == TaskStatus.erledigt,
            onTap: () => onSelected(TaskStatus.erledigt),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTargetMin),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.roundedFull,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
