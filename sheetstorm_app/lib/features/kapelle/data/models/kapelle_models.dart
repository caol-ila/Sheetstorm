/// Domain models for Kapellenverwaltung — Issue #17

// ─── Roles ────────────────────────────────────────────────────────────────────

enum KapelleRolle {
  admin('Admin'),
  dirigent('Dirigent'),
  notenwart('Notenwart'),
  registerfuehrer('Registerführer'),
  musiker('Musiker');

  const KapelleRolle(this.label);
  final String label;

  static KapelleRolle fromJson(String value) => switch (value) {
        'Admin' => KapelleRolle.admin,
        'Dirigent' => KapelleRolle.dirigent,
        'Notenwart' => KapelleRolle.notenwart,
        'Registerführer' || 'Registerfuehrer' => KapelleRolle.registerfuehrer,
        'Musiker' => KapelleRolle.musiker,
        _ => KapelleRolle.musiker,
      };

  String toJson() => label;
}

// ─── Kapelle ──────────────────────────────────────────────────────────────────

class Kapelle {
  final String id;
  final String name;
  final String? beschreibung;
  final String? ort;
  final String? logoUrl;
  final DateTime erstelltAm;
  final int mitgliederAnzahl;
  final List<KapelleRolle> meineRollen;

  const Kapelle({
    required this.id,
    required this.name,
    this.beschreibung,
    this.ort,
    this.logoUrl,
    required this.erstelltAm,
    this.mitgliederAnzahl = 0,
    this.meineRollen = const [],
  });

  bool get isAdmin => meineRollen.contains(KapelleRolle.admin);

  bool get isDirigentOrAdmin =>
      meineRollen.contains(KapelleRolle.admin) ||
      meineRollen.contains(KapelleRolle.dirigent);

  factory Kapelle.fromJson(Map<String, dynamic> json) => Kapelle(
        id: json['id'] as String,
        name: json['name'] as String,
        beschreibung: json['beschreibung'] as String?,
        ort: json['ort'] as String?,
        logoUrl: json['logo_url'] as String?,
        erstelltAm: DateTime.parse(json['erstellt_am'] as String),
        mitgliederAnzahl: json['mitglieder_anzahl'] as int? ?? 0,
        meineRollen: (json['meine_rollen'] as List<dynamic>?)
                ?.map((e) => KapelleRolle.fromJson(e as String))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'beschreibung': beschreibung,
        'ort': ort,
        'logo_url': logoUrl,
        'erstellt_am': erstelltAm.toIso8601String(),
        'mitglieder_anzahl': mitgliederAnzahl,
        'meine_rollen': meineRollen.map((r) => r.toJson()).toList(),
      };

  Kapelle copyWith({
    String? id,
    String? name,
    String? beschreibung,
    String? ort,
    String? logoUrl,
    DateTime? erstelltAm,
    int? mitgliederAnzahl,
    List<KapelleRolle>? meineRollen,
  }) =>
      Kapelle(
        id: id ?? this.id,
        name: name ?? this.name,
        beschreibung: beschreibung ?? this.beschreibung,
        ort: ort ?? this.ort,
        logoUrl: logoUrl ?? this.logoUrl,
        erstelltAm: erstelltAm ?? this.erstelltAm,
        mitgliederAnzahl: mitgliederAnzahl ?? this.mitgliederAnzahl,
        meineRollen: meineRollen ?? this.meineRollen,
      );
}

// ─── Mitglied ─────────────────────────────────────────────────────────────────

class Mitglied {
  final String musikerId;
  final String name;
  final String email;
  final String? avatarUrl;
  final List<KapelleRolle> rollen;
  final List<String> register;
  final List<String> instrumente;
  final String? standardStimme;
  final String status;
  final DateTime beigetretenAm;

  const Mitglied({
    required this.musikerId,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.rollen = const [],
    this.register = const [],
    this.instrumente = const [],
    this.standardStimme,
    this.status = 'aktiv',
    required this.beigetretenAm,
  });

  factory Mitglied.fromJson(Map<String, dynamic> json) => Mitglied(
        musikerId: json['musiker_id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        rollen: (json['rollen'] as List<dynamic>?)
                ?.map((e) => KapelleRolle.fromJson(e as String))
                .toList() ??
            const [],
        register: (json['register'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        instrumente: (json['instrumente'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        standardStimme: json['standard_stimme'] as String?,
        status: json['status'] as String? ?? 'aktiv',
        beigetretenAm: DateTime.parse(json['beigetreten_am'] as String),
      );

  Map<String, dynamic> toJson() => {
        'musiker_id': musikerId,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'rollen': rollen.map((r) => r.toJson()).toList(),
        'register': register,
        'instrumente': instrumente,
        'standard_stimme': standardStimme,
        'status': status,
        'beigetreten_am': beigetretenAm.toIso8601String(),
      };

  Mitglied copyWith({
    String? musikerId,
    String? name,
    String? email,
    String? avatarUrl,
    List<KapelleRolle>? rollen,
    List<String>? register,
    List<String>? instrumente,
    String? standardStimme,
    String? status,
    DateTime? beigetretenAm,
  }) =>
      Mitglied(
        musikerId: musikerId ?? this.musikerId,
        name: name ?? this.name,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        rollen: rollen ?? this.rollen,
        register: register ?? this.register,
        instrumente: instrumente ?? this.instrumente,
        standardStimme: standardStimme ?? this.standardStimme,
        status: status ?? this.status,
        beigetretenAm: beigetretenAm ?? this.beigetretenAm,
      );
}

// ─── Einladung ────────────────────────────────────────────────────────────────

class Einladung {
  final String id;
  final String typ;
  final String token;
  final String link;
  final String rolle;
  final DateTime ablaufAm;
  final DateTime erstelltAm;
  final String status;
  final String? email;

  const Einladung({
    required this.id,
    required this.typ,
    required this.token,
    required this.link,
    required this.rolle,
    required this.ablaufAm,
    required this.erstelltAm,
    this.status = 'ausstehend',
    this.email,
  });

  factory Einladung.fromJson(Map<String, dynamic> json) => Einladung(
        id: json['id'] as String,
        typ: json['typ'] as String,
        token: json['token'] as String,
        link: json['link'] as String,
        rolle: json['rolle'] as String,
        ablaufAm: DateTime.parse(json['ablauf_am'] as String),
        erstelltAm: DateTime.parse(json['erstellt_am'] as String),
        status: json['status'] as String? ?? 'ausstehend',
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'typ': typ,
        'token': token,
        'link': link,
        'rolle': rolle,
        'ablauf_am': ablaufAm.toIso8601String(),
        'erstellt_am': erstelltAm.toIso8601String(),
        'status': status,
        'email': email,
      };
}

// ─── Register ─────────────────────────────────────────────────────────────────

class Register {
  final String id;
  final String kapelleId;
  final String name;
  final String? beschreibung;
  final String? farbe;
  final int sortierung;

  const Register({
    required this.id,
    required this.kapelleId,
    required this.name,
    this.beschreibung,
    this.farbe,
    this.sortierung = 0,
  });

  factory Register.fromJson(Map<String, dynamic> json) => Register(
        id: json['id'] as String,
        kapelleId: json['kapelle_id'] as String,
        name: json['name'] as String,
        beschreibung: json['beschreibung'] as String?,
        farbe: json['farbe'] as String?,
        sortierung: json['sortierung'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kapelle_id': kapelleId,
        'name': name,
        'beschreibung': beschreibung,
        'farbe': farbe,
        'sortierung': sortierung,
      };

  Register copyWith({
    String? id,
    String? kapelleId,
    String? name,
    String? beschreibung,
    String? farbe,
    int? sortierung,
  }) =>
      Register(
        id: id ?? this.id,
        kapelleId: kapelleId ?? this.kapelleId,
        name: name ?? this.name,
        beschreibung: beschreibung ?? this.beschreibung,
        farbe: farbe ?? this.farbe,
        sortierung: sortierung ?? this.sortierung,
      );
}
