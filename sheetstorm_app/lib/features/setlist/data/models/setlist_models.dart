/// Domain models for Setlist-Verwaltung — MS2

// ─── Setlist Type ──────────────────────────────────────────────────────────────

enum SetlistTyp {
  konzert('konzert', 'Konzert'),
  probe('probe', 'Probe'),
  marschmusik('marschmusik', 'Marschmusik');

  const SetlistTyp(this.value, this.label);
  final String value;
  final String label;

  static SetlistTyp fromJson(String value) => switch (value) {
        'konzert' => SetlistTyp.konzert,
        'probe' => SetlistTyp.probe,
        'marschmusik' => SetlistTyp.marschmusik,
        _ => SetlistTyp.konzert,
      };

  String toJson() => value;
}

// ─── Entry Type ────────────────────────────────────────────────────────────────

enum SetlistEntryType {
  stueck('stueck'),
  platzhalter('platzhalter'),
  pause('pause');

  const SetlistEntryType(this.value);
  final String value;

  static SetlistEntryType fromJson(String value) => switch (value) {
        'stueck' => SetlistEntryType.stueck,
        'platzhalter' => SetlistEntryType.platzhalter,
        'pause' => SetlistEntryType.pause,
        _ => SetlistEntryType.stueck,
      };

  String toJson() => value;
}

// ─── Creator ───────────────────────────────────────────────────────────────────

class SetlistCreator {
  final String id;
  final String name;

  const SetlistCreator({required this.id, required this.name});

  factory SetlistCreator.fromJson(Map<String, dynamic> json) => SetlistCreator(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

// ─── Piece Info (embedded in entry) ────────────────────────────────────────────

class PieceInfo {
  final String id;
  final String titel;
  final String? komponist;
  final String? thumbnailUrl;

  const PieceInfo({
    required this.id,
    required this.titel,
    this.komponist,
    this.thumbnailUrl,
  });

  factory PieceInfo.fromJson(Map<String, dynamic> json) => PieceInfo(
        id: json['id'] as String,
        titel: json['titel'] as String,
        komponist: json['komponist'] as String?,
        thumbnailUrl: json['thumbnail_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titel': titel,
        'komponist': komponist,
        'thumbnail_url': thumbnailUrl,
      };
}

// ─── Placeholder Info ──────────────────────────────────────────────────────────

class PlatzhalterInfo {
  final String titel;
  final String? komponist;
  final String? notizen;

  const PlatzhalterInfo({
    required this.titel,
    this.komponist,
    this.notizen,
  });

  factory PlatzhalterInfo.fromJson(Map<String, dynamic> json) =>
      PlatzhalterInfo(
        titel: json['titel'] as String,
        komponist: json['komponist'] as String?,
        notizen: json['notizen'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'titel': titel,
        if (komponist != null) 'komponist': komponist,
        if (notizen != null) 'notizen': notizen,
      };
}

// ─── Pause Info ────────────────────────────────────────────────────────────────

class PauseInfo {
  final String titel;
  final int dauerSekunden;

  const PauseInfo({this.titel = 'Pause', required this.dauerSekunden});

  factory PauseInfo.fromJson(Map<String, dynamic> json) => PauseInfo(
        titel: json['titel'] as String? ?? 'Pause',
        dauerSekunden: json['dauer_sekunden'] as int,
      );

  Map<String, dynamic> toJson() => {
        'titel': titel,
        'dauer_sekunden': dauerSekunden,
      };
}

// ─── Setlist Entry ─────────────────────────────────────────────────────────────

class SetlistEntry {
  final String id;
  final int position;
  final SetlistEntryType typ;
  final PieceInfo? stueck;
  final PlatzhalterInfo? platzhalter;
  final PauseInfo? pause;
  final int? geschaetzteDauerSekunden;
  final String? startzeitBerechnet;
  final String? endzeitBerechnet;

  const SetlistEntry({
    required this.id,
    required this.position,
    required this.typ,
    this.stueck,
    this.platzhalter,
    this.pause,
    this.geschaetzteDauerSekunden,
    this.startzeitBerechnet,
    this.endzeitBerechnet,
  });

  /// Display title regardless of entry type.
  String get displayTitle => switch (typ) {
        SetlistEntryType.stueck => stueck?.titel ?? 'Unbekanntes Stück',
        SetlistEntryType.platzhalter =>
          platzhalter?.titel ?? 'Platzhalter',
        SetlistEntryType.pause => pause?.titel ?? 'Pause',
      };

  /// Display subtitle (composer or notes).
  String? get displaySubtitle => switch (typ) {
        SetlistEntryType.stueck => stueck?.komponist,
        SetlistEntryType.platzhalter => platzhalter?.komponist,
        SetlistEntryType.pause => _formatDuration(pause?.dauerSekunden),
      };

  bool get isStueck => typ == SetlistEntryType.stueck;
  bool get isPlatzhalter => typ == SetlistEntryType.platzhalter;
  bool get isPause => typ == SetlistEntryType.pause;

  /// Whether this entry can be played in the setlist player.
  bool get isPlayable => typ == SetlistEntryType.stueck && stueck != null;

  factory SetlistEntry.fromJson(Map<String, dynamic> json) => SetlistEntry(
        id: json['id'] as String,
        position: json['position'] as int,
        typ: SetlistEntryType.fromJson(json['typ'] as String),
        stueck: json['stueck'] != null
            ? PieceInfo.fromJson(json['stueck'] as Map<String, dynamic>)
            : null,
        platzhalter: json['platzhalter'] != null
            ? PlatzhalterInfo.fromJson(
                json['platzhalter'] as Map<String, dynamic>)
            : null,
        pause: json['pause'] != null
            ? PauseInfo.fromJson(json['pause'] as Map<String, dynamic>)
            : null,
        geschaetzteDauerSekunden:
            json['geschaetzte_dauer_sekunden'] as int?,
        startzeitBerechnet: json['startzeit_berechnet'] as String?,
        endzeitBerechnet: json['endzeit_berechnet'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'position': position,
        'typ': typ.toJson(),
        if (stueck != null) 'stueck': stueck!.toJson(),
        if (platzhalter != null) 'platzhalter': platzhalter!.toJson(),
        if (pause != null) 'pause': pause!.toJson(),
        if (geschaetzteDauerSekunden != null)
          'geschaetzte_dauer_sekunden': geschaetzteDauerSekunden,
        if (startzeitBerechnet != null)
          'startzeit_berechnet': startzeitBerechnet,
        if (endzeitBerechnet != null) 'endzeit_berechnet': endzeitBerechnet,
      };

  SetlistEntry copyWith({
    String? id,
    int? position,
    SetlistEntryType? typ,
    PieceInfo? stueck,
    PlatzhalterInfo? platzhalter,
    PauseInfo? pause,
    int? geschaetzteDauerSekunden,
    String? startzeitBerechnet,
    String? endzeitBerechnet,
  }) =>
      SetlistEntry(
        id: id ?? this.id,
        position: position ?? this.position,
        typ: typ ?? this.typ,
        stueck: stueck ?? this.stueck,
        platzhalter: platzhalter ?? this.platzhalter,
        pause: pause ?? this.pause,
        geschaetzteDauerSekunden:
            geschaetzteDauerSekunden ?? this.geschaetzteDauerSekunden,
        startzeitBerechnet: startzeitBerechnet ?? this.startzeitBerechnet,
        endzeitBerechnet: endzeitBerechnet ?? this.endzeitBerechnet,
      );

  static String? _formatDuration(int? seconds) {
    if (seconds == null) return null;
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}min ${s}s' : '${m}min';
  }
}

// ─── Setlist ───────────────────────────────────────────────────────────────────

class Setlist {
  final String id;
  final String name;
  final SetlistTyp typ;
  final String? datum;
  final String? startzeit;
  final String? beschreibung;
  final int anzahlEintraege;
  final int gesamtdauerMinuten;
  final SetlistCreator erstelltVon;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;
  final List<SetlistEntry> eintraege;

  const Setlist({
    required this.id,
    required this.name,
    required this.typ,
    this.datum,
    this.startzeit,
    this.beschreibung,
    this.anzahlEintraege = 0,
    this.gesamtdauerMinuten = 0,
    required this.erstelltVon,
    required this.erstelltAm,
    required this.aktualisiertAm,
    this.eintraege = const [],
  });

  /// Human-readable total duration string.
  String get formattedDauer {
    if (gesamtdauerMinuten <= 0) return '–';
    final h = gesamtdauerMinuten ~/ 60;
    final m = gesamtdauerMinuten % 60;
    if (h > 0 && m > 0) return '${h}h ${m}min';
    if (h > 0) return '${h}h';
    return '${m}min';
  }

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        id: json['id'] as String,
        name: json['name'] as String,
        typ: SetlistTyp.fromJson(json['typ'] as String),
        datum: json['datum'] as String?,
        startzeit: json['startzeit'] as String?,
        beschreibung: json['beschreibung'] as String?,
        anzahlEintraege: json['anzahl_eintraege'] as int? ?? 0,
        gesamtdauerMinuten: json['gesamtdauer_minuten'] as int? ?? 0,
        erstelltVon: SetlistCreator.fromJson(
            json['erstellt_von'] as Map<String, dynamic>),
        erstelltAm: DateTime.parse(json['erstellt_am'] as String),
        aktualisiertAm: DateTime.parse(json['aktualisiert_am'] as String),
        eintraege: (json['eintraege'] as List<dynamic>?)
                ?.map((e) =>
                    SetlistEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'typ': typ.toJson(),
        'datum': datum,
        'startzeit': startzeit,
        'beschreibung': beschreibung,
        'anzahl_eintraege': anzahlEintraege,
        'gesamtdauer_minuten': gesamtdauerMinuten,
        'erstellt_von': erstelltVon.toJson(),
        'erstellt_am': erstelltAm.toIso8601String(),
        'aktualisiert_am': aktualisiertAm.toIso8601String(),
        'eintraege': eintraege.map((e) => e.toJson()).toList(),
      };

  static const _sentinel = Object();

  Setlist copyWith({
    String? id,
    String? name,
    SetlistTyp? typ,
    Object? datum = _sentinel,
    Object? startzeit = _sentinel,
    Object? beschreibung = _sentinel,
    int? anzahlEintraege,
    int? gesamtdauerMinuten,
    SetlistCreator? erstelltVon,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
    List<SetlistEntry>? eintraege,
  }) =>
      Setlist(
        id: id ?? this.id,
        name: name ?? this.name,
        typ: typ ?? this.typ,
        datum: datum == _sentinel ? this.datum : datum as String?,
        startzeit: startzeit == _sentinel ? this.startzeit : startzeit as String?,
        beschreibung: beschreibung == _sentinel ? this.beschreibung : beschreibung as String?,
        anzahlEintraege: anzahlEintraege ?? this.anzahlEintraege,
        gesamtdauerMinuten: gesamtdauerMinuten ?? this.gesamtdauerMinuten,
        erstelltVon: erstelltVon ?? this.erstelltVon,
        erstelltAm: erstelltAm ?? this.erstelltAm,
        aktualisiertAm: aktualisiertAm ?? this.aktualisiertAm,
        eintraege: eintraege ?? this.eintraege,
      );
}

// ─── Spielmodus (Player) Models ────────────────────────────────────────────────

class SpielmmodusVoice {
  final String id;
  final String name;

  const SpielmmodusVoice({required this.id, required this.name});

  factory SpielmmodusVoice.fromJson(Map<String, dynamic> json) =>
      SpielmmodusVoice(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class SpielmodusPage {
  final String id;
  final String bildUrl;
  final String vorschauUrl;

  const SpielmodusPage({
    required this.id,
    required this.bildUrl,
    required this.vorschauUrl,
  });

  factory SpielmodusPage.fromJson(Map<String, dynamic> json) =>
      SpielmodusPage(
        id: json['id'] as String,
        bildUrl: json['bild_url'] as String,
        vorschauUrl: json['vorschau_url'] as String,
      );
}

class SpielmodusStueck {
  final String eintragId;
  final int position;
  final String? stueckId;
  final String titel;
  final SpielmmodusVoice? stimme;
  final List<SpielmodusPage> seiten;
  final bool uebersprungen;
  final String? typ;

  const SpielmodusStueck({
    required this.eintragId,
    required this.position,
    this.stueckId,
    required this.titel,
    this.stimme,
    this.seiten = const [],
    this.uebersprungen = false,
    this.typ,
  });

  bool get isPlayable => !uebersprungen && seiten.isNotEmpty;

  factory SpielmodusStueck.fromJson(Map<String, dynamic> json) =>
      SpielmodusStueck(
        eintragId: json['eintrag_id'] as String,
        position: json['position'] as int,
        stueckId: json['stueck_id'] as String?,
        titel: json['titel'] as String,
        stimme: json['stimme'] != null
            ? SpielmmodusVoice.fromJson(
                json['stimme'] as Map<String, dynamic>)
            : null,
        seiten: (json['seiten'] as List<dynamic>?)
                ?.map((e) =>
                    SpielmodusPage.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        uebersprungen: json['uebersprungen'] as bool? ?? false,
        typ: json['typ'] as String?,
      );
}

class SpielmodusData {
  final String setlistId;
  final String setlistName;
  final int anzahlEintraege;
  final List<SpielmodusStueck> stuecke;
  final List<String> preloadUrls;

  const SpielmodusData({
    required this.setlistId,
    required this.setlistName,
    required this.anzahlEintraege,
    this.stuecke = const [],
    this.preloadUrls = const [],
  });

  factory SpielmodusData.fromJson(Map<String, dynamic> json) {
    final setlist = json['setlist'] as Map<String, dynamic>;
    return SpielmodusData(
      setlistId: setlist['id'] as String,
      setlistName: setlist['name'] as String,
      anzahlEintraege: setlist['anzahl_eintraege'] as int,
      stuecke: (json['stuecke'] as List<dynamic>?)
              ?.map((e) =>
                  SpielmodusStueck.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      preloadUrls: (json['preload_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}

// ─── Pagination ────────────────────────────────────────────────────────────────

class SetlistPage {
  final List<Setlist> items;
  final int gesamt;
  final String? nextCursor;

  const SetlistPage({
    required this.items,
    required this.gesamt,
    this.nextCursor,
  });

  factory SetlistPage.fromJson(Map<String, dynamic> json) => SetlistPage(
        items: (json['items'] as List<dynamic>)
            .map((e) => Setlist.fromJson(e as Map<String, dynamic>))
            .toList(),
        gesamt: json['gesamt'] as int? ?? 0,
        nextCursor:
            (json['cursor'] as Map<String, dynamic>?)?['naechste'] as String?,
      );
}
