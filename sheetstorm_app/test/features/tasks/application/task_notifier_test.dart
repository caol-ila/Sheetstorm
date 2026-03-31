import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/tasks/application/task_notifier.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';
import 'package:sheetstorm/features/tasks/data/services/task_service.dart';

// --- Mocks ------------------------------------------------------------------

class MockTaskService extends Mock implements TaskService {}

// --- Helpers ----------------------------------------------------------------

BandTask _task({
  String id = 'task1',
  String title = 'Test Aufgabe',
  TaskStatus status = TaskStatus.open,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
}) =>
    BandTask(
      id: id,
      bandId: 'band1',
      title: title,
      status: status,
      priority: priority,
      dueDate: dueDate,
      createdByMusicianId: 'user1',
      createdByName: 'Max Mustermann',
      createdAt: DateTime(2025, 1, 15),
      updatedAt: DateTime(2025, 1, 15),
      assignees: const [],
    );

/// Creates container with service override + default stub so build() succeeds.
(ProviderContainer, MockTaskService) _makeContainer({String bandId = 'band1'}) {
  final service = MockTaskService();
  // Default stub for build() — overridden per test via refresh()
  when(() => service.getTasks(
        bandId: any(named: 'bandId'),
        status: any(named: 'status'),
      )).thenAnswer((_) async => []);

  final container = ProviderContainer(
    overrides: [taskServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return (container, service);
}

(ProviderContainer, TaskListNotifier, MockTaskService) _setupList({
  String bandId = 'band1',
}) {
  final (container, service) = _makeContainer(bandId: bandId);
  final notifier = container.read(taskListProvider(bandId: bandId).notifier);
  return (container, notifier, service);
}

(ProviderContainer, TaskDetailNotifier, MockTaskService) _setupDetail(
    String taskId, {BandTask? initialTask}) {
  final service = MockTaskService();
  final task = initialTask ?? _task(id: taskId);
  when(() => service.getTaskDetail('band1', taskId)).thenAnswer((_) async => task);

  final container = ProviderContainer(
    overrides: [taskServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  final notifier = container.read(taskDetailProvider(taskId, bandId: 'band1').notifier);
  return (container, notifier, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(TaskStatus.open);
    registerFallbackValue(TaskPriority.medium);
    registerFallbackValue(DateTime(2025, 1, 1));
    registerFallbackValue(
      const CreateTaskRequest(title: 'fallback', bandId: 'band1'),
    );
  });

  // --- TaskListNotifier — Laden ---------------------------------------------

  group('TaskListNotifier — Aufgaben laden', () {
    test('Aufgaben werden vom Service geladen', () async {
      final (c, n, service) = _setupList();
      final tasks = [
        _task(id: 'task1'),
        _task(id: 'task2', title: 'Zweite Aufgabe'),
      ];

      when(() => service.getTasks(
            bandId: 'band1',
            status: any(named: 'status'),
          )).thenAnswer((_) async => tasks);

      await n.refresh();

      final state = c.read(taskListProvider(bandId: 'band1')).value;
      expect(state?.length, 2);
      expect(state?.first.title, 'Test Aufgabe');
    });

    test('Ladefehler setzt AsyncError', () async {
      final (c, n, service) = _setupList();

      when(() => service.getTasks(
            bandId: 'band1',
            status: any(named: 'status'),
          )).thenThrow(Exception('Netzwerkfehler'));

      await n.refresh();

      expect(c.read(taskListProvider(bandId: 'band1')).hasError, isTrue);
    });
  });

  // --- TaskListNotifier — Aufgabe erstellen ---------------------------------

  group('TaskListNotifier — Aufgabe erstellen', () {
    test('Neue Aufgabe wird zur Liste hinzugefügt', () async {
      final (c, n, service) = _setupList();
      final newTask = _task(id: 'new1', title: 'Neue Aufgabe');

      await c.read(taskListProvider(bandId: 'band1').future);

      when(() => service.createTask(any()))
          .thenAnswer((_) async => newTask);

      final result = await n.createTask(
        title: 'Neue Aufgabe',
        bandId: 'band1',
      );

      expect(result, isNotNull);
      expect(result?.title, 'Neue Aufgabe');

      final state = c.read(taskListProvider(bandId: 'band1')).value;
      expect(state?.any((t) => t.id == 'new1'), isTrue);
    });

    test('Fehler bei Erstellung setzt AsyncError', () async {
      final (c, n, service) = _setupList();

      await c.read(taskListProvider(bandId: 'band1').future);

      when(() => service.createTask(any()))
          .thenThrow(Exception('API Fehler'));

      final result = await n.createTask(title: 'Fehler', bandId: 'band1');

      expect(result, isNull);
      expect(c.read(taskListProvider(bandId: 'band1')).hasError, isTrue);
    });
  });

  // --- TaskListNotifier — Aufgabe löschen ----------------------------------

  group('TaskListNotifier — Aufgabe löschen', () {
    test('Aufgabe wird aus Liste entfernt', () async {
      final (c, n, service) = _setupList();
      final tasks = [
        _task(id: 'task1'),
        _task(id: 'task2'),
      ];

      when(() => service.getTasks(
            bandId: 'band1',
            status: any(named: 'status'),
          )).thenAnswer((_) async => tasks);

      await n.refresh();

      when(() => service.deleteTask('band1', 'task1')).thenAnswer((_) async {});

      final success = await n.deleteTask('task1');

      expect(success, isTrue);
      final state = c.read(taskListProvider(bandId: 'band1')).value;
      expect(state?.length, 1);
      expect(state?.first.id, 'task2');
    });

    test('Fehler beim Löschen setzt AsyncError', () async {
      final (c, n, service) = _setupList();

      await c.read(taskListProvider(bandId: 'band1').future);

      when(() => service.deleteTask(any(), any()))
          .thenThrow(Exception('Löschfehler'));

      final success = await n.deleteTask('task1');

      expect(success, isFalse);
      expect(c.read(taskListProvider(bandId: 'band1')).hasError, isTrue);
    });
  });

  // --- TaskDetailNotifier — Details laden ----------------------------------

  group('TaskDetailNotifier — Details laden', () {
    test('Aufgaben-Details werden geladen', () async {
      final task = _task(id: 'task1', title: 'Detail Aufgabe');
      final (c, _notifier, _service) = _setupDetail('task1', initialTask: task);

      await c.read(taskDetailProvider('task1', bandId: 'band1').future);

      final state = c.read(taskDetailProvider('task1', bandId: 'band1')).value;
      expect(state?.title, 'Detail Aufgabe');
    });

    test('Ladefehler setzt AsyncError', () async {
      final service = MockTaskService();
      when(() => service.getTaskDetail('band1', 'task1'))
          .thenThrow(Exception('Nicht gefunden'));

      final container = ProviderContainer(
        overrides: [taskServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      // Listen to prevent auto-dispose during load
      container.listen(taskDetailProvider('task1', bandId: 'band1'), (_, __) {});

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(taskDetailProvider('task1', bandId: 'band1')).hasError, isTrue);
    });
  });

  // --- TaskDetailNotifier — Status ändern ----------------------------------

  group('TaskDetailNotifier — Status ändern', () {
    test('Status wird auf In Bearbeitung gesetzt', () async {
      final original = _task(id: 'task1', status: TaskStatus.open);
      final updated = _task(id: 'task1', status: TaskStatus.inProgress);
      final (c, n, service) = _setupDetail('task1', initialTask: original);

      when(() => service.updateTaskStatus('band1', 'task1', TaskStatus.inProgress))
          .thenAnswer((_) async => updated);

      await c.read(taskDetailProvider('task1', bandId: 'band1').future);

      final success = await n.updateStatus(TaskStatus.inProgress);

      expect(success, isTrue);
      final state = c.read(taskDetailProvider('task1', bandId: 'band1')).value;
      expect(state?.status, TaskStatus.inProgress);
    });

    test('Status wird auf Done gesetzt', () async {
      final original = _task(id: 'task1', status: TaskStatus.inProgress);
      final done = _task(id: 'task1', status: TaskStatus.done);
      final (c, n, service) = _setupDetail('task1', initialTask: original);

      when(() => service.updateTaskStatus('band1', 'task1', TaskStatus.done))
          .thenAnswer((_) async => done);

      await c.read(taskDetailProvider('task1', bandId: 'band1').future);

      final success = await n.updateStatus(TaskStatus.done);

      expect(success, isTrue);
      final state = c.read(taskDetailProvider('task1', bandId: 'band1')).value;
      expect(state?.status, TaskStatus.done);
    });

    test('Fehler bei Status-Änderung setzt AsyncError', () async {
      final original = _task(id: 'task1');
      final (c, n, service) = _setupDetail('task1', initialTask: original);

      when(() => service.updateTaskStatus(any(), any(), any()))
          .thenThrow(Exception('Status-Fehler'));

      await c.read(taskDetailProvider('task1', bandId: 'band1').future);

      final success = await n.updateStatus(TaskStatus.done);

      expect(success, isFalse);
      expect(c.read(taskDetailProvider('task1', bandId: 'band1')).hasError, isTrue);
    });
  });

  // --- TaskDetailNotifier — Aufgabe bearbeiten -----------------------------

  group('TaskDetailNotifier — Aufgabe bearbeiten', () {
    test('Titel wird aktualisiert', () async {
      final original = _task(id: 'task1', title: 'Alter Titel');
      final updated = _task(id: 'task1', title: 'Neuer Titel');
      final (c, n, service) = _setupDetail('task1', initialTask: original);

      when(() => service.updateTask(
            'band1',
            'task1',
            title: 'Neuer Titel',
            description: any(named: 'description'),
            dueDate: any(named: 'dueDate'),
            priority: any(named: 'priority'),
            eventId: any(named: 'eventId'),
          )).thenAnswer((_) async => updated);

      await c.read(taskDetailProvider('task1', bandId: 'band1').future);

      final success = await n.updateTask(title: 'Neuer Titel');

      expect(success, isTrue);
      final state = c.read(taskDetailProvider('task1', bandId: 'band1')).value;
      expect(state?.title, 'Neuer Titel');
    });
  });

  // --- TaskListNotifier — Filter --------------------------------------------

  group('TaskListNotifier — Filter', () {
    test('filterByStatus() gibt offene Aufgaben zurück', () async {
      final (c, n, service) = _setupList();
      final tasks = [
        _task(id: 't1', status: TaskStatus.open),
        _task(id: 't2', status: TaskStatus.done),
        _task(id: 't3', status: TaskStatus.open),
      ];

      when(() => service.getTasks(
            bandId: 'band1',
            status: any(named: 'status'),
          )).thenAnswer((_) async => tasks);

      await n.refresh();

      final open = n.filterByStatus(TaskStatus.open);

      expect(open.length, 2);
      expect(open.every((t) => t.status == TaskStatus.open), isTrue);
    });

    test('filterByStatus() gibt erledigte Aufgaben zurück', () async {
      final (c, n, service) = _setupList();
      final tasks = [
        _task(id: 't1', status: TaskStatus.open),
        _task(id: 't2', status: TaskStatus.done),
      ];

      when(() => service.getTasks(
            bandId: 'band1',
            status: any(named: 'status'),
          )).thenAnswer((_) async => tasks);

      await n.refresh();

      final done = n.filterByStatus(TaskStatus.done);

      expect(done.length, 1);
      expect(done.first.status, TaskStatus.done);
    });

    test('filterByStatus() mit leerem Ergebnis', () async {
      final (c, n, service) = _setupList();
      final tasks = [
        _task(id: 't1', status: TaskStatus.open),
      ];

      when(() => service.getTasks(
            bandId: 'band1',
            status: any(named: 'status'),
          )).thenAnswer((_) async => tasks);

      await n.refresh();

      final inProgress = n.filterByStatus(TaskStatus.inProgress);

      expect(inProgress, isEmpty);
    });
  });
}