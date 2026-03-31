import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tasks/application/task_notifier.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({required this.bandId, super.key});

  final String bandId;

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Aufgabe'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Titel ────────────────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel *',
                  hintText: 'Was muss erledigt werden?',
                  border: OutlineInputBorder(),
                ),
                maxLength: 200,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Titel ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Beschreibung ─────────────────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  hintText: 'Details zur Aufgabe...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLength: 2000,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Priorität ────────────────────────────────────────────────
              const _SectionLabel(label: 'Priorität'),
              const SizedBox(height: AppSpacing.sm),
              _PrioritySelector(
                selected: _priority,
                onChanged: (p) => setState(() => _priority = p),
              ),
              const SizedBox(height: AppSpacing.md),

              // ─── Fälligkeitsdatum ─────────────────────────────────────────
              const _SectionLabel(label: 'Fälligkeitsdatum (optional)'),
              const SizedBox(height: AppSpacing.sm),
              _DueDatePicker(
                dueDate: _dueDate,
                onChanged: (d) => setState(() => _dueDate = d),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Speichern-Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppSpacing.touchTargetMin,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aufgabe erstellen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final notifier =
        ref.read(taskListProvider(bandId: widget.bandId).notifier);

    final task = await notifier.createTask(
      title: _titleController.text.trim(),
      bandId: widget.bandId,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      priority: _priority,
      dueDate: _dueDate,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (task != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aufgabe erstellt')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Erstellen der Aufgabe'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

// ─── Priority Selector ────────────────────────────────────────────────────────

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({
    required this.selected,
    required this.onChanged,
  });

  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TaskPriority>(
      segments: const [
        ButtonSegment(
          value: TaskPriority.low,
          icon: Icon(Icons.arrow_downward, size: 16),
          label: Text('Niedrig'),
        ),
        ButtonSegment(
          value: TaskPriority.medium,
          icon: Icon(Icons.remove, size: 16),
          label: Text('Mittel'),
        ),
        ButtonSegment(
          value: TaskPriority.high,
          icon: Icon(Icons.arrow_upward, size: 16),
          label: Text('Hoch'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, AppSpacing.touchTargetMin)),
      ),
    );
  }
}

// ─── Due Date Picker ──────────────────────────────────────────────────────────

class _DueDatePicker extends StatelessWidget {
  const _DueDatePicker({
    required this.dueDate,
    required this.onChanged,
  });

  final DateTime? dueDate;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickDate(context),
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              dueDate == null
                  ? 'Datum wählen'
                  : '${dueDate!.day}.${dueDate!.month}.${dueDate!.year}',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
            ),
          ),
        ),
        if (dueDate != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Datum entfernen',
            onPressed: () => onChanged(null),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      if (context.mounted) {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (time != null) {
          onChanged(
            DateTime(picked.year, picked.month, picked.day, time.hour, time.minute),
          );
        } else {
          onChanged(DateTime(picked.year, picked.month, picked.day, 18, 0));
        }
      }
    }
  }
}
