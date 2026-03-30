// Domain models for Song-Broadcast — MS2

// ─── Enums ─────────────────────────────────────────────────────────────────────

enum BroadcastSessionStatus {
  active('active'),
  ended('ended'),
  timeout('timeout');

  const BroadcastSessionStatus(this.value);
  final String value;

  static BroadcastSessionStatus fromJson(String value) => switch (value) {
        'active' => BroadcastSessionStatus.active,
        'ended' => BroadcastSessionStatus.ended,
        'timeout' => BroadcastSessionStatus.timeout,
        _ => BroadcastSessionStatus.ended,
      };

  String toJson() => value;
}

enum MusicianConnectionStatus {
  ready('ready'),
  loading('loading'),
  error('error'),
  offline('offline');

  const MusicianConnectionStatus(this.value);
  final String value;

  static MusicianConnectionStatus fromJson(String value) => switch (value) {
        'ready' => MusicianConnectionStatus.ready,
        'loading' => MusicianConnectionStatus.loading,
        'error' => MusicianConnectionStatus.error,
        'offline' => MusicianConnectionStatus.offline,
        _ => MusicianConnectionStatus.offline,
      };

  String toJson() => value;
}

enum SongAcknowledgementStatus {
  ready('ready'),
  error('error'),
  noVoice('no_voice');

  const SongAcknowledgementStatus(this.value);
  final String value;

  static SongAcknowledgementStatus fromJson(String value) => switch (value) {
        'ready' => SongAcknowledgementStatus.ready,
        'error' => SongAcknowledgementStatus.error,
        'no_voice' => SongAcknowledgementStatus.noVoice,
        _ => SongAcknowledgementStatus.error,
      };

  String toJson() => value;
}

// ─── Broadcast Session ─────────────────────────────────────────────────────────

class BroadcastSession {
  final String sessionId;
  final String kapelleId;
  final String dirigentId;
  final String? dirigentName;
  final BroadcastSessionStatus status;
  final DateTime erstelltAm;
  final int verbundeneMusiker;
  final String? aktiveStueckId;
  final String? aktiveStueckTitel;

  const BroadcastSession({
    required this.sessionId,
    required this.kapelleId,
    required this.dirigentId,
    this.dirigentName,
    required this.status,
    required this.erstelltAm,
    this.verbundeneMusiker = 0,
    this.aktiveStueckId,
    this.aktiveStueckTitel,
  });

  factory BroadcastSession.fromJson(Map<String, dynamic> json) =>
      BroadcastSession(
        sessionId: json['sessionId'] as String,
        kapelleId: json['kapelleId'] as String,
        dirigentId: json['dirigentId'] as String,
        dirigentName: json['dirigentName'] as String?,
        status: BroadcastSessionStatus.fromJson(json['status'] as String),
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        verbundeneMusiker: json['verbundeneMusiker'] as int? ?? 0,
        aktiveStueckId: json['aktiveStueckId'] as String?,
        aktiveStueckTitel: json['aktiveStueckTitel'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'kapelleId': kapelleId,
        'dirigentId': dirigentId,
        'dirigentName': dirigentName,
        'status': status.toJson(),
        'erstelltAm': erstelltAm.toIso8601String(),
        'verbundeneMusiker': verbundeneMusiker,
        'aktiveStueckId': aktiveStueckId,
        'aktiveStueckTitel': aktiveStueckTitel,
      };

  BroadcastSession copyWith({
    String? sessionId,
    String? kapelleId,
    String? dirigentId,
    String? dirigentName,
    BroadcastSessionStatus? status,
    DateTime? erstelltAm,
    int? verbundeneMusiker,
    String? aktiveStueckId,
    String? aktiveStueckTitel,
  }) =>
      BroadcastSession(
        sessionId: sessionId ?? this.sessionId,
        kapelleId: kapelleId ?? this.kapelleId,
        dirigentId: dirigentId ?? this.dirigentId,
        dirigentName: dirigentName ?? this.dirigentName,
        status: status ?? this.status,
        erstelltAm: erstelltAm ?? this.erstelltAm,
        verbundeneMusiker: verbundeneMusiker ?? this.verbundeneMusiker,
        aktiveStueckId: aktiveStueckId ?? this.aktiveStueckId,
        aktiveStueckTitel: aktiveStueckTitel ?? this.aktiveStueckTitel,
      );
}

// ─── Connected Musician ────────────────────────────────────────────────────────

class ConnectedMusician {
  final String musikerId;
  final String name;
  final String? instrument;
  final String? register;
  final DateTime verbundenAm;
  final MusicianConnectionStatus status;
  final DateTime? letzteAktivitaet;
  final int? latenzMs;
  final String? aktuelleStueckId;

  const ConnectedMusician({
    required this.musikerId,
    required this.name,
    this.instrument,
    this.register,
    required this.verbundenAm,
    this.status = MusicianConnectionStatus.ready,
    this.letzteAktivitaet,
    this.latenzMs,
    this.aktuelleStueckId,
  });

  factory ConnectedMusician.fromJson(Map<String, dynamic> json) =>
      ConnectedMusician(
        musikerId: json['musikerId'] as String,
        name: json['name'] as String,
        instrument: json['instrument'] as String?,
        register: json['register'] as String?,
        verbundenAm: DateTime.parse(json['verbundenAm'] as String),
        status: MusicianConnectionStatus.fromJson(
            json['status'] as String? ?? 'ready'),
        letzteAktivitaet: json['letzteAktivitaet'] != null
            ? DateTime.parse(json['letzteAktivitaet'] as String)
            : null,
        latenzMs: json['latenzMs'] as int?,
        aktuelleStueckId: json['aktuelleStueckId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'musikerId': musikerId,
        'name': name,
        'instrument': instrument,
        'register': register,
        'verbundenAm': verbundenAm.toIso8601String(),
        'status': status.toJson(),
        if (letzteAktivitaet != null)
          'letzteAktivitaet': letzteAktivitaet!.toIso8601String(),
        if (latenzMs != null) 'latenzMs': latenzMs,
        if (aktuelleStueckId != null) 'aktuelleStueckId': aktuelleStueckId,
      };
}

// ─── SignalR Event Payloads ────────────────────────────────────────────────────

class SessionStartedPayload {
  final String sessionId;
  final String kapelleId;
  final String dirigentName;
  final DateTime gestartetAm;

  const SessionStartedPayload({
    required this.sessionId,
    required this.kapelleId,
    required this.dirigentName,
    required this.gestartetAm,
  });

  factory SessionStartedPayload.fromJson(Map<String, dynamic> json) =>
      SessionStartedPayload(
        sessionId: json['sessionId'] as String,
        kapelleId: json['kapelleId'] as String,
        dirigentName: json['dirigentName'] as String,
        gestartetAm: DateTime.parse(json['gestartetAm'] as String),
      );
}

class SongChangedPayload {
  final String sessionId;
  final String stueckId;
  final String stueckTitel;
  final DateTime timestamp;

  const SongChangedPayload({
    required this.sessionId,
    required this.stueckId,
    required this.stueckTitel,
    required this.timestamp,
  });

  factory SongChangedPayload.fromJson(Map<String, dynamic> json) =>
      SongChangedPayload(
        sessionId: json['sessionId'] as String,
        stueckId: json['stueckId'] as String,
        stueckTitel: json['stueckTitel'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class SessionEndedPayload {
  final String sessionId;
  final String beendetVon;
  final DateTime beendetAm;
  final String? dauer;

  const SessionEndedPayload({
    required this.sessionId,
    required this.beendetVon,
    required this.beendetAm,
    this.dauer,
  });

  factory SessionEndedPayload.fromJson(Map<String, dynamic> json) =>
      SessionEndedPayload(
        sessionId: json['sessionId'] as String,
        beendetVon: json['beendetVon'] as String,
        beendetAm: DateTime.parse(json['beendetAm'] as String),
        dauer: json['dauer'] as String?,
      );
}

class ConnectionCountPayload {
  final int count;
  final ConnectedMusicianBrief? neuVerbunden;
  final ConnectedMusicianBrief? getrennt;

  const ConnectionCountPayload({
    required this.count,
    this.neuVerbunden,
    this.getrennt,
  });

  factory ConnectionCountPayload.fromJson(Map<String, dynamic> json) =>
      ConnectionCountPayload(
        count: json['count'] as int,
        neuVerbunden: json['neuVerbunden'] != null
            ? ConnectedMusicianBrief.fromJson(
                json['neuVerbunden'] as Map<String, dynamic>)
            : null,
        getrennt: json['getrennt'] != null
            ? ConnectedMusicianBrief.fromJson(
                json['getrennt'] as Map<String, dynamic>)
            : null,
      );
}

class ConnectedMusicianBrief {
  final String musikerId;
  final String name;
  final String? instrument;

  const ConnectedMusicianBrief({
    required this.musikerId,
    required this.name,
    this.instrument,
  });

  factory ConnectedMusicianBrief.fromJson(Map<String, dynamic> json) =>
      ConnectedMusicianBrief(
        musikerId: json['musikerId'] as String,
        name: json['name'] as String,
        instrument: json['instrument'] as String?,
      );
}

// ─── Join Session Response ─────────────────────────────────────────────────────

class JoinSessionResponse {
  final String sessionId;
  final String? aktiveStueckId;
  final String? aktiveStueckTitel;
  final int verbundeneMusiker;
  final DateTime joinedAt;

  const JoinSessionResponse({
    required this.sessionId,
    this.aktiveStueckId,
    this.aktiveStueckTitel,
    required this.verbundeneMusiker,
    required this.joinedAt,
  });

  factory JoinSessionResponse.fromJson(Map<String, dynamic> json) =>
      JoinSessionResponse(
        sessionId: json['sessionId'] as String,
        aktiveStueckId: json['aktiveStueckId'] as String?,
        aktiveStueckTitel: json['aktiveStueckTitel'] as String?,
        verbundeneMusiker: json['verbundeneMusiker'] as int,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );
}

// ─── Update Song Response ──────────────────────────────────────────────────────

class UpdateSongResponse {
  final String sessionId;
  final String aktiveStueckId;
  final DateTime broadcastedAt;
  final int erreichteMusikerCount;

  const UpdateSongResponse({
    required this.sessionId,
    required this.aktiveStueckId,
    required this.broadcastedAt,
    required this.erreichteMusikerCount,
  });

  factory UpdateSongResponse.fromJson(Map<String, dynamic> json) =>
      UpdateSongResponse(
        sessionId: json['sessionId'] as String,
        aktiveStueckId: json['aktiveStueckId'] as String,
        broadcastedAt: DateTime.parse(json['broadcastedAt'] as String),
        erreichteMusikerCount: json['erreichteMusikerCount'] as int,
      );
}

// ─── Connections Response ──────────────────────────────────────────────────────

class BroadcastConnectionsResponse {
  final String sessionId;
  final List<ConnectedMusician> verbundeneMusiker;
  final int totalCount;

  const BroadcastConnectionsResponse({
    required this.sessionId,
    required this.verbundeneMusiker,
    required this.totalCount,
  });

  factory BroadcastConnectionsResponse.fromJson(Map<String, dynamic> json) =>
      BroadcastConnectionsResponse(
        sessionId: json['sessionId'] as String,
        verbundeneMusiker: (json['verbundeneMusiker'] as List<dynamic>)
            .map((e) =>
                ConnectedMusician.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCount: json['totalCount'] as int,
      );
}
