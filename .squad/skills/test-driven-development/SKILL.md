# SKILL: Test-Driven Development (TDD)

> Adaptiert von [obra/superpowers](https://github.com/obra/superpowers) (MIT-Lizenz), angepasst für Flutter/Dart + ASP.NET Core.

## Wann verwenden

**Immer:** Neue Features, Bugfixes, Refactoring, Verhaltensänderungen.

**Ausnahmen (nur mit menschlicher Genehmigung):** Wegwerf-Prototypen, generierter Code, Konfigurationsdateien.

## Eiserne Regel

```
KEIN PRODUKTIONSCODE OHNE VORHER FEHLSCHLAGENDEN TEST
```

Code vor dem Test geschrieben? Lösche ihn. Nicht als "Referenz" behalten. Frisch implementieren.

## Red-Green-Refactor Zyklus

### RED — Fehlschlagenden Test schreiben

Ein minimaler Test der das gewünschte Verhalten zeigt.

**Flutter/Dart:**
```dart
test('lehnt leere E-Mail ab', () async {
  final result = await validateEmail('');
  expect(result, ValidationResult.error('E-Mail erforderlich'));
});
```

**ASP.NET Core:**
```csharp
[Fact]
public async Task RejectsEmptyEmail()
{
    var service = new ValidationService();
    var result = await service.ValidateEmailAsync("");
    result.Should().BeEquivalentTo(ValidationResult.Error("E-Mail erforderlich"));
}
```

**Anforderungen:** Ein Verhalten, klarer Name, echten Code testen (keine Mocks außer unvermeidlich).

### VERIFY RED — Scheitern beobachten

**Pflicht. Niemals überspringen.**

```bash
# Flutter
flutter test test/path/to/test.dart

# ASP.NET Core
dotnet test tests/Sheetstorm.Tests --filter "RejectsEmptyEmail"
```

Bestätigen:
- Test schlägt fehl (nicht Error)
- Fehlermeldung ist erwartet
- Scheitert weil Feature fehlt (nicht Tippfehler)

### GREEN — Minimaler Code

Einfachster Code der den Test bestehen lässt. Keine Features hinzufügen, kein Refactoring.

### VERIFY GREEN — Bestehen beobachten

**Pflicht.**
- Test besteht
- Andere Tests bestehen weiterhin
- Ausgabe sauber (keine Fehler, Warnungen)

### REFACTOR — Bereinigen

Nur nach Grün: Duplikate entfernen, Namen verbessern, Helfer extrahieren. Tests grün halten.

### COMMIT — Fortschritt sichern

```bash
git add -A && git commit -m "feat: spezifisches Feature hinzugefügt"
```

## Gute Tests

| Qualität | Gut | Schlecht |
|----------|-----|---------|
| **Minimal** | Testet eine Sache. "und" im Namen? Aufteilen. | `test('validiert Email und Domain und Whitespace')` |
| **Klar** | Name beschreibt Verhalten | `test('test1')` |
| **Intent** | Zeigt gewünschte API | Verschleiert was Code tun soll |

## Warum Reihenfolge wichtig ist

- **Tests danach** bestehen sofort — beweist nichts
- **Tests danach** sind von der Implementierung beeinflusst
- **Tests danach** testen was gebaut wurde, nicht was benötigt wird
- **Tests zuerst** erzwingen Edge-Case-Entdeckung vor Implementierung

## Häufige Rationalisierungen

| Ausrede | Realität |
|---------|----------|
| "Zu einfach zum Testen" | Einfacher Code bricht. Test dauert 30 Sekunden. |
| "Teste ich danach" | Tests die sofort bestehen beweisen nichts. |
| "Muss erst explorieren" | OK. Exploration wegwerfen, dann TDD. |
| "X Stunden Arbeit löschen ist Verschwendung" | Sunk-Cost-Irrtum. Unverifizierten Code behalten ist technische Schuld. |
| "TDD verlangsamt mich" | TDD ist schneller als Debugging. |

## Red Flags — STOPP und neu anfangen

- Code vor Test
- Test nach Implementierung
- Test besteht sofort
- Tests "später" hinzufügen
- "Nur dieses eine Mal" rationalisieren

## Verifikations-Checkliste

Vor Abschluss der Arbeit:

- [ ] Jede neue Funktion/Methode hat einen Test
- [ ] Jeden Test scheitern sehen vor Implementierung
- [ ] Minimalen Code zum Bestehen geschrieben
- [ ] Alle Tests bestehen
- [ ] Ausgabe sauber
- [ ] Tests nutzen echten Code (Mocks nur wenn unvermeidbar)
- [ ] Edge Cases und Fehler abgedeckt
