import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tasks/application/task_notifier.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';
import 'package:sheetstorm/features/tasks/presentation/widgets/task_card.dart';
import 'package:sheetstorm/features/tasks/presentation/widgets/task_filter_bar.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({required this.bandId, super.key});

  final String bandId;

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  TaskStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider(bandId: widget.bandId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufgaben'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: () => ref
                .read(taskListProvider(bandId: widget.bandId).notifier)
                .refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/app/tasks/${widget.bandId}/new'),
        icon: const Icon(Icons.add),
        label: const Text('Neue Aufgabe'),
      ),
      body: Column(
        children: [
          TaskFilterBar(
            selected: _filter,
            onSelected: (status) => setState(() => _filter = status),
          ),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                final filtered = _filter == null
                    ? tasks
                    : tasks.where((t) => t.status == _filter).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(filter: _filter);
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(taskListProvider(bandId: widget.bandId).notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return TaskCard(
                        task: task,
                        onTap: () => context.push(
                          '/app/tasks/${widget.bandId}/${task.id}',
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Fehler beim Laden der Aufgaben'),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => ref
                          .read(
                            taskListProvider(bandId: widget.bandId).notifier,
                          )
                          .refresh(),
                      child: const Text('Erneut versuchen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.filter});

  final TaskStatus? filter;

  @override
  Widget build(BuildContext context) {
    final message = filter == null
        ? 'Keine Aufgaben vorhanden'
        : switch (filter!) {
            TaskStatus.offen => 'Keine offenen Aufgaben',
            TaskStatus.inBearbeitung => 'Keine Aufgaben in Bearbeitung',
            TaskStatus.erledigt => 'Noch keine erledigten Aufgaben',
          };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt, size: 64, color: Colors.grey),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
