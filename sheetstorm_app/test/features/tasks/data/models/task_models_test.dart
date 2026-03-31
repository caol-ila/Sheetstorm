import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';

void main() {
  // --- TaskStatus -----------------------------------------------------------

  group('TaskStatus — fromJson / toJson', () {
    test('open parst korrekt', () {
      expect(TaskStatus.fromJson('open'), TaskStatus.open);
    });

    test('inProgress parst korrekt', () {
      expect(TaskStatus.fromJson('inProgress'), TaskStatus.inProgress);
    });

    test('done parst korrekt', () {
      expect(TaskStatus.fromJson('done'), TaskStatus.done);
    });

    test('unbekannter Wert → open (Fallback)', () {
      expect(TaskStatus.fromJson('unknown'), TaskStatus.open);
    });

    test('toJson gibt den richtigen String zurück', () {
      expect(TaskStatus.open.toJson(), 'open');
      expect(TaskStatus.inProgress.toJson(), 'inProgress');
      expect(TaskStatus.done.toJson(), 'done');
    });
  });

  // --- TaskPriority ---------------------------------------------------------

  group('TaskPriority — fromJson / toJson', () {
    test('low parst korrekt', () {
      expect(TaskPriority.fromJson('low'), TaskPriority.low);
    });

    test('medium parst korrekt', () {
      expect(TaskPriority.fromJson('medium'), TaskPriority.medium);
    });

    test('high parst korrekt', () {
      expect(TaskPriority.fromJson('high'), TaskPriority.high);
    });

    test('unbekannter Wert → medium (Fallback)', () {
      expect(TaskPriority.fromJson('unknown'), TaskPriority.medium);
    });

    test('toJson gibt den richtigen String zurück', () {
      expect(TaskPriority.low.toJson(), 'low');
      expect(TaskPriority.medium.toJson(), 'medium');
      expect(TaskPriority.high.toJson(), 'high');
    });
  });

  // --- BandTask — fromJson --------------------------------------------------

  group('BandTask — fromJson', () {
    final Map<String, dynamic> fullJson = {
      'id': 'task1',
      'bandId': 'band1',
      'title': 'Notenständer besorgen',
      'description': 'Für die nächste Probe',
      'status': 'open',
      'priority': 'high',
      'dueDate': '2025-06-01T18:00:00.000Z',
      'eventId': 'event1',
      'createdBy': {
        'id': 'user1',
        'name': 'Max Mustermann',
      },
      'createdAt': '2025-01-15T10:00:00.000Z',
      'updatedAt': '2025-01-15T10:00:00.000Z',
      'assignees': [
        {
          'userId': 'user2',
          'name': 'Anna Schmidt',
          'avatarUrl': null,
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

    test('Ersteller wird korrekt gemappt', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.createdById, 'user1');
      expect(task.createdByName, 'Max Mustermann');
    });

    test('Zuweisungen werden korrekt gemappt', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.assignees.length, 1);
      expect(task.assignees.first.userId, 'user2');
      expect(task.assignees.first.name, 'Anna Schmidt');
    });

    test('Optionale Felder sind null wenn nicht vorhanden', () {
      final minimalJson = <String, dynamic>{
        'id': 'task2',
        'bandId': 'band1',
        'title': 'Einfache Aufgabe',
        'status': 'open',
        'priority': 'medium',
        'createdBy': {'id': 'u1', 'name': 'Test'},
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
      createdById: 'user1',
      createdByName: 'Max',
      createdAt: DateTime.utc(2025, 1, 15, 10),
      updatedAt: DateTime.utc(2025, 1, 15, 10),
      assignees: [
        const TaskAssignee(userId: 'user2', name: 'Anna'),
      ],
    );

    test('Status wird korrekt serialisiert', () {
      final json = task.toJson();
      expect(json['status'], 'inProgress');
    });

    test('Priorität wird korrekt serialisiert', () {
      final json = task.toJson();
      expect(json['priority'], 'high');
    });

    test('Pflichtfelder sind vorhanden', () {
      final json = task.toJson();
      expect(json['id'], 'task1');
      expect(json['bandId'], 'band1');
      expect(json['title'], 'Test Aufgabe');
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
      createdById: 'user1',
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
      expect(updated.createdById, 'user1');
      expect(updated.assignees, isEmpty);
    });
  });

  // --- TaskAssignee ---------------------------------------------------------

  group('TaskAssignee — fromJson', () {
    test('Zugewiesener wird korrekt gemappt', () {
      final json = <String, dynamic>{
        'userId': 'u1',
        'name': 'Hans Maier',
        'avatarUrl': 'https://example.com/avatar.jpg',
      };
      final assignee = TaskAssignee.fromJson(json);
      expect(assignee.userId, 'u1');
      expect(assignee.name, 'Hans Maier');
      expect(assignee.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('avatarUrl kann null sein', () {
      final json = <String, dynamic>{
        'userId': 'u1',
        'name': 'Hans',
        'avatarUrl': null,
      };
      final assignee = TaskAssignee.fromJson(json);
      expect(assignee.avatarUrl, isNull);
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
      expect(json['bandId'], 'band1');
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
      expect(json['priority'], 'high');
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