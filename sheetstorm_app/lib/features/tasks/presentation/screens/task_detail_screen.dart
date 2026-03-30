import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tasks/application/task_notifier.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';
import 'package:sheetstorm/features/tasks/presentation/widgets/task_status_badge.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({
    required this.bandId,
    required this.taskId,
    super.key,
  });

  final String bandId;
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskDetailProvider(taskId));

    return taskAsync.when(
      data: (task) => _TaskDetailContent(
        task: task,
        bandId: bandId,
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Aufgabe')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Fehler')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('Fehler beim Laden: $error'),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () =>
                    ref.read(taskDetailProvider(taskId).notifier).refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskDetailContent extends ConsumerWidget {
  const _TaskDetailContent({required this.task, required this.bandId});

  final BandTask task;
  final String bandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufgabe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Bearbeiten',
            onPressed: () => context.push(
              '/app/tasks/$bandId/${task.id}/edit',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TaskHeader(task: task),
            const SizedBox(height: AppSpacing.lg),
            _StatusSection(task: task),
            const SizedBox(height: AppSpacing.lg),
            if (task.description != null) ...[
              _DescriptionSection(description: task.description!),
              const SizedBox(height: AppSpacing.lg),
            ],
            _MetaSection(task: task),
            if (task.assignees.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _AssigneesSection(assignees: task.assignees),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Task Header ─────────────────────────────────────────────────────────────

class _TaskHeader extends StatelessWidget {
  const _TaskHeader({required this.task});

  final BandTask task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TaskStatusBadge(status: task.status),
            const Spacer(),
            _PriorityBadge(priority: task.priority),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          task.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (priority) {
      TaskPriority.niedrig => (
          Icons.arrow_downward,
          AppColors.textSecondary,
          'Niedrig'
        ),
      TaskPriority.mittel => (Icons.remove, AppColors.warning, 'Mittel'),
      TaskPriority.hoch => (Icons.arrow_upward, AppColors.error, 'Hoch'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Status Section ───────────────────────────────────────────────────────────

class _StatusSection extends ConsumerWidget {
  const _StatusSection({required this.task});

  final BandTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STATUS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: TaskStatus.values.map((status) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: _StatusButton(
                      status: status,
                      isSelected: task.status == status,
                      onPressed: () => _changeStatus(context, ref, status),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    TaskStatus newStatus,
  ) async {
    if (task.status == newStatus) return;

    final notifier = ref.read(taskDetailProvider(task.id).notifier);
    final success = await notifier.updateStatus(newStatus);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Status aktualisiert' : 'Fehler beim Aktualisieren',
          ),
        ),
      );
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.isSelected,
    required this.onPressed,
  });

  final TaskStatus status;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      TaskStatus.offen => (Icons.radio_button_unchecked, 'Offen', AppColors.error),
      TaskStatus.inBearbeitung => (Icons.pending, 'In Bearb.', AppColors.warning),
      TaskStatus.erledigt => (Icons.check_circle, 'Erledigt', AppColors.success),
    };

    return isSelected
        ? FilledButton.icon(
            onPressed: null,
            icon: Icon(icon, size: 16),
            label: Text(label, style: const TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 16),
            label: Text(label, style: const TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
          );
  }
}

// ─── Description Section ──────────────────────────────────────────────────────

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BESCHREIBUNG',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(description),
          ],
        ),
      ),
    );
  }
}

// ─── Meta Section ─────────────────────────────────────────────────────────────

class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.task});

  final BandTask task;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d. MMMM yyyy, HH:mm', 'de_DE');
    final shortFormat = DateFormat('d. MMM yyyy, HH:mm', 'de_DE');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DETAILS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            _MetaRow(
              icon: Icons.person,
              label: 'Erstellt von',
              value: task.createdByName,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(
              icon: Icons.access_time,
              label: 'Erstellt am',
              value: dateFormat.format(task.createdAt),
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _MetaRow(
                icon: Icons.event,
                label: 'Fällig am',
                value: shortFormat.format(task.dueDate!),
                valueColor: task.dueDate!.isBefore(DateTime.now()) &&
                        task.status != TaskStatus.erledigt
                    ? AppColors.error
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight: valueColor != null
                          ? FontWeight.w600
                          : null,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Assignees Section ────────────────────────────────────────────────────────

class _AssigneesSection extends StatelessWidget {
  const _AssigneesSection({required this.assignees});

  final List<TaskAssignee> assignees;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ZUGEWIESEN AN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...assignees.map(
              (a) => Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      a.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
