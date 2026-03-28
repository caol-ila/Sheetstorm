/// Domain models for GEMA compliance

enum GemaReportStatus {
  entwurf('Entwurf'),
  exportiert('Exportiert');

  const GemaReportStatus(this.label);
  final String label;

  static GemaReportStatus fromJson(String value) => switch (value) {
        'Entwurf' => GemaReportStatus.entwurf,
        'Exportiert' => GemaReportStatus.exportiert,
        _ => GemaReportStatus.entwurf,
      };

  String toJson() => label;
}

enum ExportFormat {
  xml('GEMA-XML'),
  csv('CSV'),
  pdf('PDF');

  const ExportFormat(this.label);
  final String label;

  String toJson() => name;
}

class GemaReport {
  final String id;
  final String kapelleId;
  final String? setlistId;
  final GemaReportStatus status;
  final String veranstaltungName;
  final DateTime veranstaltungDatum;
  final String veranstaltungOrt;
  final String veranstaltungArt;
  final String veranstalter;
  final List<GemaEntry> eintraege;
  final DateTime erstelltAm;
  final String erstelltVon;
  final DateTime? exportiertAm;

  const GemaReport({
    required this.id,
    required this.kapelleId,
    this.setlistId,
    required this.status,
    required this.veranstaltungName,
    required this.veranstaltungDatum,
    required this.veranstaltungOrt,
    required this.veranstaltungArt,
    required this.veranstalter,
    this.eintraege = const [],
    required this.erstelltAm,
    required this.erstelltVon,
    this.exportiertAm,
  });

  factory GemaReport.fromJson(Map<String, dynamic> json) => GemaReport(
        id: json['id'] as String,
        kapelleId: json['kapelleId'] as String,
        setlistId: json['setlistId'] as String?,
        status: GemaReportStatus.fromJson(json['status'] as String),
        veranstaltungName: json['veranstaltung']['name'] as String,
        veranstaltungDatum:
            DateTime.parse(json['veranstaltung']['datum'] as String),
        veranstaltungOrt: json['veranstaltung']['ort'] as String,
        veranstaltungArt: json['veranstaltung']['art'] as String,
        veranstalter: json['veranstaltung']['veranstalter'] as String,
        eintraege: (json['eintraege'] as List<dynamic>?)
                ?.map((e) => GemaEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        erstelltVon: json['erstelltVon'] as String,
        exportiertAm: json['exportiertAm'] != null
            ? DateTime.parse(json['exportiertAm'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kapelleId': kapelleId,
        'setlistId': setlistId,
        'status': status.toJson(),
        'veranstaltung': {
          'name': veranstaltungName,
          'datum': veranstaltungDatum.toIso8601String(),
          'ort': veranstaltungOrt,
          'art': veranstaltungArt,
          'veranstalter': veranstalter,
        },
        'eintraege': eintraege.map((e) => e.toJson()).toList(),
        'erstelltAm': erstelltAm.toIso8601String(),
        'erstelltVon': erstelltVon,
        'exportiertAm': exportiertAm?.toIso8601String(),
      };

  GemaReport copyWith({
    String? id,
    String? kapelleId,
    String? setlistId,
    GemaReportStatus? status,
    String? veranstaltungName,
    DateTime? veranstaltungDatum,
    String? veranstaltungOrt,
    String? veranstaltungArt,
    String? veranstalter,
    List<GemaEntry>? eintraege,
    DateTime? erstelltAm,
    String? erstelltVon,
    DateTime? exportiertAm,
  }) =>
      GemaReport(
        id: id ?? this.id,
        kapelleId: kapelleId ?? this.kapelleId,
        setlistId: setlistId ?? this.setlistId,
        status: status ?? this.status,
        veranstaltungName: veranstaltungName ?? this.veranstaltungName,
        veranstaltungDatum: veranstaltungDatum ?? this.veranstaltungDatum,
        veranstaltungOrt: veranstaltungOrt ?? this.veranstaltungOrt,
        veranstaltungArt: veranstaltungArt ?? this.veranstaltungArt,
        veranstalter: veranstalter ?? this.veranstalter,
        eintraege: eintraege ?? this.eintraege,
        erstelltAm: erstelltAm ?? this.erstelltAm,
        erstelltVon: erstelltVon ?? this.erstelltVon,
        exportiertAm: exportiertAm ?? this.exportiertAm,
      );

  int get fehlendeWerknummern =>
      eintraege.where((e) => e.gemaWerknummer == null).length;
}

class GemaEntry {
  final String id;
  final String meldungId;
  final String werktitel;
  final String komponist;
  final String? verlag;
  final String? gemaWerknummer;
  final String? bearbeiter;
  final int? dauerSekunden;
  final int sortOrder;

  const GemaEntry({
    required this.id,
    required this.meldungId,
    required this.werktitel,
    required this.komponist,
    this.verlag,
    this.gemaWerknummer,
    this.bearbeiter,
    this.dauerSekunden,
    this.sortOrder = 0,
  });

  factory GemaEntry.fromJson(Map<String, dynamic> json) => GemaEntry(
        id: json['id'] as String,
        meldungId: json['meldungId'] as String,
        werktitel: json['werktitel'] as String,
        komponist: json['komponist'] as String,
        verlag: json['verlag'] as String?,
        gemaWerknummer: json['gemaWerknummer'] as String?,
        bearbeiter: json['bearbeiter'] as String?,
        dauerSekunden: json['dauerSekunden'] as int?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'meldungId': meldungId,
        'werktitel': werktitel,
        'komponist': komponist,
        'verlag': verlag,
        'gemaWerknummer': gemaWerknummer,
        'bearbeiter': bearbeiter,
        'dauerSekunden': dauerSekunden,
        'sortOrder': sortOrder,
      };

  GemaEntry copyWith({
    String? id,
    String? meldungId,
    String? werktitel,
    String? komponist,
    String? verlag,
    String? gemaWerknummer,
    String? bearbeiter,
    int? dauerSekunden,
    int? sortOrder,
  }) =>
      GemaEntry(
        id: id ?? this.id,
        meldungId: meldungId ?? this.meldungId,
        werktitel: werktitel ?? this.werktitel,
        komponist: komponist ?? this.komponist,
        verlag: verlag ?? this.verlag,
        gemaWerknummer: gemaWerknummer ?? this.gemaWerknummer,
        bearbeiter: bearbeiter ?? this.bearbeiter,
        dauerSekunden: dauerSekunden ?? this.dauerSekunden,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

class GemaWerknummerVorschlag {
  final String werknummer;
  final String werktitel;
  final String komponist;
  final String? verlag;
  final double confidence;

  const GemaWerknummerVorschlag({
    required this.werknummer,
    required this.werktitel,
    required this.komponist,
    this.verlag,
    required this.confidence,
  });

  factory GemaWerknummerVorschlag.fromJson(Map<String, dynamic> json) =>
      GemaWerknummerVorschlag(
        werknummer: json['werknummer'] as String,
        werktitel: json['werktitel'] as String,
        komponist: json['komponist'] as String,
        verlag: json['verlag'] as String?,
        confidence: (json['confidence'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'werknummer': werknummer,
        'werktitel': werktitel,
        'komponist': komponist,
        'verlag': verlag,
        'confidence': confidence,
      };
}
