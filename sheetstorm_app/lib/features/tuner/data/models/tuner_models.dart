import 'package:equatable/equatable.dart';

// ─── TranspositionMode ───────────────────────────────────────────────────────

enum TranspositionMode {
  concert, // C-Instrumente (keine Transposition)
  bb, // Bb-Instrumente (Klarinette, Trompete, Sopran-Sax)
  eb, // Eb-Instrumente (Alt-Sax, Bariton-Sax)
  f, // F-Instrumente (Horn, Englisch Horn)
}

extension TranspositionModeX on TranspositionMode {
  /// Anzahl Halbtöne, um die die angezeigte Note gegenüber dem Konzertton erhöht wird.
  int get semitones => switch (this) {
        TranspositionMode.concert => 0,
        TranspositionMode.bb => 2,
        TranspositionMode.eb => 9,
        TranspositionMode.f => 7,
      };

  String get label => switch (this) {
        TranspositionMode.concert => 'C',
        TranspositionMode.bb => 'Bb',
        TranspositionMode.eb => 'Eb',
        TranspositionMode.f => 'F',
      };
}

// ─── TunerNote ───────────────────────────────────────────────────────────────

/// Ein erkannter Ton mit Name, Oktave, Frequenz und Cent-Abweichung.
class TunerNote extends Equatable {
  const TunerNote({
    required this.name,
    required this.octave,
    required this.frequency,
    this.centOffset = 0.0,
  });

  final String name;
  final int octave;
  final double frequency;

  /// Abweichung vom nächsten Equal-Temperament-Ton in Cent (Konzertton).
  final double centOffset;

  String get displayName => '$name$octave';

  @override
  List<Object?> get props => [name, octave, frequency, centOffset];
}

// ─── TunerState ──────────────────────────────────────────────────────────────

class TunerState extends Equatable {
  const TunerState({
    this.frequency,
    this.note,
    this.centDeviation = 0.0,
    this.isListening = false,
    this.referenceFrequency = 442.0,
    this.transposition = TranspositionMode.concert,
    this.errorMessage,
  });

  final double? frequency;
  final TunerNote? note;
  final double centDeviation;
  final bool isListening;
  final double referenceFrequency;
  final TranspositionMode transposition;
  final String? errorMessage;

  bool get hasNote => note != null;

  /// Perfekt gestimmt: Abweichung ≤ ±5 Cent
  bool get isInTune => centDeviation.abs() <= 5.0;

  /// Nah dran: Abweichung ≤ ±15 Cent
  bool get isClose => centDeviation.abs() <= 15.0;

  TunerState copyWith({
    double? frequency,
    Object? note = _sentinel,
    double? centDeviation,
    bool? isListening,
    double? referenceFrequency,
    TranspositionMode? transposition,
    Object? errorMessage = _sentinel,
  }) {
    return TunerState(
      frequency: frequency ?? this.frequency,
      note: note == _sentinel ? this.note : note as TunerNote?,
      centDeviation: centDeviation ?? this.centDeviation,
      isListening: isListening ?? this.isListening,
      referenceFrequency: referenceFrequency ?? this.referenceFrequency,
      transposition: transposition ?? this.transposition,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        frequency,
        note,
        centDeviation,
        isListening,
        referenceFrequency,
        transposition,
        errorMessage,
      ];
}

const Object _sentinel = Object();
