import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tuner/data/frequency_converter.dart';
import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';

void main() {
  // ─── Frequency → Note Conversion ─────────────────────────────────────────

  group('FrequencyToNoteConverter — Grundton-Erkennung (ref=442 Hz)', () {
    test('442 Hz → A4, 0 Cent', () {
      final note = FrequencyToNoteConverter.convert(442.0,
          referenceFrequency: 442.0);
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 4);
      expect(note.centOffset, closeTo(0.0, 0.5));
    });

    test('440 Hz → A4, ~-8 Cent (mit 442 Hz Referenz)', () {
      final note = FrequencyToNoteConverter.convert(440.0,
          referenceFrequency: 442.0);
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 4);
      // 440/442 ≈ -7.8 Cent
      expect(note.centOffset, closeTo(-7.8, 1.0));
    });

    test('884 Hz → A5, 0 Cent (mit 442 Hz Referenz)', () {
      final note = FrequencyToNoteConverter.convert(884.0,
          referenceFrequency: 442.0);
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 5);
      expect(note.centOffset, closeTo(0.0, 0.5));
    });

    test('880 Hz → A5, 0 Cent (mit 440 Hz Referenz)', () {
      final note = FrequencyToNoteConverter.convert(880.0,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 5);
      expect(note.centOffset, closeTo(0.0, 0.5));
    });

    test('261.63 Hz → C4 (mit 440 Hz Referenz)', () {
      final note = FrequencyToNoteConverter.convert(261.63,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'C');
      expect(note.octave, 4);
    });

    test('220 Hz → A3, 0 Cent (mit 440 Hz Referenz)', () {
      final note = FrequencyToNoteConverter.convert(220.0,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 3);
      expect(note.centOffset, closeTo(0.0, 0.5));
    });

    test('440 Hz → A4, 0 Cent (mit 440 Hz Referenz)', () {
      final note = FrequencyToNoteConverter.convert(440.0,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 4);
      expect(note.centOffset, closeTo(0.0, 0.5));
    });

    test('466.16 Hz → A#4 / Bb4 (mit 440 Hz Referenz)', () {
      // A#4 = A4 * 2^(1/12) ≈ 466.16 Hz
      final note = FrequencyToNoteConverter.convert(466.16,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'A#');
      expect(note.octave, 4);
    });

    test('523.25 Hz → C5 (mit 440 Hz Referenz)', () {
      // C5 = C4 * 2 ≈ 523.25 Hz
      final note = FrequencyToNoteConverter.convert(523.25,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'C');
      expect(note.octave, 5);
    });

    test('329.63 Hz → E4 (mit 440 Hz Referenz)', () {
      // E4 ≈ 329.63 Hz
      final note = FrequencyToNoteConverter.convert(329.63,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.name, 'E');
      expect(note.octave, 4);
    });
  });

  // ─── Cent-Genauigkeit ──────────────────────────────────────────────────────

  group('FrequencyToNoteConverter — Cent-Genauigkeit', () {
    test('Cent-Abweichung bei exaktem Ton ist 0', () {
      // G4 = A4 * 2^(-2/12)
      final g4Precise = 440.0 * _pow2(-2.0 / 12.0);
      final note = FrequencyToNoteConverter.convert(g4Precise,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.centOffset, closeTo(0.0, 1.0));
    });

    test('Frequenz zwischen zwei Tönen → ~±50 Cent', () {
      // Frequency exactly halfway between A4 and A#4 (logarithmically)
      final halfSemitone = 440.0 * _pow2(0.5 / 12.0);
      final note = FrequencyToNoteConverter.convert(halfSemitone,
          referenceFrequency: 440.0);
      expect(note, isNotNull);
      expect(note!.centOffset.abs(), closeTo(50.0, 2.0));
    });

    test('centDeviation statische Methode stimmt mit note.centOffset überein',
        () {
      const freq = 445.0;
      const ref = 440.0;
      final note = FrequencyToNoteConverter.convert(freq,
          referenceFrequency: ref);
      final cent = FrequencyToNoteConverter.centDeviation(freq,
          referenceFrequency: ref);
      expect(cent, closeTo(note!.centOffset, 0.01));
    });
  });

  // ─── Bereichsgrenzen ──────────────────────────────────────────────────────

  group('FrequencyToNoteConverter — Bereichsgrenzen', () {
    test('Frequenz 0 → null', () {
      expect(FrequencyToNoteConverter.convert(0.0), isNull);
    });

    test('Negative Frequenz → null', () {
      expect(FrequencyToNoteConverter.convert(-100.0), isNull);
    });

    test('Frequenz unterhalb C1 → null', () {
      expect(FrequencyToNoteConverter.convert(30.0), isNull);
    });

    test('Frequenz oberhalb C8 → null', () {
      expect(FrequencyToNoteConverter.convert(5000.0), isNull);
    });

    test('C1 (~32.7 Hz) → nicht null', () {
      expect(FrequencyToNoteConverter.convert(32.7), isNotNull);
    });
  });

  // ─── Transposition ────────────────────────────────────────────────────────

  group('FrequencyToNoteConverter — Transposition Bb (+2 Halbtöne)', () {
    test('Konzert A4 → Anzeige B4', () {
      final note = FrequencyToNoteConverter.convert(
        440.0,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.bb,
      );
      expect(note, isNotNull);
      expect(note!.name, 'B');
      expect(note.octave, 4);
    });

    test('Konzert G4 → Anzeige A4', () {
      final g4 = 440.0 * _pow2(-2.0 / 12.0);
      final note = FrequencyToNoteConverter.convert(
        g4,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.bb,
      );
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 4);
    });

    test('Konzert Bb3 → Anzeige C4', () {
      // Bb3 = A3 * 2^(1/12)
      final bb3 = 220.0 * _pow2(1.0 / 12.0);
      final note = FrequencyToNoteConverter.convert(
        bb3,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.bb,
      );
      expect(note, isNotNull);
      expect(note!.name, 'C');
      expect(note.octave, 4);
    });
  });

  group('FrequencyToNoteConverter — Transposition Eb (+9 Halbtöne)', () {
    test('Konzert A4 → Anzeige F#5', () {
      final note = FrequencyToNoteConverter.convert(
        440.0,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.eb,
      );
      expect(note, isNotNull);
      expect(note!.name, 'F#');
      expect(note.octave, 5);
    });

    test('Konzert C4 → Anzeige A4', () {
      final c4 = 440.0 * _pow2(-9.0 / 12.0);
      final note = FrequencyToNoteConverter.convert(
        c4,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.eb,
      );
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 4);
    });
  });

  group('FrequencyToNoteConverter — Transposition F (+7 Halbtöne)', () {
    test('Konzert A4 → Anzeige E5', () {
      final note = FrequencyToNoteConverter.convert(
        440.0,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.f,
      );
      expect(note, isNotNull);
      expect(note!.name, 'E');
      expect(note.octave, 5);
    });

    test('Konzert F3 → Anzeige C4', () {
      // F3 = A3 * 2^(-4/12)
      final f3 = 220.0 * _pow2(-4.0 / 12.0);
      final note = FrequencyToNoteConverter.convert(
        f3,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.f,
      );
      expect(note, isNotNull);
      expect(note!.name, 'C');
      expect(note.octave, 4);
    });
  });

  group('FrequencyToNoteConverter — Transposition C (kein Versatz)', () {
    test('Konzert A4 → Anzeige A4 (kein Versatz)', () {
      final note = FrequencyToNoteConverter.convert(
        440.0,
        referenceFrequency: 440.0,
        transposition: TranspositionMode.concert,
      );
      expect(note, isNotNull);
      expect(note!.name, 'A');
      expect(note.octave, 4);
    });
  });
}

// Helper: 2^x
double _pow2(double x) => math.pow(2.0, x).toDouble();
