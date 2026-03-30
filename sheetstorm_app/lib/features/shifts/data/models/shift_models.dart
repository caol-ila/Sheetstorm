/// Domain models for Shift Planning — Issue TBD (MS2)

// ─── Shift Status ─────────────────────────────────────────────────────────────

enum ShiftStatus {
  open('Offen'),
  filled('Besetzt'),
  requested('Angefragt');

  const ShiftStatus(this.label);
  final String label;

  static ShiftStatus fromJson(String value) => switch (value) {
        'open' => ShiftStatus.open,
        'filled' => ShiftStatus.filled,
        'requested' => ShiftStatus.requested,
        _ => ShiftStatus.open,
      };

  String toJson() => name;
}

// ─── Shift Plan ───────────────────────────────────────────────────────────────

class ShiftPlan {
  final String id;
  final String bandId;
  final String name;
  final DateTime date;
  final String? description;
  final String? eventId;
  final String? eventName;
  final List<Shift> shifts;
  final int totalSlots;
  final int filledSlots;

  const ShiftPlan({
    required this.id,
    required this.bandId,
    required this.name,
    required this.date,
    this.description,
    this.eventId,
    this.eventName,
    this.shifts = const [],
    this.totalSlots = 0,
    this.filledSlots = 0,
  });

  factory ShiftPlan.fromJson(Map<String, dynamic> json) => ShiftPlan(
        id: json['id'] as String,
        bandId: json['band_id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        description: json['description'] as String?,
        eventId: json['event_id'] as String?,
        eventName: json['event_name'] as String?,
        shifts: (json['shifts'] as List<dynamic>?)
                ?.map((e) => Shift.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        totalSlots: json['total_slots'] as int? ?? 0,
        filledSlots: json['filled_slots'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'band_id': bandId,
        'name': name,
        'date': date.toIso8601String(),
        'description': description,
        'event_id': eventId,
        'event_name': eventName,
        'shifts': shifts.map((s) => s.toJson()).toList(),
        'total_slots': totalSlots,
        'filled_slots': filledSlots,
      };

  ShiftPlan copyWith({
    String? id,
    String? bandId,
    String? name,
    DateTime? date,
    String? description,
    String? eventId,
    String? eventName,
    List<Shift>? shifts,
    int? totalSlots,
    int? filledSlots,
  }) =>
      ShiftPlan(
        id: id ?? this.id,
        bandId: bandId ?? this.bandId,
        name: name ?? this.name,
        date: date ?? this.date,
        description: description ?? this.description,
        eventId: eventId ?? this.eventId,
        eventName: eventName ?? this.eventName,
        shifts: shifts ?? this.shifts,
        totalSlots: totalSlots ?? this.totalSlots,
        filledSlots: filledSlots ?? this.filledSlots,
      );
}

// ─── Shift ────────────────────────────────────────────────────────────────────

class Shift {
  final String id;
  final String planId;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final int requiredPeople;
  final int assignedPeople;
  final String? description;
  final List<ShiftAssignment> assignments;
  final ShiftStatus status;

  const Shift({
    required this.id,
    required this.planId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.requiredPeople,
    this.assignedPeople = 0,
    this.description,
    this.assignments = const [],
    this.status = ShiftStatus.open,
  });

  bool get isFull => assignedPeople >= requiredPeople;
  int get openSlots => (requiredPeople - assignedPeople).clamp(0, requiredPeople);

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String,
        planId: json['plan_id'] as String,
        name: json['name'] as String,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        requiredPeople: json['required_people'] as int,
        assignedPeople: json['assigned_people'] as int? ?? 0,
        description: json['description'] as String?,
        assignments: (json['assignments'] as List<dynamic>?)
                ?.map((e) => ShiftAssignment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        status: ShiftStatus.fromJson(json['status'] as String? ?? 'open'),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_id': planId,
        'name': name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'required_people': requiredPeople,
        'assigned_people': assignedPeople,
        'description': description,
        'assignments': assignments.map((a) => a.toJson()).toList(),
        'status': status.toJson(),
      };

  Shift copyWith({
    String? id,
    String? planId,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? requiredPeople,
    int? assignedPeople,
    String? description,
    List<ShiftAssignment>? assignments,
    ShiftStatus? status,
  }) =>
      Shift(
        id: id ?? this.id,
        planId: planId ?? this.planId,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        requiredPeople: requiredPeople ?? this.requiredPeople,
        assignedPeople: assignedPeople ?? this.assignedPeople,
        description: description ?? this.description,
        assignments: assignments ?? this.assignments,
        status: status ?? this.status,
      );
}

// ─── Shift Assignment ─────────────────────────────────────────────────────────

class ShiftAssignment {
  final String id;
  final String shiftId;
  final String musicianId;
  final String musicianName;
  final String? avatarUrl;
  final bool isSelfAssigned;
  final DateTime assignedAt;

  const ShiftAssignment({
    required this.id,
    required this.shiftId,
    required this.musicianId,
    required this.musicianName,
    this.avatarUrl,
    this.isSelfAssigned = false,
    required this.assignedAt,
  });

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) => ShiftAssignment(
        id: json['id'] as String,
        shiftId: json['shift_id'] as String,
        musicianId: json['musician_id'] as String,
        musicianName: json['musician_name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        isSelfAssigned: json['is_self_assigned'] as bool? ?? false,
        assignedAt: DateTime.parse(json['assigned_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'shift_id': shiftId,
        'musician_id': musicianId,
        'musician_name': musicianName,
        'avatar_url': avatarUrl,
        'is_self_assigned': isSelfAssigned,
        'assigned_at': assignedAt.toIso8601String(),
      };

  ShiftAssignment copyWith({
    String? id,
    String? shiftId,
    String? musicianId,
    String? musicianName,
    String? avatarUrl,
    bool? isSelfAssigned,
    DateTime? assignedAt,
  }) =>
      ShiftAssignment(
        id: id ?? this.id,
        shiftId: shiftId ?? this.shiftId,
        musicianId: musicianId ?? this.musicianId,
        musicianName: musicianName ?? this.musicianName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isSelfAssigned: isSelfAssigned ?? this.isSelfAssigned,
        assignedAt: assignedAt ?? this.assignedAt,
      );
}
