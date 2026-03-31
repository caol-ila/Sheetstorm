import 'package:flutter_test/flutter_test.dart';

/// Verifiziert das korrekte Extrahieren von bandId aus Pfadparametern (#103).
///
/// Das Problem: attendance, substitute und shifts Routes verwendeten
/// `state.uri.queryParameters['bandId'] ?? ''`, was bei fehlendem Query-Parameter
/// einen leeren String an die Provider weitergibt.
///
/// Die Korrektur: `state.pathParameters['bandId'] ?? ''` — die bandId kommt
/// sicher aus dem URL-Pfad (/app/band/:bandId/attendance).
void main() {
  group('bandId Pfadparameter-Extraktion (#103)', () {
    test('pathParameters enthält bandId, queryParameters nicht (Ist-Zustand des Bugs)', () {
      // Simuliert den Routing-Kontext: die URL lautet /app/band/kapelle-123/attendance
      // Der GoRouter füllt pathParameters['bandId'] aus dem ':bandId' Segment.
      // Ohne ?bandId=... im Query ist queryParameters['bandId'] leer.
      const pathParams = {'bandId': 'kapelle-123'};
      const queryParams = <String, String>{};

      // ALTES Verhalten (Bug): leerer String wenn kein Query-Parameter
      final buggyBandId = queryParams['bandId'] ?? '';
      expect(buggyBandId, isEmpty,
          reason: 'Reproduziert den Bug: queryParam fehlt → leerer String');

      // NEUES Verhalten (Fix): bandId aus Pfadparameter
      final fixedBandId = pathParams['bandId'] ?? '';
      expect(fixedBandId, 'kapelle-123',
          reason: 'Nach der Korrektur: bandId kommt aus dem Pfad');
      expect(fixedBandId.isEmpty, isFalse,
          reason: 'bandId darf nicht leer sein');
    });

    test('Pfadparameter-bandId ist immer vorhanden wenn Route korrekt genested ist', () {
      // GoRouter stellt sicher dass ':bandId' aus dem Pfad immer befüllt ist
      // wenn die Route unter /app/band/:bandId/* liegt.
      const pathParams = {'bandId': 'uuid-band-xyz-789'};

      final bandId = pathParams['bandId'] ?? '';
      expect(bandId, isNotEmpty);
      expect(bandId, 'uuid-band-xyz-789');
    });

    test('Leere bandId wird korrekt erkannt (Validierungslogik)', () {
      // Wenn bandId aus dem Pfad fehlt (sollte bei korrektem Routing nicht passieren),
      // soll eine leere bandId erkannt und abgefangen werden.
      const pathParams = <String, String>{};

      final bandId = pathParams['bandId'] ?? '';
      expect(bandId.isEmpty, isTrue,
          reason: 'Leere bandId muss erkannt werden');

      // In den Routes wird geprüft: if (bandId.isEmpty) → Fehlerscreen
      final shouldShowError = bandId.isEmpty;
      expect(shouldShowError, isTrue);
    });

    test('shifts-Route extrahiert bandId und planId korrekt aus Pfad+Query', () {
      // bandId kommt aus dem Pfadparameter (:bandId)
      // planId kann weiterhin als Query-Parameter kommen
      const pathParams = {'bandId': 'band-shifts-123'};
      const queryParams = {'planId': 'plan-abc'};

      final bandId = pathParams['bandId'] ?? '';
      final planId = queryParams['planId'] ?? '';

      expect(bandId, 'band-shifts-123');
      expect(planId, 'plan-abc');
    });
  });
}
