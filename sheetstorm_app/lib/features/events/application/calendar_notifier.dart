import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/data/services/calendar_service.dart';

part 'calendar_notifier.g.dart';

// ─── Calendar View Mode ─────────────────────────────────────────────────────

enum CalendarViewMode {
  month,
  week,
  list;
}

// ─── Calendar State ─────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class CalendarNotifier extends _$CalendarNotifier {
  @override
  Future<List<CalendarEntry>> build({
    String? bandId,
    DateTime? month,
    EventType? typeFilter,
    RsvpStatus? statusFilter,
    CalendarViewMode viewMode = CalendarViewMode.month,
  }) async {
    final service = ref.read(calendarServiceProvider);
    final targetMonth = month ?? DateTime.now();

    return service.getMonthEntries(
      month: targetMonth,
      bandId: bandId,
      type: typeFilter,
      status: statusFilter,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(calendarServiceProvider);
      final targetMonth = month ?? DateTime.now();

      return service.getMonthEntries(
        month: targetMonth,
        bandId: bandId,
        type: typeFilter,
        status: statusFilter,
      );
    });
  }

  Future<void> loadMonth(DateTime newMonth) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(calendarServiceProvider);
      return service.getMonthEntries(
        month: newMonth,
        bandId: bandId,
        type: typeFilter,
        status: statusFilter,
      );
    });
  }

  Future<void> loadWeek(DateTime weekStart) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(calendarServiceProvider);
      return service.getWeekEntries(
        weekStart: weekStart,
        bandId: bandId,
        type: typeFilter,
        status: statusFilter,
      );
    });
  }

  List<CalendarEntry> getEntriesForDate(DateTime date) {
    final entries = state.value ?? [];
    return entries.where((e) {
      return e.date.year == date.year &&
          e.date.month == date.month &&
          e.date.day == date.day;
    }).toList();
  }
}

// ─── Selected Date (for calendar navigation) ────────────────────────────────

@Riverpod(keepAlive: true)
class SelectedDateNotifier extends _$SelectedDateNotifier {
  @override
  DateTime build() => DateTime.now();

  void selectDate(DateTime date) {
    state = date;
  }

  void selectToday() {
    state = DateTime.now();
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void previousWeek() {
    state = state.subtract(const Duration(days: 7));
  }
}

// ─── Calendar View Mode State ───────────────────────────────────────────────

@Riverpod(keepAlive: true)
class CalendarViewModeNotifier extends _$CalendarViewModeNotifier {
  @override
  CalendarViewMode build() => CalendarViewMode.month;

  void setViewMode(CalendarViewMode mode) {
    state = mode;
  }
}
