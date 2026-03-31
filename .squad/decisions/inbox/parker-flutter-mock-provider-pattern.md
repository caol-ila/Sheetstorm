# Flutter: mocktail Pattern für Provider-Overrides in Tests

**Datum:** 2026-05-30  
**Von:** Parker (QA)  
**Issue:** #113

## Entscheidung

Flutter-Tests die Netzwerk-abhängige Notifier testen MÜSSEN immer:
1. `MockXxxService extends Mock implements XxxService` definieren
2. `ProviderContainer(overrides: [xxxServiceProvider.overrideWithValue(service)])` verwenden
3. `when()` für alle Service-Methoden die im `build()` aufgerufen werden als Default-Stub einrichten

## Pattern

```dart
class MockPostService extends Mock implements PostService {}

final service = MockPostService();
when(() => service.getPosts(any(), pinnedOnly: any(named: 'pinnedOnly')))
    .thenAnswer((_) async => []);

final container = ProviderContainer(
  overrides: [postServiceProvider.overrideWithValue(service)],
);
addTearDown(container.dispose);
```

## Named-Param Capture (für Rückgabe der Input-Werte)

```dart
when(() => service.createLink(any(), expiresAt: any(named: 'expiresAt')))
    .thenAnswer((invocation) async {
      final expiresAt = invocation.namedArguments[#expiresAt] as DateTime?;
      return _link(expiresAt: expiresAt);
    });
```

## Referenz

Implementiert in: `test/features/communication/application/post_notifier_test.dart`  
und: `test/features/substitute/application/substitute_notifier_test.dart`
