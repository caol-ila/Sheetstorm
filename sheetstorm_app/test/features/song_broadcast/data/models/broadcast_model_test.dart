import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';

/// Unit-Tests für BroadcastSession.copyWith Sentinel-Pattern — Issue #101
void main() {
  BroadcastSession _session({
    String sessionId = 'sess-1',
    String? aktiveStueckId = 'stueck-1',
    String? aktiveStueckTitel = 'Auftakt',
    String? dirigentName = 'Max Dirigent',
  }) =>
      BroadcastSession(
        sessionId: sessionId,
        kapelleId: 'band-1',
        dirigentId: 'dir-1',
        dirigentName: dirigentName,
        status: BroadcastSessionStatus.active,
        erstelltAm: DateTime(2025, 1, 1),
        aktiveStueckId: aktiveStueckId,
        aktiveStueckTitel: aktiveStueckTitel,
      );

  group('BroadcastSession.copyWith — Sentinel-Pattern (#101)', () {
    // ── aktiveStueckId ────────────────────────────────────────────────────

    test('aktiveStueckId kann auf null gesetzt werden', () {
      final session = _session(aktiveStueckId: 'stueck-1');
      final updated = session.copyWith(aktiveStueckId: null);
      expect(updated.aktiveStueckId, isNull,
          reason: 'copyWith(aktiveStueckId: null) muss null setzen');
    });

    test('aktiveStueckId bleibt erhalten wenn nicht übergeben', () {
      final session = _session(aktiveStueckId: 'stueck-1');
      final updated = session.copyWith(sessionId: 'sess-2');
      expect(updated.aktiveStueckId, 'stueck-1',
          reason: 'Nicht übergebene Felder dürfen sich nicht ändern');
    });

    test('aktiveStueckId kann auf neuen Wert gesetzt werden', () {
      final session = _session(aktiveStueckId: 'stueck-1');
      final updated = session.copyWith(aktiveStueckId: 'stueck-2');
      expect(updated.aktiveStueckId, 'stueck-2');
    });

    // ── aktiveStueckTitel ─────────────────────────────────────────────────

    test('aktiveStueckTitel kann auf null gesetzt werden', () {
      final session = _session(aktiveStueckTitel: 'Auftakt');
      final updated = session.copyWith(aktiveStueckTitel: null);
      expect(updated.aktiveStueckTitel, isNull,
          reason: 'copyWith(aktiveStueckTitel: null) muss null setzen');
    });

    test('aktiveStueckTitel bleibt erhalten wenn nicht übergeben', () {
      final session = _session(aktiveStueckTitel: 'Auftakt');
      final updated = session.copyWith(sessionId: 'sess-2');
      expect(updated.aktiveStueckTitel, 'Auftakt');
    });

    // ── dirigentName ──────────────────────────────────────────────────────

    test('dirigentName kann auf null gesetzt werden', () {
      final session = _session(dirigentName: 'Max Dirigent');
      final updated = session.copyWith(dirigentName: null);
      expect(updated.dirigentName, isNull,
          reason: 'copyWith(dirigentName: null) muss null setzen');
    });

    test('dirigentName bleibt erhalten wenn nicht übergeben', () {
      final session = _session(dirigentName: 'Max Dirigent');
      final updated = session.copyWith(verbundeneMusiker: 3);
      expect(updated.dirigentName, 'Max Dirigent');
    });

    // ── Kombinationen ─────────────────────────────────────────────────────

    test('Mehrere nullable Felder können gleichzeitig auf null gesetzt werden',
        () {
      final session = _session(
        aktiveStueckId: 'stueck-1',
        aktiveStueckTitel: 'Auftakt',
      );
      final updated = session.copyWith(
        aktiveStueckId: null,
        aktiveStueckTitel: null,
      );
      expect(updated.aktiveStueckId, isNull);
      expect(updated.aktiveStueckTitel, isNull);
    });

    test('Non-nullable Felder bleiben unverändert bei null-Reset', () {
      final session = _session(aktiveStueckId: 'stueck-1');
      final updated = session.copyWith(aktiveStueckId: null);
      expect(updated.sessionId, session.sessionId);
      expect(updated.kapelleId, session.kapelleId);
      expect(updated.status, session.status);
    });
  });
}
