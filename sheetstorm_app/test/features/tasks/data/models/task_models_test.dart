import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';

void main() {
  // --- TaskStatus -----------------------------------------------------------

  group('TaskStatus — fromJson / toJson', () {
    test('0 → open', () {
      expect(TaskStatus.fromJson(0), TaskStatus.open);
    });

    test('1 → inProgress', () {
      expect(TaskStatus.fromJson(1), TaskStatus.inProgress);
    });

    test('2 → done', () {
      expect(TaskStatus.fromJson(2), TaskStatus.done);
    });

    test('unbekannter Wert → open (Fallback)', () {
      expect(TaskStatus.fromJson(99), TaskStatus.open);
    });

    test('toJson gibt den richtigen int zurück', () {
      expect(TaskStatus.open.toJson(), 0);
      expect(TaskStatus.inProgress.toJson(), 1);
      expect(TaskStatus.done.toJson(), 2);
    });
  });

  // --- TaskPriority ---------------------------------------------------------

  group('TaskPriority — fromJson / toJson', () {
    test('0 → low', () {
      expect(TaskPriority.fromJson(0), TaskPriority.low);
    });

    test('1 → medium', () {
      expect(TaskPriority.fromJson(1), TaskPriority.medium);
    });

    test('2 → high', () {
      expect(TaskPriority.fromJson(2), TaskPriority.high);
    });

    test('unbekannter Wert → medium (Fallback)', () {
      expect(TaskPriority.fromJson(99), TaskPriority.medium);
    });

    test('toJson gibt den richtigen int zurück', () {
      expect(TaskPriority.low.toJson(), 0);
      expect(TaskPriority.medium.toJson(), 1);
      expect(TaskPriority.high.toJson(), 2);
    });
  });

  // --- BandTask — fromJson --------------------------------------------------

  group('BandTask — fromJson', () {
    final Map<String, dynamic> fullJson = {
      'id': 'task1',
      'bandId': 'band1',
      'title': 'Notenständer besorgen',
      'description': 'Für die nächste Probe',
      'status': 0, // Open
      'priority': 2, // High
      'dueDate': '2025-06-01T18:00:00.000Z',
      'eventId': 'event1',
      'createdByMusicianId': 'user1',
      'createdByName': 'Max Mustermann',
      'createdAt': '2025-01-15T10:00:00.000Z',
      'updatedAt': '2025-01-15T10:00:00.000Z',
      'assignees': [
        {
          'musicianId': 'user2',
          'name': 'Anna Schmidt',
        },
      ],
    };

    test('Pflichtfelder werden korrekt gemappt', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.id, 'task1');
      expect(task.bandId, 'band1');
      expect(task.title, 'Notenständer besorgen');
      expect(task.status, TaskStatus.open);
      expect(task.priority, TaskPriority.high);
    });

    test('Optionale Felder werden korrekt gemappt', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.description, 'Für die nächste Probe');
      expect(task.dueDate, isNotNull);
      expect(task.eventId, 'event1');
    });

    test('Ersteller wird korrekt gemappt (flat fields)', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.createdByMusicianId, 'user1');
      expect(task.createdByName, 'Max Mustermann');
    });

    test('Zuweisungen werden korrekt gemappt', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.assignees.length, 1);
      expect(task.assignees.first.musicianId, 'user2');
      expect(task.assignees.first.name, 'Anna Schmidt');
    });

    test('Optionale Felder sind null wenn nicht vorhanden', () {
      final minimalJson = <String, dynamic>{
        'id': 'task2',
        'bandId': 'band1',
        'title': 'Einfache Aufgabe',
        'status': 0,
        'priority': 1,
        'createdByMusicianId': 'u1',
        'createdByName': 'Test',
        'createdAt': '2025-01-15T10:00:00.000Z',
        'updatedAt': '2025-01-15T10:00:00.000Z',
        'assignees': <dynamic>[],
      };
      final task = BandTask.fromJson(minimalJson);
      expect(task.description, isNull);
      expect(task.dueDate, isNull);
      expect(task.eventId, isNull);
      expect(task.assignees, isEmpty);
    });
  });

  // --- BandTask — toJson ----------------------------------------------------

  group('BandTask — toJson', () {
    final task = BandTask(
      id: 'task1',
      bandId: 'band1',
      title: 'Test Aufgabe',
      description: 'Beschreibung',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      dueDate: DateTime.utc(2025, 6, 1, 18),
      eventId: 'event1',
      createdByMusicianId: 'user1',
      createdByName: 'Max',
      createdAt: DateTime.utc(2025, 1, 15, 10),
      updatedAt: DateTime.utc(2025, 1, 15, 10),
      assignees: [
        const TaskAssignee(musicianId: 'user2', name: 'Anna'),
      ],
    );

    test('Status wird als int serialisiert', () {
      final json = task.toJson();
      expect(json['status'], 1); // inProgress = 1
    });

    test('Priorität wird als int serialisiert', () {
      final json = task.toJson();
      expect(json['priority'], 2); // high = 2
    });

    test('Pflichtfelder sind vorhanden', () {
      final json = task.toJson();
      expect(json['id'], 'task1');
      expect(json['bandId'], 'band1');
      expect(json['title'], 'Test Aufgabe');
    });

    test('createdByMusicianId als flat field', () {
      final json = task.toJson();
      expect(json['createdByMusicianId'], 'user1');
      expect(json['createdByName'], 'Max');
      expect(json.containsKey('createdBy'), isFalse);
    });
  });

  // --- BandTask — copyWith --------------------------------------------------

  group('BandTask — copyWith', () {
    final original = BandTask(
      id: 'task1',
      bandId: 'band1',
      title: 'Original',
      status: TaskStatus.open,
      priority: TaskPriority.medium,
      createdByMusicianId: 'user1',
      createdByName: 'Max',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      assignees: const [],
    );

    test('Status kann geändert werden', () {
      final updated = original.copyWith(status: TaskStatus.done);
      expect(updated.status, TaskStatus.done);
      expect(updated.id, 'task1');
    });

    test('Titel kann geändert werden', () {
      final updated = original.copyWith(title: 'Neu');
      expect(updated.title, 'Neu');
      expect(updated.bandId, 'band1');
    });

    test('Unveränderliche Felder bleiben erhalten', () {
      final updated = original.copyWith(title: 'Neu');
      expect(updated.createdByMusicianId, 'user1');
      expect(updated.assignees, isEmpty);
    });
  });

  // --- TaskAssignee ---------------------------------------------------------

  group('TaskAssignee — fromJson', () {
    test('Zugewiesener wird korrekt gemappt', () {
      final json = <String, dynamic>{
        'musicianId': 'u1',
        'name': 'Hans Maier',
      };
      final assignee = TaskAssignee.fromJson(json);
      expect(assignee.musicianId, 'u1');
      expect(assignee.name, 'Hans Maier');
    });
  });

  // --- CreateTaskRequest ----------------------------------------------------

  group('CreateTaskRequest — toJson', () {
    test('Pflichtfelder werden serialisiert', () {
      final req = const CreateTaskRequest(
        title: 'Neue Aufgabe',
        bandId: 'band1',
      );
      final json = req.toJson();
      expect(json['title'], 'Neue Aufgabe');
      // bandId is used for URL path, not in body
      expect(json.containsKey('bandId'), isFalse);
    });

    test('Optionale Felder werden nur eingeschlossen wenn gesetzt', () {
      final req = CreateTaskRequest(
        title: 'Neue Aufgabe',
        bandId: 'band1',
        description: 'Beschreibung',
        dueDate: DateTime.utc(2025, 6, 1),
        priority: TaskPriority.high,
      );
      final json = req.toJson();
      expect(json['description'], 'Beschreibung');
      expect(json['dueDate'], isNotNull);
      expect(json['priority'], 2); // high = 2
    });

    test('Nicht gesetzte optionale Felder fehlen im JSON', () {
      final req = const CreateTaskRequest(
        title: 'Minimal',
        bandId: 'band1',
      );
      final json = req.toJson();
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('dueDate'), isFalse);
    });
  });
}