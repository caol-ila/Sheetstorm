/// Domain models for BandManagement — Issue #17

// ─── Roles ────────────────────────────────────────────────────────────────────

enum BandRole {
  admin('Administrator'),
  conductor('Conductor'),
  sheetMusicManager('SheetMusicManager'),
  sectionLeader('SectionLeader'),
  musician('Musician');

  const BandRole(this.label);
  final String label;

  static BandRole fromJson(String value) => switch (value) {
        'Administrator' => BandRole.admin,
        'Conductor' => BandRole.conductor,
        'SheetMusicManager' => BandRole.sheetMusicManager,
        'SectionLeader' => BandRole.sectionLeader,
        'Musician' => BandRole.musician,
        _ => BandRole.musician,
      };

  String toJson() => label;
}

// ─── Kapelle ──────────────────────────────────────────────────────────────────

class Band {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? logoUrl;
  final DateTime createdAt;
  final int memberCount;
  final List<BandRole> myRoles;

  const Band({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.logoUrl,
    required this.createdAt,
    this.memberCount = 0,
    this.myRoles = const [],
  });

  bool get isAdmin => myRoles.contains(BandRole.admin);

  bool get isConductorOrAdmin =>
      myRoles.contains(BandRole.admin) ||
      myRoles.contains(BandRole.conductor);

  factory Band.fromJson(Map<String, dynamic> json) => Band(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        logoUrl: json['logo_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        memberCount: json['member_count'] as int? ?? 0,
        myRoles: (json['my_roles'] as List<dynamic>?)
                ?.map((e) => BandRole.fromJson(e as String))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'logo_url': logoUrl,
        'created_at': createdAt.toIso8601String(),
        'member_count': memberCount,
        'my_roles': myRoles.map((r) => r.toJson()).toList(),
      };

  Band copyWith({
    String? id,
    String? name,
    String? description,
    String? location,
    String? logoUrl,
    DateTime? createdAt,
    int? memberCount,
    List<BandRole>? myRoles,
  }) =>
      Band(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        location: location ?? this.location,
        logoUrl: logoUrl ?? this.logoUrl,
        createdAt: createdAt ?? this.createdAt,
        memberCount: memberCount ?? this.memberCount,
        myRoles: myRoles ?? this.myRoles,
      );
}

// ─── Mitglied ─────────────────────────────────────────────────────────────────

class Member {
  final String musicianId;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<BandRole> roles;
  final List<String> sections;
  final List<String> instruments;
  final String? defaultVoice;
  final String status;
  final DateTime joinedAt;

  const Member({
    required this.musicianId,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.roles = const [],
    this.sections = const [],
    this.instruments = const [],
    this.defaultVoice,
    this.status = 'active',
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        musicianId: json['musician_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        roles: (json['roles'] as List<dynamic>?)
                ?.map((e) => BandRole.fromJson(e as String))
                .toList() ??
            const [],
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        instruments: (json['instruments'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        defaultVoice: json['default_voice'] as String?,
        status: json['status'] as String? ?? 'active',
        joinedAt: DateTime.parse(json['joined_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'musician_id': musicianId,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'roles': roles.map((r) => r.toJson()).toList(),
        'sections': sections,
        'instruments': instruments,
        'default_voice': defaultVoice,
        'status': status,
        'joined_at': joinedAt.toIso8601String(),
      };

  Member copyWith({
    String? musicianId,
    String? name,
    String? email,
    String? avatarUrl,
    List<BandRole>? roles,
    List<String>? sections,
    List<String>? instruments,
    String? defaultVoice,
    String? status,
    DateTime? joinedAt,
  }) =>
      Member(
        musicianId: musicianId ?? this.musicianId,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        roles: roles ?? this.roles,
        sections: sections ?? this.sections,
        instruments: instruments ?? this.instruments,
        defaultVoice: defaultVoice ?? this.defaultVoice,
        status: status ?? this.status,
        joinedAt: joinedAt ?? this.joinedAt,
      );
}

// ─── Einladung ────────────────────────────────────────────────────────────────

class Invitation {
  final String id;
  final String type;
  final String token;
  final String link;
  final String role;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String status;
  final String? email;

  const Invitation({
    required this.id,
    required this.type,
    required this.token,
    required this.link,
    required this.role,
    required this.expiresAt,
    required this.createdAt,
    this.status = 'pending',
    this.email,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['id'] as String,
        type: json['type'] as String,
        token: json['token'] as String,
        link: json['link'] as String,
        role: json['role'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        status: json['status'] as String? ?? 'pending',
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'token': token,
        'link': link,
        'role': role,
        'expires_at': expiresAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'status': status,
        'email': email,
      };
}

// ─── Register ─────────────────────────────────────────────────────────────────

class Section {
  final String id;
  final String bandId;
  final String name;
  final String? description;
  final String? color;
  final int sortOrder;

  const Section({
    required this.id,
    required this.bandId,
    required this.name,
    this.description,
    this.color,
    this.sortOrder = 0,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
        id: json['id'] as String,
        bandId: json['band_id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        color: json['color'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'band_id': bandId,
        'name': name,
        'description': description,
        'color': color,
        'sort_order': sortOrder,
      };

  Section copyWith({
    String? id,
    String? bandId,
    String? name,
    String? description,
    String? color,
    int? sortOrder,
  }) =>
      Section(
        id: id ?? this.id,
        bandId: bandId ?? this.bandId,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}
