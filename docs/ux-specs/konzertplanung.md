# UX-Spec: Konzertplanung + Kalender — Sheetstorm

> **Issue:** TBD — [UX] Konzertplanung + Kalender — UX-Flows und Wireframes  
> **Version:** 1.0  
> **Status:** Implementation-ready  
> **Autorin:** Wanda (UX Designer)  
> **Datum:** 2026-03-28  
> **Meilenstein:** M2 — Vereinsleben & Aufführung  
> **Referenzen:** `docs/feature-specs/konzertplanung-spec.md`, `docs/ux-design.md §3.6`, `docs/ux-konfiguration.md`, `docs/ux-specs/setlist.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Konzept](#1-übersicht--konzept)
2. [User Flow: Termin erstellen](#2-user-flow-termin-erstellen)
3. [Kalender-Ansichten](#3-kalender-ansichten)
4. [Termin-Details](#4-termin-details)
5. [Zu-/Absage-Flow](#5-zu-absage-flow)
6. [Ersatzmusiker-Vorschlag](#6-ersatzmusiker-vorschlag)
7. [Push-Benachrichtigungen](#7-push-benachrichtigungen)
8. [Kalender-Sync-Settings](#8-kalender-sync-settings)
9. [Responsive Verhalten](#9-responsive-verhalten)
10. [Navigation & Routing](#10-navigation--routing)
11. [Interaction Patterns](#11-interaction-patterns)
12. [Error States & Leerzustände](#12-error-states--leerzustände)
13. [Accessibility](#13-accessibility)
14. [Wireframes: Phone](#14-wireframes-phone)
15. [Wireframes: Tablet/Desktop](#15-wireframes-tabletdesktop)
16. [Abhängigkeiten](#16-abhängigkeiten)

---

## 1. Übersicht & Konzept

### 1.1 Das Kernproblem

Ein Dirigent plant Proben und Konzerte. Musiker sagen zu oder ab. Bei Absagen muss schnell Ersatz gefunden werden — aber wer spielt dasselbe Instrument und ist verfügbar?

**Status Quo (ohne Sheetstorm):**
- Termine per WhatsApp-Gruppe
- Zusagen in Excel-Spreadsheet
- Ersatzmusiker-Suche per Telefon
- Jeder Musiker pflegt eigenen Kalender manuell
- Keine Übersicht: Wer ist dabei?

**Sheetstorm-Lösung:**
- Termine digital erstellen + teilen
- 1-Tap Zu-/Absage für Musiker
- Intelligenter Ersatzmusiker-Vorschlag bei Absagen
- Automatische Kalender-Sync (Google/Apple/Outlook)
- Echtzeit-Übersicht: Wer ist dabei?

### 1.2 Kern-Use-Cases

| Persona | Situation | Ziel |
|---------|-----------|------|
| Dirigent | 2 Wochen vor Konzert | Termin erstellen, Setlist verknüpfen, Zusagen überwachen |
| Musiker | Termine checken | Termine sehen, zu-/absagen, Vorbereitung planen |
| Dirigent | Musiker sagt ab | Ersatzmusiker finden und anfragen |
| Musiker | Reminder | Rechtzeitig erinnert werden, keine Termine verpassen |
| Admin | Verwaltung | Übersicht über Anwesenheitsstatistiken (MS3) |

### 1.3 Design-Prinzipien

| Prinzip | Konkrete Auswirkung |
|---------|---------------------|
| **1-Tap Zusage** | Kein Formular — nur Button "Zusagen" |
| **Progressive Disclosure** | Begründung bei Absage optional, nicht forced |
| **Real-Time Feedback** | Zusage-Status sofort sichtbar für alle |
| **Intelligent Defaults** | Ersatzmusiker-Vorschlag automatisch, nicht manuell suchen |
| **Accessibility** | Kalender-Ansichten für Screen Reader optimiert |

### 1.4 Alleinstellungsmerkmale

**Gegenüber Wettbewerber:**
- **Intelligente Ersatzmusiker-Vorschläge** (basierend auf Instrument + Verfügbarkeit)
- **Bidirektionale Kalender-Sync** (nicht nur Export, sondern auch Rücksynchronisation)
- **Setlist-Verknüpfung** (Musiker sehen beim Zusagen, welche Stücke gespielt werden)

---

## 2. User Flow: Termin erstellen

```
Kalender-Tab → [+ Neuer Termin]
        │
        ▼
Formular (Modal/Sheet):
  - Titel* (Pflicht, 1–100 Zeichen)
  - Typ* (Probe | Konzert | Auftritt | Ausflug | Sonstiges)
  - Datum* (Pflicht, Datepicker)
  - Startzeit* (Pflicht, HH:MM)
  - Endzeit (optional, HH:MM)
  - Ort (optional, max. 200 Zeichen)
  - Setlist (optional, Dropdown)
  - Beschreibung (optional, max. 1000 Zeichen)
  - Treffpunkt (optional, falls abweichend vom Ort)
  - Kleiderordnung (optional, z.B. "Tracht", "Uniform")
  - Zusage-Frist (optional, Datum)
  - Wiederholen (optional, "Wöchentlich für 12 Wochen")
        │
        ▼
[Erstellen] → API-Call
        │
        ▼
Termin erstellt
Push-Benachrichtigung an alle aktiven Mitglieder
        │
        ▼
Zurück zur Kalender-Ansicht
Toast: "Termin erstellt. Alle Mitglieder wurden benachrichtigt."
```

### 2.1 Formular-Validierung

| Feld | Validierung | Fehlerfall |
|------|-------------|------------|
| Titel | 1–100 Zeichen, nicht leer | "Titel darf nicht leer sein" |
| Typ | Auswahl aus 5 Optionen | Immer gültig (Radio/Dropdown) |
| Datum | ISO 8601 Date, Pflicht | Warnung wenn in Vergangenheit |
| Startzeit | HH:MM, Pflicht | "Bitte Startzeit eingeben" |
| Endzeit | HH:MM, optional | Fehler wenn vor Startzeit |
| Setlist | Dropdown aus Setlists | Optional, kann leer sein |

### 2.2 Wiederkehrende Termine

```
[■ Wöchentlich wiederholen]   ← Toggle

Wenn aktiviert:
Anzahl Wochen: [12_] (Standard: 12 Wochen)

Erstellt automatisch:
- Termin am 3. April 2026, 19:00
- Termin am 10. April 2026, 19:00
- Termin am 17. April 2026, 19:00
- ... (12 Wochen)

Toast: "12 Termine erstellt (wöchentlich bis Juni 2026)"
```

### 2.3 Berechtigungen

| Rolle | Darf Termine erstellen? |
|-------|------------------------|
| Dirigent | ✅ |
| Admin | ✅ |
| Notenwart | ❌ (nur anzeigen) |
| Musiker | ❌ (nur anzeigen) |

---

## 3. Kalender-Ansichten

### 3.1 Drei Ansichten

| Ansicht | Use-Case | Interaktion |
|---------|----------|-------------|
| **Monatsansicht** | Überblick über mehrere Wochen | Tap auf Tag → Termin-Liste für diesen Tag |
| **Wochenansicht** | Detaillierte Wochenplanung | Tap auf Termin → Detail-Ansicht |
| **Listenansicht** | Chronologische Durchsicht | Scroll + Tap → Detail-Ansicht |

### 3.2 Ansicht wechseln

```
PHONE:
┌─────────────────────────────────┐
│ [Monat] [Woche] [Liste]   [+]  │  ← Segment-Control + Neuer Termin
├─────────────────────────────────┤
│        April 2026               │  ← Aktuelle Ansicht
│  Mo Di Mi Do Fr Sa So           │
│  ...                            │
└─────────────────────────────────┘
```

### 3.3 Monatsansicht (Phone)

```
┌─────────────────────────────────┐
│ [Monat] [Woche] [Liste]   [+]  │
├─────────────────────────────────┤
│ ← [April 2026] →      [Heute]  │  ← Navigation + Heute-Button
├─────────────────────────────────┤
│  Mo  Di  Mi  Do  Fr  Sa  So    │
│  ──  ──  ──  ──  01  02  03    │
│  04  05  06  07  08  09  10    │
│  11  12 [13] 14  15  16  17    │  ← Heute highlighted
│  18  19  20  21  22  23  24    │
│  25  26  27  28  29  30  ──    │
├─────────────────────────────────┤
│  Termine am 13. April:          │  ← Termin-Liste für gewählten Tag
│                                 │
│  🎼 19:00 Probe                 │  ← Typ-Icon + Zeit + Titel
│     ✓ Zugesagt                  │    Status
│                                 │
│  🎵 20:00 Frühjahrskonzert      │
│     ○ Offen                     │
│                                 │
└─────────────────────────────────┘
```

**Termin-Badges:**
```
Tag mit Terminen:
┌────┐
│ 13 │  ← Zahl
│ ●● │  ← Dots (max. 3, Farbe = Termin-Typ)
└────┘

Tag ohne Termine:
┌────┐
│ 14 │
│    │
└────┘

Heute:
┌────┐
│[13]│  ← Blauer Rahmen
│ ●● │
└────┘
```

**Typ-Farben:**
- 🎼 Probe = Blau (#1A56DB)
- 🎵 Konzert = Rot (#DC2626)
- 🎺 Auftritt = Orange (#D97706)
- 🎉 Sonstiges = Grau (#6B7280)

### 3.4 Wochenansicht (Phone, Hochformat)

```
┌─────────────────────────────────┐
│ [Monat] [Woche] [Liste]   [+]  │
├─────────────────────────────────┤
│ ← [KW 15 • Apr 2026] →   [Heute]│
├─────────────────────────────────┤
│       Mo Di Mi Do Fr Sa So      │
│       08 09 10 11 12 13 14      │
├─────────────────────────────────┤
│ 18:00 │  │  │🎼│  │  │  │      │  ← Timeline
│ 19:00 │  │  │Pr│  │🎵│  │      │    Termine als Blöcke
│ 20:00 │  │  │  │  │Ko│  │      │
│ 21:00 │  │  │  │  │  │  │      │
├─────────────────────────────────┤
│  🎼 Probe (Do, 19:00)           │  ← Termin-Details unterhalb
│     ✓ Zugesagt                  │
│                                 │
│  🎵 Frühjahrskonzert (Fr, 20:00)│
│     ○ Offen                     │
└─────────────────────────────────┘
```

**Wochenansicht (Tablet, Querformat):**
```
TABLET (1024×768, Landscape):
┌─────────────────────────────────────────────────────────────┐
│ [Monat] [Woche] [Liste]                        [+ Termin]  │
├─────────────────────────────────────────────────────────────┤
│ ← [KW 15 • April 2026] →                         [Heute]   │
├──────┬──────┬──────┬──────┬──────┬──────┬──────────────────┤
│      │ Mo 8 │ Di 9 │Mi 10 │Do 11 │Fr 12 │ Sa 13 │ So 14   │
├──────┼──────┼──────┼──────┼──────┼──────┼───────┼─────────┤
│ 18:00│      │      │      │      │      │       │         │
│ 19:00│      │      │ 🎼   │      │ 🎵   │       │         │
│ 20:00│      │      │Probe │      │Konz. │       │         │
│ 21:00│      │      │      │      │      │       │         │
└──────┴──────┴──────┴──────┴──────┴──────┴───────┴─────────┘
```

### 3.5 Listenansicht (Phone)

```
┌─────────────────────────────────┐
│ [Monat] [Woche] [Liste]   [+]  │
├─────────────────────────────────┤
│ 🔍 [Suche...] [Filter ▼]       │
├─────────────────────────────────┤
│                                 │
│ APRIL 2026                      │
│ ─────────────────────────────── │
│                                 │
│ Do, 3. April • 19:00            │
│ 🎼 Probe                        │  ← Typ-Icon + Titel
│ ✓ Zugesagt                      │    Status-Badge
│                                 │
│ Fr, 10. April • 20:00           │
│ 🎵 Frühjahrskonzert             │
│ ○ Offen                         │
│                                 │
│ Do, 17. April • 19:00           │
│ 🎼 Probe                        │
│ ✓ Zugesagt                      │
│                                 │
│ MAI 2026                        │
│ ─────────────────────────────── │
│                                 │
│ Sa, 15. Mai • 20:00             │
│ 🎵 Maikonzert                   │
│ ? Unsicher                      │
│                                 │
│ ...                             │
│                                 │
└─────────────────────────────────┘
```

**Status-Badges:**
- ✓ Zugesagt (grün)
- ✗ Abgesagt (rot)
- ? Unsicher (orange)
- ○ Offen (grau)

### 3.6 Filter (Listenansicht)

```
[Filter ▼] → öffnet Dropdown

┌─────────────────────────────┐
│ Filtern                     │
├─────────────────────────────┤
│ KAPELLE                     │
│ ✓ Musikkapelle Beispiel     │
│   Jugendkapelle Beispiel    │
│ ─────────────────────────── │
│ TYP                         │
│ ✓ Alle                      │
│   Probe                     │
│   Konzert                   │
│   Auftritt                  │
│   Sonstiges                 │
│ ─────────────────────────── │
│ STATUS                      │
│ ✓ Alle                      │
│   Zugesagt                  │
│   Abgesagt                  │
│   Offen                     │
│   Unsicher                  │
│ ─────────────────────────── │
│ [Zurücksetzen] [Anwenden]  │
└─────────────────────────────┘
```

---

## 4. Termin-Details

### 4.1 Termin-Detail-Ansicht (Phone)

```
┌─────────────────────────────────┐
│ ← Kalender    🎵 Konzert   ⋮   │  ← Zurück + Typ + Mehr-Menü
├─────────────────────────────────┤
│                                 │
│ Frühjahrskonzert 2026           │  ← Titel (große Schrift)
│ Sa, 15. Mai 2026 • 20:00 Uhr   │  ← Datum + Zeit
│                                 │
├─────────────────────────────────┤
│ DEINE ZUSAGE                    │
│ ─────────────────────────────── │
│  [✓ Zusagen]  [✗ Absagen]      │  ← Große Buttons
│  [? Vielleicht]                 │    (aktuell: ○ Offen)
│                                 │
├─────────────────────────────────┤
│ DETAILS                         │
│ ─────────────────────────────── │
│ 📍 Ort: Stadthalle Beispiel     │
│ 🎵 Setlist: Frühjahrskonzert    │  ← Tap öffnet Setlist-Detail
│ 👕 Kleiderordnung: Tracht       │
│ 📝 Treffpunkt: 19:30 am Eingang │
│ ⏰ Zusage bis: 8. Mai 2026      │
│                                 │
│ Beschreibung:                   │
│ Traditionelles Konzert im       │
│ Festzelt. Bitte pünktlich!      │
│                                 │
├─────────────────────────────────┤
│ ANWESENHEIT                     │  ← Nur für Musiker
│ ─────────────────────────────── │
│ 23 zugesagt • 2 abgesagt • 3 offen│
│                                 │
│ [→ Details anzeigen]            │  ← Nur für Dirigent/Admin
│                                 │
├─────────────────────────────────┤
│ SETLIST (12 Stücke)             │  ← Falls Setlist verknüpft
│ ─────────────────────────────── │
│  1. Böhmischer Traum            │  ← Tap öffnet Noten
│  2. Alte Kameraden              │
│  3. Auf der Vogelwiese          │
│  ... (+ 9 weitere)              │
│                                 │
│ [→ Komplette Setlist anzeigen] │
│                                 │
└─────────────────────────────────┘
```

### 4.2 Anwesenheitsliste (Dirigent/Admin)

```
Tap auf [→ Details anzeigen]

┌─────────────────────────────────┐
│ ← Zurück    Anwesenheit         │
├─────────────────────────────────┤
│ Frühjahrskonzert 2026           │
│ 23 zugesagt • 2 abgesagt • 3 offen│
├─────────────────────────────────┤
│ [Alle] [Zugesagt] [Abgesagt]   │  ← Filter-Tabs
│ [Offen] [Unsicher]              │
├─────────────────────────────────┤
│                                 │
│ ZUGESAGT (23)                   │
│ ─────────────────────────────── │
│ ✓ Anna Müller                   │  ← Avatar + Name + Status
│   2. Klarinette                 │    Instrument
│                                 │
│ ✓ Max Meier                     │
│   1. Trompete                   │
│                                 │
│ ✓ Lisa Schmidt                  │
│   Querflöte                     │
│                                 │
│ ... (20 weitere)                │
│                                 │
│ ABGESAGT (2)                    │
│ ─────────────────────────────── │
│ ✗ Tom Wagner                    │
│   Tenorhorn • Urlaub            │  ← Begründung angezeigt
│   [Ersatz finden]               │  ← Direkt-Action
│                                 │
│ ✗ Julia Becker                  │
│   Schlagzeug • Krank            │
│   [Ersatz finden]               │
│                                 │
│ OFFEN (3)                       │
│ ─────────────────────────────── │
│ ○ Peter Klein                   │
│   Tuba                          │
│                                 │
│ ○ Sarah Lang                    │
│   Fagott                        │
│                                 │
│ ○ Lukas Groß                    │
│   Horn                          │
│                                 │
└─────────────────────────────────┘
```

---

## 5. Zu-/Absage-Flow

### 5.1 Zusage (1-Tap)

```
Termin-Detail → [✓ Zusagen]
        │
        ▼
API-Call (POST /termine/{id}/zusagen)
        │
        ▼ Success
        ▼
Button wechselt zu "Zugesagt ✓" (grün, disabled)
Toast: "Zusage für '[Termin]' gespeichert"
        │
        ▼
Push-Benachrichtigung an Dirigent/Admin
(zusammengefasst alle 30 Minuten)
```

### 5.2 Absage (mit optionaler Begründung)

```
Termin-Detail → [✗ Absagen]
        │
        ▼
Bottom-Sheet öffnet sich:

┌─────────────────────────────────┐
│ Absagen                    ✕   │
├─────────────────────────────────┤
│ Möchtest du für diesen Termin   │
│ absagen?                        │
│                                 │
│ Begründung (optional):          │
│ [Urlaub_____________________]  │
│ (max. 200 Zeichen)              │
│                                 │
│ 💡 Tipp: Eine Begründung hilft  │
│ dem Dirigenten bei der Planung. │
│                                 │
│ [Abbrechen]  [Absagen ✓]       │
└─────────────────────────────────┘
        │
        ▼
API-Call (POST /termine/{id}/absagen)
        │
        ▼ Success
        ▼
Button wechselt zu "Abgesagt ✗" (rot, disabled)
Toast: "Absage für '[Termin]' gespeichert"
        │
        ▼
Push-Benachrichtigung an Dirigent/Admin
Ersatzmusiker-Vorschlag erscheint (§6)
```

### 5.3 Vielleicht (Unsicher)

```
Termin-Detail → [? Vielleicht]
        │
        ▼
API-Call (POST /termine/{id}/unsicher)
        │
        ▼ Success
        ▼
Button wechselt zu "Unsicher ?" (orange, disabled)
Toast: "Status auf 'Vielleicht' gesetzt"
        │
        ▼
Hinweis-Toast (4 Sekunden):
┌────────────────────────────────┐
│ ℹ️ Bitte spätestens 1 Woche   │
│ vor Termin endgültig zu-/absagen│
└────────────────────────────────┘
```

### 5.4 Status ändern

```
Aktueller Status: Zugesagt
        │
        ▼ Tap [✗ Absagen]
        ▼
Bestätigung:
┌─────────────────────────────────┐
│ Zusage zurückziehen?            │
├─────────────────────────────────┤
│ Du hast bereits zugesagt.       │
│ Möchtest du deine Zusage        │
│ zurückziehen?                   │
│                                 │
│ [Abbrechen]  [Zusage ändern]   │
└─────────────────────────────────┘
        │ Tap [Zusage ändern]
        ▼
Absage-Flow wie in §5.2
```

### 5.5 Kurzfristige Absage (< 2 Stunden vor Termin)

```
Termin beginnt in 1 Stunde
        │
        ▼ Tap [✗ Absagen]
        ▼
Warnung:
┌─────────────────────────────────┐
│ ⚠️ Kurzfristige Absage          │
├─────────────────────────────────┤
│ Der Termin beginnt in 1 Stunde! │
│                                 │
│ Bitte kontaktiere den Dirigenten│
│ direkt per Telefon.             │
│                                 │
│ Trotzdem absagen?               │
│                                 │
│ [Abbrechen]  [Absagen ✓]       │
└─────────────────────────────────┘
```

---

## 6. Ersatzmusiker-Vorschlag

### 6.1 Konzept

Wenn ein Musiker absagt, analysiert das System automatisch:
1. Instrument/Stimme des abgesagten Musikers
2. Alle anderen Musiker mit gleichem oder kompatiblem Instrument
3. Verfügbarkeit (Status für diesen Termin)
4. Letzte Aktivität mit der Kapelle

**Ausgabe:** Liste von max. 5 Ersatzmusikern, sortiert nach Match-Score.

### 6.2 Ersatzmusiker-Vorschlag (Dirigent/Admin)

```
Tom Wagner (Tenorhorn) sagt ab
        │
        ▼
Benachrichtigung an Dirigent:
"Tom Wagner hat für Frühjahrskonzert abgesagt (Urlaub)"
        │
        ▼
Anwesenheitsliste → Tap auf Tom Wagner
        │
        ▼
Bottom-Sheet öffnet sich:

┌─────────────────────────────────┐
│ Ersatzmusiker finden       ✕   │
├─────────────────────────────────┤
│ Tom Wagner (Tenorhorn) hat      │
│ für Frühjahrskonzert abgesagt.  │
│                                 │
│ Ersatzmusiker vorgeschlagen:    │
│ ─────────────────────────────── │
│                                 │
│ 🎺 Markus Bauer                 │  ← Match-Score: 100 (exakt)
│    Tenorhorn • 2. Stimme        │    Instrument + Stimme
│    Status: ○ Offen              │    Status für diesen Termin
│    Letzter Auftritt: vor 2 Wochen│   Aktivität
│    [Anfragen ✉️]                │    Direkt-Action
│                                 │
│ 🎺 Stefan Keller                │  ← Match-Score: 75 (kompatibel)
│    Euphonium • 1. Stimme        │    (Gleiches Register)
│    Status: ○ Offen              │
│    Letzter Auftritt: vor 1 Monat│
│    [Anfragen ✉️]                │
│                                 │
│ 🎺 Julia Richter                │  ← Match-Score: 50 (Fallback)
│    Posaune • 1. Stimme          │    (Blechbläser)
│    Status: ? Unsicher           │
│    Letzter Auftritt: vor 3 Monaten│
│    [Anfragen ✉️]                │
│                                 │
│ ℹ️ Kein passender Ersatz?      │
│ [Externe Aushilfe suchen →]    │
│                                 │
└─────────────────────────────────┘
```

### 6.3 Anfrage senden

```
Tap auf [Anfragen ✉️] bei Markus Bauer
        │
        ▼
Bestätigung:
┌─────────────────────────────────┐
│ Anfrage senden?                 │
├─────────────────────────────────┤
│ Markus Bauer wird per Push-     │
│ Benachrichtigung gefragt, ob er │
│ als Ersatz für Tom Wagner       │
│ (Tenorhorn) einspringen kann.   │
│                                 │
│ Nachricht:                      │
│ „Tom hat abgesagt (Urlaub).     │
│ Kannst du als Ersatz einspringen?│
│ (Tenorhorn • 2. Stimme)"        │
│                                 │
│ [Abbrechen]  [Anfragen ✓]      │
└─────────────────────────────────┘
        │
        ▼
Push-Benachrichtigung an Markus Bauer:
"🎺 Ersatzmusiker-Anfrage für Frühjahrskonzert (15. Mai)"
        │
        ▼
Markus öffnet Benachrichtigung
→ Termin-Detail öffnet sich
→ Kann direkt zu-/absagen
```

### 6.4 Matching-Algorithmus (vereinfacht)

```
Score-Berechnung:
─────────────────
IF Instrument == exakt gleich: Score += 100
IF Stimme == exakt gleich: Score += 50
IF Register == gleich: Score += 25
IF Status == "Offen": Score += 30
IF Status == "Unsicher": Score += 15
IF letzter_auftritt < 30 Tage: Score += 10
IF hat_konflikt_mit_anderem_termin: Score -= 100

Sortierung: Score DESC
Ausgabe: Top 5
```

### 6.5 Konflikte (Musiker hat anderen Termin)

```
Ersatzmusiker-Liste:

🎺 Markus Bauer
   Tenorhorn • 2. Stimme
   Status: ⚠️ Konflikt mit „Probe (15. Mai)"
   [Trotzdem anfragen]               ← Disabled oder mit Warnung
```

---

## 7. Push-Benachrichtigungen

### 7.1 Benachrichtigungs-Typen

| Typ | Trigger | Zeitpunkt | Zusammenfassung |
|-----|---------|-----------|----------------|
| **Neuer Termin** | Dirigent erstellt Termin | Sofort | Nein (sofort an alle) |
| **Termin-Erinnerung** | 7 Tage vor Termin | 09:00 Uhr | Nein |
| **Zusage-Erinnerung** | Frist läuft ab | 09:00 Uhr am Fristdatum | Nein |
| **Zusage-Update** | Musiker sagt zu/ab | Alle 30 Minuten | Ja (an Dirigent/Admin) |
| **Ersatzmusiker-Anfrage** | Dirigent sendet Anfrage | Sofort | Nein |
| **Termin-Änderung** | Dirigent ändert Termin | Sofort | Nein |
| **1-Stunde-Erinnerung** | 1 Stunde vor Termin | 1h vorher | Nein (nur Zugesagt) |

### 7.2 Benachrichtigungs-Inhalte

**Neuer Termin:**
```
🎵 Neuer Termin: Frühjahrskonzert
Sa, 15. Mai 2026 • 20:00 Uhr
→ Jetzt zusagen
```

**7-Tage-Erinnerung:**
```
📅 Erinnerung: Frühjahrskonzert in 1 Woche
Sa, 15. Mai 2026 • 20:00 Uhr
Bitte zusagen!
```

**Zusage-Frist:**
```
⏰ Zusage-Frist läuft ab: Frühjahrskonzert
Bitte bis heute zusagen.
```

**Zusage-Update (an Dirigent):**
```
✓ 3 neue Zusagen für Frühjahrskonzert
Anna Müller, Max Meier, Lisa Schmidt
```

**Ersatzmusiker-Anfrage:**
```
🎺 Ersatzmusiker-Anfrage für Frühjahrskonzert
Tom hat abgesagt. Kannst du einspringen? (Tenorhorn)
→ Zusagen oder absagen
```

**Termin-Änderung:**
```
📝 Termin geändert: Frühjahrskonzert
Neue Zeit: 19:30 Uhr (vorher 20:00 Uhr)
```

**1-Stunde-Erinnerung:**
```
⏰ In 1 Stunde: Frühjahrskonzert
Stadthalle Beispiel • 20:00 Uhr
```

### 7.3 Benachrichtigungs-Einstellungen

```
Einstellungen → Nutzer → Benachrichtigungen

┌─────────────────────────────────┐
│ Benachrichtigungen              │
├─────────────────────────────────┤
│                                 │
│ TERMINE                         │
│ ─────────────────────────────── │
│ [■] Neue Termine                │
│ [■] Termin-Erinnerungen         │
│ [■] Termin-Änderungen           │
│ [■] Zusage-Fristen              │
│ [■] 1-Stunde-Erinnerung         │
│                                 │
│ ERSATZMUSIKER                   │
│ ─────────────────────────────── │
│ [■] Ersatzmusiker-Anfragen      │
│                                 │
│ PRO KAPELLE                     │
│ ─────────────────────────────── │
│ 🏛 Musikkapelle Beispiel        │
│    [■] Alle Benachrichtigungen  │
│                                 │
│ 🏛 Jugendkapelle Beispiel       │
│    [  ] Alle Benachrichtigungen │  ← Deaktiviert
│                                 │
└─────────────────────────────────┘
```

---

## 8. Kalender-Sync-Settings

### 8.1 Konzept

Bidirektionale Synchronisation mit externen Kalendern:
- **Sheetstorm → Externer Kalender:** Neue/geänderte Termine werden synchronisiert
- **Externer Kalender → Sheetstorm:** Änderungen am Termin-Titel/Zeit/Ort werden zurück übertragen

### 8.2 Kalender-Sync einrichten

```
Einstellungen → Nutzer → Kalender-Synchronisation

┌─────────────────────────────────┐
│ Kalender-Synchronisation        │
├─────────────────────────────────┤
│                                 │
│ ANBIETER                        │
│ ─────────────────────────────── │
│ [+ Google Calendar]             │
│ [+ Apple Calendar (iCloud)]     │
│ [+ Outlook (Microsoft 365)]     │
│                                 │
│ VERBUNDENE KALENDER             │
│ ─────────────────────────────── │
│ (leer — noch keine Verbindungen)│
│                                 │
│ ℹ️ Synchronisiere Sheetstorm-  │
│ Termine automatisch mit deinem  │
│ persönlichen Kalender.          │
│                                 │
└─────────────────────────────────┘
```

### 8.3 Google Calendar verbinden

```
Tap auf [+ Google Calendar]
        │
        ▼
OAuth2-Flow (Weiterleitung zu Google):
"Sheetstorm möchte auf deinen Google Calendar zugreifen"
        │
        ▼ Berechtigung erteilen
        ▼
Zurück zu Sheetstorm:
┌─────────────────────────────────┐
│ Google Calendar verbunden ✓     │
├─────────────────────────────────┤
│ E-Mail: musiker@example.com     │
│ Status: ✅ Aktiv                │
│ Letzte Sync: vor 2 Minuten      │
│                                 │
│ KALENDER-ABOS (1)               │
│ ─────────────────────────────── │
│ 🏛 Musikkapelle Beispiel        │
│    [■] Synchronisieren          │
│    Farbe: [🔵 Blau]             │
│                                 │
│ [Verbindung trennen]            │
└─────────────────────────────────┘
```

### 8.4 Mehrere Kapellen (separate Kalender-Abos)

```
VERBUNDENE KALENDER
─────────────────────────────────

🏛 Musikkapelle Beispiel
   Google Calendar • ✅ Aktiv
   [■] Synchronisieren
   Farbe: [🔵 Blau]

🏛 Jugendkapelle Beispiel
   Google Calendar • ✅ Aktiv
   [■] Synchronisieren
   Farbe: [🟢 Grün]
```

**Externer Kalender:**
```
Musiker mit 2 Kapellen sieht:

Google Calendar:
├── Sheetstorm — Musikkapelle Beispiel (blau)
│   ├── Probe (3. April)
│   ├── Frühjahrskonzert (15. Mai)
│   └── ...
└── Sheetstorm — Jugendkapelle Beispiel (grün)
    ├── Probe (5. April)
    ├── Sommerkonzert (1. Juli)
    └── ...
```

### 8.5 Kalender-Eintrag-Format

```
Titel: [Kapellenname] — [Termin-Titel]
Beispiel: "Musikkapelle Beispiel — Frühjahrskonzert"

Beschreibung:
─────────────
Frühjahrskonzert
Sa, 15. Mai 2026 • 20:00 Uhr
Stadthalle Beispiel

Setlist: Frühjahrskonzert 2026
→ 12 Stücke (Böhmischer Traum, Alte Kameraden, ...)

Kleiderordnung: Tracht

Deine Zusage: Zugesagt ✓

→ In Sheetstorm öffnen: sheetstorm://termine/550e8400-e29b...

Ort: Stadthalle Beispiel

Erinnerung: 1 Stunde vorher

Zusage-Status: Accepted (Google Calendar Response)
```

### 8.6 Sync-Status & Fehlerbehandlung

```
Einstellungen → Kalender-Synchronisation

┌─────────────────────────────────┐
│ Google Calendar                 │
│ ✅ Aktiv                        │
│ Letzte Sync: vor 2 Minuten      │
│                                 │
│ [Jetzt synchronisieren]         │
└─────────────────────────────────┘

FEHLERFALL:
┌─────────────────────────────────┐
│ Google Calendar                 │
│ ⚠️ Synchronisation fehlgeschlagen│
│ Letzte Sync: vor 3 Tagen        │
│                                 │
│ Fehler: OAuth-Token abgelaufen  │
│                                 │
│ [Berechtigung erneuern]         │
└─────────────────────────────────┘
```

---

## 9. Responsive Verhalten

### 9.1 Breakpoints

| Viewport | Layout-Anpassungen |
|----------|-------------------|
| **Phone (< 600px)** | Single-Column, Bottom-Buttons, Monatsansicht = Compact Grid |
| **Tablet (600–1024px)** | Wochenansicht = Timeline-Grid, Two-Column Termin-Details |
| **Desktop (> 1024px)** | Sidebar-Navigation, Wochenansicht = Full-Width-Grid |

### 9.2 Tablet — Wochenansicht (Querformat)

```
TABLET (1024×768, Landscape):
┌─────────────────────────────────────────────────────────────┐
│ [Monat] [Woche] [Liste]                        [+ Termin]  │
├─────────────────────────────────────────────────────────────┤
│ ← [KW 15 • April 2026] →                         [Heute]   │
├──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────────┤
│      │ Mo 8 │ Di 9 │Mi 10 │Do 11 │Fr 12 │Sa 13 │ So 14    │
├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────────┤
│ 18:00│      │      │      │      │      │      │          │
│ 19:00│      │      │ 🎼   │      │ 🎵   │      │          │
│ 20:00│      │      │Probe │      │Konz. │      │          │
│ 21:00│      │      │      │      │      │      │          │
└──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────────┘
```

### 9.3 Desktop — Kalender mit Sidebar

```
DESKTOP (1440×900):
┌────────┬──────────────────────────────────────────────────┐
│ SIDE   │ [Monat] [Woche] [Liste]          [+ Neuer Termin]│
│ BAR    ├──────────────────────────────────────────────────┤
│        │ ← [April 2026] →                       [Heute]   │
│ 📚 Bib ├──────────────────────────────────────────────────┤
│ 🎵 Set │  Mo  Di  Mi  Do  Fr  Sa  So                     │
│ 📅 Kal │  ──  ──  01  02  03  04  05                     │
│ 👤 Pro │  06  07  08  09 [10] 11  12    ← Heute          │
│        │  13  14  15  16  17  18  19                     │
│        │  20  21  22  23  24  25  26                     │
│        │  27  28  29  30  ──  ──  ──                     │
│        ├──────────────────────────────────────────────────┤
│        │ Termine am 10. April:                            │
│        │                                                  │
│        │ 🎼 19:00 Probe                                   │
│        │    Musikkapelle Beispiel                         │
│        │    ✓ Zugesagt                                    │
│        │    [Details]                                     │
│        │                                                  │
│        │ 🎵 20:00 Frühjahrskonzert                        │
│        │    Musikkapelle Beispiel                         │
│        │    ○ Offen                                       │
│        │    [Details]                                     │
│        │                                                  │
└────────┴──────────────────────────────────────────────────┘
```

---

## 10. Navigation & Routing

### 10.1 URL-Schema

```
/kalender                         → Kalender-Übersicht (Monatsansicht)
/kalender/woche                   → Wochenansicht
/kalender/liste                   → Listenansicht
/kalender/termine/{id}            → Termin-Detail
/kalender/termine/new             → Neuer Termin erstellen
/kalender/termine/{id}/edit       → Termin bearbeiten
/kalender/einstellungen/sync      → Kalender-Sync-Einstellungen
```

### 10.2 Bottom-Navigation (Phone)

```
┌─────────────────────────────────┐
│ [📚 Bibl.][🎵 Setl.][📅 Kal.][👤]│  ← Kalender-Tab = 3. Position
└─────────────────────────────────┘
```

### 10.3 Deep-Links

```
sheetstorm://kalender                    → Öffnet Kalender-Übersicht
sheetstorm://termine/{id}                → Öffnet Termin-Detail
sheetstorm://termine/{id}/zusagen        → Öffnet Termin + Zusage-Dialog
sheetstorm://kalender/sync               → Öffnet Kalender-Sync-Settings
```

---

## 11. Interaction Patterns

### 11.1 Quick-Actions (Long-Press)

```
Long-Press auf Termin (in Liste oder Kalender)
        │
        ▼
Context-Menu (Bottom Sheet):
┌─────────────────────────────┐
│ Frühjahrskonzert            │
├─────────────────────────────┤
│ ✓ Zusagen                   │
│ ✗ Absagen                   │
│ 📝 Details anzeigen         │
│ 🎵 Setlist öffnen           │
│ 📍 Ort in Karten öffnen     │  ← Öffnet Google Maps/Apple Maps
│ 📅 Zu Kalender hinzufügen   │  ← Falls Sync deaktiviert
│ ✕ Abbrechen                 │
└─────────────────────────────┘
```

### 11.2 Swipe-Geste (Listenansicht, iOS/Android)

```
Swipe right auf Termin:
┌─────────────────────────────┐
│ [✓] Frühjahrskonzert        │  ← Zusage-Action erscheint
└─────────────────────────────┘

Swipe left auf Termin:
┌─────────────────────────────┐
│ Frühjahrskonzert       [✗]  │  ← Absage-Action erscheint
└─────────────────────────────┘
```

### 11.3 Pull-to-Refresh

```
Pull-Down in Kalender-Ansicht oder Liste
        │
        ▼
Spinner erscheint
API-Call: Neue Termine laden
        │
        ▼ Success
        ▼
Spinner verschwindet
Toast: "Kalender aktualisiert" (nur bei neuen Terminen)
```

---

## 12. Error States & Leerzustände

### 12.1 Leerzustände

| Kontext | Leerzustand |
|---------|-------------|
| Kalender (keine Termine) | "Noch keine Termine geplant. [+ Ersten Termin erstellen]" |
| Listenansicht (Filter = 0 Treffer) | "Keine Termine gefunden. [Filter zurücksetzen]" |
| Anwesenheitsliste (niemand zugesagt) | "Noch keine Zusagen." |
| Ersatzmusiker (keine Vorschläge) | "Keine Ersatzmusiker verfügbar. [Externe Aushilfe suchen]" |
| Kalender-Sync (keine Verbindungen) | "Noch keine Kalender verbunden. [+ Kalender verbinden]" |

### 12.2 Error States

| Fehler | Anzeige | Recovery |
|--------|---------|----------|
| Titel leer | "Titel darf nicht leer sein" (unter Input) | Input fokussieren |
| Endzeit vor Startzeit | "Endzeit muss nach Startzeit liegen" | Input korrigieren |
| Zusage fehlgeschlagen | Toast: "Zusage konnte nicht gespeichert werden. [Wiederholen]" | Retry-Button |
| Kalender-Sync fehlgeschlagen | "Synchronisation fehlgeschlagen. [Berechtigung erneuern]" | OAuth-Flow neu starten |
| Termin gelöscht | "Dieser Termin existiert nicht mehr" → Zurück zur Übersicht | — |
| Offline | Toast: "Offline. Änderungen werden synchronisiert, sobald Verbindung besteht." | Auto-Sync |

### 12.3 Offline-Verhalten

```
Keine Internetverbindung:
┌────────────────────────────────┐
│ ⚠️ Offline                     │
│ Termine werden angezeigt, aber │
│ Zusagen/Absagen erst online    │
│ synchronisiert.                │
└────────────────────────────────┘
```

**Offline-Fähigkeit:**
- Kalender-Anzeige funktioniert (gecachte Daten)
- Zusagen/Absagen lokal gespeichert
- Sync bei Verbindung (mit Conflict-Resolution)

---

## 13. Accessibility

### 13.1 Keyboard-Navigation

| Kontext | Keyboard-Shortcuts |
|---------|-------------------|
| Kalender-Übersicht | Tab: Fokus auf Tage, Enter: Tag öffnen, ←/→/↑/↓: Navigation |
| Termin-Detail | Tab: Fokus auf Buttons, Enter: Zusagen/Absagen |
| Anwesenheitsliste | Tab: Fokus auf Einträge, Enter: Details |
| Ersatzmusiker-Vorschlag | Tab: Fokus auf Einträge, Enter: Anfragen |

### 13.2 Screen Reader

**Semantisches HTML:**
- `<nav>` für Kalender-Navigation
- `<main>` für Kalender-Ansicht
- `<article>` für Termin-Kacheln
- `<button>` statt `<div>` für Aktionen

**Aria-Labels:**
```html
<button aria-label="Für Termin 'Frühjahrskonzert' am 15. Mai 2026 zusagen">
  ✓ Zusagen
</button>

<div role="listitem" aria-label="Termin: Frühjahrskonzert, Samstag 15. Mai 2026, 20:00 Uhr, Status: Offen">
  ...
</div>
```

### 13.3 Touch-Targets

| Element | Mindestgröße |
|---------|-------------|
| Zusagen/Absagen-Buttons | 48×48 px |
| Kalender-Tage (tappable) | 44×44 px |
| Termin-Kacheln (Liste) | Min. 64 px Höhe |
| Ersatzmusiker-Einträge | Min. 64 px Höhe |

### 13.4 Kontrast

| Kontext | Kontrast-Ratio |
|---------|---------------|
| Text auf Hintergrund | ≥ 4.5:1 (WCAG AA) |
| Typ-Icons (farbig) | ≥ 3:1 + zusätzlich durch Icon unterscheidbar |
| Status-Badges | ≥ 4.5:1 (Text in Badge) |
| Disabled Buttons | 2:1 (erkennbar als disabled) |

---

## 14. Wireframes: Phone

### 14.1 Phone — Kalender-Übersicht (Monatsansicht)

```
┌─────────────────────────────────┐
│ [Monat] [Woche] [Liste]   [+]  │
├─────────────────────────────────┤
│ ← [April 2026] →      [Heute]  │
├─────────────────────────────────┤
│  Mo  Di  Mi  Do  Fr  Sa  So    │
│  ──  ──  ──  ──  01  02  03    │
│  04  05  06  07  08  09  10    │
│  11  12 [13] 14  15  16  17    │  ← Heute
│  18  19  20  21  22  23  24    │
│  25  26  27  28  29  30  ──    │
├─────────────────────────────────┤
│  Termine am 13. April:          │
│                                 │
│  🎼 19:00 Probe                 │
│     ✓ Zugesagt                  │
│                                 │
│  🎵 20:00 Frühjahrskonzert      │
│     ○ Offen                     │
│                                 │
└─────────────────────────────────┘
│ [📚][🎵][📅][👤]  ← Bottom-Nav  │
└─────────────────────────────────┘
```

### 14.2 Phone — Termin erstellen

```
┌─────────────────────────────────┐
│ ← Abbrechen   Neuer Termin      │
├─────────────────────────────────┤
│                                 │
│ Titel*                          │
│ [Frühjahrskonzert__________]   │
│                                 │
│ Typ*                            │
│ ● Konzert  ○ Probe  ○ Auftritt │
│ ○ Ausflug  ○ Sonstiges         │
│                                 │
│ Datum*                          │
│ [15.05.2026_]  📅             │
│                                 │
│ Startzeit*          Endzeit     │
│ [20:00_]  ⏰      [22:00_]  ⏰ │
│                                 │
│ Ort                             │
│ [Stadthalle Beispiel_______]   │
│                                 │
│ Setlist                         │
│ [Frühjahrskonzert 2026   ▼]   │
│                                 │
│ [▼ Mehr Optionen]               │  ← Expandable
│                                 │
│ [Erstellen ✓]                  │
└─────────────────────────────────┘
```

### 14.3 Phone — Termin-Detail

```
┌─────────────────────────────────┐
│ ← Kalender    🎵 Konzert   ⋮   │
├─────────────────────────────────┤
│                                 │
│ Frühjahrskonzert 2026           │
│ Sa, 15. Mai 2026 • 20:00 Uhr   │
│                                 │
├─────────────────────────────────┤
│ DEINE ZUSAGE                    │
│ ─────────────────────────────── │
│  [✓ Zusagen]  [✗ Absagen]      │
│  [? Vielleicht]                 │
│                                 │
├─────────────────────────────────┤
│ DETAILS                         │
│ ─────────────────────────────── │
│ 📍 Ort: Stadthalle Beispiel     │
│ 🎵 Setlist: Frühjahrskonzert    │
│ 👕 Kleiderordnung: Tracht       │
│ ⏰ Zusage bis: 8. Mai 2026      │
│                                 │
├─────────────────────────────────┤
│ ANWESENHEIT                     │
│ ─────────────────────────────── │
│ 23 zugesagt • 2 abgesagt • 3 offen│
│ [→ Details anzeigen]            │
│                                 │
├─────────────────────────────────┤
│ SETLIST (12 Stücke)             │
│ ─────────────────────────────── │
│  1. Böhmischer Traum            │
│  2. Alte Kameraden              │
│  3. Auf der Vogelwiese          │
│  ... (+ 9 weitere)              │
│                                 │
│ [→ Komplette Setlist anzeigen] │
│                                 │
└─────────────────────────────────┘
```

### 14.4 Phone — Absage-Dialog

```
┌─────────────────────────────────┐
│ Absagen                    ✕   │
├─────────────────────────────────┤
│ Möchtest du für diesen Termin   │
│ absagen?                        │
│                                 │
│ Begründung (optional):          │
│ [Urlaub_____________________]  │
│ (max. 200 Zeichen)              │
│                                 │
│ 💡 Tipp: Eine Begründung hilft  │
│ dem Dirigenten bei der Planung. │
│                                 │
│ [Abbrechen]  [Absagen ✓]       │
└─────────────────────────────────┘
```

### 14.5 Phone — Anwesenheitsliste (Dirigent)

```
┌─────────────────────────────────┐
│ ← Zurück    Anwesenheit         │
├─────────────────────────────────┤
│ Frühjahrskonzert 2026           │
│ 23 zugesagt • 2 abgesagt • 3 offen│
├─────────────────────────────────┤
│ [Alle] [Zugesagt] [Abgesagt]   │
│ [Offen] [Unsicher]              │
├─────────────────────────────────┤
│                                 │
│ ZUGESAGT (23)                   │
│ ─────────────────────────────── │
│ ✓ Anna Müller                   │
│   2. Klarinette                 │
│                                 │
│ ✓ Max Meier                     │
│   1. Trompete                   │
│                                 │
│ ... (21 weitere)                │
│                                 │
│ ABGESAGT (2)                    │
│ ─────────────────────────────── │
│ ✗ Tom Wagner                    │
│   Tenorhorn • Urlaub            │
│   [Ersatz finden]               │
│                                 │
│ ✗ Julia Becker                  │
│   Schlagzeug • Krank            │
│   [Ersatz finden]               │
│                                 │
│ OFFEN (3)                       │
│ ─────────────────────────────── │
│ ○ Peter Klein • Tuba            │
│ ○ Sarah Lang • Fagott           │
│ ○ Lukas Groß • Horn             │
│                                 │
└─────────────────────────────────┘
```

### 14.6 Phone — Ersatzmusiker-Vorschlag

```
┌─────────────────────────────────┐
│ Ersatzmusiker finden       ✕   │
├─────────────────────────────────┤
│ Tom Wagner (Tenorhorn) hat      │
│ für Frühjahrskonzert abgesagt.  │
│                                 │
│ Ersatzmusiker vorgeschlagen:    │
│ ─────────────────────────────── │
│                                 │
│ 🎺 Markus Bauer                 │
│    Tenorhorn • 2. Stimme        │
│    Status: ○ Offen              │
│    Letzter Auftritt: vor 2 Wochen│
│    [Anfragen ✉️]                │
│                                 │
│ 🎺 Stefan Keller                │
│    Euphonium • 1. Stimme        │
│    Status: ○ Offen              │
│    Letzter Auftritt: vor 1 Monat│
│    [Anfragen ✉️]                │
│                                 │
│ 🎺 Julia Richter                │
│    Posaune • 1. Stimme          │
│    Status: ? Unsicher           │
│    Letzter Auftritt: vor 3 Monaten│
│    [Anfragen ✉️]                │
│                                 │
│ ℹ️ Kein passender Ersatz?      │
│ [Externe Aushilfe suchen →]    │
│                                 │
└─────────────────────────────────┘
```

### 14.7 Phone — Kalender-Sync-Settings

```
┌─────────────────────────────────┐
│ ← Einstellungen                 │
│ Kalender-Synchronisation        │
├─────────────────────────────────┤
│                                 │
│ ANBIETER                        │
│ ─────────────────────────────── │
│ [+ Google Calendar]             │
│ [+ Apple Calendar (iCloud)]     │
│ [+ Outlook (Microsoft 365)]     │
│                                 │
│ VERBUNDENE KALENDER             │
│ ─────────────────────────────── │
│                                 │
│ Google Calendar                 │
│ ✅ Aktiv • musiker@example.com  │
│ Letzte Sync: vor 2 Minuten      │
│                                 │
│ 🏛 Musikkapelle Beispiel        │
│    [■] Synchronisieren          │
│    Farbe: [🔵 Blau]             │
│                                 │
│ 🏛 Jugendkapelle Beispiel       │
│    [  ] Synchronisieren         │
│    Farbe: [🟢 Grün]             │
│                                 │
│ [Verbindung trennen]            │
│                                 │
└─────────────────────────────────┘
```

---

## 15. Wireframes: Tablet/Desktop

### 15.1 Tablet — Wochenansicht (Querformat)

```
TABLET (1024×768, Landscape):
┌─────────────────────────────────────────────────────────────┐
│ [Monat] [Woche] [Liste]                        [+ Termin]  │
├─────────────────────────────────────────────────────────────┤
│ ← [KW 15 • April 2026] →                         [Heute]   │
├──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────────┤
│ Zeit │ Mo 8 │ Di 9 │Mi 10 │Do 11 │Fr 12 │Sa 13 │ So 14    │
├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────────┤
│ 18:00│      │      │      │      │      │      │          │
│ 19:00│      │      │ 🎼   │      │ 🎵   │      │          │
│ 20:00│      │      │Probe │      │Konz. │      │          │
│ 21:00│      │      │      │      │      │      │          │
└──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────────┘
```

### 15.2 Desktop — Kalender mit Termin-Detail (Split-View)

```
DESKTOP (1440×900):
┌────────┬──────────────────────┬──────────────────────────┐
│ NAV    │ KALENDER             │ TERMIN-DETAIL            │
│        │                      │                          │
│ 📚 Bib │ [Monat][Woche][Liste]│ 🎵 Frühjahrskonzert      │
│ 🎵 Set │                      │ Sa, 15. Mai • 20:00 Uhr  │
│ 📅 Kal │ ← [April 2026] →     │                          │
│ 👤 Pro │  Mo Di Mi Do Fr Sa So│ DEINE ZUSAGE             │
│        │  ── ── ── ── 01 02 03│ [✓ Zusagen][✗ Absagen]  │
│        │  04 05 06 07 08 09 10│                          │
│        │  11 12 13 14 15 16 17│ DETAILS                  │
│        │  18 19 20 21 22 23 24│ 📍 Stadthalle Beispiel   │
│        │  25 26 27 28 29 30 ──│ 🎵 Setlist: Frühj...     │
│        │                      │ 👕 Kleiderordnung: Tracht│
│        │ Termine am 13. April:│                          │
│        │ 🎼 19:00 Probe       │ ANWESENHEIT              │
│        │    ✓ Zugesagt        │ 23 zu • 2 ab • 3 offen   │
│        │ 🎵 20:00 Frühjahrs...│ [Details]                │
│        │    ○ Offen           │                          │
│        │                      │ SETLIST (12 Stücke)      │
│        │                      │ 1. Böhmischer Traum      │
│        │                      │ 2. Alte Kameraden        │
│        │                      │ ... (+ 10 weitere)       │
└────────┴──────────────────────┴──────────────────────────┘
```

---

## 16. Abhängigkeiten

### 16.1 MS1-Features (vorhanden)

- Kapellenverwaltung (Mitglieder, Rollen, Berechtigungen)
- Push-Notification-Infrastruktur (FCM/APNs)

### 16.2 MS2-Features (parallel entwickelt)

- Setlist-Verwaltung (Termin ↔ Setlist-Verknüpfung)

### 16.3 Backend-Abhängigkeiten

- `/api/v1/termine` — CRUD-Endpoints
- `/api/v1/termine/{id}/zusagen` — Zu-/Absage-Endpoints
- `/api/v1/termine/{id}/ersatzmusiker` — Ersatzmusiker-Vorschlag
- `/api/v1/kalender-sync` — OAuth2-Flow + Sync-Logic

### 16.4 Frontend-Abhängigkeiten

- Datepicker (für Datum/Zeit-Auswahl)
- Kalender-Grid-Component (Monats-/Wochenansicht)
- OAuth2-Library (für Google/Apple/Outlook-Verbindung)

### 16.5 Externe Dienste

- **Google Calendar API v3** (OAuth2, REST)
- **Microsoft Graph API** (OAuth2, REST)
- **Apple iCloud CalDAV** (CalDAV-Protokoll)
- **Firebase Cloud Messaging** (Push-Benachrichtigungen Android)
- **Apple Push Notification Service** (Push-Benachrichtigungen iOS)

---

**Ende der UX-Spec: Konzertplanung + Kalender**
