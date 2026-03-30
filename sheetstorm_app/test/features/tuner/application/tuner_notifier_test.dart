import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tuner/application/tuner_notifier.dart';
import 'package:sheetstorm/features/tuner/data/audio_analyzer.dart';
import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

(ProviderContainer, TunerNotifier, MockAudioAnalyzer) _setup() {
  final analyzer = MockAudioAnalyzer();
  final container = ProviderContainer(
    overrides: [
      audioAnalyzerProvider.overrideWithValue(analyzer),
    ],
  );
  addTearDown(container.dispose);

  final notifier = container.read(tunerProvider.notifier);
  return (container, notifier, analyzer);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── Initialzustand ─────────────────────────────────────────────────────────

  group('TunerNotifier — Initialzustand', () {
    test('Startzustand: isListening ist false', () {
      final (c, _, __) = _setup();
      expect(c.read(tunerProvider).isListening, isFalse);
    });

    test('Startzustand: kein erkannter Ton', () {
      final (c, _, __) = _setup();
      expect(c.read(tunerProvider).note, isNull);
    });

    test('Startzustand: referenceFrequency ist 442 Hz', () {
      final (c, _, __) = _setup();
      expect(c.read(tunerProvider).referenceFrequency, 442.0);
    });

    test('Startzustand: Transposition ist Concert', () {
      final (c, _, __) = _setup();
      expect(c.read(tunerProvider).transposition, TranspositionMode.concert);
    });

    test('Startzustand: centDeviation ist 0', () {
      final (c, _, __) = _setup();
      expect(c.read(tunerProvider).centDeviation, 0.0);
    });
  });

  // ─── start() ────────────────────────────────────────────────────────────────

  group('TunerNotifier — start()', () {
    test('start() setzt isListening auf true', () async {
      final (c, n, _) = _setup();
      await n.start();
      expect(c.read(tunerProvider).isListening, isTrue);
    });

    test('start() ruft AudioAnalyzer.startListening() auf', () async {
      final (_, n, analyzer) = _setup();
      await n.start();
      expect(analyzer.isListening, isTrue);
    });

    test('start() empfängt Frequenz und aktualisiert State', () async {
      final (c, n, analyzer) = _setup();
      await n.start();

      analyzer.emitFrequency(440.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final state = c.read(tunerProvider);
      expect(state.frequency, 440.0);
      expect(state.note, isNotNull);
    });

    test('start() setzt Ton-Name für gültige Frequenz', () async {
      final (c, n, analyzer) = _setup();
      await n.start();

      analyzer.emitFrequency(440.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 440 Hz mit 442 Hz Referenz → A4
      expect(c.read(tunerProvider).note?.name, 'A');
    });
  });

  // ─── stop() ─────────────────────────────────────────────────────────────────

  group('TunerNotifier — stop()', () {
    test('stop() setzt isListening auf false', () async {
      final (c, n, _) = _setup();
      await n.start();
      await n.stop();
      expect(c.read(tunerProvider).isListening, isFalse);
    });

    test('stop() löscht erkannten Ton', () async {
      final (c, n, analyzer) = _setup();
      await n.start();
      analyzer.emitFrequency(440.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(tunerProvider).note, isNotNull);

      await n.stop();
      expect(c.read(tunerProvider).note, isNull);
    });

    test('stop() ruft AudioAnalyzer.stopListening() auf', () async {
      final (_, n, analyzer) = _setup();
      await n.start();
      await n.stop();
      expect(analyzer.isListening, isFalse);
    });
  });

  // ─── setReferenceFrequency() ────────────────────────────────────────────────

  group('TunerNotifier — setReferenceFrequency()', () {
    test('setzt Kammerton auf gültigen Wert', () {
      final (c, n, _) = _setup();
      n.setReferenceFrequency(441.5);
      expect(c.read(tunerProvider).referenceFrequency, 441.5);
    });

    test('clampt auf 430 Hz wenn Wert zu niedrig', () {
      final (c, n, _) = _setup();
      n.setReferenceFrequency(400.0);
      expect(c.read(tunerProvider).referenceFrequency, 430.0);
    });

    test('clampt auf 450 Hz wenn Wert zu hoch', () {
      final (c, n, _) = _setup();
      n.setReferenceFrequency(500.0);
      expect(c.read(tunerProvider).referenceFrequency, 450.0);
    });

    test('erlaubt Minimum 430 Hz', () {
      final (c, n, _) = _setup();
      n.setReferenceFrequency(430.0);
      expect(c.read(tunerProvider).referenceFrequency, 430.0);
    });

    test('erlaubt Maximum 450 Hz', () {
      final (c, n, _) = _setup();
      n.setReferenceFrequency(450.0);
      expect(c.read(tunerProvider).referenceFrequency, 450.0);
    });
  });

  // ─── setTransposition() ─────────────────────────────────────────────────────

  group('TunerNotifier — setTransposition()', () {
    test('setzt Transpositionsmodus auf Bb', () {
      final (c, n, _) = _setup();
      n.setTransposition(TranspositionMode.bb);
      expect(c.read(tunerProvider).transposition, TranspositionMode.bb);
    });

    test('setzt Transpositionsmodus auf Eb', () {
      final (c, n, _) = _setup();
      n.setTransposition(TranspositionMode.eb);
      expect(c.read(tunerProvider).transposition, TranspositionMode.eb);
    });

    test('setzt Transpositionsmodus auf F', () {
      final (c, n, _) = _setup();
      n.setTransposition(TranspositionMode.f);
      expect(c.read(tunerProvider).transposition, TranspositionMode.f);
    });

    test('setzt Transpositionsmodus auf Concert', () {
      final (c, n, _) = _setup();
      n.setTransposition(TranspositionMode.bb);
      n.setTransposition(TranspositionMode.concert);
      expect(c.read(tunerProvider).transposition, TranspositionMode.concert);
    });
  });

  // ─── Frequenz-Verarbeitung mit Transposition ────────────────────────────────

  group('TunerNotifier — Transposition in Echtzeit', () {
    test('Bb: Konzert A4 → Anzeige B4', () async {
      final (c, n, analyzer) = _setup();
      n.setTransposition(TranspositionMode.bb);
      await n.start();

      // A4 = 440 Hz mit 440 Hz-basierter Referenz
      // Aber wir nutzen 442 Hz Standard → trotzdem A4 als nächste Note
      analyzer.emitFrequency(440.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final note = c.read(tunerProvider).note;
      expect(note, isNotNull);
      expect(note!.name, 'B');
      expect(note.octave, 4);
    });

    test('Ungültige Frequenz → Ton wird gelöscht', () async {
      final (c, n, analyzer) = _setup();
      await n.start();
      analyzer.emitFrequency(440.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(tunerProvider).note, isNotNull);

      // Frequenz außerhalb des Bereichs
      analyzer.emitFrequency(0.0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(tunerProvider).note, isNull);
    });
  });

  // ─── TunerState helpers ─────────────────────────────────────────────────────

  group('TunerState — Hilfsmethoden', () {
    test('isInTune: true wenn Abweichung ≤ 5 Cent', () {
      const state = TunerState(centDeviation: 4.9);
      expect(state.isInTune, isTrue);
    });

    test('isInTune: false wenn Abweichung > 5 Cent', () {
      const state = TunerState(centDeviation: 5.1);
      expect(state.isInTune, isFalse);
    });

    test('isClose: true wenn Abweichung ≤ 15 Cent', () {
      const state = TunerState(centDeviation: 14.9);
      expect(state.isClose, isTrue);
    });

    test('isClose: false wenn Abweichung > 15 Cent', () {
      const state = TunerState(centDeviation: 15.1);
      expect(state.isClose, isFalse);
    });

    test('hasNote: false ohne erkannten Ton', () {
      const state = TunerState();
      expect(state.hasNote, isFalse);
    });

    test('hasNote: true mit erkanntem Ton', () {
      const state = TunerState(
        note: TunerNote(name: 'A', octave: 4, frequency: 440.0),
      );
      expect(state.hasNote, isTrue);
    });
  });
}
