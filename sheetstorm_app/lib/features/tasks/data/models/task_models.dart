// Domain models for Aufgabenverwaltung (Task Management) — MS3

// ─── TaskStatus ───────────────────────────────────────────────────────────────

enum TaskStatus {
  offen('offen'),
  inBearbeitung('in_bearbeitung'),
  erledigt('erledigt');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromJson(String value) => switch (value) {
        'offen' => TaskStatus.offen,
        'in_bearbeitung' => TaskStatus.inBearbeitung,
        'erledigt' => TaskStatus.erledigt,
        _ => TaskStatus.offen,
      };

  String toJson() => value;
}

// ─── TaskPriority ─────────────────────────────────────────────────────────────

enum TaskPriority {
  niedrig('niedrig'),
  mittel('mittel'),
  hoch('hoch');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromJson(String value) => switch (value) {
        'niedrig' => TaskPriority.niedrig,
        'mittel' => TaskPriority.mittel,
        'hoch' => TaskPriority.hoch,
        _ => TaskPriority.mittel,
      };

  String toJson() => value;
}

// ─── TaskAssignee ─────────────────────────────────────────────────────────────

class TaskAssignee {
  final String userId;
  final String name;
  final String? avatarUrl;

  const TaskAssignee({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  factory TaskAssignee.fromJson(Map<String, dynamic> json) => TaskAssignee(
        userId: json['nutzer_id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'nutzer_id': userId,
        'name': name,
        'avatar_url': avatarUrl,
      };
}

// ─── BandTask ─────────────────────────────────────────────────────────────────

class BandTask {
  final String id;
  final String bandId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? eventId;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskAssignee> assignees;

  const BandTask({
    required this.id,
    required this.bandId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.eventId,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.assignees,
  });

  factory BandTask.fromJson(Map<String, dynamic> json) {
    final creator = json['erstellt_von'] as Map<String, dynamic>;
    final rawAssignees = json['zuweisungen'] as List<dynamic>? ?? [];

    return BandTask(
      id: json['id'] as String,
      bandId: json['kapelle_id'] as String,
      title: json['titel'] as String,
      description: json['beschreibung'] as String?,
      status: TaskStatus.fromJson(json['status'] as String),
      priority: TaskPriority.fromJson(json['prioritaet'] as String),
      dueDate: json['faellig_am'] != null
          ? DateTime.parse(json['faellig_am'] as String)
          : null,
      eventId: json['termin_id'] as String?,
      createdById: creator['id'] as String,
      createdByName: creator['name'] as String,
      createdAt: DateTime.parse(json['erstellt_am'] as String),
      updatedAt: DateTime.parse(json['geaendert_am'] as String),
      assignees: rawAssignees
          .map((e) => TaskAssignee.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kapelle_id': bandId,
        'titel': title,
        if (description != null) 'beschreibung': description,
        'status': status.toJson(),
        'prioritaet': priority.toJson(),
        if (dueDate != null) 'faellig_am': dueDate!.toIso8601String(),
        if (eventId != null) 'termin_id': eventId,
        'erstellt_von': {
          'id': createdById,
          'name': createdByName,
        },
        'erstellt_am': createdAt.toIso8601String(),
        'geaendert_am': updatedAt.toIso8601String(),
        'zuweisungen': assignees.map((a) => a.toJson()).toList(),
      };

  BandTask copyWith({
    String? id,
    String? bandId,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? eventId,
    String? createdById,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskAssignee>? assignees,
  }) =>
      BandTask(
        id: id ?? this.id,
        bandId: bandId ?? this.bandId,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        eventId: eventId ?? this.eventId,
        createdById: createdById ?? this.createdById,
        createdByName: createdByName ?? this.createdByName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        assignees: assignees ?? this.assignees,
      );
}

// ─── CreateTaskRequest ────────────────────────────────────────────────────────

class CreateTaskRequest {
  final String title;
  final String bandId;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final String? eventId;
  final List<String>? assigneeIds;

  const CreateTaskRequest({
    required this.title,
    required this.bandId,
    this.description,
    this.dueDate,
    this.priority,
    this.eventId,
    this.assigneeIds,
  });

  Map<String, dynamic> toJson() => {
        'titel': title,
        'kapelle_id': bandId,
        if (description != null) 'beschreibung': description,
        if (dueDate != null) 'faellig_am': dueDate!.toIso8601String(),
        if (priority != null) 'prioritaet': priority!.toJson(),
        if (eventId != null) 'termin_id': eventId,
        if (assigneeIds != null) 'zuweisungen': assigneeIds,
      };
}

// ─── UpdateTaskRequest ────────────────────────────────────────────────────────

class UpdateTaskRequest {
  final String? title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final String? eventId;

  const UpdateTaskRequest({
    this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.eventId,
  });

  Map<String, dynamic> toJson() => {
        if (title != null) 'titel': title,
        if (description != null) 'beschreibung': description,
        if (dueDate != null) 'faellig_am': dueDate!.toIso8601String(),
        if (priority != null) 'prioritaet': priority!.toJson(),
        if (eventId != null) 'termin_id': eventId,
      };
}
