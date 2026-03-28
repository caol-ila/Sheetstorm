/// Domain models for Events & Calendar — MS2

// ─── Event Type ──────────────────────────────────────────────────────────────

enum EventType {
  probe('Probe'),
  konzert('Konzert'),
  auftritt('Auftritt'),
  ausflug('Ausflug'),
  sonstiges('Sonstiges');

  const EventType(this.label);
  final String label;

  static EventType fromJson(String value) => switch (value) {
        'Probe' => EventType.probe,
        'Konzert' => EventType.konzert,
        'Auftritt' => EventType.auftritt,
        'Ausflug' => EventType.ausflug,
        'Sonstiges' => EventType.sonstiges,
        _ => EventType.sonstiges,
      };

  String toJson() => label;
}

// ─── RSVP Status ────────────────────────────────────────────────────────────

enum RsvpStatus {
  offen('Offen'),
  zugesagt('Zugesagt'),
  abgesagt('Abgesagt'),
  unsicher('Unsicher');

  const RsvpStatus(this.label);
  final String label;

  static RsvpStatus fromJson(String value) => switch (value) {
        'Offen' => RsvpStatus.offen,
        'Zugesagt' => RsvpStatus.zugesagt,
        'Abgesagt' => RsvpStatus.abgesagt,
        'Unsicher' => RsvpStatus.unsicher,
        _ => RsvpStatus.offen,
      };

  String toJson() => label;
}

// ─── Event ──────────────────────────────────────────────────────────────────

class Event {
  final String id;
  final String bandId;
  final String title;
  final EventType type;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final String? location;
  final String? meetingPoint;
  final String? description;
  final String? setlistId;
  final String? setlistName;
  final String? dressCode;
  final DateTime? rsvpDeadline;
  final DateTime createdAt;
  final String createdByName;
  final EventStatistics statistics;
  final RsvpStatus myRsvpStatus;

  const Event({
    required this.id,
    required this.bandId,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    this.endTime,
    this.location,
    this.meetingPoint,
    this.description,
    this.setlistId,
    this.setlistName,
    this.dressCode,
    this.rsvpDeadline,
    required this.createdAt,
    required this.createdByName,
    required this.statistics,
    this.myRsvpStatus = RsvpStatus.offen,
  });

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        bandId: json['kapelle_id'] as String,
        title: json['titel'] as String,
        type: EventType.fromJson(json['typ'] as String),
        date: DateTime.parse(json['datum'] as String),
        startTime: json['start_uhrzeit'] as String,
        endTime: json['end_uhrzeit'] as String?,
        location: json['ort'] as String?,
        meetingPoint: json['treffpunkt'] as String?,
        description: json['beschreibung'] as String?,
        setlistId: json['setlist_id'] as String?,
        setlistName: json['setlist_name'] as String?,
        dressCode: json['kleiderordnung'] as String?,
        rsvpDeadline: json['zusage_frist'] != null
            ? DateTime.parse(json['zusage_frist'] as String)
            : null,
        createdAt: DateTime.parse(json['erstellt_am'] as String),
        createdByName:
            (json['erstellt_von'] as Map<String, dynamic>)['name'] as String,
        statistics: EventStatistics.fromJson(
          json['statistik'] as Map<String, dynamic>,
        ),
        myRsvpStatus: json['meine_teilnahme'] != null
            ? RsvpStatus.fromJson(json['meine_teilnahme'] as String)
            : RsvpStatus.offen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kapelle_id': bandId,
        'titel': title,
        'typ': type.toJson(),
        'datum': date.toIso8601String().split('T')[0],
        'start_uhrzeit': startTime,
        'end_uhrzeit': endTime,
        'ort': location,
        'treffpunkt': meetingPoint,
        'beschreibung': description,
        'setlist_id': setlistId,
        'setlist_name': setlistName,
        'kleiderordnung': dressCode,
        'zusage_frist': rsvpDeadline?.toIso8601String().split('T')[0],
        'erstellt_am': createdAt.toIso8601String(),
        'statistik': statistics.toJson(),
        'meine_teilnahme': myRsvpStatus.toJson(),
      };

  Event copyWith({
    String? id,
    String? bandId,
    String? title,
    EventType? type,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? meetingPoint,
    String? description,
    String? setlistId,
    String? setlistName,
    String? dressCode,
    DateTime? rsvpDeadline,
    DateTime? createdAt,
    String? createdByName,
    EventStatistics? statistics,
    RsvpStatus? myRsvpStatus,
  }) =>
      Event(
        id: id ?? this.id,
        bandId: bandId ?? this.bandId,
        title: title ?? this.title,
        type: type ?? this.type,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        location: location ?? this.location,
        meetingPoint: meetingPoint ?? this.meetingPoint,
        description: description ?? this.description,
        setlistId: setlistId ?? this.setlistId,
        setlistName: setlistName ?? this.setlistName,
        dressCode: dressCode ?? this.dressCode,
        rsvpDeadline: rsvpDeadline ?? this.rsvpDeadline,
        createdAt: createdAt ?? this.createdAt,
        createdByName: createdByName ?? this.createdByName,
        statistics: statistics ?? this.statistics,
        myRsvpStatus: myRsvpStatus ?? this.myRsvpStatus,
      );
}

// ─── Event Statistics ──────────────────────────────────────────────────────

class EventStatistics {
  final int zugesagt;
  final int abgesagt;
  final int unsicher;
  final int offen;

  const EventStatistics({
    this.zugesagt = 0,
    this.abgesagt = 0,
    this.unsicher = 0,
    this.offen = 0,
  });

  int get total => zugesagt + abgesagt + unsicher + offen;

  factory EventStatistics.fromJson(Map<String, dynamic> json) =>
      EventStatistics(
        zugesagt: json['zugesagt'] as int? ?? 0,
        abgesagt: json['abgesagt'] as int? ?? 0,
        unsicher: json['unsicher'] as int? ?? 0,
        offen: json['offen'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'zugesagt': zugesagt,
        'abgesagt': abgesagt,
        'unsicher': unsicher,
        'offen': offen,
      };
}

// ─── RSVP ───────────────────────────────────────────────────────────────────

class Rsvp {
  final String eventId;
  final String musicianId;
  final String name;
  final String? avatarUrl;
  final String instrument;
  final String? section;
  final RsvpStatus status;
  final String? reason;
  final DateTime changedAt;

  const Rsvp({
    required this.eventId,
    required this.musicianId,
    required this.name,
    this.avatarUrl,
    required this.instrument,
    this.section,
    required this.status,
    this.reason,
    required this.changedAt,
  });

  factory Rsvp.fromJson(Map<String, dynamic> json) => Rsvp(
        eventId: json['termin_id'] as String,
        musicianId: json['musiker_id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        instrument: json['instrument'] as String,
        section: json['register'] as String?,
        status: RsvpStatus.fromJson(json['status'] as String),
        reason: json['begruendung'] as String?,
        changedAt: DateTime.parse(json['geaendert_am'] as String),
      );

  Map<String, dynamic> toJson() => {
        'termin_id': eventId,
        'musiker_id': musicianId,
        'name': name,
        'avatar_url': avatarUrl,
        'instrument': instrument,
        'register': section,
        'status': status.toJson(),
        'begruendung': reason,
        'geaendert_am': changedAt.toIso8601String(),
      };

  Rsvp copyWith({
    String? eventId,
    String? musicianId,
    String? name,
    String? avatarUrl,
    String? instrument,
    String? section,
    RsvpStatus? status,
    String? reason,
    DateTime? changedAt,
  }) =>
      Rsvp(
        eventId: eventId ?? this.eventId,
        musicianId: musicianId ?? this.musicianId,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        instrument: instrument ?? this.instrument,
        section: section ?? this.section,
        status: status ?? this.status,
        reason: reason ?? this.reason,
        changedAt: changedAt ?? this.changedAt,
      );
}

// ─── Calendar Entry (simplified for calendar views) ────────────────────────

class CalendarEntry {
  final String id;
  final String title;
  final EventType type;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final String? location;
  final RsvpStatus myRsvpStatus;
  final String bandId;
  final String bandName;

  const CalendarEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    this.endTime,
    this.location,
    this.myRsvpStatus = RsvpStatus.offen,
    required this.bandId,
    required this.bandName,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) => CalendarEntry(
        id: json['id'] as String,
        title: json['titel'] as String,
        type: EventType.fromJson(json['typ'] as String),
        date: DateTime.parse(json['datum'] as String),
        startTime: json['start_uhrzeit'] as String,
        endTime: json['end_uhrzeit'] as String?,
        location: json['ort'] as String?,
        myRsvpStatus: json['meine_teilnahme'] != null
            ? RsvpStatus.fromJson(json['meine_teilnahme'] as String)
            : RsvpStatus.offen,
        bandId: json['kapelle_id'] as String,
        bandName: json['kapelle_name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titel': title,
        'typ': type.toJson(),
        'datum': date.toIso8601String().split('T')[0],
        'start_uhrzeit': startTime,
        'end_uhrzeit': endTime,
        'ort': location,
        'meine_teilnahme': myRsvpStatus.toJson(),
        'kapelle_id': bandId,
        'kapelle_name': bandName,
      };

  CalendarEntry copyWith({
    String? id,
    String? title,
    EventType? type,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    RsvpStatus? myRsvpStatus,
    String? bandId,
    String? bandName,
  }) =>
      CalendarEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        location: location ?? this.location,
        myRsvpStatus: myRsvpStatus ?? this.myRsvpStatus,
        bandId: bandId ?? this.bandId,
        bandName: bandName ?? this.bandName,
      );
}
