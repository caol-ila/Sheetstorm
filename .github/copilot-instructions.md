# Copilot Instructions — Sheetstorm

## Projekt-Kontext

Sheetstorm ist eine Notenmanagement-App für Blaskapellen. Flutter (Dart) Frontend + ASP.NET Core 10 (.NET 10 LTS) Backend + PostgreSQL (Server) + SQLite/Drift (Client).

## Qualitätsprinzipien

### Test-Driven Development (TDD)

Kein Produktionscode ohne vorher fehlschlagenden Test.

```
RED → Schreibe einen fehlschlagenden Test
VERIFY RED → Führe ihn aus, sieh ihn scheitern
GREEN → Schreibe minimalen Code zum Bestehen
VERIFY GREEN → Führe ihn aus, sieh ihn bestehen
REFACTOR → Bereinige, halte Tests grün
COMMIT → Committe den Fortschritt
```

**Eiserne Regel:** Code vor dem Test geschrieben? Lösche ihn. Frisch mit TDD beginnen.

**Ausnahmen (nur mit menschlicher Genehmigung):** Wegwerf-Prototypen, generierter Code, Konfigurationsdateien.

### Systematisches Debugging

Keine Fixes ohne Root-Cause-Analyse. Symptom-Fixes sind Fehler.

1. **Fehlermeldungen genau lesen** — Stack Traces vollständig, Zeilennummern, Fehlercodes
2. **Konsistent reproduzieren** — Exakte Schritte, jedes Mal auslösbar?
3. **Letzte Änderungen prüfen** — git diff, neue Dependencies, Config-Änderungen
4. **Evidence sammeln** — An jeder Komponentengrenze loggen bevor Fixes versucht werden
5. **Hypothese bilden und minimal testen** — Eine Variable ändern, nicht mehrere
6. **3+ gescheiterte Fixes → Architektur hinterfragen** — Nicht Fix #4 ohne Diskussion

### Verifikation vor Abschluss

Keine Abschlussbehauptungen ohne frische Verifikation. Evidenz vor Behauptungen.

```
BEVOR eine Fertigmeldung gemacht wird:
1. IDENTIFIZIERE: Welcher Befehl beweist die Behauptung?
2. FÜHRE AUS: Vollständigen Befehl frisch ausführen
3. LESE: Vollständige Ausgabe, Exit-Code, Fehlerzählung
4. VERIFIZIERE: Bestätigt die Ausgabe die Behauptung?
5. ERST DANN: Die Behauptung machen
```

**Red Flags:** "Sollte jetzt funktionieren", "Sieht korrekt aus", Zufriedenheit ausdrücken ohne Verifikation.

## Code-Standards

### Flutter / Dart

- **State Management:** Riverpod 3.x — Providers für alle Geschäftslogik
- **Routing:** GoRouter mit deklarativen Routen
- **Lokale DB:** Drift (SQLite) — typsichere Queries, Migrationen als Code
- **Tests:** `flutter test` — Widget-Tests bevorzugt, `testWidgets()` für UI
- **Naming:** lowerCamelCase für Variablen/Funktionen, UpperCamelCase für Klassen/Enums
- **Null Safety:** Strict — keine `!` Operator-Nutzung ohne guten Grund
- **Internationalisierung:** Alle Strings externalisiert via ARB, keine hardcodierten Strings

```dart
// ✅ Gut: Testbare Architektur
final noteProvider = FutureProvider.family<Note, String>((ref, id) async {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.getById(id);
});

// ❌ Schlecht: Direkter API-Aufruf im Widget
class NoteScreen extends StatelessWidget {
  Future<Note> _loadNote() => ApiClient().get('/notes/$id'); // Untestbar
}
```

### ASP.NET Core / C#

- **Architektur:** 3-Schichten — Api → Domain → Infrastructure
- **DI:** Built-in Microsoft.Extensions.DependencyInjection
- **ORM:** Entity Framework Core mit PostgreSQL (Npgsql)
- **API:** REST, versioniert (/api/v1/), Cursor-basierte Pagination
- **Auth:** JWT Bearer Tokens
- **Tests:** xUnit + FluentAssertions — Arrange/Act/Assert Pattern
- **Naming:** PascalCase für öffentliche Member, _camelCase für private Felder

```csharp
// ✅ Gut: Service mit klarer Verantwortung
public class NoteService(INoteRepository repository, ILogger<NoteService> logger)
{
    public async Task<Note> GetByIdAsync(Guid id, CancellationToken ct)
    {
        var note = await repository.GetByIdAsync(id, ct);
        return note ?? throw new NotFoundException($"Note {id} not found");
    }
}

// ❌ Schlecht: Controller mit Geschäftslogik
[HttpGet("{id}")]
public async Task<IActionResult> Get(Guid id)
{
    var note = await _context.Notes.FindAsync(id); // DB direkt im Controller
    if (note == null) return NotFound();
    return Ok(note);
}
```

## Testing-Anti-Patterns

### Mock-Verhalten testen statt echtes Verhalten

```dart
// ❌ Schlecht: Mock-Existenz prüfen
test('zeigt Sidebar', () {
  expect(find.byKey(Key('sidebar-mock')), findsOneWidget); // Testet den Mock
});

// ✅ Gut: Echtes Verhalten prüfen
test('zeigt Sidebar mit Navigation', () {
  expect(find.byType(NavigationRail), findsOneWidget);
});
```

### Test-Only Methoden in Produktionscode

```csharp
// ❌ Schlecht: destroy() nur in Tests genutzt
public class Session { public void Destroy() { /* cleanup */ } }

// ✅ Gut: Cleanup in Test-Utilities
public static class TestHelpers {
    public static async Task CleanupSession(Session session) { /* cleanup */ }
}
```

### Unvollständige Mocks

Immer die **vollständige** Datenstruktur mocken, nicht nur die Felder die der aktuelle Test braucht. Unvollständige Mocks versagen still wenn Code auf weggelassene Felder zugreift.

## Defense-in-Depth

Bei Bugfixes: Validierung an **jeder Schicht** hinzufügen, nicht nur am Symptom.

1. **Entry Point:** Eingabevalidierung an der API-Grenze
2. **Business Logic:** Sinnprüfung für die Operation
3. **Infrastructure:** Umgebungs-Guards (z.B. keine gefährlichen Operationen in Tests)
4. **Debug Logging:** Kontext für Forensik erfassen

## Commit-Konventionen

```
feat: Kurze Beschreibung des Features
fix: Kurze Beschreibung des Bugfixes
refactor: Code-Umstrukturierung ohne Verhaltensänderung
test: Neue Tests oder Test-Korrekturen
docs: Dokumentationsänderungen
chore: Build, Dependencies, Konfiguration
```

## Projektstruktur

```
src/                          # Backend (ASP.NET Core)
  Sheetstorm.Api/             # REST API, Controller, Middleware
  Sheetstorm.Domain/          # Entities, Interfaces, Value Objects
  Sheetstorm.Infrastructure/  # EF Core, Repositories, externe Services
sheetstorm_app/               # Frontend (Flutter/Dart)
  lib/
    core/                     # Routing, Config, Themes
    features/                 # Feature-Module (Auth, Noten, Kapelle...)
    shared/                   # Geteilte Widgets, Services, Models
  test/                       # Flutter Tests
tests/                        # Backend Tests (xUnit)
docs/                         # Spezifikation, UX, Architektur
.squad/                       # AI-Team Setup (Squad Framework)
```

## Escalation-Grade für Agenten

Jeder Agent MUSS seinen Abschlussstatus mit einem der folgenden Grade melden:

| Grade | Bedeutung | Pflichtangaben |
|-------|-----------|----------------|
| `DONE` | Aufgabe vollständig erledigt | — |
| `DONE_WITH_CONCERNS` | Erledigt, aber mit Risiken | Was funktioniert, was riskant ist, empfohlenes Follow-up |
| `NEEDS_CONTEXT` | Kann nicht fortfahren ohne Info | Konkrete Frage, welche Datei/Entscheidung fehlt |
| `BLOCKED` | Kann nicht weiterarbeiten | Was blockiert, welche Info benötigt wird, Lösungsvorschlag |

**Format am Ende jeder Agenten-Antwort:**

```
STATUS: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED

# Bei BLOCKED:
BLOCKED_BY: [Was blockiert]
NEEDED: [Welche Information/Entscheidung fehlt]
SUGGESTED_RESOLUTION: [Vorgeschlagene Lösung]

# Bei NEEDS_CONTEXT:
QUESTION: [Konkrete Frage]
MISSING: [Welche Datei/Entscheidung/Kontext fehlt]

# Bei DONE_WITH_CONCERNS:
WORKS: [Was funktioniert]
RISK: [Was riskant ist]
FOLLOW_UP: [Empfohlenes Follow-up]
```

**Regel:** Kein Agent beendet seine Arbeit ohne expliziten Escalation-Grade.

## Squad-Integration

Dieses Projekt nutzt das **Squad**-Framework für AI-gestützte Entwicklung:
- Team-Rollen und Routing: `.squad/team.md`, `.squad/routing.md`
- Skills: `.squad/skills/` — Wiederverwendbare Entwicklungspraktiken
- Entscheidungen: `.squad/decisions.md` — Team-Entscheidungen respektieren
- Code Review: 3 verschiedene AI-Reviewer (Claude Sonnet, Claude Opus, GPT)
