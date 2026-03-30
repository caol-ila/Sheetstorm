import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/shifts/application/shift_notifier.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';
import 'package:sheetstorm/features/shifts/presentation/widgets/shift_slot.dart';
import 'package:sheetstorm/features/shifts/presentation/widgets/open_shifts_badge.dart';

class ShiftPlanScreen extends ConsumerWidget {
  const ShiftPlanScreen({
    super.key,
    required this.bandId,
    required this.planId,
  });

  final String bandId;
  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(shiftPlanProvider(bandId, planId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schichtplan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(shiftPlanProvider(bandId, planId).notifier)
                  .refresh();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateShiftDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Schicht hinzufügen'),
      ),
      body: planAsync.when(
        data: (plan) => _buildPlanContent(context, ref, plan),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  Widget _buildPlanContent(BuildContext context, WidgetRef ref, ShiftPlan plan) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(shiftPlanProvider(bandId, planId).notifier)
            .refresh();
      },
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(plan.date),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    if (plan.description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(plan.description!),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Chip(
                          label: Text('${plan.filledSlots}/${plan.totalSlots} besetzt'),
                          avatar: const Icon(Icons.people, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (plan.totalSlots > plan.filledSlots)
                          OpenShiftsBadge(count: plan.totalSlots - plan.filledSlots),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shifts
          if (plan.shifts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('Keine Schichten definiert'),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final shift = plan.shifts[index];
                    return ShiftSlot(
                      shift: shift,
                      onTap: () => _showShiftDetail(context, ref, shift),
                      onSelfAssign: () => _handleSelfAssign(ref, shift.id),
                      onRemoveSelfAssignment: () =>
                          _handleRemoveSelfAssignment(ref, shift.id),
                    );
                  },
                  childCount: plan.shifts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCreateShiftDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    DateTime? startTime;
    DateTime? endTime;
    int requiredPeople = 1;
    String? description;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schicht hinzufügen'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Pflichtfeld' : null,
                  onSaved: (value) => name = value!,
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  title: const Text('Von *'),
                  subtitle: Text(
                    startTime != null ? _formatTime(startTime!) : 'Nicht gesetzt',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      startTime = DateTime(2000, 1, 1, time.hour, time.minute);
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                ListTile(
                  title: const Text('Bis *'),
                  subtitle: Text(
                    endTime != null ? _formatTime(endTime!) : 'Nicht gesetzt',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      endTime = DateTime(2000, 1, 1, time.hour, time.minute);
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: 'Benötigte Personen *'),
                  keyboardType: TextInputType.number,
                  initialValue: '1',
                  validator: (value) {
                    final val = int.tryParse(value ?? '');
                    if (val == null || val < 1) return 'Mindestens 1';
                    return null;
                  },
                  onSaved: (value) => requiredPeople = int.parse(value!),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    hintText: 'z.B. Getränkeausschank',
                  ),
                  maxLines: 2,
                  onSaved: (value) =>
                      description = value?.isNotEmpty == true ? value : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() &&
                  startTime != null &&
                  endTime != null) {
                formKey.currentState!.save();
                Navigator.pop(context);

                final notifier =
                    ref.read(shiftPlanProvider(bandId, planId).notifier);

                final shift = await notifier.createShift(
                  name: name,
                  startTime: startTime!,
                  endTime: endTime!,
                  requiredPeople: requiredPeople,
                  description: description,
                );

                if (shift != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schicht erstellt')),
                  );
                }
              }
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _showShiftDetail(BuildContext context, WidgetRef ref, Shift shift) {
    Navigator.pushNamed(
      context,
      '/shift/detail',
      arguments: {'bandId': bandId, 'planId': planId, 'shift': shift},
    );
  }

  Future<void> _handleSelfAssign(WidgetRef ref, String shiftId) async {
    final notifier = ref.read(shiftPlanProvider(bandId, planId).notifier);
    final success = await notifier.selfAssign(shiftId);
    // Show snackbar would be handled by the widget
  }

  Future<void> _handleRemoveSelfAssignment(WidgetRef ref, String shiftId) async {
    final notifier = ref.read(shiftPlanProvider(bandId, planId).notifier);
    final success = await notifier.removeSelfAssignment(shiftId);
    // Show snackbar would be handled by the widget
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
