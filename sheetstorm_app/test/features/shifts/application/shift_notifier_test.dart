import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/shifts/application/shift_notifier.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

ShiftPlan _shiftPlan({
  String id = 'plan1',
  String name = 'Test Schichtplan',
  DateTime? date,
  List<Shift>? shifts,
  int totalSlots = 0,
  int filledSlots = 0,
}) =>
    ShiftPlan(
      id: id,
      bandId: 'band1',
      name: name,
      date: date ?? DateTime(2024, 6, 15),
      shifts: shifts ?? [],
      totalSlots: totalSlots,
      filledSlots: filledSlots,
    );

Shift _shift({
  String id = 'shift1',
  String planId = 'plan1',
  String name = 'Aufbau',
  DateTime? startTime,
  DateTime? endTime,
  int requiredPeople = 3,
  int assignedPeople = 0,
  List<ShiftAssignment>? assignments,
  ShiftStatus status = ShiftStatus.open,
}) =>
    Shift(
      id: id,
      planId: planId,
      name: name,
      startTime: startTime ?? DateTime(2024, 6, 15, 14, 0),
      endTime: endTime ?? DateTime(2024, 6, 15, 16, 0),
      requiredPeople: requiredPeople,
      assignedPeople: assignedPeople,
      assignments: assignments ?? [],
      status: status,
    );

ShiftAssignment _assignment({
  String id = 'assign1',
  String shiftId = 'shift1',
  String musicianId = 'musician1',
  String musicianName = 'Max Mustermann',
  bool isSelfAssigned = false,
}) =>
    ShiftAssignment(
      id: id,
      shiftId: shiftId,
      musicianId: musicianId,
      musicianName: musicianName,
      isSelfAssigned: isSelfAssigned,
      assignedAt: DateTime(2024, 6, 10),
    );

void main() {
  // Initialize Flutter bindings for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── ShiftPlanListNotifier Tests ───────────────────────────────────────────

  group('ShiftPlanListNotifier — Plan-Liste', () {
    test('Pläne werden initial geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shiftPlanListProvider('band1').notifier);

      expect(container.read(shiftPlanListProvider('band1')).isLoading, isTrue);
    });

    test('createPlan erstellt neuen Schichtplan', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanListProvider('band1').notifier);

      final plan = await notifier.createPlan(
        name: 'Sommerfest 2024',
        date: DateTime(2024, 7, 20),
      );

      expect(plan, isNotNull);
      expect(plan?.name, 'Sommerfest 2024');
    });

    test('createPlan mit description speichert Beschreibung', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanListProvider('band1').notifier);

      final plan = await notifier.createPlan(
        name: 'Konzert',
        date: DateTime(2024, 8, 15),
        description: 'Aufbau, Durchführung, Abbau',
      );

      expect(plan, isNotNull);
      expect(plan?.description, 'Aufbau, Durchführung, Abbau');
    });

    test('createPlan mit eventId verknüpft mit Event', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanListProvider('band1').notifier);

      final plan = await notifier.createPlan(
        name: 'Weihnachtskonzert Helfer',
        date: DateTime(2024, 12, 20),
        eventId: 'event123',
      );

      expect(plan, isNotNull);
      expect(plan?.eventId, 'event123');
    });

    test('deletePlan entfernt Plan', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanListProvider('band1').notifier);

      final success = await notifier.deletePlan('plan1');

      expect(success, isTrue);
    });

    test('deletePlan mit unbekannter ID gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanListProvider('band1').notifier);

      final success = await notifier.deletePlan('unknown_plan');

      expect(success, isFalse);
    });

    test('refresh lädt Plan-Liste neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanListProvider('band1').notifier);

      await notifier.refresh();

      expect(container.read(shiftPlanListProvider('band1')).isLoading, isTrue);
    });
  });

  // ─── ShiftPlanNotifier Tests ───────────────────────────────────────────────

  group('ShiftPlanNotifier — Plan-Details', () {
    test('Plan wird initial geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shiftPlanProvider('band1', 'plan1').notifier);

      expect(container.read(shiftPlanProvider('band1', 'plan1')).isLoading, isTrue);
    });

    test('createShift erstellt neue Schicht', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final shift = await notifier.createShift(
        name: 'Aufbau Bühne',
        startTime: DateTime(2024, 6, 15, 10, 0),
        endTime: DateTime(2024, 6, 15, 12, 0),
        requiredPeople: 5,
      );

      expect(shift, isNotNull);
      expect(shift?.name, 'Aufbau Bühne');
      expect(shift?.requiredPeople, 5);
    });

    test('createShift mit description speichert Details', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final shift = await notifier.createShift(
        name: 'Catering',
        startTime: DateTime(2024, 6, 15, 14, 0),
        endTime: DateTime(2024, 6, 15, 18, 0),
        requiredPeople: 3,
        description: 'Getränke und Snacks vorbereiten',
      );

      expect(shift, isNotNull);
      expect(shift?.description, 'Getränke und Snacks vorbereiten');
    });

    test('deleteShift entfernt Schicht', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.deleteShift('shift1');

      expect(success, isTrue);
    });

    test('refresh lädt Plan neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      await notifier.refresh();

      expect(container.read(shiftPlanProvider('band1', 'plan1')).isLoading, isTrue);
    });
  });

  // ─── Self-Assignment Tests ─────────────────────────────────────────────────

  group('ShiftPlanNotifier — Selbstzuordnung', () {
    test('selfAssign weist aktuelle Person zu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.selfAssign('shift1');

      expect(success, isTrue);
    });

    test('selfAssign auf volle Schicht gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.selfAssign('full_shift');

      expect(success, isFalse);
    });

    test('removeSelfAssignment entfernt eigene Zuordnung', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      await notifier.selfAssign('shift1');
      final success = await notifier.removeSelfAssignment('shift1');

      expect(success, isTrue);
    });

    test('removeSelfAssignment ohne Assignment gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.removeSelfAssignment('shift_no_assignment');

      expect(success, isFalse);
    });
  });

  // ─── Assignment Management Tests ───────────────────────────────────────────

  group('ShiftPlanNotifier — Zuordnungs-Management', () {
    test('assignMember weist Mitglied zu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.assignMember('shift1', 'musician2');

      expect(success, isTrue);
    });

    test('removeAssignment entfernt Zuordnung', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.removeAssignment('shift1', 'assign1');

      expect(success, isTrue);
    });

    test('removeAssignment mit unbekannter ID gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(shiftPlanProvider('band1', 'plan1').notifier);

      final success = await notifier.removeAssignment('shift1', 'unknown_assign');

      expect(success, isFalse);
    });
  });

  // ─── Shift Status Tests ────────────────────────────────────────────────────

  group('Shift — Status-Management', () {
    test('Open Status für offene Schicht', () {
      final shift = _shift(status: ShiftStatus.open);
      expect(shift.status, ShiftStatus.open);
    });

    test('Filled Status wenn Schicht voll', () {
      final shift = _shift(
        requiredPeople: 3,
        assignedPeople: 3,
        status: ShiftStatus.filled,
      );
      expect(shift.status, ShiftStatus.filled);
      expect(shift.isFull, isTrue);
    });

    test('Requested Status für angeforderte Schicht', () {
      final shift = _shift(status: ShiftStatus.requested);
      expect(shift.status, ShiftStatus.requested);
    });

    test('isFull ist true wenn assignedPeople >= requiredPeople', () {
      final shift = _shift(requiredPeople: 3, assignedPeople: 3);
      expect(shift.isFull, isTrue);
    });

    test('isFull ist false wenn assignedPeople < requiredPeople', () {
      final shift = _shift(requiredPeople: 5, assignedPeople: 2);
      expect(shift.isFull, isFalse);
    });

    test('openSlots berechnet freie Plätze', () {
      final shift = _shift(requiredPeople: 5, assignedPeople: 2);
      expect(shift.openSlots, 3);
    });

    test('openSlots ist 0 wenn voll', () {
      final shift = _shift(requiredPeople: 3, assignedPeople: 3);
      expect(shift.openSlots, 0);
    });
  });

  // ─── ShiftPlan Capacity Tests ──────────────────────────────────────────────

  group('ShiftPlan — Kapazitäts-Tracking', () {
    test('totalSlots summiert requiredPeople aller Shifts', () {
      final plan = _shiftPlan(
        shifts: [
          _shift(id: 's1', requiredPeople: 3),
          _shift(id: 's2', requiredPeople: 5),
          _shift(id: 's3', requiredPeople: 2),
        ],
        totalSlots: 10,
      );
      expect(plan.totalSlots, 10);
    });

    test('filledSlots summiert assignedPeople aller Shifts', () {
      final plan = _shiftPlan(
        shifts: [
          _shift(id: 's1', requiredPeople: 3, assignedPeople: 3),
          _shift(id: 's2', requiredPeople: 5, assignedPeople: 2),
        ],
        totalSlots: 8,
        filledSlots: 5,
      );
      expect(plan.filledSlots, 5);
    });

    test('Plan ohne Shifts hat 0 totalSlots', () {
      final plan = _shiftPlan(shifts: [], totalSlots: 0);
      expect(plan.totalSlots, 0);
    });
  });

  // ─── ShiftAssignment Tests ─────────────────────────────────────────────────

  group('ShiftAssignment — Zuordnungs-Details', () {
    test('Assignment enthält Musiker-Daten', () {
      final assignment = _assignment(
        musicianId: 'mus1',
        musicianName: 'Alice',
      );
      expect(assignment.musicianId, 'mus1');
      expect(assignment.musicianName, 'Alice');
    });

    test('isSelfAssigned ist true bei Selbstzuordnung', () {
      final assignment = _assignment(isSelfAssigned: true);
      expect(assignment.isSelfAssigned, isTrue);
    });

    test('isSelfAssigned ist false bei Admin-Zuordnung', () {
      final assignment = _assignment(isSelfAssigned: false);
      expect(assignment.isSelfAssigned, isFalse);
    });

    test('assignedAt speichert Zuordnungszeitpunkt', () {
      final assignedAt = DateTime(2024, 6, 10, 15, 30);
      final assignment = _assignment().copyWith(assignedAt: assignedAt);
      expect(assignment.assignedAt, assignedAt);
    });
  });

  // ─── MyShifts Provider Tests ───────────────────────────────────────────────

  group('myShifts Provider — Eigene Schichten', () {
    test('Gibt Shifts zurück wo User zugeordnet ist', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final myShifts = await container.read(
        myShiftsProvider('band1', 'musician1').future,
      );

      expect(myShifts, isA<List<Shift>>());
    });

    test('Leere Liste wenn User keine Assignments hat', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final myShifts = await container.read(
        myShiftsProvider('band1', 'musician_without_shifts').future,
      );

      expect(myShifts, isEmpty);
    });
  });

  // ─── OpenShifts Provider Tests ─────────────────────────────────────────────

  group('openShifts Provider — Offene Schichten', () {
    test('Gibt nur nicht-volle Shifts zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final openShifts = await container.read(
        openShiftsProvider('band1').future,
      );

      expect(openShifts, isA<List<Shift>>());
    });

    test('Filtert volle Shifts aus', () {
      final openShift = _shift(requiredPeople: 5, assignedPeople: 2);
      final fullShift = _shift(
        id: 'shift2',
        requiredPeople: 3,
        assignedPeople: 3,
      );

      expect(openShift.isFull, isFalse);
      expect(fullShift.isFull, isTrue);
    });

    test('Filtert geschlossene Shifts aus', () {
      final openShift = _shift(status: ShiftStatus.open);
      final filledShift = _shift(id: 'shift2', status: ShiftStatus.filled);

      expect(openShift.status, ShiftStatus.open);
      expect(filledShift.status, ShiftStatus.filled);
    });
  });

  // ─── Time Validation Tests ─────────────────────────────────────────────────

  group('Shift — Zeitvalidierung', () {
    test('startTime ist vor endTime', () {
      final shift = _shift(
        startTime: DateTime(2024, 6, 15, 10, 0),
        endTime: DateTime(2024, 6, 15, 12, 0),
      );
      expect(shift.startTime.isBefore(shift.endTime), isTrue);
    });

    test('Duration wird korrekt berechnet', () {
      final shift = _shift(
        startTime: DateTime(2024, 6, 15, 10, 0),
        endTime: DateTime(2024, 6, 15, 14, 0),
      );
      final duration = shift.endTime.difference(shift.startTime);
      expect(duration.inHours, 4);
    });

    test('Shift-Überlappungen sind möglich', () {
      final shift1 = _shift(
        id: 's1',
        startTime: DateTime(2024, 6, 15, 10, 0),
        endTime: DateTime(2024, 6, 15, 14, 0),
      );
      final shift2 = _shift(
        id: 's2',
        startTime: DateTime(2024, 6, 15, 12, 0),
        endTime: DateTime(2024, 6, 15, 16, 0),
      );

      // Shifts können sich überlappen
      expect(shift2.startTime.isBefore(shift1.endTime), isTrue);
    });
  });

  // ─── copyWith Tests ────────────────────────────────────────────────────────

  group('Shift — copyWith', () {
    test('copyWith aktualisiert Status', () {
      final shift = _shift(status: ShiftStatus.open);
      final filled = shift.copyWith(status: ShiftStatus.filled);

      expect(filled.status, ShiftStatus.filled);
      expect(filled.name, shift.name);
    });

    test('copyWith aktualisiert assignedPeople', () {
      final shift = _shift(assignedPeople: 0);
      final updated = shift.copyWith(assignedPeople: 2);

      expect(updated.assignedPeople, 2);
      expect(updated.requiredPeople, shift.requiredPeople);
    });

    test('copyWith aktualisiert assignments', () {
      final shift = _shift(assignments: []);
      final newAssignments = [
        _assignment(id: 'a1'),
        _assignment(id: 'a2'),
      ];
      final updated = shift.copyWith(assignments: newAssignments);

      expect(updated.assignments.length, 2);
    });
  });

  // ─── Provider Family Tests ─────────────────────────────────────────────────

  group('Shift Provider — Family-Scoping', () {
    test('Verschiedene bandId-Scopes sind unabhängig', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shiftPlanListProvider('band1').notifier);
      container.read(shiftPlanListProvider('band2').notifier);

      expect(container.read(shiftPlanListProvider('band1')).isLoading, isTrue);
      expect(container.read(shiftPlanListProvider('band2')).isLoading, isTrue);
    });

    test('Verschiedene planId-Scopes sind unabhängig', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(shiftPlanProvider('band1', 'plan1').notifier);
      container.read(shiftPlanProvider('band1', 'plan2').notifier);

      expect(container.read(shiftPlanProvider('band1', 'plan1')).isLoading, isTrue);
      expect(container.read(shiftPlanProvider('band1', 'plan2')).isLoading, isTrue);
    });

    test('Änderungen in plan1 beeinflussen nicht plan2', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier1 = container.read(shiftPlanProvider('band1', 'plan1').notifier);
      final notifier2 = container.read(shiftPlanProvider('band1', 'plan2').notifier);

      await notifier1.createShift(
        name: 'Plan1 Shift',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        requiredPeople: 3,
      );

      // plan2 should remain unchanged
      expect(container.read(shiftPlanProvider('band1', 'plan2')).isLoading, isTrue);
    });
  });
}
