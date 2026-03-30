import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';

/// Month view calendar widget displaying events as dots on dates
class CalendarMonthView extends StatelessWidget {
  const CalendarMonthView({
    required this.month,
    required this.entries,
    required this.onDateTap,
    required this.onEventTap,
    super.key,
  });

  final DateTime month;
  final List<CalendarEntry> entries;
  final void Function(DateTime) onDateTap;
  final void Function(String) onEventTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;

    return Column(
      children: [
        _WeekdayHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday - 1) {
                return const SizedBox.shrink();
              }

              final day = index - startWeekday + 2;
              final date = DateTime(month.year, month.month, day);
              final dayEntries = _getEntriesForDate(date);

              return _DayCell(
                date: date,
                entries: dayEntries,
                isToday: _isToday(date),
                onTap: () => onDateTap(date),
                onEventTap: onEventTap,
              );
            },
          ),
        ),
      ],
    );
  }

  List<CalendarEntry> _getEntriesForDate(DateTime date) {
    return entries.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: weekdays
            .map((day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entries,
    required this.isToday,
    required this.onTap,
    required this.onEventTap,
  });

  final DateTime date;
  final List<CalendarEntry> entries;
  final bool isToday;
  final VoidCallback onTap;
  final void Function(String) onEventTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: entries.isEmpty ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: isToday
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          borderRadius: AppSpacing.roundedSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : null,
                    color: isToday ? AppColors.primary : null,
                  ),
            ),
            const SizedBox(height: 4),
            if (entries.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: entries
                    .take(3)
                    .map((e) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _getEventTypeColor(e.type),
                            shape: BoxShape.circle,
                          ),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    return switch (type) {
      EventType.probe => AppColors.primary,
      EventType.konzert => AppColors.error,
      EventType.auftritt => AppColors.warning,
      EventType.ausflug => AppColors.secondary,
      EventType.sonstiges => AppColors.textSecondary,
    };
  }
}

/// Week view calendar widget displaying events in time slots
class CalendarWeekView extends StatelessWidget {
  const CalendarWeekView({
    required this.weekStart,
    required this.entries,
    required this.onEventTap,
    super.key,
  });

  final DateTime weekStart;
  final List<CalendarEntry> entries;
  final void Function(String) onEventTap;

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    return Column(
      children: [
        _WeekHeader(days: weekDays),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final day in weekDays) ...[
                _DaySection(
                  date: day,
                  entries: _getEntriesForDate(day),
                  onEventTap: onEventTap,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<CalendarEntry> _getEntriesForDate(DateTime date) {
    return entries.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({required this.days});

  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final weekdayFormat = DateFormat('EEE', 'de_DE');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: days
            .map((day) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekdayFormat.format(day),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                      ),
                      Text(
                        day.day.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.entries,
    required this.onEventTap,
  });

  final DateTime date;
  final List<CalendarEntry> entries;
  final void Function(String) onEventTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('EEEE, d. MMMM', 'de_DE');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateFormat.format(date),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: ListTile(
                  leading: _EventTypeIcon(type: entry.type),
                  title: Text(entry.title),
                  subtitle: Text(entry.startTime),
                  trailing: const Icon(Icons.arrow_forward, size: 16),
                  onTap: () => onEventTap(entry.id),
                ),
              ),
            )),
      ],
    );
  }
}

class _EventTypeIcon extends StatelessWidget {
  const _EventTypeIcon({required this.type});

  final EventType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      EventType.probe => (Icons.music_note, AppColors.primary),
      EventType.konzert => (Icons.music_note_outlined, AppColors.error),
      EventType.auftritt => (Icons.campaign, AppColors.warning),
      EventType.ausflug => (Icons.directions_bus, AppColors.secondary),
      EventType.sonstiges => (Icons.event, AppColors.textSecondary),
    };

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
