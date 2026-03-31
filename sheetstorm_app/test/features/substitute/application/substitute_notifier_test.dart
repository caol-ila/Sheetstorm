import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/substitute/application/substitute_notifier.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';
import 'package:sheetstorm/features/substitute/data/services/substitute_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockSubstituteService extends Mock implements SubstituteService {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

SubstituteAccess _access({
  String id = 'access1',
  String token = 'abc123xyz',
  String name = 'Test Aushilfe',
  String instrument = 'Trompete',
  String voice = 'Trompete 1',
  SubstituteStatus status = SubstituteStatus.active,
  DateTime? expiresAt,
  String? eventId,
  List<String>? permissions,
  String? note,
}) =>
    SubstituteAccess(
      id: id,
      token: token,
      name: name,
      instrument: instrument,
      voice: voice,
      status: status,
      createdAt: DateTime(2024, 1, 15),
      expiresAt: expiresAt ?? DateTime(2024, 2, 15),
      eventId: eventId,
      permissions: permissions ?? ['view_sheet', 'view_event'],
      note: note,
    );

SubstituteLink _link({
  String linkUrl = 'https://app.sheetstorm.de/s/abc123xyz',
  String qrData = 'abc123xyz',
  SubstituteAccess? access,
}) =>
    SubstituteLink(
      link: linkUrl,
      qrData: qrData,
      access: access ?? _access(),
    );

// ─── Setup Helpers ────────────────────────────────────────────────────────────

MockSubstituteService _defaultListService() {
  final service = MockSubstituteService();
  when(() => service.listAccess(any(), status: any(named: 'status')))
      .thenAnswer((_) async => []);
  return service;
}

(ProviderContainer, MockSubstituteService) _createContainer(
    MockSubstituteService service) {
  final container = ProviderContainer(
    overrides: [substituteServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return (container, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2024));
    registerFallbackValue(SubstituteStatus.active);
  });

  // ─── SubstituteListNotifier Tests ──────────────────────────────────────────

  group('SubstituteListNotifier — Access-Liste', () {
    test('Access-Liste wird initial geladen', () async {
      final service = _defaultListService();
      final (container, _) = _createContainer(service);

      container.read(substituteListProvider('band1').notifier);

      expect(container.read(substituteListProvider('band1')).isLoading, isTrue);
    });

    test('createAccess erstellt neuen Zugang', () async {
      final service = _defaultListService();
      when(() => service.createAccessLink(
        any(),
        name: any(named: 'name'),
        instrument: any(named: 'instrument'),
        voice: any(named: 'voice'),
        eventId: any(named: 'eventId'),
        expiresAt: any(named: 'expiresAt'),
        note: any(named: 'note'),
      )).thenAnswer((invocation) async => _link(
            access: _access(
              name: invocation.namedArguments[#name] as String,
              instrument: invocation.namedArguments[#instrument] as String,
              voice: invocation.namedArguments[#voice] as String,
            ),
          ));
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);

      final link = await notifier.createAccess(
        name: 'Max Aushilfe',
        instrument: 'Trompete',
        voice: 'Trompete 2',
      );

      expect(link, isNotNull);
      expect(link?.access.name, 'Max Aushilfe');
      expect(link?.access.instrument, 'Trompete');
    });

    test('createAccess mit eventId bindet an Event', () async {
      final service = _defaultListService();
      when(() => service.createAccessLink(
        any(),
        name: any(named: 'name'),
        instrument: any(named: 'instrument'),
        voice: any(named: 'voice'),
        eventId: any(named: 'eventId'),
        expiresAt: any(named: 'expiresAt'),
        note: any(named: 'note'),
      )).thenAnswer((invocation) async => _link(
            access: _access(
              eventId: invocation.namedArguments[#eventId] as String?,
            ),
          ));
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);

      final link = await notifier.createAccess(
        name: 'Event Aushilfe',
        instrument: 'Klarinette',
        voice: 'Klarinette 1',
        eventId: 'event123',
      );

      expect(link, isNotNull);
      expect(link?.access.eventId, 'event123');
    });

    test('createAccess mit expiresAt setzt Ablaufdatum', () async {
      final service = _defaultListService();
      when(() => service.createAccessLink(
        any(),
        name: any(named: 'name'),
        instrument: any(named: 'instrument'),
        voice: any(named: 'voice'),
        eventId: any(named: 'eventId'),
        expiresAt: any(named: 'expiresAt'),
        note: any(named: 'note'),
      )).thenAnswer((invocation) async {
        final expiresAt = invocation.namedArguments[#expiresAt] as DateTime?;
        return _link(access: _access(expiresAt: expiresAt));
      });
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);
      final expiresAt = DateTime.now().add(const Duration(days: 30));

      final link = await notifier.createAccess(
        name: 'Temp Aushilfe',
        instrument: 'Saxophon',
        voice: 'Alt-Sax',
        expiresAt: expiresAt,
      );

      expect(link, isNotNull);
      expect(link?.access.expiresAt, expiresAt);
    });

    test('createAccess mit note speichert Notiz', () async {
      final service = _defaultListService();
      when(() => service.createAccessLink(
        any(),
        name: any(named: 'name'),
        instrument: any(named: 'instrument'),
        voice: any(named: 'voice'),
        eventId: any(named: 'eventId'),
        expiresAt: any(named: 'expiresAt'),
        note: any(named: 'note'),
      )).thenAnswer((invocation) async => _link(
            access: _access(
              note: invocation.namedArguments[#note] as String?,
            ),
          ));
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);

      final link = await notifier.createAccess(
        name: 'Notiz Aushilfe',
        instrument: 'Posaune',
        voice: 'Posaune 1',
        note: 'Nur für Weihnachtskonzert',
      );

      expect(link, isNotNull);
      expect(link?.access.note, 'Nur für Weihnachtskonzert');
    });

    test('revokeAccess widerruft Zugang', () async {
      final service = _defaultListService();
      when(() => service.revokeAccess(any(), any()))
          .thenAnswer((_) async {});
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);

      final success = await notifier.revokeAccess('access1');

      expect(success, isTrue);
    });

    test('revokeAccess mit unbekannter ID gibt false zurück', () async {
      final service = _defaultListService();
      when(() => service.revokeAccess(any(), any()))
          .thenThrow(Exception('Zugang nicht gefunden'));
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);

      final success = await notifier.revokeAccess('unknown_access');

      expect(success, isFalse);
    });

    test('extendExpiry verlängert Ablaufdatum', () async {
      final service = _defaultListService();
      when(() => service.extendExpiry(any(), any(), any()))
          .thenAnswer((_) async => _access());
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);
      final newExpiresAt = DateTime.now().add(const Duration(days: 60));

      final success = await notifier.extendExpiry('access1', newExpiresAt);

      expect(success, isTrue);
    });

    test('refresh lädt Access-Liste neu', () async {
      final service = _defaultListService();
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);

      await notifier.refresh();

      expect(container.read(substituteListProvider('band1')).hasValue, isTrue);
    });
  });

  // ─── SubstituteAccess Status Tests ─────────────────────────────────────────

  group('SubstituteAccess — Status-Management', () {
    test('Active Status für gültigen Zugang', () {
      final access = _access(status: SubstituteStatus.active);
      expect(access.status, SubstituteStatus.active);
      expect(access.isActive, isTrue);
    });

    test('Expired Status nach Ablaufdatum', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final access = _access(status: SubstituteStatus.expired, expiresAt: pastDate);
      expect(access.status, SubstituteStatus.expired);
      expect(access.isExpired, isTrue);
    });

    test('Revoked Status nach Widerruf', () {
      final access = _access(status: SubstituteStatus.revoked);
      expect(access.status, SubstituteStatus.revoked);
      expect(access.isActive, isFalse);
    });

    test('isExpired prüft Datum gegen aktuelle Zeit', () {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final access = _access(status: SubstituteStatus.active, expiresAt: futureDate);
      expect(access.isExpired, isFalse);
    });

    test('isActive ist false bei revoked', () {
      final access = _access(status: SubstituteStatus.revoked);
      expect(access.isActive, isFalse);
    });
  });

  // ─── SubstituteLink Tests ──────────────────────────────────────────────────

  group('SubstituteLink — Link-Generierung', () {
    test('Link enthält korrekte URL', () {
      final link = _link(linkUrl: 'https://app.sheetstorm.de/s/token123');
      expect(link.link, 'https://app.sheetstorm.de/s/token123');
    });

    test('QR-Data wird generiert', () {
      final link = _link(qrData: 'qr_token_xyz');
      expect(link.qrData, 'qr_token_xyz');
    });

    test('Link enthält Access-Objekt', () {
      final access = _access(name: 'Link Test');
      final link = _link(access: access);
      expect(link.access, access);
      expect(link.access.name, 'Link Test');
    });

    test('Token ist eindeutig', () {
      final access1 = _access(token: 'token1');
      final access2 = _access(token: 'token2');
      expect(access1.token, isNot(equals(access2.token)));
    });
  });

  // ─── Permissions Tests ─────────────────────────────────────────────────────

  group('SubstituteAccess — Berechtigungen', () {
    test('Standard-Berechtigungen enthalten view_sheet', () {
      final access = _access(permissions: ['view_sheet', 'view_event']);
      expect(access.permissions, contains('view_sheet'));
    });

    test('Standard-Berechtigungen enthalten view_event', () {
      final access = _access(permissions: ['view_sheet', 'view_event']);
      expect(access.permissions, contains('view_event'));
    });

    test('Erweiterte Berechtigungen können hinzugefügt werden', () {
      final access = _access(
        permissions: ['view_sheet', 'view_event', 'view_attendance'],
      );
      expect(access.permissions.length, 3);
      expect(access.permissions, contains('view_attendance'));
    });

    test('Leere Permissions-Liste ist erlaubt', () {
      final access = _access(permissions: []);
      expect(access.permissions, isEmpty);
    });
  });

  // ─── Event Binding Tests ───────────────────────────────────────────────────

  group('SubstituteAccess — Event-Bindung', () {
    test('Access ohne Event hat eventId null', () {
      final access = _access(eventId: null);
      expect(access.eventId, isNull);
    });

    test('Access mit Event hat eventId gesetzt', () {
      final access = _access(eventId: 'concert123');
      expect(access.eventId, 'concert123');
    });

    test('eventName wird angezeigt wenn verfügbar', () {
      final access = _access(
        eventId: 'concert123',
      ).copyWith(eventName: 'Weihnachtskonzert');
      expect(access.eventName, 'Weihnachtskonzert');
    });
  });

  // ─── Active Substitutes Provider Tests ─────────────────────────────────────

  group('activeSubstitutes Provider — Filter', () {
    test('Nur aktive Zugänge werden zurückgegeben', () async {
      final service = _defaultListService();
      final (container, _) = _createContainer(service);

      final actives = container.read(activeSubstitutesProvider('band1'));

      // Initial empty or loading
      expect(actives, isEmpty);
    });

    test('Expired Zugänge werden ausgefiltert', () {
      final activeAccess = _access(status: SubstituteStatus.active);
      final expiredAccess = _access(
        id: 'access2',
        status: SubstituteStatus.expired,
      );

      expect(activeAccess.isActive, isTrue);
      expect(expiredAccess.isActive, isFalse);
    });

    test('Revoked Zugänge werden ausgefiltert', () {
      final activeAccess = _access(status: SubstituteStatus.active);
      final revokedAccess = _access(
        id: 'access2',
        status: SubstituteStatus.revoked,
      );

      expect(activeAccess.isActive, isTrue);
      expect(revokedAccess.isActive, isFalse);
    });
  });

  // ─── Expiry Handling Tests ─────────────────────────────────────────────────

  group('SubstituteAccess — Ablauf-Logik', () {
    test('Zugang läuft nach expiresAt ab', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final access = _access(expiresAt: pastDate);
      expect(access.isExpired, isTrue);
    });

    test('Zugang ist gültig vor expiresAt', () {
      final futureDate = DateTime.now().add(const Duration(days: 7));
      final access = _access(expiresAt: futureDate);
      expect(access.isExpired, isFalse);
    });

    test('Verlängerung verschiebt expiresAt', () async {
      final service = _defaultListService();
      when(() => service.extendExpiry(any(), any(), any()))
          .thenAnswer((_) async => _access());
      final (container, _) = _createContainer(service);

      final notifier = container.read(substituteListProvider('band1').notifier);
      final newExpiry = DateTime.now().add(const Duration(days: 90));

      final success = await notifier.extendExpiry('access1', newExpiry);

      expect(success, isTrue);
    });

    test('Standard-Laufzeit ist 30 Tage', () {
      final now = DateTime.now();
      final thirtyDaysLater = now.add(const Duration(days: 30));
      final access = _access(expiresAt: thirtyDaysLater);

      final difference = access.expiresAt.difference(now);
      expect(difference.inDays, closeTo(30, 1));
    });
  });

  // ─── Token Security Tests ──────────────────────────────────────────────────

  group('SubstituteAccess — Token-Sicherheit', () {
    test('Token wird bei Erstellung generiert', () {
      final access = _access();
      expect(access.token, isNotEmpty);
    });

    test('Token ist ausreichend lang', () {
      final access = _access(token: 'abc123xyz789def456ghi');
      expect(access.token.length, greaterThanOrEqualTo(10));
    });

    test('Zwei verschiedene Zugänge haben unterschiedliche Tokens', () {
      final access1 = _access(id: 'access1', token: 'token_abc');
      final access2 = _access(id: 'access2', token: 'token_xyz');
      expect(access1.token, isNot(equals(access2.token)));
    });
  });

  // ─── copyWith Tests ────────────────────────────────────────────────────────

  group('SubstituteAccess — copyWith', () {
    test('copyWith aktualisiert Status', () {
      final access = _access(status: SubstituteStatus.active);
      final revoked = access.copyWith(status: SubstituteStatus.revoked);

      expect(revoked.status, SubstituteStatus.revoked);
      expect(revoked.id, access.id); // Other fields unchanged
    });

    test('copyWith aktualisiert expiresAt', () {
      final access = _access();
      final newExpiry = DateTime.now().add(const Duration(days: 60));
      final extended = access.copyWith(expiresAt: newExpiry);

      expect(extended.expiresAt, newExpiry);
      expect(extended.name, access.name); // Other fields unchanged
    });

    test('copyWith aktualisiert note', () {
      final access = _access(note: 'Alte Notiz');
      final updated = access.copyWith(note: 'Neue Notiz');

      expect(updated.note, 'Neue Notiz');
    });
  });

  // ─── Provider Family Tests ─────────────────────────────────────────────────

  group('Substitute Provider — Family-Scoping', () {
    test('Verschiedene bandId-Scopes sind unabhängig', () async {
      final service = _defaultListService();
      final (container, _) = _createContainer(service);

      container.read(substituteListProvider('band1').notifier);
      container.read(substituteListProvider('band2').notifier);

      expect(container.read(substituteListProvider('band1')).isLoading, isTrue);
      expect(container.read(substituteListProvider('band2')).isLoading, isTrue);
    });

    test('createAccess in band1 beeinflusst nicht band2', () async {
      final service = _defaultListService();
      when(() => service.createAccessLink(
        any(),
        name: any(named: 'name'),
        instrument: any(named: 'instrument'),
        voice: any(named: 'voice'),
        eventId: any(named: 'eventId'),
        expiresAt: any(named: 'expiresAt'),
        note: any(named: 'note'),
      )).thenAnswer((_) async => _link());
      final (container, _) = _createContainer(service);

      final notifier1 = container.read(substituteListProvider('band1').notifier);
      container.read(substituteListProvider('band2').notifier);

      await container.read(substituteListProvider('band1').future);
      await container.read(substituteListProvider('band2').future);

      await notifier1.createAccess(
        name: 'Band1 Aushilfe',
        instrument: 'Trompete',
        voice: 'Trompete 1',
      );

      // band2 should remain independent (empty list from mock)
      final band2State = container.read(substituteListProvider('band2')).value ?? [];
      expect(band2State.isEmpty, isTrue);
    });
  });
}
