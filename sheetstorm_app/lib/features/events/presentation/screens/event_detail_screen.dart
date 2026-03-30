import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/events/application/event_notifier.dart';
import 'package:sheetstorm/features/events/application/calendar_notifier.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/presentation/widgets/rsvp_status_badge.dart';
import 'package:sheetstorm/features/events/presentation/widgets/event_type_chip.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return eventAsync.when(
      data: (event) => _EventDetailContent(event: event),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Termin')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Fehler')),
        body: Center(child: Text('Fehler beim Laden: $error')),
      ),
    );
  }
}

class _EventDetailContent extends ConsumerWidget {
  const _EventDetailContent({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu (edit, delete, share)
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EventHeader(event: event),
            const SizedBox(height: AppSpacing.lg),
            _RsvpSection(event: event),
            const SizedBox(height: AppSpacing.lg),
            _EventDetails(event: event),
            const SizedBox(height: AppSpacing.lg),
            _AttendanceOverview(event: event),
            if (event.setlistName != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _SetlistSection(event: event),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Event Header ───────────────────────────────────────────────────────────

class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d. MMMM yyyy', 'de_DE');
    final timeText = event.endTime != null
        ? '${event.startTime} - ${event.endTime} Uhr'
        : '${event.startTime} Uhr';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            EventTypeChip(type: event.type),
            const Spacer(),
            RsvpStatusBadge(status: event.myRsvpStatus),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          event.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          dateFormat.format(event.date),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          timeText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

// ─── RSVP Section ───────────────────────────────────────────────────────────

class _RsvpSection extends ConsumerWidget {
  const _RsvpSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEINE ZUSAGE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _RsvpButton(
                    status: RsvpStatus.zugesagt,
                    isSelected: event.myRsvpStatus == RsvpStatus.zugesagt,
                    onPressed: () => _submitRsvp(
                      context,
                      ref,
                      RsvpStatus.zugesagt,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _RsvpButton(
                    status: RsvpStatus.abgesagt,
                    isSelected: event.myRsvpStatus == RsvpStatus.abgesagt,
                    onPressed: () => _showAbsageDialog(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: _RsvpButton(
                status: RsvpStatus.unsicher,
                isSelected: event.myRsvpStatus == RsvpStatus.unsicher,
                onPressed: () => _submitRsvp(
                  context,
                  ref,
                  RsvpStatus.unsicher,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRsvp(
    BuildContext context,
    WidgetRef ref,
    RsvpStatus status,
  ) async {
    final notifier = ref.read(eventDetailProvider(event.id).notifier);
    final success = await notifier.submitRsvp(status: status);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Zusage erfolgreich geändert'
                : 'Fehler beim Ändern der Zusage',
          ),
        ),
      );
    }
  }

  Future<void> _showAbsageDialog(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Absagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Möchtest du für diesen Termin absagen?'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Begründung (optional)',
                hintText: 'z.B. Urlaub, Krank...',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '💡 Eine Begründung hilft dem Dirigenten bei der Planung.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Absagen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notifier = ref.read(eventDetailProvider(event.id).notifier);
      final success = await notifier.submitRsvp(
        status: RsvpStatus.abgesagt,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Absage gespeichert' : 'Fehler beim Absagen',
            ),
          ),
        );
      }
    }
  }
}

class _RsvpButton extends StatelessWidget {
  const _RsvpButton({
    required this.status,
    required this.isSelected,
    required this.onPressed,
  });

  final RsvpStatus status;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      RsvpStatus.zugesagt => (Icons.check, 'Zusagen', AppColors.success),
      RsvpStatus.abgesagt => (Icons.close, 'Absagen', AppColors.error),
      RsvpStatus.unsicher => (Icons.help_outline, 'Vielleicht', AppColors.warning),
      RsvpStatus.offen => (Icons.circle_outlined, 'Offen', AppColors.textSecondary),
    };

    return isSelected
        ? FilledButton.icon(
            onPressed: null,
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.touchTargetMin),
            ),
          );
  }
}

// ─── Event Details ──────────────────────────────────────────────────────────

class _EventDetails extends StatelessWidget {
  const _EventDetails({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
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
            if (event.location != null) ...[
              _DetailRow(
                icon: Icons.location_on,
                label: 'Ort',
                value: event.location!,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (event.meetingPoint != null) ...[
              _DetailRow(
                icon: Icons.place,
                label: 'Treffpunkt',
                value: event.meetingPoint!,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (event.dressCode != null) ...[
              _DetailRow(
                icon: Icons.checkroom,
                label: 'Kleiderordnung',
                value: event.dressCode!,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (event.rsvpDeadline != null) ...[
              _DetailRow(
                icon: Icons.access_time,
                label: 'Zusage bis',
                value: DateFormat('d. MMMM yyyy', 'de_DE')
                    .format(event.rsvpDeadline!),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (event.description != null) ...[
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Beschreibung:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(event.description!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}

// ─── Attendance Overview ────────────────────────────────────────────────────

class _AttendanceOverview extends ConsumerWidget {
  const _AttendanceOverview({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = event.statistics;

    return Card(
      child: InkWell(
        onTap: () {
          context.push('/app/events/${event.id}/rsvps');
        },
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANWESENHEIT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    count: stats.zugesagt,
                    label: 'Zugesagt',
                    color: AppColors.success,
                  ),
                  _StatColumn(
                    count: stats.abgesagt,
                    label: 'Abgesagt',
                    color: AppColors.error,
                  ),
                  _StatColumn(
                    count: stats.offen,
                    label: 'Offen',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Details anzeigen'),
                    SizedBox(width: AppSpacing.xs),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─── Setlist Section ────────────────────────────────────────────────────────

class _SetlistSection extends StatelessWidget {
  const _SetlistSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SETLIST',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.music_note, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    event.setlistName!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Tap zum Öffnen',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
