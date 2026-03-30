import 'dart:math' as math;

import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';

/// Konvertiert eine Frequenz in Hz in eine musikalische Note (Equal Temperament).
///
/// Referenz: A-basierte Schlüsselnummerierung (A0 = Schlüssel 1, A4 = Schlüssel 49).
/// Formel: noteNumber = 12 * log2(f / referenceFreq) + 49
abstract final class FrequencyToNoteConverter {
  // A-basierte Noten-Reihenfolge (A0 = Index 0)
  static const List<String> _noteNames = [
    'A',
    'A#',
    'B',
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
  ];

  static const double defaultReferenceFrequency = 442.0;

  // C1 ≈ 32.7 Hz, C8 ≈ 4186 Hz
  static const double _minFrequency = 32.0;
  static const double _maxFrequency = 4200.0;

  /// Konvertiert eine Frequenz in eine [TunerNote].
  ///
  /// Gibt `null` zurück, wenn die Frequenz außerhalb des Bereichs liegt.
  /// [transposition] verschiebt nur den angezeigten Tonnamen, nicht die Cent-Abweichung.
  static TunerNote? convert(
    double frequency, {
    double referenceFrequency = defaultReferenceFrequency,
    TranspositionMode transposition = TranspositionMode.concert,
  }) {
    if (frequency <= 0 ||
        frequency < _minFrequency ||
        frequency > _maxFrequency) {
      return null;
    }

    // A4 = Schlüssel 49 in A-basierter Nummerierung
    final noteNumber =
        12.0 * (math.log(frequency / referenceFrequency) / math.log(2.0)) +
            49.0;
    final nearestNote = noteNumber.round();
    final cents = (noteNumber - nearestNote) * 100.0;

    // Transposition auf den angezeigten Ton anwenden
    final displayNote = nearestNote + transposition.semitones;

    // Positiver Modulo, um negative Indizes zu vermeiden
    final nameIndex = ((displayNote - 1) % 12 + 12) % 12;
    final name = _noteNames[nameIndex];
    final octave = (displayNote + 8) ~/ 12;

    return TunerNote(
      name: name,
      octave: octave,
      frequency: frequency,
      centOffset: cents,
    );
  }

  /// Gibt nur die Cent-Abweichung ohne Transposition zurück.
  static double centDeviation(
    double frequency, {
    double referenceFrequency = defaultReferenceFrequency,
  }) {
    if (frequency <= 0) return 0.0;
    final noteNumber =
        12.0 * (math.log(frequency / referenceFrequency) / math.log(2.0)) +
            49.0;
    final nearestNote = noteNumber.round();
    return (noteNumber - nearestNote) * 100.0;
  }
}
