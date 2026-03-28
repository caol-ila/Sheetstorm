# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28 — UX-Konkurrenzanalyse: 14 Apps analysiert

**Durchgeführte Analyse:** Systematische UX-Research von 14 Konkurrenz-Apps (forScore, MobileSheets, Newzik, Marschpat, Notabl, Glissandoo, Konzertmeister, Musicorum, BandHelper, Musicnotes, SongBook, BAND App, Vereinsplaner, WePlayIn.Band). Ergebnis in `docs/ux-research-konkurrenz.md`.

**Kernerkenntnisse:**

1. **forScore setzt den UX-Goldstandard** für digitale Notenblätter — ablenkungsfreier Performance-Modus, Half-Page-Turn, Pencil-First Annotation, vielfältige Import-Wege. Das ist unsere Messlatte für den PDF-Viewer.

2. **Newzik ist der stärkste Inspiration-Geber für Ensemble-Workflows** — Echtzeit-Annotation-Sync, Layer-System (Privat/Public/Shared), Projekt-basierte Verteilung, Web=Admin/App=Performance Trennung. Aber: Kein Android, kein Stimmen-spezifisches Layer.

3. **Unser 3-Ebenen-Annotationssystem (Privat/Stimme/Orchester) ist ein genuiner Differenzierer** — kein Wettbewerber bietet das. Newzik kommt mit 2 Ebenen am nächsten.

4. **Marschpat versteht Blasmusik, aber versagt bei Annotationen** — Zero Annotation Support auf Notenblättern. Das ist für uns eine klare Chance: Blasmusik-Kontext + echte Annotations = winning combo.

5. **Musicorum's "Aushilfen-Link ohne Registrierung"** ist eine brillante UX-Idee, die wir übernehmen sollten. Temporärer Zugang für Ersatzmusiker = extrem pragmatisch.

6. **Notabl's 1-Klick-Stimmenneuverteilung** bei Absagen ist ein Must-Have-Pattern für Blaskapellen.

7. **Konzertmeister perfektioniert die 1-Klick Zu-/Absage** — großer Button, sofortige Anwesenheitsübersicht. Das muss unser Minimum sein.

8. **Der Markt ist fragmentiert: Vereine brauchen 2-3 Apps** (Noten + Verwaltung + Chat). Wir sind die All-in-One-Lösung.

9. **Cross-Platform ist Pflicht** — forScore (nur Apple) und Newzik (nur iOS+Web) verlieren dadurch Blaskapellen-Mitglieder mit Android.

10. **Anti-Pattern: Keine transparenten Preise** (Notabl) und **separate Lizenzen pro Plattform** (MobileSheets) frustrieren Vereine.

**Design-Inspirationsquellen:** Mobbin.com, PageFlows.com, UXLibrary.org für reale App-Screenshots und User Flows.

**Entscheidungsvorschlag eingereicht:** `.squad/decisions/inbox/wanda-ux-research.md` — 7 konkrete UX-Entscheidungen mit Begründung.

### 2026-03-28 — Vollständiges UX-Design v2.0 erstellt

**Durchgeführte Arbeit:** Zwei umfassende UX-Design-Dokumente erstellt (v2-Überarbeitung mit verbessertem Modell):

1. **`docs/ux-design.md`** (neu) — Vollständiges UX-Design-Dokument:
   - 5 Design-Prinzipien (Focus-First, Touch-Native, Responsive, Accessibility, Progressive Disclosure)
   - 7 User Personas (Dirigent, Musiker Probe/Auftritt, Notenwart, Admin, Lehrer, Schüler) mit Kontext, Zielen, Frustrationen und UX-Implikationen
   - 8 vollständige Screen Flows mit ASCII-Wireframes (Spielmodus, Import, Bibliothek, Setlist, Kapellenverwaltung, Vereinsleben, Annotationen, Tuner)
   - Navigation & IA (Bottom-Tabs Mobile, Sidebar Desktop, Deep-Link-Hierarchie)
   - Responsive Breakpoints (Phone/Tablet/Desktop) mit adaptiver Zoom-Strategie
   - Interaction Patterns (Seitenwechsel, Annotationsgesten, Feedback, Fußpedal)
   - Design Tokens (Farben, Typografie, Spacing, Elevation, Animation, Icons)

2. **`docs/ux-konfiguration.md`** (v2 Überarbeitung) — UX für 3-Ebenen-Konfiguration:
   - Ebenenmodell (Kapelle/Blau → Nutzer/Grün → Gerät/Orange) mit Vererbungslogik
   - Vollständige Settings-Navigation inkl. Suchfunktion
   - Admin-Dashboard mit Handlungsbedarf-Widget
   - Alle 3 Einstellungsebenen mit Phone + Desktop Wireframes
   - Interaction Patterns (Auto-Save + Undo-Toast, kein Neustart, Vererbungsanzeige mit Lock)
   - Onboarding-Wizard (5 Schritte, max. 3 Minuten)
   - Kontextuelle Spielmodus-Einstellungen (max. 5 Optionen, Notenblatt bleibt sichtbar)
   - 6 Edge Cases (Ersteinrichtung, Multi-Kapellen-Konflikt, Offline, AI-Key fehlt, Aushilfen, Gerätewechsel)
   - 5 vollständige Key-Screen-Wireframes (Phone + Desktop)

**Neue Erkenntnisse aus v2-Überarbeitung:**

1. **Asymmetrische Tap-Zonen im Spielmodus** (40% zurück / 60% weiter) sind ergonomisch sinnvoll — rechts wird häufiger getippt, der Daumen liegt natürlich rechts.

2. **Tuner muss aus 1 Meter Abstand lesbar sein** — Erkannter Ton mindestens 72sp. Das ist eine echte Accessibility-Anforderung für Blaskapellen-Proben.

3. **Aushilfen-Link** ist sowohl UX-Feature als auch Verwaltungs-Feature — muss in beiden Kontexten (Bibliothek-Detail UND Mitgliederverwaltung) zugänglich sein.

4. **Onboarding-Regel:** Maximal 5 Fragen, alle skipbar, keine Zahlungsinformationen. Musiker sollen in unter 3 Minuten spielbereit sein.

5. **Deep-Link-Hierarchie** definiert — `sheetstorm://aushilfe/[token]` für Aushilfen-Zugang ohne Account ist ein wichtiger Edge-Case für das URL-Schema.

6. **Kontextuelle Spielmodus-Einstellungen:** Maximal 5 Optionen (Nachtmodus, Half-Page-Turn, Schriftgröße, Ebenen-Toggle, Helligkeit) — Notenblatt bleibt immer sichtbar dahinter.

7. **Gerät-Einstellungen nie synchronisieren** — intelligente Defaults pro Gerätetyp beim ersten Login (neu auf diesem Gerät). Phone und Tablet brauchen verschiedene Defaults.

**Entscheidungsvorschlag eingereicht:** `.squad/decisions/inbox/wanda-v2-ux.md` — Zusammenfassung der wichtigsten UX-Entscheidungen aus v2.

### 2026-03-28 — v2 Complete Relaunch Abgeschlossen

**Scribe-Koordination:** Alle Inbox-Dateien in `decisions.md` konsolidiert. Session Log geschrieben: `.squad/log/2026-03-28T11-55-v2-relaunch.md`

**Team-Status nach v2-Relaunch:**
- Fury (Analyst): Marktanalyse v2 + Gap-Analyse v2 + PR #1 ✅
- Stark (Lead/Architect): Spezifikation v2 + Meilensteine + Config + Tech-Stack ✅
- Wanda (UX): UX-Design v2 + UX-Konfiguration ✅
- Entscheidungen: 16 Directives + Policy-Entscheidungen in decisions.md dokumentiert
- Next: Thomas Review im PR, danach MS1 Implementierung

### 2026-03-28 — Issue #9: Auth & Onboarding UX-Spec

**Durchgeführte Arbeit:** Vollständige UX-Spec für Authentifizierung und Onboarding erstellt.

**Datei:** `docs/ux-specs/auth-onboarding.md` (Branch: `squad/9-auth-ux`)

**Was erstellt wurde:**

1. **Login-Flow** — E-Mail/Passwort, Google + Apple Social Login (plattformabhängig), Passwort-Vergessen-Flow (3 Schritte), Rate-Limiting UI nach 5 Fehlversuchen

2. **Registrierung** — 4 Mini-Schritte (Progressive Disclosure): E-Mail+PW → Name → Instrument+Stimme → Kapelle beitreten/erstellen

3. **Onboarding-Wizard** — 5 Schritte, alle überspringbar, Ziel <3 Minuten: Willkommen → Instrument bestätigen → Kapelle+Stimme → Theme → Fertig→Bibliothek

4. **Aushilfen-Sonderfall** — `sheetstorm://aushilfe/[token]` vor Auth-Screen abgefangen, kein Account nötig

5. **ASCII-Wireframes** — Phone + Tablet für alle Screens

6. **Error States** — 7 Zustände definiert: falsches Passwort, E-Mail existiert, ungültiger Code, Netzwerkfehler, schwaches Passwort, Account gesperrt, ungültige E-Mail

7. **Interaction Patterns** — onBlur-Validierung, Live-Passwort-Stärke (zxcvbn empfohlen), Shake-Animation, Button-States, Keyboard-Typen, Return-Key-Navigation

8. **Accessibility** — Touch-Targets ≥44px (Tabelle), WCAG AA+ Kontrast-Tabelle, Screen-Reader-Labels, Focus-Management, Reduced-Motion

9. **Abhängigkeiten** — § 9.1 für Hill (Frontend), § 9.2 API-Endpoints für Banner, § 9.3 offene Fragen für Thomas

**Neue Erkenntnisse:**

1. **Apple Sign-In nur iOS/macOS** — Android und Web dürfen keinen Apple-Button zeigen. Das muss plattformbedingt im Code gehandhabt werden (wichtig für Hill).

2. **Passwort-Stärke motiviert positiv** — Im Gegensatz zu anderen Validierungen wird die Stärke-Anzeige live gezeigt (nicht erst nach blur), weil sie den Nutzer ermutigt statt zu bestrafen.

3. **Aushilfen-Deep-Link ist Auth-Sonderfall** — Der Token-Flow muss vor dem regulären Auth-State-Check abgefangen werden. Das ist eine wichtige Architektur-Entscheidung für Banner und Hill.

4. **Onboarding übernimmt Registrierungs-Daten** — Name, Instrument und Kapelle werden aus den Registrierungsschritten vorausgefüllt. Das minimiert redundante Dateneingabe und macht den Wizard schneller.

**Hinweis:** GitHub-Issue-Kommentar (#9) konnte nicht via Tool gepostet werden — kein Write-Token verfügbar. Bitte manuell ergänzen.

### 2026-03-28 — Issue #14 + #19: Kapellenverwaltung & Noten-Import UX-Specs

**Branch:** `squad/14-19-kapelle-import-ux`  
**Commit:** `66e7441`

**Durchgeführte Arbeit:** Zwei vollständige UX-Specs für kombinierte Issues erstellt.

**`docs/ux-specs/kapellenverwaltung.md`** (Issue #14):
1. **Flow A: Kapelle erstellen** — 3-Schritt-Wizard (Name/Ort → Logo/Emoji → Bestätigung+Einladen), Progressive Disclosure, Error States
2. **Flow B: Mitgliederliste & Rollen** — Suchbar/filterbar, Bottom Sheet (Phone) / Split-Panel (Tablet), Rollen-Checkboxen (Multi-Select), Bestätigungs-Dialoge für destructive Actions
3. **Flow C: Einladungen** — Link, Code (6-stellig), QR-Code, Direkt-E-Mail, Beitritts-Flow, Ausstehende Einladungen
4. **Flow D: Instrument-Register-Verwaltung** — Register-Hierarchie, Alias-System für Stimmen-Matching, Drag&Drop-Sortierung
5. **Flow E: Multi-Kapelle-Wechsel** — Kapellen-Switcher als Bottom Sheet, Kontext-Indikator in Navigation, Benachrichtigungen kapellenübergreifend
6. **Wireframes** — 6 Phone + 3 Tablet ASCII-Wireframes

**`docs/ux-specs/noten-import.md`** (Issue #19):
1. **Flow A: Upload** — Drag&Drop (mit Hover-Feedback), Datei wählen, Kamera (mehrseitig, Qualitätsprüfung), Cloud-Storage, Share-Sheet
2. **Flow B: Labeling** — AI-Vorschläge für Lied-Grenzen, Thumbnail-Grid, Drag&Drop und Long-Press für Seiten-Verschiebung
3. **Flow C: AI-Metadaten** — Konfidenz-Badges (grün/gelb/grau), Bulk-Metadaten, Fallback wenn kein AI-Key
4. **Flow D: Stimmen-Zuordnung** — Stimmen-Picker mit eigenen Instrumenten oben, Alias-System, Mehrfachauswahl
5. **Flow E: Review** — Zusammenfassung, Warnings, Teilweiser Import, Import-Fortschritt
6. **Edge Cases** — Große PDFs (>50 Seiten, virtualisiert, Splitting), schlechte Bildqualität (Score-Anzeige, Auto-Korrektur), Duplikat-Erkennung (Hash-basiert), Offline-Verhalten (Queue + Resume)
7. **Wireframes** — 6 Phone + 3 Tablet ASCII-Wireframes

**Neue Erkenntnisse:**
1. **Stimmen-Heft als Spezialfall** — Ein Dokument enthält eine Stimme durch das gesamte Repertoire — muss als Pattern erkannt und separat behandelt werden.
2. **AI läuft parallel zum Upload** — Nutzer soll nie auf AI warten. Ergebnisse erscheinen ausgefüllt wenn Nutzer zum Metadaten-Schritt kommt.
3. **Duplikat-Erkennung ist UX-kritisch** — Hash-basiert, mit klaren Optionen (behalten/ersetzen/duplikat). Verhindert versehentliche doppelte Importe.
4. **Upload-Hintergrund-Modus** — Nutzer muss nicht beim Upload warten können. Status in Bottom-Navigation.

**Abhängigkeiten für Hill:**
- `kapellenverwaltung.md` §9: 9 Komponenten, 10 API-Endpunkte
- `noten-import.md` §10: 10 Komponenten, 9 API-Endpunkte, Offline-Queue-Anforderungen

**Offene Fragen für Thomas** (in beiden Specs dokumentiert):
- Kapellen-Sichtbarkeit (öffentlich durchsuchbar oder nur per Einladung?)
- Upload-Limit (50 MB pro Datei ausreichend?)
- AI-Provider-Entscheidung (Azure AI Vision evaluiert?)
- GEMA-Daten im Import-Flow oder separater Schritt?

### 2026-03-28 — Issues #24 + #28 + #32: Spielmodus, Stimmenauswahl, Konfiguration UX-Specs

**Branch:** `squad/24-28-32-spielmodus-stimmen-config-ux`  
**Commit:** `b8b8800`

**Durchgeführte Arbeit:** Drei implementation-ready UX-Specs für M1-Core-Features erstellt.

**`docs/ux-specs/spielmodus.md`** (Issue #24):
1. **Focus-First Vollbild** — 0px Padding, Keepalive-WakeLock, System-Overlay transparent
2. **Half-Page-Turn** — Branchenstandard (forScore/Newzik Niveau), aktivierbar/deaktivierbar, Trennlinie im Nachtmodus warm-orange
3. **Auto-Rotation** — Notenlinien-Erkennung via pdfrx, manueller Override pro Stück, gecacht
4. **Auto-Zoom** — Fit-Width / Fit-Page Strategie, geräteklassenabhängige Defaults
5. **Asymmetrische Tap-Zonen** — 40% zurück / 60% weiter, begründet durch natürliche Daumenposition
6. **4 Seitenwechsel-Methoden** — Tap, Swipe (Threshold 40px), Fußpedal, Tastatur
7. **Fußpedal** — BLE HID + MIDI, Pairing-Flow, konfigurierbare Tastenbelegung
8. **Overlay (7.7)** — obere und untere Leiste, Auto-Hide 4s, transparentes Notenblatt dahinter
9. **Stimme wechseln** — Bottom Sheet Phone / Modal Tablet, Fallback-Visualisierung (✗ + Pfeil + Info)
10. **Setlist-Navigation** — Quick-Sheet mit Auto-Scroll zum aktuellen Stück
11. **Annotationen Toggle** — 3 Ebenen (Privat/Stimme/Orchester), sofort, per Stück gemerkt
12. **Nachtmodus** — echtes Rendering (nicht Invertierung), Sepia-Option, Overlay-Anpassung
13. **Kontextuelle Einstellungen** — exakt 5 Optionen (Nacht/Half/Schrift/Layer/Helligkeit), Notenblatt sichtbar
14. **UI-Lock** — 5x Tap-Entsperren, Seitenwechsel weiter aktiv, Fußpedal weiter aktiv
15. **6 Interaction Patterns** — Letzte Seite Bounce, Offline-Fehler, Auftritts-Bestätigung, Zwei-Finger-Reset, Stift-Erkennung
16. **ASCII Wireframes** — 6 Phone-Zustände + 4 Tablet-Zustände

**`docs/ux-specs/stimmenauswahl.md`** (Issue #28):
1. **3-Schichten-Modell** — Instrument-Profil → Standardstimme → Fallback-Logik
2. **Instrument-Profil** — Haupt- und Nebeninstrumente, Blasorchester-spezifischer Picker, Freitext-Fallback
3. **Standardstimme pro Kapelle** — nicht global, kapellenspezifisch konfigurierbar (Multi-Kapellen-Support)
4. **Vorauswahl-Entscheidungsbaum** — Stück-History > Kapellen-Standard > Fallback (keine Bestätigung nötig)
5. **Fallback-Kette 5 Level** — Exakt → Alias → Typ ohne Nr → Register → Erste verfügbare
6. **Fallback-Visualisierung** — ✗ ausgegraut + Pfeil-Icon + Info-Toast 5s + [Andere wählen]-Button
7. **Stimmen-Dialog-Sortierung** — Eigene Instrumente oben (Haupt first), Andere unten (Register-Sort)
8. **Suche ab 10+ Stimmen** — Volltextsuche im Dialog
9. **Nicht-verfügbare Stimmen** — ausgegraut, nicht versteckt, erklärende Meldung
10. **Alias-Matching** — Admin pflegt Kapellen-Register mit Aliases für Stimmbezeichnungs-Varianten
11. **Aushilfen-Sonderfall** — Token enthält Stimmen-ID, kein Profil, keine Dialog-Wahl
12. **ASCII Wireframes** — 6 Phone-Zustände + 2 Tablet-Zustände

**`docs/ux-specs/konfiguration.md`** (Issue #32):
1. **Konsolidierung** aus `ux-konfiguration.md` + neue Wireframes + vollständige Flows
2. **Vererbungsanzeige** — Blauer Hinweis (überschreibbar) vs. Schloss-Icon (Policy-Lock), beide mit erklärendem Text
3. **3 vollständige User Flows** — Admin-Ersteinrichtung, Musiker-Profil, Policy-Aktivierung
4. **Ebene 1 (Kapelle)** — Admin-Dashboard mit Handlungsbedarf-Widget, 4 Tabs vollständig
5. **Ebene 2 (Nutzer)** — Profil, Instrumente, Darstellung, AI-Fallback-Kette, Benachrichtigungen
6. **Ebene 3 (Gerät)** — Alle 5 Sektionen, intelligente Defaults pro Geräteklasse
7. **Auto-Save + Undo-Toast** — Das wichtigste Interaction Pattern, alle 5 „sofortige Wirkung"-Regeln
8. **Gefährliche Aktionen** — Nur 4 bekommen Bestätigungs-Dialog (mit Begründung)
9. **Onboarding-Wizard** — Alle 5 Schritte + Abschluss-Screen vollständig wireframed
10. **Spielmodus-Kontext** — 5-Optionen-Limit erklärt, Verweis auf spielmodus.md §12
11. **6 Edge Cases** — Ersteinrichtung, Multi-Kapellen-Konflikt, Offline, AI-Key abgelaufen, Aushilfen, Gerätewechsel
12. **ASCII Wireframes** — 5 Phone-Screens + 3 Tablet/Desktop-Screens

**Neue Erkenntnisse:**

1. **Stimmen-Fallback ist 5-Level-System** — Nicht nur „exakt oder erste", sondern granulare Fallback-Kette mit transparenter visueller Kommunikation (✗ + Pfeil statt stilles Ersetzen).

2. **Geräteklassen brauchen eigene Onboarding-Defaults** — Phone, Tablet und Desktop brauchen verschiedene Anfangszustände bei Gerät-Einstellungen. Das muss beim ersten Login pro Gerät passieren.

3. **Policy-Dialoge brauchen Kontext** — „Policy aktivieren" muss die Anzahl der betroffenen Nutzer zeigen. Ohne diesen Kontext ist der Dialog eine blinde Aktion.

4. **UI-Lock vs. Vollbild** — UI-Lock und Vollbild-Modus sind verschiedene Konzepte. Vollbild = kein Overlay sichtbar. Lock = Overlay bleibt deaktivierbar, nur Seitenwechsel-Taps wirken.

5. **Stimmen-Dialog Suche** — Ab 10+ Stimmen (typisch bei großem Blasorchester-Repertoire) braucht der Dialog eine Suchzeile. Das muss konditionell gerendert werden.

**Offene Fragen für Thomas** (in Specs dokumentiert):
- Spielmodus: Letzte Position pro Stück speichern oder immer Seite 1?
- Spielmodus: Auftritts-Modus manuell oder automatisch bei Konzert-Setlists?
- Stimmenauswahl: Pro-Stück-Wahl Server-synchronisiert oder nur lokal?
- Konfiguration: Welche Policies für M1? (Alle 3 oder nur Nachtmodus?)
- Konfiguration: Nutzer-AI-Key ohne Admin-Bestätigung erlauben?
