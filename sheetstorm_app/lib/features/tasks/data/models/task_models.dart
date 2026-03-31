// Domain models for Task Management — MS3

// --- TaskStatus --------------------------------------------------------------

enum TaskStatus {
  open('open'),
  inProgress('inProgress'),
  done('done');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromJson(String value) => switch (value) {
        'open' => TaskStatus.open,
        'inProgress' => TaskStatus.inProgress,
        'done' => TaskStatus.done,
        _ => TaskStatus.open,
      };

  String toJson() => value;
}

// --- TaskPriority ------------------------------------------------------------

enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromJson(String value) => switch (value) {
        'low' => TaskPriority.low,
        'medium' => TaskPriority.medium,
        'high' => TaskPriority.high,
        _ => TaskPriority.medium,
      };

  String toJson() => value;
}

// --- TaskAssignee ------------------------------------------------------------

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
        userId: json['userId'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'avatarUrl': avatarUrl,
      };
}

// --- BandTask ----------------------------------------------------------------

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
    final creator = json['createdBy'] as Map<String, dynamic>;
    final rawAssignees = json['assignees'] as List<dynamic>? ?? [];

    return BandTask(
      id: json['id'] as String,
      bandId: json['bandId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatus.fromJson(json['status'] as String),
      priority: TaskPriority.fromJson(json['priority'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      eventId: json['eventId'] as String?,
      createdById: creator['id'] as String,
      createdByName: creator['name'] as String,
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
        'createdBy': {
          'id': createdById,
          'name': createdByName,
        },
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
        'bandId': bandId,
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