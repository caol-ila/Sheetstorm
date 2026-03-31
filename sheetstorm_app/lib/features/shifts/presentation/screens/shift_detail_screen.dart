import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/shifts/application/shift_notifier.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';

/// Shift-Detail-Ansicht.
///
/// Empfängt bandId, planId und shiftId als Pfadparameter (kein state.extra).
/// Liest den Shift aus dem bereits gecachten [shiftPlanProvider].
class ShiftDetailScreen extends ConsumerWidget {
  const ShiftDetailScreen({
    super.key,
    required this.bandId,
    required this.planId,
    required this.shiftId,
  });

  final String bandId;
  final String planId;
  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(shiftPlanProvider(bandId, planId));

    return planAsync.when(
      data: (plan) {
        final Shift? shift = plan.shifts
            .where((s) => s.id == shiftId)
            .cast<Shift?>()
            .firstOrNull;

        if (shift == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Schicht-Details')),
            body: const Center(child: Text('Schicht nicht gefunden')),
          );
        }

        return _ShiftDetailContent(shift: shift);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Schicht-Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Schicht-Details')),
        body: Center(child: Text('Fehler: $error')),
      ),
    );
  }
}

class _ShiftDetailContent extends StatelessWidget {
  const _ShiftDetailContent({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schicht-Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoRow(
                      context,
                      Icons.access_time,
                      'Zeit',
                      '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      Icons.people,
                      'Personen',
                      '${shift.assignedPeople}/${shift.requiredPeople} besetzt',
                    ),
                    if (shift.description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        context,
                        Icons.description,
                        'Beschreibung',
                        shift.description!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Zugewiesene Personen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (shift.assignments.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Center(
                    child: Text(
                      'Noch niemand zugewiesen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              )
            else
              ...shift.assignments.map((assignment) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: assignment.avatarUrl != null
                            ? NetworkImage(assignment.avatarUrl!)
                            : null,
                        child: assignment.avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(assignment.musicianName),
                      subtitle: Text(
                        assignment.isSelfAssigned ? 'Selbst' : 'Zugewiesen',
                        style: TextStyle(
                          color: assignment.isSelfAssigned
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.error),
                        tooltip: 'Zuweisung entfernen',
                        onPressed: () {
                          // Handle remove assignment
                        },
                      ),
                    ),
                  )),
            const SizedBox(height: AppSpacing.lg),
            if (!shift.isFull)
              ElevatedButton.icon(
                onPressed: () {
                  // Handle self-assign
                },
                icon: const Icon(Icons.check),
                label: const Text('Ich bin dabei'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

