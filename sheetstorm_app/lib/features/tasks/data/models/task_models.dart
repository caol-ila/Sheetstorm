// Domain models for Task Management — MS3
//
// Backend contract: src/Sheetstorm.Domain/Tasks/TaskModels.cs
// Enums serialize as int (ASP.NET Core default).

// --- BandTaskStatus (backend: BandTaskStatus) --------------------------------

enum TaskStatus {
  open(0),
  inProgress(1),
  done(2);

  const TaskStatus(this.value);
  final int value;

  static TaskStatus fromJson(dynamic value) => switch (value) {
        0 => TaskStatus.open,
        1 => TaskStatus.inProgress,
        2 => TaskStatus.done,
        _ => TaskStatus.open,
      };

  int toJson() => value;
}

// --- TaskPriority ------------------------------------------------------------

enum TaskPriority {
  low(0),
  medium(1),
  high(2);

  const TaskPriority(this.value);
  final int value;

  static TaskPriority fromJson(dynamic value) => switch (value) {
        0 => TaskPriority.low,
        1 => TaskPriority.medium,
        2 => TaskPriority.high,
        _ => TaskPriority.medium,
      };

  int toJson() => value;
}

// --- TaskAssignee (backend: TaskAssigneeDto) ---------------------------------

class TaskAssignee {
  final String musicianId;
  final String name;

  const TaskAssignee({
    required this.musicianId,
    required this.name,
  });

  factory TaskAssignee.fromJson(Map<String, dynamic> json) => TaskAssignee(
        musicianId: json['musicianId'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'musicianId': musicianId,
        'name': name,
      };
}

// --- BandTask (backend: BandTaskDto) -----------------------------------------

class BandTask {
  final String id;
  final String bandId;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? eventId;
  final String createdByMusicianId;
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
    required this.createdByMusicianId,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    required this.assignees,
  });

  factory BandTask.fromJson(Map<String, dynamic> json) {
    final rawAssignees = json['assignees'] as List<dynamic>? ?? [];

    return BandTask(
      id: json['id'] as String,
      bandId: json['bandId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromJson(json['status']),
      priority: TaskPriority.fromJson(json['priority']),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      eventId: json['eventId'] as String?,
      createdByMusicianId: json['createdByMusicianId'] as String,
      createdByName: json['createdByName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      assignees: rawAssignees
          .map((e) => TaskAssignee.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bandId': bandId,
        'title': title,
        if (description != null) 'description': description,
        'status': status.toJson(),
        'priority': priority.toJson(),
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (eventId != null) 'eventId': eventId,
        'createdByMusicianId': createdByMusicianId,
        'createdByName': createdByName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'assignees': assignees.map((a) => a.toJson()).toList(),
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
    String? createdByMusicianId,
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
        createdByMusicianId: createdByMusicianId ?? this.createdByMusicianId,
        createdByName: createdByName ?? this.createdByName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        assignees: assignees ?? this.assignees,
      );
}

// --- CreateTaskRequest -------------------------------------------------------

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
        'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (priority != null) 'priority': priority!.toJson(),
        if (eventId != null) 'eventId': eventId,
        if (assigneeIds != null) 'assigneeIds': assigneeIds,
      };
}

// --- UpdateTaskRequest -------------------------------------------------------

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
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
        if (priority != null) 'priority': priority!.toJson(),
        if (eventId != null) 'eventId': eventId,
      };
}