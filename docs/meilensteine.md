# Meilensteinplanung — Notenmanagement-App

> Version: 1.0  
> Status: Entwurf  
> Autor: Stark (Lead / Architect)  
> Datum: 2026-03-28  
> Referenz: docs/spezifikation.md

---

## Grundsätze

1. **Jeder Meilenstein ist ein vollständiges, deploybares Produkt** mit echtem Endnutzer-Mehrwert.
2. **Inkrementelle Wertlieferung:** Nutzer können nach jedem Meilenstein produktiv arbeiten.
3. **Testing und UX-Validierung** sind Teil jedes Meilensteins, nicht nachgelagert.
4. **Keine Feature-Flags oder halbe Features:** Was ausgeliefert wird, funktioniert vollständig.

---

## Übersicht

| Meilenstein | Titel | Kern-Mehrwert |
|:-----------:|-------|---------------|
| **M1** | Kern — Noten & Kapelle | Noten importieren, anzeigen und spielen. Kapelle gründen, Mitglieder einladen, Stimmen zuweisen. |
| **M2** | Organisation | Setlists erstellen, Konzerte planen, Termine verwalten, Schichten organisieren. |
| **M3** | Erweiterte Tools | Stimmgerät, Echtzeit-Metronom, Cloud-Sync für persönliche Sammlung. |
| **M4** | Lehre | Lehrer-/Schüler-System, Lernpfade, Content-Freischaltung. |
| **M5** | Verfeinerung | Mehrsprachigkeit, erweiterte AI-Features, Performance-Optimierung. |

---

## M1 — Kern: Noten & Kapelle

### Mehrwert für den Endnutzer

> "Ich kann meine Noten digital auf mein Gerät bringen, meine Kapelle anlegen und im Fokus-Modus spielen — ohne Ablenkung."

### Scope

#### Notenverwaltung
- **F1.1** Zentrale Notenablage (Kapelle + persönlich)
- **F1.2** Noten-Upload & Labeling (Bilder, PDFs, Kamera)
- **F1.3** AI-basierte Metadaten-Erkennung (Grundversion: Titel, Stimme)
- **F1.4** AI-Lizenzierung (pro User und pro Kapelle)
- **F1.5** Stimmenauswahl & Instrument-Profil (Standard-Stimme, Fallback)
- **F1.6** Berechtigungen für Noteneinpflege

#### Spielmodus
- **F2.1** Fokus-Modus (Vollbild, ablenkungsfrei, Seitenwechsel per Swipe/Tap)
- **F2.2** Auto-Rotation (Notenlinien-Erkennung)
- **F2.3** Auto-Zoom (Notenbereich erkennen, optimal skalieren)
- **F2.4** Annotationen & Markierungen (alle drei Sichtbarkeitsebenen)

#### Kapellenverwaltung
- **F3.1** Kapelle erstellen & verwalten
- **F3.2** Multi-Kapellen-Zugehörigkeit (Wechsler)
- **F3.3** Rollen & Mitgliederverwaltung (Admin, Dirigent, Notenwart, Registerführer, Musiker)

#### Persönliche Sammlung
- **F6.1** Eigene Notensammlung (lokale Speicherung, gleiche Mechanismen)

#### Infrastruktur
- Benutzer-Registrierung & Login (E-Mail + Passwort, JWT)
- Responsive UI (Mobile, Tablet, Desktop)
- Touch-Support (Swipe, Pinch-to-Zoom, Stift-Support)
- Offline-Fähigkeit: Noten ansehen & Annotationen (lokal)
- i18n-Architektur (alle Strings externalisiert, Deutsch als Sprache)
- Basis-Sicherheit (TLS, verschlüsselte API-Keys, RBAC)

### Deliverables

- [ ] Deploybare Web-App
- [ ] Mobile App (iOS + Android) oder PWA mit Touch-Support
- [ ] API-Server (v1) mit Authentifizierung
- [ ] AI-Service-Integration (mindestens 1 Provider: Azure Vision)
- [ ] Datenbankschema Version 1
- [ ] Grundlegende CI/CD-Pipeline
- [ ] Onboarding-Flow für neue Nutzer und Kapellen

### Abhängigkeiten

- Keine externen Abhängigkeiten (erster Meilenstein)
- AI-Provider-Evaluation muss abgeschlossen sein (Azure Vision als Minimum)
- UX-Design für Fokus-Modus und Upload-Flow muss vorliegen

### Testing & UX-Validierung

- [ ] Unit-Tests: ≥80% Coverage für Business-Logik
- [ ] Integration-Tests: Upload-Flow, Labeling, Stimmauswahl
- [ ] E2E-Tests: Registrierung → Kapelle erstellen → Noten hochladen → Fokus-Modus
- [ ] UX-Test: Musiker testet kompletten Flow auf Tablet (Touch-Optimierung)
- [ ] UX-Test: Upload von 20+ Seiten mit Labeling (Performance, Usability)
- [ ] UX-Test: Fokus-Modus im Probenszenario (Ablenkungsfreiheit, Seitenwechsel)
- [ ] Accessibility-Check: Basis-WCAG 2.1 AA
- [ ] Performance-Test: Seitenwechsel <100ms, App-Start <3s

### Definition of Done

- [ ] Alle oben genannten Features sind implementiert und getestet
- [ ] App ist auf Web, iOS und Android deployt und nutzbar
- [ ] Code Review durch 3 Reviewer (Claude Sonnet 4.6, Claude Opus 4.6, GPT 5.4) + Lead-Review
- [ ] Keine kritischen oder hohen Bugs offen
- [ ] Dokumentation: API-Docs, Setup-Anleitung
- [ ] DSGVO-Grundlagen: Datenschutzerklärung, Account-Löschung
- [ ] Mindestens 3 Musiker haben den kompletten Flow getestet und Feedback gegeben

---

## M2 — Organisation: Setlists, Termine & Vereinsleben

### Mehrwert für den Endnutzer

> "Ich kann Setlists für Konzerte zusammenstellen, Termine verwalten und Schichten auf Festen organisieren — alles in einer App."

### Scope

#### Setlist-Verwaltung
- **F4.1** Setlist erstellen, bearbeiten, Stücke sortieren (Drag & Drop)
- Setlist im Spielmodus: automatischer Übergang zum nächsten Stück
- Setlist mit Termin/Konzert verknüpfen
- Setlist duplizieren

#### Konzertplanung
- **F5.1** Konzert anlegen (Datum, Ort, Setlist)
- Zu-/Absage-Funktion für Musiker
- Teilnehmerübersicht (nach Registern)
- Push-Benachrichtigungen

#### Feste & Schichtplanung
- **F5.2** Feste anlegen, Schichten definieren
- Musiker tragen sich für Schichten ein
- Schichttausch
- Übersicht besetzt/offen

#### Terminplanung
- **F5.3** Kalenderansicht (Monat/Woche/Agenda)
- Termine filtern nach Kapelle und Typ
- iCal-Export
- Zu-/Absage für alle Termintypen

### Deliverables

- [ ] Setlist-Modul (UI + API)
- [ ] Konzertplanungs-Modul (UI + API)
- [ ] Fest- und Schichtplanungs-Modul (UI + API)
- [ ] Kalender-Modul mit Filterung und Export
- [ ] Push-Notification-System (Firebase/APNs)
- [ ] Aktualisierte API-Dokumentation

### Abhängigkeiten

- M1 muss abgeschlossen sein (Kapellen, Mitglieder, Rollen, Noten)
- Push-Notification-Infrastruktur muss eingerichtet werden

### Testing & UX-Validierung

- [ ] Unit-Tests: Setlist-Logik, Termin-Verwaltung, Schicht-Zuteilung
- [ ] Integration-Tests: Setlist → Spielmodus-Übergang, Zu-/Absage-Flow
- [ ] E2E-Tests: Konzert anlegen → Setlist zuordnen → Musiker sagt zu → Konzert spielen
- [ ] UX-Test: Dirigent erstellt Setlist auf Tablet (Drag & Drop, Touch)
- [ ] UX-Test: Musiker nutzt Kalender und sagt für Termine zu/ab
- [ ] UX-Test: Schichtplanung auf Mobilgerät
- [ ] Performance-Test: Kalender mit 100+ Terminen

### Definition of Done

- [ ] Alle Features implementiert und getestet
- [ ] Code Review (3 Reviewer + Lead)
- [ ] Setlist-Spielmodus funktioniert nahtlos
- [ ] Push-Benachrichtigungen funktionieren auf iOS und Android
- [ ] Keine kritischen oder hohen Bugs offen
- [ ] Mindestens 1 Kapelle hat den Organisations-Flow getestet

---

## M3 — Erweiterte Tools: Tuner, Metronom & Cloud-Sync

### Mehrwert für den Endnutzer

> "Ich kann mein Instrument in der App stimmen, im Probenraum hat jeder den gleichen Klick, und meine persönlichen Noten sind auf allen Geräten synchron."

### Scope

#### Stimmgerät (Tuner)
- **F7.1** Chromatische Tonerkennung über Mikrofon
- Anzeige: Ton, Abweichung in Cent, visuelles Feedback
- Kammerton einstellbar (430–450 Hz)
- Transposition für verschiedene Instrumente
- Funktioniert offline

#### Echtzeit-Klick / Metronom
- **F7.2** Tempo- und Taktart-Einstellung
- Visuelles und akustisches Metronom
- Synchronisation über lokales Netzwerk (WiFi UDP)
- Fallback: WebSocket über Internet
- Clock-Synchronisation (NTP-ähnlich)
- Dirigent als Controller (Start/Stop/Tempo)

#### Cloud-Storage-Synchronisation
- **F6.2** OneDrive-Integration (OAuth2)
- Dropbox-Integration (OAuth2)
- Bidirektionale Sync, Konfliktbehandlung
- Sync-Status pro Datei

### Deliverables

- [ ] Tuner-Modul (Audio-Processing, UI)
- [ ] Metronom-Modul (lokales Metronom)
- [ ] Echtzeit-Sync-Server (UDP + WebSocket)
- [ ] Clock-Synchronisations-Protokoll
- [ ] Cloud-Storage-Integration (OneDrive + Dropbox)
- [ ] Sync-Status-UI und Konflikt-Handling

### Abhängigkeiten

- M1 muss abgeschlossen sein (persönliche Sammlung für Cloud-Sync)
- Audio-Processing-Libraries evaluiert und ausgewählt
- Echtzeit-Server-Infrastruktur aufgebaut
- OneDrive und Dropbox Developer-Accounts eingerichtet

### Testing & UX-Validierung

- [ ] Unit-Tests: Tonerkennungsalgorithmus, Clock-Sync-Logik
- [ ] Integration-Tests: Cloud-Sync mit echten Diensten (Sandbox-Accounts)
- [ ] E2E-Tests: Tuner starten → Ton spielen → Ergebnis korrekt
- [ ] E2E-Tests: Metronom starten → 2+ Geräte synchron
- [ ] UX-Test: Tuner im echten Probenraum-Szenario (Hintergrundgeräusche)
- [ ] UX-Test: Metronom mit 5+ Musikern synchron (Latenz-Empfinden)
- [ ] UX-Test: Cloud-Sync einrichten und Noten zwischen 2 Geräten synchronisieren
- [ ] Performance-Test: Metronom-Latenz <20ms über WiFi
- [ ] Performance-Test: Tuner-Latenz <100ms

### Definition of Done

- [ ] Tuner funktioniert zuverlässig für alle gängigen Blasinstrumente
- [ ] Metronom ist auf ≥5 Geräten im selben Netzwerk synchron (<20ms Abweichung)
- [ ] Cloud-Sync funktioniert bidirektional mit OneDrive und Dropbox
- [ ] Code Review (3 Reviewer + Lead)
- [ ] Keine kritischen oder hohen Bugs offen
- [ ] Tuner und Metronom in realer Probenumgebung getestet

---

## M4 — Lehre: Lehrer, Schüler & Lernpfade

### Mehrwert für den Endnutzer

> "Als Musiklehrer kann ich meinen Schülern gezielt Noten freischalten und strukturierte Lernpfade erstellen. Schüler arbeiten Stück für Stück durch."

### Scope

#### Lehrer-/Schüler-Rollen
- **F8.1** Rolle "Lehrer" mit Schüler-Verwaltung
- Rolle "Schüler" mit eingeschränktem Zugriff
- Noten pro Schüler freischalten/sperren
- Schüler sieht nur freigeschaltete Inhalte

#### Lernpfade
- **F8.2** Lernpfad erstellen (geordnete Stücke/Übungen)
- Stufenweise Freischaltung (sequenziell oder manuell)
- Fortschrittsanzeige für Schüler
- Lehrer kann Fortschritt einsehen
- Lernpfade duplizieren und anpassen

### Deliverables

- [ ] Lehrer-Dashboard (Schüler-Übersicht, Freischaltung)
- [ ] Schüler-Ansicht (freigeschaltete Stücke, Lernpfade)
- [ ] Lernpfad-Editor (Drag & Drop Stücke sortieren)
- [ ] Fortschrittstracking (UI + API)
- [ ] Rollen-Erweiterung im Berechtigungssystem
- [ ] Dokumentation des Lehre-Moduls

### Abhängigkeiten

- M1 muss abgeschlossen sein (Noten, Rollen, Berechtigungen)
- Detaillierte Spezifikation des Lehre-Moduls von Thomas (ausstehend)
- UX-Design für Lehrer- und Schüler-Flows

### Testing & UX-Validierung

- [ ] Unit-Tests: Freischaltungslogik, Lernpfad-Progression
- [ ] Integration-Tests: Lehrer schaltet frei → Schüler sieht Stück
- [ ] E2E-Tests: Lernpfad erstellen → Schüler zuweisen → Fortschritt tracken
- [ ] UX-Test: Lehrer erstellt Lernpfad und verwaltet 5+ Schüler
- [ ] UX-Test: Schüler arbeitet Lernpfad auf Tablet durch
- [ ] Berechtigungs-Test: Schüler kann keine nicht-freigeschalteten Inhalte sehen

### Definition of Done

- [ ] Lehrer können Schüler verwalten, Noten freischalten und Lernpfade erstellen
- [ ] Schüler sehen nur freigeschaltete Inhalte und können Fortschritt tracken
- [ ] Code Review (3 Reviewer + Lead)
- [ ] Keine kritischen oder hohen Bugs offen
- [ ] Mindestens 1 Lehrer-Schüler-Paar hat den kompletten Flow getestet

---

## M5 — Verfeinerung: i18n, AI-Erweiterung & Performance

### Mehrwert für den Endnutzer

> "Die App ist schneller, unterstützt weitere Sprachen, und die AI-Erkennung ist noch zuverlässiger."

### Scope

#### Mehrsprachigkeit
- Englisch als zweite Sprache
- Sprachauswahl in den Einstellungen
- Alle UI-Texte übersetzt

#### Erweiterte AI-Features
- Weitere AI-Provider unterstützen (Google Vision, OpenAI GPT-4V)
- Verbesserte Metadaten-Erkennung (Tonart, Tempo, Genre)
- AI-Konfidenz-Schwellwerte konfigurierbar
- Batch-Verarbeitung für große Uploads

#### Performance-Optimierung
- Bild-Komprimierung und Caching optimieren
- Lazy Loading für Noten-Galerie
- Offline-Cache-Strategie verfeinern
- App-Start-Optimierung
- Memory-Management für große Notensammlungen

#### Zusätzliche Features
- Social Login (Google, Apple)
- 2FA für Administratoren (TOTP)
- Datenexport (DSGVO)
- Erweiterte Suche (Volltextsuche über Metadaten)
- Nutzungsstatistiken für Administratoren

### Deliverables

- [ ] Englische Übersetzung aller UI-Texte
- [ ] Sprachauswahl-UI
- [ ] Weitere AI-Provider-Adapter
- [ ] Performance-Optimierungen (messbar)
- [ ] Social Login Integration
- [ ] 2FA-Modul
- [ ] Datenexport-Funktion
- [ ] Erweiterte Suchfunktion

### Abhängigkeiten

- M1–M4 müssen abgeschlossen sein
- Übersetzungen müssen erstellt werden
- Performance-Baseline muss gemessen sein (vor Optimierung)

### Testing & UX-Validierung

- [ ] Unit-Tests: Sprachumschaltung, neue AI-Provider, Datenexport
- [ ] Integration-Tests: Social Login, 2FA-Flow
- [ ] E2E-Tests: App komplett auf Englisch durchspielen
- [ ] Performance-Tests: Vorher/Nachher-Vergleich (App-Start, Seitenwechsel, Upload)
- [ ] UX-Test: Englischsprachiger Nutzer testet kompletten Flow
- [ ] Security-Audit: 2FA, Social Login, Datenexport
- [ ] Last-Test: 200+ gleichzeitige Nutzer

### Definition of Done

- [ ] App vollständig auf Deutsch und Englisch nutzbar
- [ ] Mindestens 2 AI-Provider unterstützt
- [ ] Performance-Ziele erreicht (Seitenwechsel <100ms, App-Start <3s)
- [ ] Social Login und 2FA funktionieren
- [ ] Datenexport DSGVO-konform
- [ ] Code Review (3 Reviewer + Lead)
- [ ] Keine kritischen oder hohen Bugs offen
- [ ] Security-Audit bestanden

---

## Risiken & Mitigationsstrategien

| Risiko | Auswirkung | Mitigation |
|--------|-----------|------------|
| AI-Erkennung unzuverlässig für Notenblätter | Manueller Aufwand steigt | Mehrere Provider evaluieren; manuelle Eingabe immer als Fallback |
| Metronom-Latenz zu hoch für musikalische Zwecke | Feature nicht nutzbar | WiFi UDP als primären Kanal; frühzeitig mit echten Musikern testen |
| Cloud-Sync-Konflikte bei Annotationen | Datenverlust möglich | Merge-Strategie statt Last-Write-Wins für Annotationen |
| Touch-Performance auf älteren Geräten | UX leidet | Frühzeitig auf Zielgeräten testen; Performance-Budget definieren |
| Lehre-Modul: Spezifikation unklar | Verzögerung M4 | Frühzeitig mit Thomas klären; M4 kann unabhängig von M2/M3 starten |
| Urheberrecht bei Noten | Rechtliches Risiko | Klarer Haftungsausschluss; keine öffentliche Sharing-Funktion |

---

## Zeitplanung

> Zeitschätzungen hängen von Team-Größe und Verfügbarkeit ab. Die folgende Reihenfolge ist verbindlich.

```
M1 ─────────────▶ M2 ─────────────▶ M3 ─────────────▶ M4 ──────▶ M5
Kern               Organisation       Erweiterte Tools   Lehre      Verfeinerung
                                                         │
                                                         └── Kann parallel zu M3
                                                              starten (unabhängig)
```

**Parallelisierbarkeit:**
- M1 → M2 → M3: Strikt sequenziell (Abhängigkeiten)
- M4: Kann nach M1 parallel zu M2/M3 gestartet werden (benötigt nur Kern-Features)
- M5: Beginnt nach M4, kann aber einzelne Optimierungen bereits ab M2 einstreuen

---

*Diese Planung wird fortlaufend angepasst. Änderungen werden dokumentiert und mit dem Team abgestimmt.*
