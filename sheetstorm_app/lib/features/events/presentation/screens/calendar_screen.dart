import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/date_utils.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/events/application/calendar_notifier.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/presentation/widgets/calendar_view.dart';
import 'package:sheetstorm/features/events/presentation/widgets/event_card.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).selectToday();
            },
            tooltip: 'Heute',
          ),
        ],
      ),
      body: Column(
        children: [
          _ViewModeSelector(viewMode: viewMode),
          const SizedBox(height: AppSpacing.sm),
          _DateNavigationBar(
            viewMode: viewMode,
            selectedDate: selectedDate,
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildViewForMode(context, ref, viewMode, selectedDate),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create event screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Termin erstellen (noch nicht implementiert)')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildViewForMode(
    BuildContext context,
    WidgetRef ref,
    CalendarViewMode viewMode,
    DateTime selectedDate,
  ) {
    switch (viewMode) {
      case CalendarViewMode.month:
        return _MonthView(selectedDate: selectedDate);
      case CalendarViewMode.week:
        return _WeekView(selectedDate: selectedDate);
      case CalendarViewMode.list:
        return _ListView(selectedDate: selectedDate);
    }
  }
}

// ─── View Mode Selector ─────────────────────────────────────────────────────

class _ViewModeSelector extends ConsumerWidget {
  const _ViewModeSelector({required this.viewMode});

  final CalendarViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: SegmentedButton<CalendarViewMode>(
        segments: const [
          ButtonSegment(
            value: CalendarViewMode.month,
            label: Text('Monat'),
            icon: Icon(Icons.calendar_month),
          ),
          ButtonSegment(
            value: CalendarViewMode.week,
            label: Text('Woche'),
            icon: Icon(Icons.calendar_view_week),
          ),
          ButtonSegment(
            value: CalendarViewMode.list,
            label: Text('Liste'),
            icon: Icon(Icons.list),
          ),
        ],
        selected: {viewMode},
        onSelectionChanged: (Set<CalendarViewMode> newSelection) {
          ref
              .read(calendarViewModeProvider.notifier)
              .setViewMode(newSelection.first);
        },
      ),
    );
  }
}

// ─── Date Navigation Bar ────────────────────────────────────────────────────

class _DateNavigationBar extends ConsumerWidget {
  const _DateNavigationBar({
    required this.viewMode,
    required this.selectedDate,
  });

  final CalendarViewMode viewMode;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleText = _getTitleText();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _navigatePrevious(ref),
          ),
          Text(
            titleText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _navigateNext(ref),
          ),
        ],
      ),
    );
  }

  String _getTitleText() {
    switch (viewMode) {
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy', 'de_DE').format(selectedDate);
      case CalendarViewMode.week:
        final weekStart = _getWeekStart(selectedDate);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'KW ${_getWeekNumber(selectedDate)} • ${DateFormat('MMM yyyy', 'de_DE').format(selectedDate)}';
      case CalendarViewMode.list:
        return DateFormat('yyyy', 'de_DE').format(selectedDate);
    }
  }

  void _navigatePrevious(WidgetRef ref) {
    final notifier = ref.read(selectedDateProvider.notifier);
    switch (viewMode) {
      case CalendarViewMode.month:
        notifier.previousMonth();
        break;
      case CalendarViewMode.week:
        notifier.previousWeek();
        break;
      case CalendarViewMode.list:
        break;
    }
  }

  void _navigateNext(WidgetRef ref) {
    final notifier = ref.read(selectedDateProvider.notifier);
    switch (viewMode) {
      case CalendarViewMode.month:
        notifier.nextMonth();
        break;
      case CalendarViewMode.week:
        notifier.nextWeek();
        break;
      case CalendarViewMode.list:
        break;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  int _getWeekNumber(DateTime date) {
    return isoWeekNumber(date);
  }
}

// ─── Month View ─────────────────────────────────────────────────────────────

class _MonthView extends ConsumerWidget {
  const _MonthView({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarProvider(
      month: selectedDate,
    ));

    return calendarAsync.when(
      data: (entries) => CalendarMonthView(
        month: selectedDate,
        entries: entries,
        onDateTap: (date) {
          ref.read(selectedDateProvider.notifier).selectDate(date);
        },
        onEventTap: (eventId) {
          context.push('/app/events/$eventId');
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler beim Laden: $error'),
      ),
    );
  }
}

// ─── Week View ──────────────────────────────────────────────────────────────

class _WeekView extends ConsumerWidget {
  const _WeekView({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = selectedDate.subtract(
      Duration(days: selectedDate.weekday - 1),
    );

    final calendarAsync = ref.watch(calendarProvider(
      month: selectedDate,
    ));

    return calendarAsync.when(
      data: (entries) {
        final weekEntries = entries.where((e) {
          final isInWeek = e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              e.date.isBefore(weekStart.add(const Duration(days: 7)));
          return isInWeek;
        }).toList();

        return CalendarWeekView(
          weekStart: weekStart,
          entries: weekEntries,
          onEventTap: (eventId) {
            context.push('/app/events/$eventId');
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler beim Laden: $error'),
      ),
    );
  }
}

// ─── List View ──────────────────────────────────────────────────────────────

class _ListView extends ConsumerWidget {
  const _ListView({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(calendarProvider(
      month: selectedDate,
    ));

    return calendarAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('Noch keine Termine geplant'),
          );
        }

        entries.sort((a, b) => a.date.compareTo(b.date));

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: EventCard(
                title: entry.title,
                type: entry.type,
                date: entry.date,
                startTime: entry.startTime,
                location: entry.location,
                rsvpStatus: entry.myRsvpStatus,
                onTap: () => context.push('/app/events/${entry.id}'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler beim Laden: $error'),
      ),
    );
  }
}
