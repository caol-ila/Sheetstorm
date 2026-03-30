import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/events/application/calendar_notifier.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

(ProviderContainer, SelectedDateNotifier) _setupSelectedDate() {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(selectedDateProvider.notifier);
  return (container, notifier);
}

(ProviderContainer, CalendarViewModeNotifier) _setupViewMode() {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final notifier = container.read(calendarViewModeProvider.notifier);
  return (container, notifier);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── CalendarNotifier — Provider ──────────────────────────────────────────

  group('CalendarNotifier — Provider', () {
    test('provider exists and initial state is AsyncLoading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(calendarProvider());
      expect(state, isA<AsyncLoading<List<CalendarEntry>>>());
    });

    test('notifier can be read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(calendarProvider().notifier);
      expect(notifier, isA<CalendarNotifier>());
    });
  });

  // ─── CalendarViewMode — Enum ──────────────────────────────────────────────

  group('CalendarViewMode — Enum', () {
    test('CalendarViewMode values exist', () {
      expect(CalendarViewMode.month, isNotNull);
      expect(CalendarViewMode.week, isNotNull);
      expect(CalendarViewMode.list, isNotNull);
    });
  });

  // ─── SelectedDateNotifier — Datum-Navigation ──────────────────────────────

  group('SelectedDateNotifier — Datum wählen', () {
    test('selectDate() setzt ausgewähltes Datum', () {
      final (c, n) = _setupSelectedDate();
      final targetDate = DateTime(2025, 6, 15);

      n.selectDate(targetDate);

      final state = c.read(selectedDateProvider);
      expect(state.year, 2025);
      expect(state.month, 6);
      expect(state.day, 15);
    });

    test('selectToday() setzt heutiges Datum', () {
      final (c, n) = _setupSelectedDate();
      final today = DateTime.now();

      n.selectToday();

      final state = c.read(selectedDateProvider);
      expect(state.year, today.year);
      expect(state.month, today.month);
      expect(state.day, today.day);
    });
  });

  group('SelectedDateNotifier — Monats-Navigation', () {
    test('nextMonth() wechselt zum nächsten Monat', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 5, 15));

      n.nextMonth();

      final state = c.read(selectedDateProvider);
      expect(state.year, 2025);
      expect(state.month, 6);
      expect(state.day, 1);
    });

    test('nextMonth() bei Dezember wechselt zu nächstem Jahr', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 12, 15));

      n.nextMonth();

      final state = c.read(selectedDateProvider);
      expect(state.year, 2026);
      expect(state.month, 1);
    });

    test('previousMonth() wechselt zum vorherigen Monat', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 5, 15));

      n.previousMonth();

      final state = c.read(selectedDateProvider);
      expect(state.year, 2025);
      expect(state.month, 4);
      expect(state.day, 1);
    });

    test('previousMonth() bei Januar wechselt zu vorigem Jahr', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 1, 15));

      n.previousMonth();

      final state = c.read(selectedDateProvider);
      expect(state.year, 2024);
      expect(state.month, 12);
    });
  });

  group('SelectedDateNotifier — Wochen-Navigation', () {
    test('nextWeek() fügt 7 Tage hinzu', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 5, 15));

      n.nextWeek();

      final state = c.read(selectedDateProvider);
      expect(state.day, 22);
    });

    test('nextWeek() wechselt Monat bei Bedarf', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 5, 28));

      n.nextWeek();

      final state = c.read(selectedDateProvider);
      expect(state.month, 6);
      expect(state.day, 4);
    });

    test('previousWeek() zieht 7 Tage ab', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 5, 15));

      n.previousWeek();

      final state = c.read(selectedDateProvider);
      expect(state.day, 8);
    });

    test('previousWeek() wechselt Monat bei Bedarf', () {
      final (c, n) = _setupSelectedDate();
      n.selectDate(DateTime(2025, 5, 3));

      n.previousWeek();

      final state = c.read(selectedDateProvider);
      expect(state.month, 4);
      expect(state.day, 26);
    });
  });

  // ─── CalendarViewModeNotifier — Ansichtsmodus ─────────────────────────────

  group('CalendarViewModeNotifier — Ansichtsmodus wechseln', () {
    test('Standard-Modus ist Monat', () {
      final (c, _) = _setupViewMode();

      final state = c.read(calendarViewModeProvider);
      expect(state, CalendarViewMode.month);
    });

    test('setViewMode() wechselt zu Wochen-Ansicht', () {
      final (c, n) = _setupViewMode();

      n.setViewMode(CalendarViewMode.week);

      final state = c.read(calendarViewModeProvider);
      expect(state, CalendarViewMode.week);
    });

    test('setViewMode() wechselt zu Listen-Ansicht', () {
      final (c, n) = _setupViewMode();

      n.setViewMode(CalendarViewMode.list);

      final state = c.read(calendarViewModeProvider);
      expect(state, CalendarViewMode.list);
    });

    test('Mehrfacher Wechsel zwischen Modi', () {
      final (c, n) = _setupViewMode();

      n.setViewMode(CalendarViewMode.week);
      expect(c.read(calendarViewModeProvider), CalendarViewMode.week);

      n.setViewMode(CalendarViewMode.list);
      expect(c.read(calendarViewModeProvider), CalendarViewMode.list);

      n.setViewMode(CalendarViewMode.month);
      expect(c.read(calendarViewModeProvider), CalendarViewMode.month);
    });
  });
}
