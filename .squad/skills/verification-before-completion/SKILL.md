# SKILL: Verifikation vor Abschluss

> Adaptiert von [obra/superpowers](https://github.com/obra/superpowers) (MIT-Lizenz).

## Kernprinzip

Arbeit als fertig zu melden ohne Verifikation ist Unehrlichkeit, nicht Effizienz.

**Evidenz vor Behauptungen, immer.**

## Eiserne Regel

```
KEINE FERTIGMELDUNG OHNE FRISCHE VERIFIKATIONS-EVIDENZ
```

Verifikationsbefehl in dieser Nachricht nicht ausgeführt? Dann nicht behaupten dass es funktioniert.

## Gate-Funktion

```
BEVOR irgendein Status behauptet oder Zufriedenheit ausgedrückt wird:

1. IDENTIFIZIERE: Welcher Befehl beweist die Behauptung?
2. FÜHRE AUS: Vollständigen Befehl frisch ausführen
3. LESE: Vollständige Ausgabe, Exit-Code, Fehlerzählung
4. VERIFIZIERE: Bestätigt die Ausgabe die Behauptung?
   - NEIN: Tatsächlichen Status mit Evidenz melden
   - JA: Behauptung MIT Evidenz melden
5. ERST DANN: Die Behauptung machen

Einen Schritt überspringen = Lügen, nicht verifizieren
```

## Verifikations-Anforderungen

| Behauptung | Erfordert | Nicht ausreichend |
|------------|-----------|-------------------|
| Tests bestehen | Test-Ausgabe: 0 Fehler | Vorheriger Lauf, "sollte bestehen" |
| Linter sauber | Linter-Ausgabe: 0 Errors | Teilprüfung, Extrapolation |
| Build erfolgreich | Build-Befehl: Exit 0 | Linter bestanden, Logs sehen gut aus |
| Bug behoben | Originalsymptom testen: besteht | Code geändert, "sollte gefixt sein" |
| Anforderungen erfüllt | Punkt-für-Punkt-Checkliste | Tests bestehen |

### Sheetstorm-spezifische Verifikation

```bash
# Flutter
flutter test                           # Alle Tests
flutter analyze                        # Statische Analyse
flutter build web --release            # Build-Check

# ASP.NET Core
dotnet test tests/                     # Alle Backend-Tests
dotnet build src/ --no-restore         # Build-Check

# Beide
git --no-pager diff --stat             # Was wurde geändert
```

## Red Flags — STOPP

- "Sollte jetzt funktionieren", "wahrscheinlich", "sieht richtig aus"
- Zufriedenheit vor Verifikation ("Super!", "Perfekt!", "Fertig!")
- Commit/Push/PR ohne Verifikation
- Auf partielle Verifikation verlassen
- "Nur dieses eine Mal" denken
- Müde und Arbeit beenden wollen

## Rationalisierungen

| Ausrede | Realität |
|---------|----------|
| "Sollte jetzt gehen" | FÜHRE die Verifikation AUS |
| "Bin zuversichtlich" | Zuversicht ≠ Evidenz |
| "Nur dieses Mal" | Keine Ausnahmen |
| "Linter bestanden" | Linter ≠ Compiler ≠ Tests |
| "Agent sagt Erfolg" | Unabhängig verifizieren |
| "Bin müde" | Erschöpfung ≠ Entschuldigung |
| "Teilprüfung reicht" | Teilprüfung beweist nichts |

## Wann anwenden

**IMMER vor:**
- Jeder Variation von Erfolgs-/Abschluss-Behauptungen
- Jedem Ausdruck von Zufriedenheit
- Commits, PR-Erstellung, Task-Abschluss
- Weiter zum nächsten Task
