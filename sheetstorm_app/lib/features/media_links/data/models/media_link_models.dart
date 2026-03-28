/// Media Links models

enum MediaLinkType {
  youtube('YouTube'),
  spotify('Spotify'),
  soundcloud('SoundCloud'),
  other('Andere');

  const MediaLinkType(this.label);
  final String label;

  static MediaLinkType fromJson(String value) => switch (value.toLowerCase()) {
        'youtube' => MediaLinkType.youtube,
        'spotify' => MediaLinkType.spotify,
        'soundcloud' => MediaLinkType.soundcloud,
        _ => MediaLinkType.other,
      };

  String toJson() => name;
}

class MediaLink {
  final String id;
  final String stueckId;
  final MediaLinkType plattform;
  final String url;
  final String? titel;
  final String? thumbnailUrl;
  final int? dauerSekunden;
  final bool vorgeschlagenVonAi;
  final DateTime erstelltAm;
  final String? erstelltVon;

  const MediaLink({
    required this.id,
    required this.stueckId,
    required this.plattform,
    required this.url,
    this.titel,
    this.thumbnailUrl,
    this.dauerSekunden,
    this.vorgeschlagenVonAi = false,
    required this.erstelltAm,
    this.erstelltVon,
  });

  factory MediaLink.fromJson(Map<String, dynamic> json) => MediaLink(
        id: json['id'] as String,
        stueckId: json['stueckId'] as String,
        plattform: MediaLinkType.fromJson(json['plattform'] as String),
        url: json['url'] as String,
        titel: json['titel'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        dauerSekunden: json['dauerSekunden'] as int?,
        vorgeschlagenVonAi: json['vorgeschlagenVonAi'] as bool? ?? false,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        erstelltVon: json['erstelltVon'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'stueckId': stueckId,
        'plattform': plattform.toJson(),
        'url': url,
        'titel': titel,
        'thumbnailUrl': thumbnailUrl,
        'dauerSekunden': dauerSekunden,
        'vorgeschlagenVonAi': vorgeschlagenVonAi,
        'erstelltAm': erstelltAm.toIso8601String(),
        'erstelltVon': erstelltVon,
      };

  MediaLink copyWith({
    String? id,
    String? stueckId,
    MediaLinkType? plattform,
    String? url,
    String? titel,
    String? thumbnailUrl,
    int? dauerSekunden,
    bool? vorgeschlagenVonAi,
    DateTime? erstelltAm,
    String? erstelltVon,
  }) =>
      MediaLink(
        id: id ?? this.id,
        stueckId: stueckId ?? this.stueckId,
        plattform: plattform ?? this.plattform,
        url: url ?? this.url,
        titel: titel ?? this.titel,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        dauerSekunden: dauerSekunden ?? this.dauerSekunden,
        vorgeschlagenVonAi: vorgeschlagenVonAi ?? this.vorgeschlagenVonAi,
        erstelltAm: erstelltAm ?? this.erstelltAm,
        erstelltVon: erstelltVon ?? this.erstelltVon,
      );

  String get formattedDuration {
    if (dauerSekunden == null) return '';
    final minutes = dauerSekunden! ~/ 60;
    final seconds = dauerSekunden! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class MediaLinkVorschlag {
  final MediaLinkType plattform;
  final String url;
  final String titel;
  final String? thumbnailUrl;
  final int? dauerSekunden;
  final String? kuenstler;

  const MediaLinkVorschlag({
    required this.plattform,
    required this.url,
    required this.titel,
    this.thumbnailUrl,
    this.dauerSekunden,
    this.kuenstler,
  });

  factory MediaLinkVorschlag.fromJson(Map<String, dynamic> json) =>
      MediaLinkVorschlag(
        plattform: MediaLinkType.fromJson(json['plattform'] as String),
        url: json['url'] as String,
        titel: json['titel'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        dauerSekunden: json['dauerSekunden'] as int?,
        kuenstler: json['kuenstler'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'plattform': plattform.toJson(),
        'url': url,
        'titel': titel,
        'thumbnailUrl': thumbnailUrl,
        'dauerSekunden': dauerSekunden,
        'kuenstler': kuenstler,
      };
}
