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

### 2026-03-29 — MS2 UX-Specs: GEMA, Media Links, Song-Broadcast

**Durchgeführte Arbeit:** Drei vollständige UX-Spezifikationen für MS2-Features erstellt.

**Dateien:**
1. `docs/ux-specs/gema-compliance.md` — GEMA-Meldungen generieren, exportieren, AI-gestützte Werknummern-Suche
2. `docs/ux-specs/media-links.md` — YouTube/Spotify-Links auf Stück-Ebene, Anhören-Button, AI-Vorschläge
3. `docs/ux-specs/song-broadcast.md` — Echtzeit-Stück-Broadcasting Dirigent→Musiker, Live-Verbindungsstatus

**Kernerkenntnisse:**

1. **GEMA-Compliance ist UX für Nicht-Technik-Nutzer** — Verwertungsgesellschafts-Auswahl, Werknummern-Suche und Export müssen ohne Backend-Wissen nutzbar sein. Draft→Export→Read-Only-Workflow ist Pflicht für historische Konsistenz.

2. **AI als Assistent, nicht Entscheider** — Sowohl bei GEMA-Werknummern-Suche als auch bei Media-Link-Vorschlägen: Confidence-Scores + manuelle Korrektur sind Pflicht. Keine stillen AI-Entscheidungen.

3. **Song-Broadcast ist kritisches Live-Feature** — Vertrauen durch Transparenz: Dirigent sieht live, wie viele Musiker verbunden sind und ob alle das Stück empfangen haben. Reconnect <3s ist unsichtbar, >3s zeigt Status.

4. **Musiker-Sicht ist passiv** — Stück-Wechsel passiert automatisch, Noten öffnen sich im Spielmodus. Keine Unterbrechung, Benachrichtigungen sind subtil.

5. **Fehlende Stimme = Explicit Fallback** — Wenn Stimme fehlt, wird Musiker informiert (nicht stillschweigend ersetzt). Das gilt für Song-Broadcast genauso wie für normale Stimmenauswahl.

6. **Media Links: Minimal & Fokussiert** — Ein Link = eine URL. Keine komplexen Playlists, keine Inline-Player (MS2). Deep-Link-First zu nativer App (YouTube/Spotify), Browser als Fallback.

7. **Export-Formate: XML (Pflicht) + CSV/PDF (Optional)** — GEMA-XML ist gesetzlich erforderlich, CSV für Backup/Excel, PDF für Papierarchiv/Behörden.

8. **oEmbed-Fallback** — Falls Metadaten-Abruf fehlschlägt (404, Timeout), Link trotzdem speichern (mit null Metadata). Link bleibt funktional.

9. **Session-Kollision = Takeover-Dialog** — Falls Broadcast-Session läuft, kann neuer Dirigent übernehmen (mit Bestätigung). Alter Dirigent wird getrennt + Notification.

10. **Latenz-Transparenz für Dirigent** — Live-Anzeige von Durchschnitts-Latenz + Pro-Musiker-Details. Warnung bei >1000ms, keine automatische Aktion — Dirigent entscheidet.

**Wichtige UX-Patterns etabliert:**

- **GEMA-Reminder = Nudge, nicht Nag:** Erinnerungen nach 7 Tagen, konfigurierbar, informativ
- **Duplikat-Schutz:** Gleiche URL pro Stück nur einmal (Media Links)
- **Auto-Discovery:** Musiker erkennen aktive Broadcast-Session automatisch via WebSocket
- **Persistent Broadcast-Indicator:** Musiker bleiben verbunden, auch wenn sie zwischen Screens wechseln
- **Confidence-Level-Farben:** >90% Grün, 70-89% Blau, 50-69% Orange, <50% Rot (konsistent mit bestehendem Design System)

**Responsive Besonderheiten:**

- **GEMA:** Split-View Tablet (Liste links, Detail rechts), Phone Scrollable
- **Media Links:** Link-Karten 2-Spalten Grid (Tablet), 100% breit (Phone)
- **Song-Broadcast:** Dirigent-View Split-View (Sidebar + Hauptbereich), Musiker-View Banner + Indicator

**Accessibility-Highlights:**

- Touch Targets min. 44×44px, Stück-Karten min. 56px hoch
- Status-Badges immer Farbe + Icon (nie Farbe allein)
- Screen Reader: Aria-Labels für Live-Regionen (AI-Suche-Progress, Export-Status, Broadcast-Status)
- Keyboard Navigation: Shortcuts für GEMA-Export (Cmd+E), Broadcast-Start (Cmd+B)

**Datei-Referenzen:**
- Feature-Specs: `docs/feature-specs/gema-compliance-spec.md`, `media-links-spec.md`, `song-broadcast-spec.md`
- Format-Vorlage: `docs/ux-specs/noten-import.md`, `spielmodus.md`
- Design System: `docs/ux-design.md`
- Konfiguration: `docs/ux-konfiguration.md`

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

### 2026-03-28 — Issue #37: Annotationen (3 Ebenen) UX-Spec

**Branch:** `squad/37-annotationen-ux`  
**Commit:** `7a2dbfa`

**Durchgeführte Arbeit:** Vollständige UX-Spec für das 3-Ebenen-Annotationssystem erstellt.

**Datei:** `docs/ux-specs/annotationen.md`

**Was erstellt wurde:**

1. **3 Sichtbarkeitsebenen** — Privat (Blau 🔵), Stimme (Grün 🟢), Orchester (Orange 🟠) mit vollständigem visuellen Encoding-System (Rand + Icon + Muster für Barrierefreiheit)

2. **7 Annotationstypen** — Freihand-Zeichnung (Stift-First, Druck-sensitiv), Text-Notizen, Textmarker, Durchstreichen, Stamp-Tools (Dynamik/Artikulation/Atem/Navigation + benutzerdefiniert), Radierer, Auswahl

3. **Vollständige Interaction Patterns** — 3 Einstiegswege (Long-Press 600ms, Stift-Erkennung sofort, Toolbar-Button), Toolbar-Aufbau (Phone horizontal / Tablet vertikal + verschiebbar), Ebenen-Flyout, Farbkodierung Toolbar = aktive Ebene, Undo/Redo per Touch-Geste, Long-Press Kontextmenü

4. **Integration im Spielmodus** — SVG-Layer (relative Koordinaten, zoom/rotationsunabhängig), Z-Order definiert, Layer-Toggle pro Ebene (pro Stück gemerkt), Fokus-Schutz (kein versehentliches Annotieren), Nachtmodus-Kompatibilität

5. **Sync-Verhalten** — Privat=lokal+Konto-Backup, Stimme/Orchester=SignalR Real-time, Delta-Sync (Patches, kein Full-State), Latenz-Ziel <500ms LAN

6. **6 Edge Cases** — Offline (pending_sync + auto-sync bei Verbindung), Konflikte (Last-Write-Wins per UUID + Timestamp), gelöschte Seite (Warnung + Soft-Delete 30 Tage), Berechtigungssperren, Aushilfen-Session (kein persistentes Privat), Performance (lazy load + 500 Annotations Warnung)

7. **ASCII Wireframes** — 6 Phone-States (inaktiv, Long-Press-Einstieg, aktiver Freihand-Modus, Ebenen-Flyout, Kontextmenü, Layer-Toggle) + 4 Tablet-States (aktiver Modus, Stempel-Picker, Dirigenten-Orchester-Ebene, Offline-Zustand)

**Neue Erkenntnisse:**

1. **Farb-Konflikt entdeckt:** `spezifikation.md` setzt Privat=Grün/Stimme=Blau/Orchester=Orange, aber das Konfigurationssystem nutzt Privat=Blau/Stimme=Grün/Orchester=Orange. Diese Inkonsistenz ist ein offener Punkt für Thomas (Q1 im Spec). Empfehlung: Konsistenz mit dem Konfigurationssystem — Farbe = konzeptuelle Ebene.

2. **„Senden"-Bestätigung für Orchester-Layer** ist eine wichtige UX-Entscheidung: Sofort-Sync (wie forScore/Newzik) vs. explizites Bestätigen (weniger Fehler, aber mehr Reibung). Muss Thomas entscheiden (Q3).

### 2026-04-15 — MS2 UX-Specs: Anwesenheit, Aushilfen, Schichtplanung

**Durchgeführte Arbeit:** Drei vollständige UX-Specs für MS2-Features erstellt.

**Dateien:**
1. `docs/ux-specs/anwesenheit.md` — Anwesenheits-Statistiken
2. `docs/ux-specs/aushilfen.md` — Aushilfen-Zugang (Token/QR-Flow)
3. `docs/ux-specs/schichtplanung.md` — Schichtplanung (Basic-Version)

**Was erstellt wurde:**

**1. Anwesenheit (`anwesenheit.md`):**
- **3 Tabs:** Musiker-Liste, Register-Analyse, Trend-Ansicht (Charts)
- **RBAC-Matrix:** Musiker sehen nur eigene Daten, Registerführer nur eigenes Register, Admin/Dirigent alles
- **Filter:** Zeitraum (3/6/12 Monate), Termintyp (Probe/Konzert/Marsch) — Multi-Select
- **Farb-Kodierung:** Grün >80%, Gelb 60-80%, Rot <60% (immer mit Text-Label)
- **Drill-Down:** Register → Musiker-Liste (gefiltert)
- **Export-Flow:** CSV/PDF als async Job, Download-Link 24h gültig
- **Charts:** Line-Chart für Trends (Gesamt/Register/Personen), tappable Datenpunkte
- **5 Error States:** Keine Termine, zu wenig Termine, keine Rückmeldungen, Export fehlgeschlagen, ungültiger Zeitraum
- **ASCII Wireframes:** 6 Phone + 4 Tablet/Desktop

**2. Aushilfen (`aushilfen.md`):**
- **Token-basierter Zugang:** `ash_` + 43 Zeichen (256-bit), kein Login/Registrierung
- **Flow:** Admin erstellt → Link/QR generiert → Aushilfe scannt/öffnet → direkt zu Noten
- **QR-Code:** Client-seitig generiert (qr_flutter), 256×256px inline, 512×512px Download
- **Read-Only Guest-View:** Nur zugewiesene Stimme, nur Termin-Setlist, keine Annotationen
- **Verwaltung:** Liste aktiv/widerrufen/abgelaufen, Aktionen (Link kopieren, QR zeigen, verlängern, widerrufen)
- **Offline-Support:** Service Worker cacht PDFs nach initialem Load
- **Auth-State-Machine:** Token-Prüfung vor normalem Auth-Flow (Sonderfall)
- **6 Error States:** Abgelaufen, widerrufen, ungültig, Netzwerkfehler, keine Aushilfen, volle Schicht
- **ASCII Wireframes:** 8 Phone + 4 Tablet/Desktop

**3. Schichtplanung (`schichtplanung.md`):**
- **Basic-Version für MS2:** Schichtpläne für Events (Aufbau/Getränke/Abbau), Selbsteintragung + Admin-Zuweisung
- **Plan erstellen:** Name, Datum, Beschreibung, optional mit Termin verknüpft
- **Schichten definieren:** Name, Von/Bis (Time-Picker), Anzahl Personen (Stepper), Beschreibung
- **Selbsteintragung:** „Ich bin dabei"-Button, First-Come-First-Served, Zeitkonflikt-Warnung (nicht blockierend)
- **Admin-Zuweisung:** Modal (Phone) / Inline-Dropdown (Desktop), Such-Feld, Verfügbar/Zugewiesen-Sektionen
- **Übersicht:** 2 Tabs (Meine Schichten / Verfügbar), Sortierung nach Dringlichkeit + Datum
- **Kapazitäts-Anzeige:** Fortschritts-Dots (●●●○○), Farb-Kodierung (Grün=voll, Gelb=teilweise, Rot=leer)
- **Push-Notifications:** Neuer Plan, neue Schicht, Admin-Zuweisung (pro Kapelle/Nutzer deaktivierbar)
- **6 Error States:** Keine Pläne, keine Schichten, Schicht voll, bereits eingetragen, Zeitkonflikt, keine verfügbaren Schichten
- **ASCII Wireframes:** 8 Phone + 4 Tablet/Desktop

**Neue Erkenntnisse:**

1. **Statistik-Drill-Down-Pattern:** Register → Musiker-Liste ist ein wiederkehrendes Pattern bei Vereins-Features. Breadcrumb „← Zurück zu Register-Übersicht" ist wichtig für Orientierung.

2. **Aushilfen-Token als Auth-Sonderfall:** `sheetstorm://aushilfe/{token}` muss vor dem regulären Auth-State-Check abgefangen werden — bestätigt durch existierende `auth-onboarding.md`. Wichtig: Token-Flow ist komplett bypassend, kein Account-Requirement.

3. **QR-Codes client-seitig generieren:** Server sendet nur Token, Frontend generiert QR → reduziert Server-Last und ermöglicht Offline-QR-Anzeige nach initialer Erstellung.

4. **Schicht-Kapazitäts-Visualisierung:** Fortschritts-Dots (max 8, darüber Zahl) + Farb-Kodierung + Text-Label („3/5 Personen") = dreifache Redundanz für Accessibility.

5. **Zeitkonflikt-Warnung, nicht Blockierung:** Bei Schichten können Nutzer Konflikte selbst einschätzen (z.B. kurze Überschneidung akzeptabel) — UX zeigt Warnung, blockiert aber nicht. Wichtig: Entscheidung beim Nutzer lassen.

6. **Async Export-Jobs für Statistiken:** CSV/PDF-Export läuft im Hintergrund, Download-Link ist 24h gültig → verhindert Timeout bei großen Exporten und ermöglicht „Export starten + weiterarbeiten".

7. **First-Come-First-Served für Schichten:** Keine Prioritäten, keine Wartelisten, keine Genehmigungen in MS2 — bewusst simpel gehalten. Tap auf „Ich bin dabei" = sofortige Zuweisung (mit Toast-Feedback).

8. **Farb-Konsistenz über MS2-Features:** Grün/Gelb/Rot-Schema für Anwesenheit (Quote) und Schichtplanung (Kapazität) → konsistent mit Design-System `color-success/warning/error`.

**Pattern-Erkenntnisse für zukünftige Features:**

- **Dashboard-Widget-Pattern:** Anwesenheit + Schichtplanung könnten beide Widgets im Admin-Dashboard bekommen („Kritische Anwesenheit" / „Unfilled Shifts")
- **Export-Pattern:** Async Job + 24h-Link ist wiederverwendbar für andere Reports (z.B. Mitgliederliste, Repertoire-Übersicht)
- **Guest-Access-Pattern:** Token-Flow aus Aushilfen ist wiederverwendbar für andere temporäre Zugänge (z.B. externe Veranstalter, Presse)

**Abhängigkeiten für Hill:**
- Chart-Library: `fl_chart` oder Syncfusion für Flutter
- QR-Library: `qr_flutter` (Dart)
- Service Worker: PWA-Cache für Aushilfen-Offline-Support
- Date-Range-Picker + Time-Picker: Material Design Picker
- System-Share-Sheet: Native Share-API

**Offene Fragen für Thomas:**
- Anwesenheit: Automatische Reminder für niedrige Quoten (<60%)?
- Aushilfen: Token-Gültigkeit standardmäßig 7 Tage oder konfigurierbar?
- Schichtplanung: Automatische Konflikt-Erkennung mit Proben/Konzerten in späterem MS oder nie?

3. **Stimmen-Annotationen bei Fallback-Stimme** ist ein ungelöster Grenzfall: Wenn Musiker Fallback-Stimme spielt — Stimmen-Layer der Fallback-Stimme oder eigentlichen Stimme? Relevant für Banner und Stark (Q6).

4. **Toolbar verschiebbar auf Tablet** ist essenziell für Linkshänder und für Dirigenten mit einhändiger Bedienung (Taktstock in der anderen Hand).

**Abhängigkeiten für Hill:** 10 Flutter-Komponenten definiert (F1–F10)  
**Abhängigkeiten für Banner:** 10 API-Endpoints + SignalR Hub definiert (B1–B10)

**Offene Fragen für Thomas:**
- Farbschema: Annotations-Ebenen konsistent mit Konfigurations-Ebenen?
- Stimmen-Annotationen für andere Register sichtbar (ja/nein)?
- Orchester-Annotation: sofort senden oder [Senden]-Button?
- Kapellenweite Stamp-Sets für M1?

### 2026-03-28 — UX-Spec: Kommunikation (MS2)

**Durchgeführte Arbeit:** Vollständige UX-Spezifikation für das Kommunikations-Feature erstellt.

**Datei:** `docs/ux-specs/kommunikation.md` (48 KB, sehr umfangreich)

**Inhalt:**
1. **Board-Feed:** Chronologischer Feed mit gepinnten Posts (max. 3), Post-Cards mit Reaktionen/Kommentaren
2. **Post erstellen:** Titel, Inhalt (bis 5.000 Zeichen), bis 5 Anhänge (Bilder/PDFs), Register-Auswahl
3. **Kommentare:** 1-Ebene-Kommentare (keine Verschachtelung), chronologisch sortiert, mit optionalem Bild-Anhang
4. **Reaktionen:** 5 vordefinierte Emoji (👍 👏 ❤️ 😊 🎺), nur 1 pro Nutzer pro Post, Toggle-Verhalten
5. **Pin-Funktion:** Bis zu 3 Posts oben fixieren, gelber Hintergrund, Pin-Badge, Dialog bei Limit-Überschreitung
6. **Umfragen:** Editor mit 2-10 Optionen, Einzel-/Mehrfachauswahl, anonym/öffentlich, Ablaufdatum, Live-Ergebnisse
7. **Abstimmungs-Ansicht:** Progress-Bars, Echtzeit-Updates, "Stimme ändern"-Button, Register-Filter
8. **Notification-Einstellungen:** 3-Ebenen-Hierarchie (Global → Pro Kapelle → Pro Kategorie), Register-Filter
9. **Navigation:** Board-Tab in Bottom-Navigation, Deep-Links für Push-Benachrichtigungen
10. **Error States:** 7 verschiedene Fehlerzustände + Leerzustände
11. **Interaction Patterns:** Pull-to-Refresh, Infinite Scroll, Optimistic Updates, Auto-Save
12. **Accessibility:** Screen Reader, WCAG 2.1 AA, Touch-Targets 44×44px, Keyboard-Navigation

**Kernerkenntnisse:**

1. **Register-basierte Kommunikation ist das Differenzierungsmerkmal** — Posts/Umfragen können an bestimmte Register gerichtet sein (z.B. "Nur Trompeten"). Das muss visuell prominent sein: Badge mit 🎺 + Register-Name.

2. **Pin-Funktion braucht klare Hierarchie** — Gepinnte Posts (max. 3) müssen visuell vom chronologischen Feed unterscheidbar sein: Gelber Hintergrund + 📌-Badge + separater Abschnitt oben.

3. **Umfragen sind komplex** — Viele Konfigurationsoptionen (Einzelauswahl/Mehrfachauswahl, anonym/öffentlich, Ergebnisse sofort/nach Ablauf, Ablaufdatum). Aber: Defaults müssen intelligent sein ("Einzelauswahl, anonym, sofort, 7 Tage").

4. **Live-Ergebnisse sind UX-kritisch** — Umfragen müssen Echtzeit-Updates zeigen (Progress-Bars), ohne dass Nutzer manuell neu laden müssen. Websocket oder Polling nötig.

5. **Notification-Granularität ist Pflicht** — Nutzer müssen pro Kapelle UND pro Kategorie (Posts/Umfragen/Kommentare) steuern können. Sonst: Notification-Fatigue. Register-Filter: "Nur Benachrichtigungen für meine Register" ist wichtig für große Kapellen.

6. **1-Ebene-Kommentare sind bewusste Vereinfachung** — Keine verschachtelten Threads (wie Reddit/Slack). Chronologische Sortierung (älteste zuerst) ist typisch für Diskussionen. Vereinfacht UI massiv.

7. **Optimistic Updates für Kommentare** — Sofort anzeigen, grauer Hintergrund während "Wird gesendet", bei Fehler rot + Retry-Button. Bessere gefühlte Performance.

8. **Split-View auf Desktop** — Post/Umfrage erstellen mit Live-Vorschau rechts ist sehr hilfreich. Nutzer sieht sofort, wie es aussehen wird.

9. **Filter-Chips für Board-Feed** — [Alle] [Pinned] [Umfragen] [Register ▼] — Horizontal-Scroll, aktiver Filter farbig. Wichtig für große Kapellen mit vielen Posts.

10. **Error States müssen konkret sein** — Nicht nur "Fehler", sondern "Anhang zu groß (15 MB, max. 10 MB)" mit Handlungsempfehlung.

**Design-Pattern-Entscheidungen:**

- **Card-basiertes Layout** für Posts/Umfragen (nicht Liste) — mehr Depth, klare Abgrenzung
- **Bottom-Fixed Kommentar-Input** — bleibt beim Scrollen sichtbar, schneller Zugriff
- **Tap auf Reaktionszahl → Nutzer-Liste** (bei öffentlichen Umfragen/Posts)
- **Collapsible Sections** für lange Nutzer-Listen ("…und 11 weitere")
- **Master-Switches** für Benachrichtigungen (Global → Kapelle → Kategorie)

**Key-Screens (12 ASCII-Wireframes):**
1. Board-Feed (Phone + Tablet/Desktop)
2. Post erstellen (Phone + Desktop Split-View)
3. Post-Detail mit Kommentaren
4. Kommentar schreiben (Expanded)
5. Reaktions-Picker (Bottom Sheet)
6. Umfrage erstellen (Phone + Desktop)
7. Umfrage abstimmen (vor/nach Abstimmung, abgelaufen)
8. Benachrichtigungs-Einstellungen (Phone + Desktop)
9. Pin-Limit-Dialog
10. Error States (7 verschiedene)

**File-Paths für Hill:**
- UX-Spec: `docs/ux-specs/kommunikation.md`
- Feature-Spec: `docs/feature-specs/kommunikation-spec.md` (Hill muss beide lesen)
- Design Tokens: `docs/ux-design.md` (Farben, Typografie, Spacing)
- Konfiguration: `docs/ux-konfiguration.md` (für Notification-Settings)

**Abhängigkeiten:**
- Backend (Banner): Posts-API, Umfragen-API, Push-API (siehe Feature-Spec § 4)
- MS1: Rollenmodell, Register-Daten, JWT-Auth
- Flutter-Plugins: Image Picker, FCM/APNs, PDF-Preview

### 2026-03-28 — MS2 UX-Specs: Setlist + Konzertplanung

**Durchgeführte Arbeit:** 2 vollständige UX-Spezifikationen für MS2-Features erstellt, basierend auf Feature-Specs von Hill + bestehenden UX-Specs als Format-Vorlage.

**Dateien erstellt:**
1. **`docs/ux-specs/setlist.md`** (42 KB) — Setlist-Verwaltung
2. **`docs/ux-specs/konzertplanung.md`** (48 KB) — Konzertplanung + Kalender

**Setlist-Verwaltung — Kernerkenntnisse:**

1. **Builder-UI = Kern-UX** — Das Zusammenstellen einer Setlist muss so einfach sein wie eine Playlist erstellen. Drag & Drop mit Long-Press (Mobile) + Mouse-Drag (Desktop) + Keyboard-Unterstützung (Tab + ↑/↓).

2. **Platzhalter sind Business-Critical** — Blaskapellen digitalisieren schrittweise. Ohne Platzhalter (📌-Icon, kein Stück-Referenz) ist eine vollständige Programmplanung unmöglich. Platzhalter im Spielmodus = automatisch überspringen mit 4-Sekunden-Toast.

3. **Timing-Ansicht = GEMA-Vorbereitung** — Startzeit (20:00) + geschätzte Dauern → automatische Berechnung von Start-/Endzeiten pro Stück. Wichtig für Veranstalter + GEMA-Meldung (separate Spec MS2).

4. **Setlist-Player ≠ Normaler Spielmodus** — Erweitert MS1-Spielmodus um: Progress "Stück 3/12", ⏮/⏭-Buttons, Setlist-Schnellnavigation, Auto-Wechsel (optional), Preloading (<200ms Übergang).

5. **Pause-Einträge sind Sonderfall** — 💤-Icon, nur für Timing (kein Stück), nicht anklickbar im Player. Use-Case: "15 Minuten Pause — Getränke im Foyer".

6. **Drag-Feedback muss klar sein** — Element hebt sich ab (opacity 0.9), andere Einträge zeigen Drop-Zonen (gestrichelte Linien), Drop-Zone highlighted (blauer Rahmen), Smooth Animation (200ms).

7. **Responsive: Tablet = Table-Layout** — Desktop zeigt Setlist als Wide-Table (Spalten: #, Titel, Komponist, Dauer, Timing) statt Cards. Effizienter für große Setlists (15+ Stücke).

**Konzertplanung + Kalender — Kernerkenntnisse:**

1. **1-Tap Zusage ist Pflicht** — Keine Formulare, keine Bestätigungen (außer bei Absage). Button [✓ Zusagen] → API-Call → Status ändert sich sofort → Toast "Zusage gespeichert".

2. **Ersatzmusiker-Vorschlag = Alleinstellungsmerkmal** — Wenn Musiker absagt, analysiert System automatisch: Instrument, Stimme, Verfügbarkeit, letzte Aktivität. Output: Top 5 Match-Score-sortiert. Kein Wettbewerber bietet das.

3. **Matching-Algorithmus muss transparent sein** — Score sichtbar machen: "🎺 Markus Bauer (Tenorhorn • 2. Stimme) • Match: 100 (exakt)". Konflikt-Kennzeichnung: "⚠️ Konflikt mit 'Probe (15. Mai)'".

4. **Bidirektionale Kalender-Sync ist komplex** — OAuth2-Flow für Google/Apple/Outlook, pro Kapelle eigenes Kalender-Abo, Farbe pro Kapelle, Änderungen im externen Kalender → zurück zu Sheetstorm (nur Dirigent/Admin dürfen editieren).

5. **3 Ansichten = 3 Use-Cases** — Monatsansicht (Überblick), Wochenansicht (detaillierte Wochenplanung, Timeline-Grid), Listenansicht (chronologische Durchsicht mit Filter + Suche).

6. **Status-Badges müssen konsistent sein** — ✓ Zugesagt (grün), ✗ Abgesagt (rot), ? Unsicher (orange), ○ Offen (grau). Immer Icon + Farbe (nie nur Farbe = Accessibility).

7. **Push-Benachrichtigungen = Notification-Fatigue-Risk** — Zusammenfassen: Zusage-Updates alle 30 Minuten (an Dirigent), keine Einzelbenachrichtigung pro Musiker. Pro-Kapelle-Deaktivierung wichtig (Multi-Kapellen-Nutzer).

8. **Kurzfristige Absage (<2h) braucht Warnung** — "⚠️ Der Termin beginnt in 1 Stunde! Bitte kontaktiere den Dirigenten direkt per Telefon."

9. **Anwesenheitsliste nur für Dirigent/Admin** — Musiker sehen nur Gesamtzahlen ("23 zugesagt • 2 abgesagt • 3 offen"), keine Namen. Privacy + Rollenmodell.

10. **Responsive: Tablet = Timeline-Grid** — Wochenansicht auf Tablet zeigt 7 Spalten (Mo–So) + Timeline (18:00–21:00) mit Terminen als Blöcke. Desktop = Split-View (Kalender + Termin-Detail).

**Format-Konsistenz mit bestehenden UX-Specs:**
- Header mit Version, Status, Autorin, Datum, Meilenstein, Referenzen
- Inhaltsverzeichnis (16 Sections)
- ASCII-Wireframes (Phone + Tablet/Desktop)
- User Flows mit Entscheidungsbäumen
- Interaction Patterns
- Responsive Breakpoints (Phone/Tablet/Desktop)
- Error States & Leerzustände
- Accessibility (Keyboard, Screen Reader, Touch-Targets, Kontrast)
- Abhängigkeiten

**Design-Patterns verwendet:**
- **Auto-Save + Undo-Toast** (keine "Speichern"-Buttons)
- **Long-Press Context Menu** (Mobile)
- **Swipe-Geste** (iOS/Android: Swipe left/right für Quick-Actions)
- **Pull-to-Refresh** (Kalender-Ansicht)
- **Bottom Sheet** (Modals auf Mobile)
- **Optimistic Updates** (sofort anzeigen, bei Fehler rückgängig)
- **Progressive Disclosure** (Begründung bei Absage optional, nicht forced)

**Key-Screens (30 ASCII-Wireframes):**

**Setlist (15 Wireframes):**
1. Setlist-Übersicht (Phone + Tablet)
2. Setlist-Detail (Phone + Desktop)
3. Noten-Picker (Stück hinzufügen)
4. Platzhalter hinzufügen
5. Setlist-Player (Phone + Tablet Querformat)
6. Setlist-Schnellnavigation
7. Drag & Drop (Feedback-States)
8. Timing-Ansicht
9. Pause hinzufügen
10. Leerzustände

**Konzertplanung (15 Wireframes):**
1. Kalender-Übersicht: Monats-/Wochen-/Listenansicht (Phone + Tablet)
2. Termin erstellen (Phone + Erweiterte Optionen)
3. Termin-Detail (Phone + Desktop Split-View)
4. Absage-Dialog (mit Begründung)
5. Anwesenheitsliste (Dirigent)
6. Ersatzmusiker-Vorschlag (mit Match-Score)
7. Kalender-Sync-Settings (Phone + Desktop)
8. Push-Benachrichtigungen
9. Wochenansicht Timeline-Grid (Tablet)
10. Leerzustände + Error States

**Abhängigkeiten:**
- MS1: Spielmodus, Stimmenauswahl, PDF-Rendering, Rollenmodell
- MS2-parallel: Konzertplanung ↔ Setlist-Verknüpfung
- Backend: `/api/v1/setlists`, `/api/v1/termine`, Kalender-Sync-API (OAuth2)
- Externe Dienste: Google Calendar API v3, Microsoft Graph API, Apple iCloud CalDAV, FCM/APNs

**Nicht committet** — Dateien nur angelegt, wie in Task gefordert.

---

### 2026-03-29 — MS2 UX-Specs: 9 Features definiert (parallel orchestration)

**Durchgeführte Arbeit:** Parallel orchestration von 4 Wanda-UX-Agenten zur Erstellung von 9 kompletten MS2-Feature-UX-Spezifikationen (326.4 KB total output).

**9 Spezifikationen erstellt:**

1. **Setlist-Verwaltung** (`docs/ux-specs/setlist.md`) — Song-Collections, Sortierung, Metadaten, Versionierung, Timing-Ansichten, Drag-Drop-Reordering
2. **Konzertplanung** (`docs/ux-specs/konzertplanung.md`) — Event-Scheduling, Musiker-Zuweisung, Kalender-Sync (Google/Apple/Outlook), Ersatzmusiker-Matching
3. **Team-Kommunikation** (`docs/ux-specs/kommunikation.md`) — Messaging, Channels, Notifications, Inline-Collaboration
4. **GEMA-Compliance** (`docs/ux-specs/gema-compliance.md`) — Rechte-Management-Reporting, AI-Werknummern-Suche (Confidence-Scoring), XML/CSV/PDF-Export
5. **Media-Links** (`docs/ux-specs/media-links.md`) — YouTube/Spotify Deep-Links, oEmbed-Metadaten, AI-Vorschläge, Anhören-Button im Spielmodus
6. **Song-Broadcasting** (`docs/ux-specs/song-broadcast.md`) — Echtzeit-Sync (SignalR), Transparente Status-Indikatoren, Latenz-Monitoring (>1000ms Warnung), Auto-Reconnect
7. **Anwesenheits-Tracking** (`docs/ux-specs/anwesenheit.md`) — Musiker-Präsenz, Rollenbasierte Sichten, Abwesenheits-Benachrichtigungen
8. **Aushilfen/Temporäre Mitglieder** (`docs/ux-specs/aushilfen.md`) — Ersatz-Workflows, Verfügbarkeit, Trainings-Status, One-Click-Zusage ohne Registrierung
9. **Schichtplanung** (`docs/ux-specs/schichtplanung.md`) — Probe/Auftritt-Zuweisungen, Konflikt-Erkennung, Automatische Substitutions-Vorschläge

**Parallelisierungsstrategie:**
- wanda-ux-a: Setlist + Konzertplanung (2 verwandte, komplexe Features) — 586s
- wanda-ux-b: Kommunikation (standalone) — 357s
- wanda-ux-c: GEMA + Media + Broadcast (3 technisch komplexe Features mit Backend-Abhängigkeiten) — 740s
- wanda-ux-d: Anwesenheit + Aushilfen + Schichtplanung (3 verwaltungs-fokussierte Features) — 639s

**Gesamtdauer:** ~12m 20s (parallel efficiency = sehr gut)

**Kernentscheidungen (dokumentiert in `.squad/decisions.md`):**

**GEMA-Compliance:** Draft-first export-locked, AI-Confidence-Levels (≥90% grün, 70-89% blau, 50-69% orange, <50% none), Gemeinfrei-Checkbox optional

**Media-Links:** Minimal-UI, Deep-Link-First, oEmbed-Fallback bei Metadaten-Fehler

**Song-Broadcast:** Transparente Status-Indikatoren, Musiker-Sicht passiv, Reconnect-Schwellen (<3s no-feedback, 3-30s orange, >30s dialog)

**UX-Pattern-Konsistenz:** Touch-Targets 44×64px, Icon+Farbe (kein Farbe-only), Screen Reader ARIA-Labels, Keyboard Shortcuts, Responsive Phone/Tablet/Desktop

**Backend-Abhängigkeiten:** SignalR Hub, oEmbed-Service, Azure OpenAI (GEMA + Media-Links)

**Status:** Ready for Review by Stark (Lead)

---

## Team Update: Kapellenverwaltung & Auth-Onboarding Spec-Update (2026-03-28T22:10Z)

**From:** Hill (Product Manager)  
**Action:** UX flows updated — new entry point + approval UI.

**UX Changes Required:**
1. **Kapellen-Auswahl as Entry Point (Post-Onboarding)**
   - Smart routing: 1 Kapelle → skip to that Kapelle; Only "Meine Musik" → skip to "Meine Musik"
   - "Meine Musik" always first (personal library, special treatment)
   - Clean selector UI with band names, member counts, roles

2. **"Meine Musik" Display**
   - Visual distinction from regular Kapellen (icon, color, label)
   - Read-only indicators (can't leave, can't invite, can't delete)
   - Appears in all Kapelle selectors

3. **Join Request Flow (New)**
   - User with invitation → submits request
   - Shows "Request Pending" status with spinner
   - After approval: "Request Approved" with green checkmark
   - After rejection: "Request Denied" with reason (if provided) + "Try Another Invite" button

4. **Admin Approval UI (New)**
   - Request list: name, email, requested role, "Approve" / "Reject" buttons
   - Reject flow: optional "reason" text field for user feedback
   - Confirmation dialogs before approving/rejecting

**Specs Affected:**
- docs/feature-specs/auth-onboarding-spec.md — US-02, US-04 (entry point logic)
- docs/feature-specs/kapellenverwaltung-spec.md — §7 (UI patterns), edge cases

**Next Step:** Mock designs for Kapellen-Auswahl + approval screens for team review

### 2026-03-31 — MS3 UX-Specs: 6 Features

**Durchgeführte Arbeit:** Vollständige UX-Specs für alle 6 MS3-Features erstellt.

**Dateien:**
1. `docs/ux-specs/tuner.md` — Chromatischer Stimmgerät mit Cent-Anzeige, Kammerton-Kalibrierung, Transpositions-Umschaltung
2. `docs/ux-specs/metronom.md` — Echtzeit-Metronom: Dirigent-View (Steuerung), Musiker-View (Beat-Indikator), UDP/WebSocket Sync
3. `docs/ux-specs/cloud-sync.md` — Cloud-Sync: Sync-Status (synced/syncing/conflict/offline), Last-Write-Wins, Offline-Indikator
4. `docs/ux-specs/annotationen-sync.md` — Echtzeit-Annotationen-Sync: Live-Indikator, Gleichzeitig-Zeichnen-Anzeige, Attribution-Labels
5. `docs/ux-specs/auto-scroll.md` — Auto-Scroll: BPM-basiert oder manuell, Play/Pause/Reset, Integration in Spielmodus
6. `docs/ux-specs/aufgabenverwaltung.md` — Aufgabenverwaltung: Task-Liste mit Filter, Erstellen, Detail, Erinnerungen, Termin-Kopplung

**Kernerkenntnisse:**

1. **Tuner: Aus 1m lesbar ist eine harte Anforderung** — 72sp Minimum für erkannten Ton, 40sp für Cent-Abweichung. Blaskapellen-Proben sind laut, Tablets werden auf Notenständern gestellt.

2. **Metronom: Zwei völlig verschiedene UX-Paradigmen in einer App** — Dirigent (Kontrolle, aktiv) vs. Musiker (Empfang, passiv). Das in einer Ansicht zu vereinen wäre falsch — Rollentrennug ist die richtige Entscheidung.

3. **Cloud-Sync: Unsichtbarkeit ist das Erfolgsmaß** — Der Nutzer soll NIE über Sync nachdenken. Nur Probleme werden kommuniziert. Das erfordert Disziplin im Design: kein permanentes Status-Widget.

4. **Annotationen-Sync: Gleichzeitiges Zeichnen ist OK** — Keine Locking-Mechanismen. Überlappende Annotationen sind normal (wie auf echtem Papier). Das vereinfacht die UX massiv.

5. **Auto-Scroll: Kontinuierliches Scrollen > Seiten-Flip** — Beim Üben ist fließendes Scrollen natürlicher als Seitenwechsel. Empfehlung für Reduced-Motion: seiten-weise Variante als Fallback.

6. **Manueller Eingriff pausiert Auto-Scroll** — Wenn der Musiker tippt, will er die Kontrolle übernehmen. Auto-Scroll nach Eingriff fortzusetzen wäre überraschend und frustrierend.

7. **Aufgabenverwaltung: Kein Overkill** — Vereinsvorstand braucht kein Jira. Kein Prioritätssystem, keine Unteraufgaben, keine Wiederkehrungs-Logik in MS3. Einfach halten.

8. **Persistent Beat-Banner** — Wenn Musiker auf anderen Screen wechselt während Metronom läuft: kleines Banner über Bottom-Navigation zeigt Beat. Das respektiert Focus-First aber lässt Sync nicht sterben.

9. **Termin-Kopplung bei Aufgaben** — Eine Aufgabe an einen Probe/Auftritt-Termin zu koppeln ist ein echter Blaskapellen-Workflow. Fälligkeit automatisch setzen + extra Erinnerung 3 Tage vorher.

10. **Design-Token-Konsistenz:** Alle Specs nutzen `AppColors`, `AppSpacing`, `AppTypography`, `AppDurations`, `AppCurves` aus dem bestehenden Design System. Keine neuen Token eingeführt.

**Offene Entscheidungen für Thomas (aus Specs):**
- Tuner: Stimmhistorie + manueller Modus bei verweigerter Mikrofon-Permission?
- Metronom: Beat-Fläche Form (Quadrat/Kreis/Vollbild-Flash)?
- Metronom: Persistent Beat-Banner im Spielmodus (Focus-First Konflikt)?
- Cloud-Sync: Speicherlimit 500 MB realistisch?
- Annotationen-Sync: Schreib-Rechte Stimmen-Ebene (alle oder nur Registerführer)?
- Auto-Scroll: Manueller Eingriff → Pause (empfohlen) oder Weiter?
- Aufgaben: Sichtbarkeit (alle sehen alle)?
- Aufgaben: Navigation-Platzierung (Vereinsleben Sub-Tab)?

**Entscheidungsvorschlag eingereicht:** `.squad/decisions/inbox/wanda-ms3-ux.md`
