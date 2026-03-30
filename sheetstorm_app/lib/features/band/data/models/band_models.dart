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

  /// Parse from backend value — handles both int (C# enum ordinal) and string.
  /// Backend enum: Musician=0, SectionLeader=1, Conductor=2,
  /// SheetMusicManager=3, Administrator=4
  static BandRole fromJson(dynamic value) => switch (value) {
        0 || 'Musician' => BandRole.musician,
        1 || 'SectionLeader' => BandRole.sectionLeader,
        2 || 'Conductor' => BandRole.conductor,
        3 || 'SheetMusicManager' => BandRole.sheetMusicManager,
        4 || 'Administrator' => BandRole.admin,
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

  factory Band.fromJson(Map<String, dynamic> json) {
    // Backend sends 'myRole' as int (C# enum ordinal) or string.
    final myRoleValue = json['myRole'];
    final roles = myRoleValue != null
        ? [BandRole.fromJson(myRoleValue)]
        : const <BandRole>[];

    return Band(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      logoUrl: json['logoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memberCount: json['memberCount'] as int? ?? 0,
      myRoles: roles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'logoUrl': logoUrl,
        'createdAt': createdAt.toIso8601String(),
        'memberCount': memberCount,
        'myRole': myRoles.isNotEmpty ? myRoles.first.toJson() : null,
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
  final String userId;
  final String name;
  final String email;
  final String? instrument;
  final BandRole role;
  final String? voiceOverride;
  final DateTime joinedAt;

  const Member({
    required this.userId,
    required this.name,
    required this.email,
    this.instrument,
    this.role = BandRole.musician,
    this.voiceOverride,
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        userId: json['userId'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        instrument: json['instrument'] as String?,
        role: BandRole.fromJson(json['role'] ?? 0),
        voiceOverride: json['voiceOverride'] as String?,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'instrument': instrument,
        'role': role.toJson(),
        'voiceOverride': voiceOverride,
        'joinedAt': joinedAt.toIso8601String(),
      };

  Member copyWith({
    String? userId,
    String? name,
    String? email,
    String? instrument,
    BandRole? role,
    String? voiceOverride,
    DateTime? joinedAt,
  }) =>
      Member(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        instrument: instrument ?? this.instrument,
        role: role ?? this.role,
        voiceOverride: voiceOverride ?? this.voiceOverride,
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
