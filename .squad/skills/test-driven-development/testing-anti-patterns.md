# Testing Anti-Patterns

> Adaptiert von [obra/superpowers](https://github.com/obra/superpowers) (MIT-Lizenz), angepasst für Flutter/Dart + ASP.NET Core.

**Laden wenn:** Tests geschrieben oder geändert werden, Mocks hinzugefügt werden, oder Test-Only-Methoden in Produktionscode verlockend erscheinen.

## Kernprinzip

Tests müssen **echtes Verhalten** verifizieren, nicht Mock-Verhalten.

## Anti-Pattern 1: Mock-Verhalten testen

```dart
// ❌ SCHLECHT: Testet ob der Mock existiert
testWidgets('zeigt Sidebar', (tester) async {
  await tester.pumpWidget(TestPage());
  expect(find.byKey(Key('sidebar-mock')), findsOneWidget);
});

// ✅ GUT: Testet echtes Komponentenverhalten
testWidgets('zeigt Sidebar mit Navigationseinträgen', (tester) async {
  await tester.pumpWidget(TestPage());
  expect(find.byType(NavigationRail), findsOneWidget);
  expect(find.text('Noten'), findsOneWidget);
});
```

```csharp
// ❌ SCHLECHT: Mock verifizieren
mock.Verify(x => x.DoSomething(), Times.Once); // Testet den Mock

// ✅ GUT: Ergebnis verifizieren
var result = await service.Process(input);
result.Should().Be(expectedOutput); // Testet echtes Verhalten
```

**Gate:** Vor jeder Mock-Assertion fragen: "Teste ich echtes Verhalten oder nur Mock-Existenz?"

## Anti-Pattern 2: Test-Only Methoden in Produktionscode

```csharp
// ❌ SCHLECHT: Destroy() nur in Tests genutzt
public class KapelleService
{
    public void ResetInternalState() { /* Gefährlich in Produktion! */ }
}

// ✅ GUT: Test-Utilities separat
// tests/Helpers/TestCleanup.cs
public static class TestCleanup
{
    public static async Task ResetKapelle(AppDbContext context, Guid kapelleId)
    {
        var kapelle = await context.Kapellen.FindAsync(kapelleId);
        if (kapelle != null) context.Kapellen.Remove(kapelle);
        await context.SaveChangesAsync();
    }
}
```

**Gate:** Vor jeder neuen Methode in Produktionsklassen fragen: "Wird das nur in Tests genutzt?" Wenn ja → in Test-Utilities verschieben.

## Anti-Pattern 3: Mocking ohne Verständnis

```dart
// ❌ SCHLECHT: Mock bricht Testlogik
test('erkennt doppelte Kapelle', () async {
  // Mock verhindert DB-Schreibvorgang den Test braucht!
  when(mockRepo.save(any)).thenAnswer((_) async => null);

  await service.createKapelle(testData);
  await service.createKapelle(testData); // Sollte werfen — tut es aber nicht!
});

// ✅ GUT: Auf richtigem Level mocken
test('erkennt doppelte Kapelle', () async {
  // Nur den langsamen Teil mocken, Verhalten beibehalten
  when(mockHttpClient.post(any, body: anyNamed('body')))
      .thenAnswer((_) async => Response('', 409));

  expect(
    () => service.createKapelle(testData),
    throwsA(isA<DuplicateException>()),
  );
});
```

**Gate vor jedem Mock:**
1. Welche Seiteneffekte hat die echte Methode?
2. Braucht der Test einen davon?
3. Verstehe ich die Dependency-Kette vollständig?

## Anti-Pattern 4: Unvollständige Mocks

```dart
// ❌ SCHLECHT: Nur Felder die man gerade braucht
final mockNote = Note(id: '1', title: 'Test');
// Fehlt: composer, parts, createdAt — bricht wenn Code darauf zugreift

// ✅ GUT: Vollständige Struktur wie reale API
final mockNote = Note(
  id: '1',
  title: 'Böhmischer Traum',
  composer: 'Norbert Gälle',
  parts: [Part(instrument: 'Trompete', voice: 1)],
  createdAt: DateTime(2026, 1, 1),
);
```

## Anti-Pattern 5: Tests als Nachgedanke

```
❌ "Implementierung fertig, jetzt Tests schreiben"
✅ TDD-Zyklus: Test → Implementierung → Refactor → Fertig
```

## Red Flags

- Assertion prüft Mock-Test-IDs
- Methoden nur in Testdateien aufgerufen
- Mock-Setup ist >50% des Tests
- Test bricht wenn Mock entfernt wird
- Mock "sicherheitshalber" hinzugefügt
- Kann nicht erklären warum Mock nötig ist
