import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/events/application/event_notifier.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/presentation/widgets/rsvp_status_badge.dart';

class RsvpScreen extends ConsumerStatefulWidget {
  const RsvpScreen({required this.eventId, super.key});

  final String eventId;

  @override
  ConsumerState<RsvpScreen> createState() => _RsvpScreenState();
}

class _RsvpScreenState extends ConsumerState<RsvpScreen> {
  RsvpStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final rsvpAsync = ref.watch(rsvpListProvider(widget.eventId));
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anwesenheit'),
      ),
      body: Column(
        children: [
          if (eventAsync.hasValue) ...[
            _EventSummary(event: eventAsync.value!),
            const Divider(height: 1),
          ],
          _FilterTabs(
            selectedStatus: _filterStatus,
            onStatusSelected: (status) {
              setState(() => _filterStatus = status);
            },
          ),
          Expanded(
            child: rsvpAsync.when(
              data: (rsvps) {
                final filtered = _filterStatus == null
                    ? rsvps
                    : rsvps.where((r) => r.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Keine Einträge gefunden'),
                  );
                }

                return _RsvpList(rsvps: filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Fehler beim Laden: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event Summary ──────────────────────────────────────────────────────────

class _EventSummary extends StatelessWidget {
  const _EventSummary({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final stats = event.statistics;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${stats.zugesagt} zugesagt • ${stats.abgesagt} abgesagt • ${stats.offen} offen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Tabs ────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  final RsvpStatus? selectedStatus;
  final void Function(RsvpStatus?) onStatusSelected;

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
            isSelected: selectedStatus == null,
            onTap: () => onStatusSelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Zugesagt',
            isSelected: selectedStatus == RsvpStatus.zugesagt,
            onTap: () => onStatusSelected(RsvpStatus.zugesagt),
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Abgesagt',
            isSelected: selectedStatus == RsvpStatus.abgesagt,
            onTap: () => onStatusSelected(RsvpStatus.abgesagt),
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Offen',
            isSelected: selectedStatus == RsvpStatus.offen,
            onTap: () => onStatusSelected(RsvpStatus.offen),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Unsicher',
            isSelected: selectedStatus == RsvpStatus.unsicher,
            onTap: () => onStatusSelected(RsvpStatus.unsicher),
            color: AppColors.warning,
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
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: isSelected ? (color ?? AppColors.primary) : null,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
      ),
    );
  }
}

// ─── RSVP List ──────────────────────────────────────────────────────────────

class _RsvpList extends StatelessWidget {
  const _RsvpList({required this.rsvps});

  final List<Rsvp> rsvps;

  @override
  Widget build(BuildContext context) {
    final groupedByStatus = <RsvpStatus, List<Rsvp>>{};
    for (final rsvp in rsvps) {
      groupedByStatus.putIfAbsent(rsvp.status, () => []).add(rsvp);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final entry in groupedByStatus.entries) ...[
          _StatusSection(
            status: entry.key,
            rsvps: entry.value,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ─── Status Section ─────────────────────────────────────────────────────────

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.status,
    required this.rsvps,
  });

  final RsvpStatus status;
  final List<Rsvp> rsvps;

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (status) {
      RsvpStatus.zugesagt => 'ZUGESAGT',
      RsvpStatus.abgesagt => 'ABGESAGT',
      RsvpStatus.offen => 'OFFEN',
      RsvpStatus.unsicher => 'UNSICHER',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            '$statusLabel (${rsvps.length})',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        ...rsvps.map((rsvp) => _RsvpCard(rsvp: rsvp)),
      ],
    );
  }
}

// ─── RSVP Card ──────────────────────────────────────────────────────────────

class _RsvpCard extends StatelessWidget {
  const _RsvpCard({required this.rsvp});

  final Rsvp rsvp;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: rsvp.avatarUrl != null
              ? NetworkImage(rsvp.avatarUrl!)
              : null,
          child: rsvp.avatarUrl == null
              ? Text(rsvp.name[0].toUpperCase())
              : null,
        ),
        title: Text(rsvp.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rsvp.instrument),
            if (rsvp.reason != null) ...[
              const SizedBox(height: 4),
              Text(
                rsvp.reason!,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: RsvpStatusBadge(status: rsvp.status),
        isThreeLine: rsvp.reason != null,
      ),
    );
  }
}
