import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';

void main() {
  // ─── TaskStatus ────────────────────────────────────────────────────────────

  group('TaskStatus — fromJson / toJson', () {
    test('offen parst korrekt', () {
      expect(TaskStatus.fromJson('offen'), TaskStatus.offen);
    });

    test('in_bearbeitung parst korrekt', () {
      expect(TaskStatus.fromJson('in_bearbeitung'), TaskStatus.inBearbeitung);
    });

    test('erledigt parst korrekt', () {
      expect(TaskStatus.fromJson('erledigt'), TaskStatus.erledigt);
    });

    test('unbekannter Wert → offen (Fallback)', () {
      expect(TaskStatus.fromJson('unknown'), TaskStatus.offen);
    });

    test('toJson gibt den richtigen String zurück', () {
      expect(TaskStatus.offen.toJson(), 'offen');
      expect(TaskStatus.inBearbeitung.toJson(), 'in_bearbeitung');
      expect(TaskStatus.erledigt.toJson(), 'erledigt');
    });
  });

  // ─── TaskPriority ─────────────────────────────────────────────────────────

  group('TaskPriority — fromJson / toJson', () {
    test('niedrig parst korrekt', () {
      expect(TaskPriority.fromJson('niedrig'), TaskPriority.niedrig);
    });

    test('mittel parst korrekt', () {
      expect(TaskPriority.fromJson('mittel'), TaskPriority.mittel);
    });

    test('hoch parst korrekt', () {
      expect(TaskPriority.fromJson('hoch'), TaskPriority.hoch);
    });

    test('unbekannter Wert → mittel (Fallback)', () {
      expect(TaskPriority.fromJson('unknown'), TaskPriority.mittel);
    });

    test('toJson gibt den richtigen String zurück', () {
      expect(TaskPriority.niedrig.toJson(), 'niedrig');
      expect(TaskPriority.mittel.toJson(), 'mittel');
      expect(TaskPriority.hoch.toJson(), 'hoch');
    });
  });

  // ─── BandTask — fromJson ──────────────────────────────────────────────────

  group('BandTask — fromJson', () {
    final Map<String, dynamic> fullJson = {
      'id': 'task1',
      'kapelle_id': 'band1',
      'titel': 'Notenständer besorgen',
      'beschreibung': 'Für die nächste Probe',
      'status': 'offen',
      'prioritaet': 'hoch',
      'faellig_am': '2025-06-01T18:00:00.000Z',
      'termin_id': 'event1',
      'erstellt_von': {
        'id': 'user1',
        'name': 'Max Mustermann',
      },
      'erstellt_am': '2025-01-15T10:00:00.000Z',
      'geaendert_am': '2025-01-15T10:00:00.000Z',
      'zuweisungen': [
        {
          'nutzer_id': 'user2',
          'name': 'Anna Schmidt',
          'avatar_url': null,
        },
      ],
    };

    test('Pflichtfelder werden korrekt gemappt', () {
      final task = BandTask.fromJson(fullJson);
      expect(task.id, 'task1');
      expect(task.bandId, 'band1');
      expect(task.title, 'Notenständer besorgen');
      expect(task.status, TaskStatus.offen);
      expect(task.priority, TaskPriority.hoch);
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
        'kapelle_id': 'band1',
        'titel': 'Einfache Aufgabe',
        'status': 'offen',
        'prioritaet': 'mittel',
        'erstellt_von': {'id': 'u1', 'name': 'Test'},
        'erstellt_am': '2025-01-15T10:00:00.000Z',
        'geaendert_am': '2025-01-15T10:00:00.000Z',
        'zuweisungen': <dynamic>[],
      };
      final task = BandTask.fromJson(minimalJson);
      expect(task.description, isNull);
      expect(task.dueDate, isNull);
      expect(task.eventId, isNull);
      expect(task.assignees, isEmpty);
    });
  });

  // ─── BandTask — toJson ────────────────────────────────────────────────────

  group('BandTask — toJson', () {
    final task = BandTask(
      id: 'task1',
      bandId: 'band1',
      title: 'Test Aufgabe',
      description: 'Beschreibung',
      status: TaskStatus.inBearbeitung,
      priority: TaskPriority.hoch,
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
      expect(json['status'], 'in_bearbeitung');
    });

    test('Priorität wird korrekt serialisiert', () {
      final json = task.toJson();
      expect(json['prioritaet'], 'hoch');
    });

    test('Pflichtfelder sind vorhanden', () {
      final json = task.toJson();
      expect(json['id'], 'task1');
      expect(json['kapelle_id'], 'band1');
      expect(json['titel'], 'Test Aufgabe');
    });
  });

  // ─── BandTask — copyWith ──────────────────────────────────────────────────

  group('BandTask — copyWith', () {
    final original = BandTask(
      id: 'task1',
      bandId: 'band1',
      title: 'Original',
      status: TaskStatus.offen,
      priority: TaskPriority.mittel,
      createdById: 'user1',
      createdByName: 'Max',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      assignees: const [],
    );

    test('Status kann geändert werden', () {
      final updated = original.copyWith(status: TaskStatus.erledigt);
      expect(updated.status, TaskStatus.erledigt);
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

  // ─── TaskAssignee ─────────────────────────────────────────────────────────

  group('TaskAssignee — fromJson', () {
    test('Zugewiesener wird korrekt gemappt', () {
      final json = <String, dynamic>{
        'nutzer_id': 'u1',
        'name': 'Hans Maier',
        'avatar_url': 'https://example.com/avatar.jpg',
      };
      final assignee = TaskAssignee.fromJson(json);
      expect(assignee.userId, 'u1');
      expect(assignee.name, 'Hans Maier');
      expect(assignee.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('avatar_url kann null sein', () {
      final json = <String, dynamic>{
        'nutzer_id': 'u1',
        'name': 'Hans',
        'avatar_url': null,
      };
      final assignee = TaskAssignee.fromJson(json);
      expect(assignee.avatarUrl, isNull);
    });
  });

  // ─── CreateTaskRequest ────────────────────────────────────────────────────

  group('CreateTaskRequest — toJson', () {
    test('Pflichtfelder werden serialisiert', () {
      final req = const CreateTaskRequest(
        title: 'Neue Aufgabe',
        bandId: 'band1',
      );
      final json = req.toJson();
      expect(json['titel'], 'Neue Aufgabe');
      expect(json['kapelle_id'], 'band1');
    });

    test('Optionale Felder werden nur eingeschlossen wenn gesetzt', () {
      final req = CreateTaskRequest(
        title: 'Neue Aufgabe',
        bandId: 'band1',
        description: 'Beschreibung',
        dueDate: DateTime.utc(2025, 6, 1),
        priority: TaskPriority.hoch,
      );
      final json = req.toJson();
      expect(json['beschreibung'], 'Beschreibung');
      expect(json['faellig_am'], isNotNull);
      expect(json['prioritaet'], 'hoch');
    });

    test('Nicht gesetzte optionale Felder fehlen im JSON', () {
      final req = const CreateTaskRequest(
        title: 'Minimal',
        bandId: 'band1',
      );
      final json = req.toJson();
      expect(json.containsKey('beschreibung'), isFalse);
      expect(json.containsKey('faellig_am'), isFalse);
    });
  });
}
