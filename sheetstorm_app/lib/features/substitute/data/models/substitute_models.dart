/// Domain models for Substitute Access — Issue TBD (MS2)

// ─── Substitute Status ────────────────────────────────────────────────────────

enum SubstituteStatus {
  active('Aktiv'),
  expired('Abgelaufen'),
  revoked('Widerrufen');

  const SubstituteStatus(this.label);
  final String label;

  static SubstituteStatus fromJson(String value) => switch (value) {
        'active' => SubstituteStatus.active,
        'expired' => SubstituteStatus.expired,
        'revoked' => SubstituteStatus.revoked,
        _ => SubstituteStatus.active,
      };

  String toJson() => name;
}

// ─── Substitute Access ────────────────────────────────────────────────────────

class SubstituteAccess {
  final String id;
  final String token;
  final String name;
  final String instrument;
  final String voice;
  final String? eventId;
  final String? eventName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final SubstituteStatus status;
  final List<String> permissions;
  final String? note;

  const SubstituteAccess({
    required this.id,
    required this.token,
    required this.name,
    required this.instrument,
    required this.voice,
    this.eventId,
    this.eventName,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    this.permissions = const [],
    this.note,
  });

  bool get isActive => status == SubstituteStatus.active;
  bool get isExpired => status == SubstituteStatus.expired || DateTime.now().isAfter(expiresAt);

  factory SubstituteAccess.fromJson(Map<String, dynamic> json) => SubstituteAccess(
        id: json['id'] as String,
        token: json['token'] as String,
        name: json['name'] as String,
        instrument: json['instrument'] as String,
        voice: json['voice'] as String,
        eventId: json['event_id'] as String?,
        eventName: json['event_name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        status: SubstituteStatus.fromJson(json['status'] as String),
        permissions: (json['permissions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'name': name,
        'instrument': instrument,
        'voice': voice,
        'event_id': eventId,
        'event_name': eventName,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'status': status.toJson(),
        'permissions': permissions,
        'note': note,
      };

  SubstituteAccess copyWith({
    String? id,
    String? token,
    String? name,
    String? instrument,
    String? voice,
    String? eventId,
    String? eventName,
    DateTime? createdAt,
    DateTime? expiresAt,
    SubstituteStatus? status,
    List<String>? permissions,
    String? note,
  }) =>
      SubstituteAccess(
        id: id ?? this.id,
        token: token ?? this.token,
        name: name ?? this.name,
        instrument: instrument ?? this.instrument,
        voice: voice ?? this.voice,
        eventId: eventId ?? this.eventId,
        eventName: eventName ?? this.eventName,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        status: status ?? this.status,
        permissions: permissions ?? this.permissions,
        note: note ?? this.note,
      );
}

// ─── Substitute Link ──────────────────────────────────────────────────────────

class SubstituteLink {
  final String link;
  final String qrData;
  final SubstituteAccess access;

  const SubstituteLink({
    required this.link,
    required this.qrData,
    required this.access,
  });

  factory SubstituteLink.fromJson(Map<String, dynamic> json) => SubstituteLink(
        link: json['link'] as String,
        qrData: json['qr_data'] as String,
        access: SubstituteAccess.fromJson(json['access'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'link': link,
        'qr_data': qrData,
        'access': access.toJson(),
      };
}
