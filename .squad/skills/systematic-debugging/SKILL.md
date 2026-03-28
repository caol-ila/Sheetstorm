# SKILL: Systematisches Debugging

> Adaptiert von [obra/superpowers](https://github.com/obra/superpowers) (MIT-Lizenz), angepasst für Flutter/Dart + ASP.NET Core.

## Wann verwenden

Bei **jedem** technischen Problem: Test-Fehler, Bugs, unerwartetes Verhalten, Performance-Probleme, Build-Fehler, Integrationsprobleme.

**Besonders wenn:**
- Unter Zeitdruck (Notfälle machen Raten verlockend)
- "Nur ein schneller Fix" offensichtlich scheint
- Bereits mehrere Fixes versucht wurden

## Eiserne Regel

```
KEINE FIXES OHNE VORHERIGE ROOT-CAUSE-ANALYSE
```

Phase 1 nicht abgeschlossen? Keine Fixes vorschlagen.

## Die vier Phasen

### Phase 1: Root-Cause-Analyse

**BEVOR ein Fix versucht wird:**

1. **Fehlermeldungen genau lesen**
   - Stack Traces vollständig lesen
   - Zeilennummern, Dateipfade, Fehlercodes notieren
   - Flutter: `flutter doctor`, `flutter analyze`
   - ASP.NET: Vollständige Exception Details, Inner Exceptions

2. **Konsistent reproduzieren**
   - Exakte Schritte dokumentieren
   - Passiert es jedes Mal?
   - Nicht reproduzierbar → mehr Daten sammeln, nicht raten

3. **Letzte Änderungen prüfen**
   - `git --no-pager diff`, letzte Commits
   - Neue Dependencies, Versionsänderungen
   - `pubspec.yaml` / `.csproj` Änderungen

4. **Evidence sammeln bei Multi-Komponenten-Systemen**

   ```
   Für JEDE Komponentengrenze:
     - Loggen was reinkommt
     - Loggen was rausgeht
     - Umgebung/Config-Propagierung prüfen
   
   Einmal ausführen → Evidence analysieren → Fehlerquelle identifizieren
   ```

   **Sheetstorm-spezifisch (Flutter ↔ API ↔ DB):**
   ```dart
   // Flutter: Was geht zum API?
   debugPrint('=== API Request: ${request.method} ${request.url}');
   debugPrint('=== Headers: ${request.headers}');
   debugPrint('=== Body: ${request.body}');
   ```
   ```csharp
   // ASP.NET: Was kommt an?
   logger.LogDebug("=== Request: {Method} {Path}", Request.Method, Request.Path);
   logger.LogDebug("=== Body: {Body}", await new StreamReader(Request.Body).ReadToEndAsync());
   ```

5. **Datenfluss rückwärts verfolgen**
   - Wo kommt der fehlerhafte Wert her?
   - Was hat diese Funktion mit diesem Wert aufgerufen?
   - Weiter zurückverfolgen bis zur Quelle
   - An der Quelle fixen, nicht am Symptom

### Phase 2: Pattern-Analyse

1. **Funktionierende Beispiele finden** — Ähnlicher funktionierender Code im Projekt
2. **Unterschiede identifizieren** — Jeder Unterschied, egal wie klein
3. **Abhängigkeiten verstehen** — Welche Config, Umgebung, Annahmen

### Phase 3: Hypothese und Test

1. **Eine Hypothese formulieren:** "Ich denke X ist die Ursache weil Y"
2. **Minimal testen:** Kleinstmögliche Änderung, eine Variable
3. **Verifizieren:** Funktioniert? → Phase 4. Nicht? → Neue Hypothese
4. **Nicht wissen zugeben** wenn nötig — nicht so tun als ob

### Phase 4: Implementierung

1. **Fehlschlagenden Test erstellen** — Einfachste Reproduktion
2. **Einzelnen Fix implementieren** — Eine Änderung, kein "da ich schon hier bin"
3. **Fix verifizieren** — Test besteht? Andere Tests noch grün?
4. **3+ gescheiterte Fixes → STOPP** — Architektur hinterfragen, mit Thomas besprechen

## Defense-in-Depth

Nach Bug-Fix: Validierung an **jeder Schicht** hinzufügen.

| Schicht | Zweck | Beispiel |
|---------|-------|---------|
| Entry Point | Offensichtlich ungültige Eingaben ablehnen | API Controller Validierung |
| Business Logic | Sinnprüfung für die Operation | Service-Layer Prüfungen |
| Infrastructure | Umgebungs-Guards | Keine gefährlichen Ops in Tests |
| Debug Logging | Kontext für Forensik | Strukturiertes Logging mit Serilog |

## Red Flags — STOPP und zu Phase 1 zurück

- "Schneller Fix jetzt, später untersuchen"
- "Einfach X ändern und schauen ob's geht"
- "Mehrere Änderungen gleichzeitig, dann Tests"
- "Ist wahrscheinlich X, das fix ich mal"
- Lösungen vorschlagen ohne Datenfluss-Analyse
- "Noch ein Fix-Versuch" (wenn schon 2+ versucht)

## Häufige Rationalisierungen

| Ausrede | Realität |
|---------|----------|
| "Problem ist einfach, brauche keinen Prozess" | Einfache Bugs haben auch Root Causes. |
| "Notfall, keine Zeit für Prozess" | Systematisch ist SCHNELLER als Raten. |
| "Erst mal das probieren, dann untersuchen" | Erster Fix setzt das Muster. Gleich richtig machen. |
| "Fix nach Fix drauflegen" | Kann nicht isolieren was funktioniert hat. |

## Schnellreferenz

| Phase | Aktivitäten | Erfolgskriterium |
|-------|-------------|-----------------|
| 1. Root Cause | Fehler lesen, reproduzieren, Evidence | WAS und WARUM verstehen |
| 2. Pattern | Funktionierendes finden, vergleichen | Unterschiede identifiziert |
| 3. Hypothese | Theorie bilden, minimal testen | Bestätigt oder neue Hypothese |
| 4. Implementierung | Test erstellen, fixen, verifizieren | Bug behoben, Tests grün |
