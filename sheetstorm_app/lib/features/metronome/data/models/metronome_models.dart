/// Data models for the Echtzeit-Metronom feature.
///
/// All models use manual fromJson/toJson following the project convention.
/// Backend uses camelCase JSON keys with /api/ prefix (no version segment).

/// Transport protocol for metronome connection.
enum MetronomeTransport {
  udp('udp'),
  websocket('websocket'),
  none('none');

  const MetronomeTransport(this.value);
  final String value;

  factory MetronomeTransport.fromJson(String json) =>
      values.firstWhere((e) => e.value == json, orElse: () => none);

  String toJson() => value;
}

/// Connection state of the metronome service.
enum MetronomeConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Time signature (e.g. 4/4, 3/4, 6/8).
class TimeSignature {
  final int beatsPerMeasure;
  final int beatUnit;

  const TimeSignature({
    required this.beatsPerMeasure,
    required this.beatUnit,
  });

  static const common = TimeSignature(beatsPerMeasure: 4, beatUnit: 4);
  static const waltz = TimeSignature(beatsPerMeasure: 3, beatUnit: 4);
  static const march = TimeSignature(beatsPerMeasure: 2, beatUnit: 4);
  static const sixEight = TimeSignature(beatsPerMeasure: 6, beatUnit: 8);

  /// Standard time signatures for the UI selector.
  static const standardOptions = [march, waltz, common, sixEight];

  String get display => '$beatsPerMeasure/$beatUnit';

  factory TimeSignature.fromJson(Map<String, dynamic> json) => TimeSignature(
        beatsPerMeasure: json['beatsPerMeasure'] as int,
        beatUnit: json['beatUnit'] as int,
      );

  Map<String, dynamic> toJson() => {
        'beatsPerMeasure': beatsPerMeasure,
        'beatUnit': beatUnit,
      };

  factory TimeSignature.parse(String display) {
    final parts = display.split('/');
    return TimeSignature(
      beatsPerMeasure: int.parse(parts[0]),
      beatUnit: int.parse(parts[1]),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSignature &&
          beatsPerMeasure == other.beatsPerMeasure &&
          beatUnit == other.beatUnit;

  @override
  int get hashCode => Object.hash(beatsPerMeasure, beatUnit);

  @override
  String toString() => 'TimeSignature($display)';
}

/// A single beat event calculated from session timestamps.
class BeatEvent {
  final int beatNumber;
  final int timestampUs;
  final int measure;
  final int beatInMeasure;
  final bool isDownbeat;

  const BeatEvent({
    required this.beatNumber,
    required this.timestampUs,
    required this.measure,
    required this.beatInMeasure,
    required this.isDownbeat,
  });

  factory BeatEvent.fromJson(Map<String, dynamic> json) => BeatEvent(
        beatNumber: json['beatNumber'] as int,
        timestampUs: json['timestampUs'] as int,
        measure: json['measure'] as int,
        beatInMeasure: json['beatInMeasure'] as int,
        isDownbeat: json['isDownbeat'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'beatNumber': beatNumber,
        'timestampUs': timestampUs,
        'measure': measure,
        'beatInMeasure': beatInMeasure,
        'isDownbeat': isDownbeat,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeatEvent &&
          beatNumber == other.beatNumber &&
          timestampUs == other.timestampUs &&
          measure == other.measure &&
          beatInMeasure == other.beatInMeasure &&
          isDownbeat == other.isDownbeat;

  @override
  int get hashCode =>
      Object.hash(beatNumber, timestampUs, measure, beatInMeasure, isDownbeat);

  @override
  String toString() =>
      'BeatEvent(beat: $beatNumber, measure: $measure, beatInMeasure: $beatInMeasure, downbeat: $isDownbeat)';
}

/// Clock synchronization state (NTP-like offset calculation).
class ClockSyncState {
  final int serverOffsetUs;
  final int roundTripTimeUs;
  final ClockSyncQuality syncQuality;
  final DateTime? lastSyncAt;

  const ClockSyncState({
    this.serverOffsetUs = 0,
    this.roundTripTimeUs = 0,
    this.syncQuality = ClockSyncQuality.unknown,
    this.lastSyncAt,
  });

  ClockSyncState copyWith({
    int? serverOffsetUs,
    int? roundTripTimeUs,
    ClockSyncQuality? syncQuality,
    DateTime? lastSyncAt,
  }) =>
      ClockSyncState(
        serverOffsetUs: serverOffsetUs ?? this.serverOffsetUs,
        roundTripTimeUs: roundTripTimeUs ?? this.roundTripTimeUs,
        syncQuality: syncQuality ?? this.syncQuality,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      );
}

/// Quality of the clock synchronization.
enum ClockSyncQuality {
  unknown,
  good,
  acceptable,
  poor,
}

/// Active metronome session.
class MetronomeSession {
  final String sessionId;
  final String bandId;
  final int bpm;
  final TimeSignature timeSignature;
  final int startTimeUs;
  final String conductorId;
  final String? conductorName;
  final int connectedClients;

  const MetronomeSession({
    required this.sessionId,
    required this.bandId,
    required this.bpm,
    required this.timeSignature,
    required this.startTimeUs,
    required this.conductorId,
    this.conductorName,
    this.connectedClients = 0,
  });

  factory MetronomeSession.fromJson(Map<String, dynamic> json) =>
      MetronomeSession(
        sessionId: json['sessionId'] as String,
        bandId: json['bandId'] as String,
        bpm: json['bpm'] as int,
        timeSignature: TimeSignature.fromJson(
          json['timeSignature'] as Map<String, dynamic>,
        ),
        startTimeUs: json['startTimeUs'] as int,
        conductorId: json['conductorId'] as String,
        conductorName: json['conductorName'] as String?,
        connectedClients: (json['connectedClients'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'bandId': bandId,
        'bpm': bpm,
        'timeSignature': timeSignature.toJson(),
        'startTimeUs': startTimeUs,
        'conductorId': conductorId,
        if (conductorName != null) 'conductorName': conductorName,
        'connectedClients': connectedClients,
      };

  MetronomeSession copyWith({
    String? sessionId,
    String? bandId,
    int? bpm,
    TimeSignature? timeSignature,
    int? startTimeUs,
    String? conductorId,
    String? conductorName,
    int? connectedClients,
  }) =>
      MetronomeSession(
        sessionId: sessionId ?? this.sessionId,
        bandId: bandId ?? this.bandId,
        bpm: bpm ?? this.bpm,
        timeSignature: timeSignature ?? this.timeSignature,
        startTimeUs: startTimeUs ?? this.startTimeUs,
        conductorId: conductorId ?? this.conductorId,
        conductorName: conductorName ?? this.conductorName,
        connectedClients: connectedClients ?? this.connectedClients,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetronomeSession && sessionId == other.sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

/// Overall metronome UI state.
class MetronomeState {
  final bool isPlaying;
  final int bpm;
  final TimeSignature timeSignature;
  final MetronomeTransport transport;
  final MetronomeConnectionState connectionState;
  final MetronomeSession? session;
  final BeatEvent? currentBeat;
  final int connectedClients;
  final bool isConductor;
  final bool audioClickEnabled;
  final int latencyCompensationMs;
  final String? error;

  const MetronomeState({
    this.isPlaying = false,
    this.bpm = 120,
    this.timeSignature = const TimeSignature(beatsPerMeasure: 4, beatUnit: 4),
    this.transport = MetronomeTransport.none,
    this.connectionState = MetronomeConnectionState.disconnected,
    this.session,
    this.currentBeat,
    this.connectedClients = 0,
    this.isConductor = false,
    this.audioClickEnabled = false,
    this.latencyCompensationMs = 0,
    this.error,
  });

  static const _sentinel = Object();

  MetronomeState copyWith({
    bool? isPlaying,
    int? bpm,
    TimeSignature? timeSignature,
    MetronomeTransport? transport,
    MetronomeConnectionState? connectionState,
    Object? session = _sentinel,
    Object? currentBeat = _sentinel,
    int? connectedClients,
    bool? isConductor,
    bool? audioClickEnabled,
    int? latencyCompensationMs,
    Object? error = _sentinel,
  }) =>
      MetronomeState(
        isPlaying: isPlaying ?? this.isPlaying,
        bpm: bpm ?? this.bpm,
        timeSignature: timeSignature ?? this.timeSignature,
        transport: transport ?? this.transport,
        connectionState: connectionState ?? this.connectionState,
        session:
            identical(session, _sentinel) ? this.session : session as MetronomeSession?,
        currentBeat: identical(currentBeat, _sentinel)
            ? this.currentBeat
            : currentBeat as BeatEvent?,
        connectedClients: connectedClients ?? this.connectedClients,
        isConductor: isConductor ?? this.isConductor,
        audioClickEnabled: audioClickEnabled ?? this.audioClickEnabled,
        latencyCompensationMs:
            latencyCompensationMs ?? this.latencyCompensationMs,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );
}
