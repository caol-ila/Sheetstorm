# UX-Spec: Kapellenverwaltung — Sheetstorm

> **Issue:** #14
> **Version:** 1.0
> **Status:** Entwurf
> **Autorin:** Wanda (UX Designer)
> **Datum:** 2026-03-28
> **Meilenstein:** M1 — Kern: Noten & Kapelle
> **Referenzen:** `docs/ux-design.md`, `docs/anforderungen.md`, `docs/spezifikation.md`

---

## Inhaltsverzeichnis

1. [Übersicht & Design-Prinzipien](#1-übersicht--design-prinzipien)
2. [Flow A: Kapelle erstellen](#2-flow-a-kapelle-erstellen)
3. [Flow B: Mitgliederliste & Rollen](#3-flow-b-mitgliederliste--rollen)
4. [Flow C: Einladungen per Code/Link](#4-flow-c-einladungen-per-codelink)
5. [Flow D: Instrument-Register-Verwaltung](#5-flow-d-instrument-register-verwaltung)
6. [Flow E: Multi-Kapelle — Wechsel](#6-flow-e-multi-kapelle--wechsel)
7. [Wireframes: Phone](#7-wireframes-phone)
8. [Wireframes: Tablet](#8-wireframes-tablet)
9. [Abhängigkeiten für Hill (Frontend)](#9-abhängigkeiten-für-hill-frontend)

---

## 1. Übersicht & Design-Prinzipien

### Nutzer-Kontext

Die Kapellenverwaltung ist primär eine **Admin- und Notenwart-Aufgabe**. Sie wird am häufigsten vom Desktop/Browser aus genutzt — aber muss auch mobil funktionieren, wenn der Kapellmeister gerade vor Ort an der Probe ist.

**Primäre Personas:**
- **Notenwart** — lädt Noten hoch, verwaltet Stimmen-Register, vergibt Zugänge
- **Admin/Kapellmeister** — verwaltet Mitglieder, Rollen, Einladungen
- **Musiker** — schaut seine eigene Kapellenzugehörigkeit, wechselt zwischen Kapellen

### Leitfragen für jede Interaktion

1. Kann ein Kapellmeister das auf seinem Tablet erledigen, während er auf Probenbeginn wartet?
2. Ist klar, welche Aktion welche Reichweite hat (nur ich / alle Mitglieder / diese Kapelle)?
3. Ist Fehlerwiederherstellung möglich (Rollen-Vergabe zurücksetzen, Einladung widerrufen)?

### Rollenmodell

| Rolle | Abkürzung | Berechtigungen |
|-------|-----------|----------------|
| Admin | A | Alles: Kapelle löschen, alle Rollen verwalten, Einstellungen |
| Dirigent | D | Noten verwalten, Setlists, Probe-Planung, Mitglieder anzeigen |
| Notenwart | N | Noten hochladen, Stimmen zuweisen, Bibliothek verwalten |
| Registerführer | R | Mitglieder seines Registers verwalten, Anwesenheit |
| Musiker | M | Noten lesen (eigene Stimme), Zu-/Absage, eigenes Profil |

**Regel:** Eine Person kann mehrere Rollen haben (z.B. Notenwart + Musiker). Die höchste Rolle gewinnt bei Konflikten.

---

## 2. Flow A: Kapelle erstellen

### 2.1 Einstiegspunkte

- Erster App-Start nach Registrierung → Onboarding-Wizard → "Kapelle erstellen oder beitreten"
- Profil-Menü → "Neue Kapelle erstellen"
- Multi-Kapellen-Übersicht → `[+ Kapelle hinzufügen]`

### 2.2 Schritte (Progressive Disclosure: 3 Schritte)

```
Schritt 1/3        Schritt 2/3         Schritt 3/3
──────────         ──────────          ──────────
Name               Logo (optional)     Fertig
Beschreibung       Hochladen oder      → Direkt zur
(optional)         ein Emoji wählen    Mitgliederverwaltung
```

**Schritt 1: Name & Beschreibung**
- Name: Pflichtfeld, max. 60 Zeichen, Live-Validierung
- Ort/Region: Optional, max. 60 Zeichen (hilft bei Suche)
- Beschreibung: Optional, max. 300 Zeichen, Multiline-Textarea
- Vorwärts-Button erst aktiv wenn Name ≥ 2 Zeichen

**Schritt 2: Logo / Avatar**
- Optionen:
  1. Bild hochladen (Galerie oder Kamera)
  2. Aus Emoji wählen (Grid mit 40 Blasmusik-Emojis: 🎺🎷🥁🎻 etc.)
  3. Automatisch generierter Buchstaben-Avatar (Initialen, farbig)
- Bildupload: Zuschneiden mit Crop-UI (quadratisch), min. 200×200px empfohlen
- „Überspringen" immer sichtbar → Buchstaben-Avatar als Default

**Schritt 3: Bestätigung & Weiter**
- Preview-Karte der Kapelle
- Einladungsoptionen direkt zeigen: „Ersten Mitglieder einladen" (→ Flow C)
- Oder: „Später einladen" → Direkt in die leere Kapellenverwaltung

### 2.3 Fehlerbehandlung

| Fehler | Feedback |
|--------|---------|
| Name bereits vergeben | Inline-Fehler unter Feld: „Dieser Name ist bereits vergeben. Wähle einen anderen oder füge einen Ort hinzu." |
| Bild zu groß (>10 MB) | „Das Bild ist zu groß. Bitte wähle ein Bild unter 10 MB." |
| Offline | Toast: „Keine Verbindung. Deine Eingaben werden gespeichert und beim nächsten Verbindungsaufbau übertragen." |
| Netzwerkfehler beim Erstellen | Retry-Button, kein Datenverlust |

---

## 3. Flow B: Mitgliederliste & Rollen

### 3.1 Mitgliederliste-Screen

**Layout:** Suchleiste oben + gefilterte Liste + Filter-Chips für Rollen.

**Listeneinträge:**
- Avatar, Name, Hauptinstrument, Rolle(n) als Chips
- Tap auf Eintrag → Mitglieder-Detailansicht

**Filter-Chips (horizontal scroll):**
`Alle` · `Admin` · `Dirigent` · `Notenwart` · `Registerführer` · `Musiker` · `Ausstehend`

**Sortierung:** Standard nach Nachname A–Z, wechselbar zu Instrument, Beitrittsdatum

**Leer-Zustand (neue Kapelle):**
```
  🎺
  Noch keine Mitglieder

  Lade deine erste Kapelle ein und
  fangt gemeinsam an.

  [Mitglieder einladen]
```

### 3.2 Rolle zuweisen / bearbeiten

**Tap auf Mitglied → Bottom Sheet (Phone) / Sidebar-Panel (Tablet):**

```
┌─────────────────────────────┐
│  [Avatar]  Max Mustermann   │
│  Klarinette · Beigetreten   │
│  15. Jan 2026               │
│─────────────────────────────│
│  ROLLEN                     │
│  ☑ Musiker      (Standard)  │
│  ☐ Registerführer           │
│  ☐ Notenwart                │
│  ☐ Dirigent                 │
│  ☐ Admin                    │
│─────────────────────────────│
│  INSTRUMENTE                │
│  Klarinette (Haupt)    [✎]  │
│  + Weiteres Instrument      │
│─────────────────────────────│
│  [Aus Kapelle entfernen]    │  ← destructive, rot
└─────────────────────────────┘
```

**Rollen-Checkboxen:**
- Multi-Select (mehrere Rollen möglich)
- Mindestens 1 Rolle immer aktiv (kann nicht alle abwählen)
- Admin-Vergabe zeigt Bestätigungs-Dialog: „Du gibst Max Admin-Rechte. Er kann die Kapelle verwalten und Mitglieder hinzufügen/entfernen."
- Eigene Admin-Rolle entziehen: Warnung „Du verlierst deinen Admin-Zugang. Bitte stelle sicher, dass ein anderer Admin vorhanden ist."

**Entfernen:**
- Bestätigungs-Dialog: „Max Mustermann wird aus der Kapelle entfernt. Seine Annotationen bleiben erhalten. Er verliert Zugriff auf die Kapellennoten."
- Undo-Toast (10 Sekunden): „Max entfernt. [Rückgängig]"

### 3.3 Eigenes Profil in der Kapelle

- Jeder Musiker sieht sein Kapellen-Profil
- Kann Instrument und Stimmen-Präferenz ändern
- Kann Kapelle verlassen (nicht: sich selbst entfernen wenn letzter Admin)

---

## 4. Flow C: Einladungen per Code/Link

### 4.1 Einladungs-Typen

| Typ | Beschreibung | Ablauf |
|-----|-------------|--------|
| Einladungslink | URL, teilbar via WhatsApp etc. | Klick → App öffnet, Registrierung oder Login, Kapelle beigetreten |
| Einladungscode | 6-stelliger alphanumerischer Code | Code manuell eingeben in App |
| QR-Code | Visuell, für Probenabend | Einlesen mit Kamera |
| Direkt-Einladung | E-Mail-Adresse eingeben | E-Mail mit Link wird gesendet |

### 4.2 Einladungs-Screen (Admin-Ansicht)

```
Einladungen verwalten
─────────────────────────────────────────
AKTIVER EINLADUNGSLINK
╔═══════════════════════════════════════╗
║  https://sheetstorm.app/join/XK7-M2P ║
╚═══════════════════════════════════════╝
  [📋 Kopieren]  [📤 Teilen]  [QR-Code]

  Gültig bis: 30. April 2026
  Verbleibend: Unbegrenzt Einladungen
  [Widerrufen]  [Neu generieren]

────────────────────────────────────────
EINLADUNGSCODE
  ┌──────────────────┐
  │   KAP-7X2-M9P    │  ← 6-stellig, groß
  └──────────────────┘
  [Kopieren]  [Neu generieren]

────────────────────────────────────────
DIREKT EINLADEN
  [E-Mail-Adresse eingeben          ➤]

────────────────────────────────────────
AUSSTEHENDE EINLADUNGEN (2)
  📧 hans@kapelle.at   Gesendet vor 3 Tagen  [Erneut senden]
  📧 fritz@gmail.com   Gesendet vor 1 Tag    [Erneut senden]
```

### 4.3 Beitritts-Flow (Empfänger-Sicht)

1. **Link/Code erhalten** → App öffnen (oder AppStore-Redirect wenn nicht installiert)
2. **Auth-Check:** Eingeloggt? → Direkt zu Beitritts-Bestätigung. Nicht eingeloggt? → Login/Registrierung → dann Beitritt
3. **Beitritts-Bestätigung:**
   ```
   🎺 Blaskapelle Musterstadt
   ──────────────────────────
   Du wurdest eingeladen beizutreten.
   
   128 Mitglieder · Gegründet 1952
   
   [Kapelle beitreten]
   [Ablehnen]
   ```
4. **Sofortiger Zugriff** nach Beitritt → Kurzes Onboarding für die Kapelle (Instrument bestätigen, Stimme)

### 4.4 Code-Eingabe (manuell)

- Feld zeigt 6 separate Boxen (wie Bestätigungscode)
- Auto-Paste aus Clipboard wenn Code Format erkannt
- Auto-Uppercase während Eingabe
- Fehler bei falschem Code: „Dieser Code ist ungültig oder abgelaufen."

---

## 5. Flow D: Instrument-Register-Verwaltung

### 5.1 Konzept

Register = Gruppe von Instrumenten (z.B. Klarinetten, Blechbläser, Schlagwerk). Jede Kapelle kann ihre Register selbst definieren und anpassen.

### 5.2 Register-Übersicht (Admin/Notenwart)

```
Instrument-Register
───────────────────────────────────────
  [🔍 Register suchen]

  HOLZBLÄSER                      [✎]
  ├ 1. Klarinette          4 Mitgl.
  ├ 2. Klarinette          5 Mitgl.
  ├ Es-Klarinette          1 Mitgl.
  ├ Flöte                  3 Mitgl.
  └ Oboe                   0 Mitgl.  ← grau

  BLECHBLÄSER                     [✎]
  ├ 1. Trompete            3 Mitgl.
  ├ 2. Trompete            4 Mitgl.
  ├ 1. Flügelhorn          2 Mitgl.
  └ Posaune                3 Mitgl.

  SCHLAGWERK                      [✎]
  ├ Snare                  2 Mitgl.
  └ Percussion             1 Mitgl.

  [+ Register hinzufügen]
```

### 5.3 Register bearbeiten

- Name des Registers ändern
- Instrumente hinzufügen/entfernen/umbenennen (Drag&Drop für Reihenfolge)
- Instrument-Aliasse: z.B. „Bariton" kann auch „Euphonium" sein (wichtig für Stimmen-Matching)
- Register zusammenführen oder teilen
- Register löschen: Warnung wenn Mitglieder zugeordnet sind

### 5.4 Mitglied einem Register zuordnen

- Beim Hinzufügen eines Mitglieds: Instrument auswählen → automatisch dem richtigen Register zugeordnet
- Manuelle Übersteuerung möglich (Instrument: „Horn" → Register: „Blechbläser" statt „Holzbläser")
- Registerführer sieht nur sein Register in der Mitgliederliste

### 5.5 Stimmen-Mapping

- Jedes Instrument hat eine Liste bekannter Stimmen-Bezeichnungen in importierten Noten
- Notenwart kann mappen: „Klar. I" → „1. Klarinette"
- Das verbessert die AI-Erkennung über die Zeit (Kapellen-spezifisches Vokabular)

---

## 6. Flow E: Multi-Kapelle — Wechsel

### 6.1 Szenario

Ein Musiker (z.B. Hobbymusiker) spielt in zwei Kapellen: Stadtkapelle und Stadtjugendkapelle. Er will nahtlos zwischen den Kontexten wechseln.

### 6.2 Kapellen-Switcher

**Einstiegspunkt:** Avatar/Profilbild oben links in der Navigation → Tap öffnet Kapellen-Übersicht.

**Kapellen-Übersicht (Bottom Sheet Phone / Dropdown Tablet):**

```
┌────────────────────────────────────┐
│  DEINE KAPELLEN                    │
│                                    │
│  ✓ [🎺] Stadtkapelle Musterstadt   │ ← aktiv (Checkmark)
│        Admin · 128 Mitgl.          │
│                                    │
│     [🥁] Jugendblasorchester West  │
│        Musiker · 34 Mitgl.         │
│                                    │
│     [📁] Meine Sammlung            │ ← persönlich
│        Privat · 47 Stücke          │
│                                    │
│  ─────────────────────────────── │
│  [+ Kapelle erstellen]             │
│  [Einladungscode eingeben]         │
└────────────────────────────────────┘
```

### 6.3 Wechsel-Mechanismus

1. Tap auf andere Kapelle → sofortiger Kontextwechsel
2. Navigations-Header zeigt Kapellen-Name + Avatar
3. Bibliothek, Setlists, Kalender — alles zeigt nur Inhalte der aktiven Kapelle
4. Kein Reload nötig — Daten sind gecacht (Offline-First)
5. **Visueller Kontext-Indikator:** Farbiger Balken oder Avatar-Badge der aktiven Kapelle in der Bottom-Navigation

### 6.4 Benachrichtigungen im Multi-Kapellen-Kontext

- Benachrichtigungen aus **allen** Kapellen werden empfangen
- In der Benachrichtigung ist klar, welche Kapelle betroffen ist: „[Stadtkapelle] Probe verschoben auf Dienstag"
- Tap auf Benachrichtigung → wechselt automatisch zur betreffenden Kapelle

### 6.5 Einstellungen pro Kapelle

- Jede Kapelle hat eigene Einstellungen (Rolle, Instrument, Stimme)
- Nutzer-Einstellungen (Theme, Schriftgröße) gelten kapellenübergreifend
- Gerät-Einstellungen gelten immer nur gerätebezogen

---

## 7. Wireframes: Phone

### 7.1 Kapelle erstellen — Schritt 1/3 (Phone)

```
╔══════════════════════════════════╗
║ ←   Neue Kapelle     1 / 3  ◉○○ ║
╠══════════════════════════════════╣
║                                  ║
║  Wie heißt deine Kapelle?        ║
║                                  ║
║  ┌────────────────────────────┐  ║
║  │ Stadtkapelle Musterstadt   │  ║
║  └────────────────────────────┘  ║
║  Dieser Name ist bereits vergeb- ║
║  en. Füge einen Ort hinzu.  ⚠️   ║
║                                  ║
║  Ort / Region (optional)         ║
║  ┌────────────────────────────┐  ║
║  │ Bayern                     │  ║
║  └────────────────────────────┘  ║
║                                  ║
║  Beschreibung (optional)         ║
║  ┌────────────────────────────┐  ║
║  │ Traditionelle Blaskapelle  │  ║
║  │ aus dem Bayerischen...     │  ║
║  │                     42/300 │  ║
║  └────────────────────────────┘  ║
║                                  ║
╠══════════════════════════════════╣
║         [Weiter →]               ║
╚══════════════════════════════════╝
```

### 7.2 Kapelle erstellen — Schritt 2/3 Logo (Phone)

```
╔══════════════════════════════════╗
║ ←   Neue Kapelle     2 / 3  ○◉○ ║
╠══════════════════════════════════╣
║                                  ║
║  Logo hinzufügen (optional)      ║
║                                  ║
║  ┌──────────────────────────┐    ║
║  │                          │    ║
║  │      ┌────────┐          │    ║
║  │      │   SM   │          │    ║ ← Auto-Avatar
║  │      └────────┘          │    ║
║  │   Stadtkapelle Muster... │    ║
║  └──────────────────────────┘    ║
║                                  ║
║  ┌──────────┐  ┌──────────┐      ║
║  │📷 Foto   │  │🖼️ Galerie│      ║
║  └──────────┘  └──────────┘      ║
║                                  ║
║  Oder ein Emoji wählen:          ║
║  🎺 🎷 🥁 🎻 🎵 🎶 🎼 🎤        ║
║  🪗 🎸 🎹 🎺 🪘 🎵 🎙️ 🎟️       ║
║  🏆 🎭 🎪 🌟 🎊 🎉 ⭐ 🏅        ║
║                                  ║
╠══════════════════════════════════╣
║  [Überspringen]    [Weiter →]    ║
╚══════════════════════════════════╝
```

### 7.3 Mitgliederliste (Phone)

```
╔══════════════════════════════════╗
║ 🎺 Stadtkapelle    [👤+]  [···]  ║
╠══════════════════════════════════╣
║ Mitglieder (128)                 ║
║ ┌────────────────────────────┐   ║
║ │ 🔍 Mitglied suchen...      │   ║
║ └────────────────────────────┘   ║
║                                  ║
║ [Alle] [Admin] [Dirigent] [Not…] ►║
║                                  ║
║ ──────── A ──────────────────    ║
║ 👤 Anna Berger                   ║
║    Flöte · Musiker               ║
║                                  ║
║ 👤 Max Mustermann           [›]  ║
║    Klarinette · Notenwart        ║
║                                  ║
║ ──────── B ──────────────────    ║
║ 👤 Klaus Bauer                   ║
║    Posaune · Musiker             ║
║                                  ║
║ 👤 Maria Becker                  ║
║    Trompete · Admin · Dirigent   ║
║                                  ║
╠══════════════════════════════════╣
║  📋  🎵  📅  👤                  ║ ← Bottom Nav
╚══════════════════════════════════╝
```

### 7.4 Rollen bearbeiten — Bottom Sheet (Phone)

```
╔══════════════════════════════════╗
║ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ║ ← dimmed background
║                                  ║
╠══╦═══════════════════════════════╣
║  ║ — ← drag handle               ║
║  ╠═══════════════════════════════╣
║  ║  👤  Max Mustermann            ║
║  ║  Klarinette · seit 15.1.2026  ║
║  ╠═══════════════════════════════╣
║  ║  ROLLEN                       ║
║  ║  ☑ Musiker          Standard  ║
║  ║  ☑ Notenwart                  ║
║  ║  ☐ Registerführer             ║
║  ║  ☐ Dirigent                   ║
║  ║  ☐ Admin                      ║
║  ╠═══════════════════════════════╣
║  ║  INSTRUMENTE                  ║
║  ║  🎵 1. Klarinette    [Haupt] [✎]║
║  ║  🎵 Es-Klarinette          [✎]║
║  ║  [+ Instrument hinzufügen]    ║
║  ╠═══════════════════════════════╣
║  ║  [🗑️ Aus Kapelle entfernen]   ║
╚══╩═══════════════════════════════╝
```

### 7.5 Einladungs-Screen (Phone)

```
╔══════════════════════════════════╗
║ ←  Einladen                [✕]  ║
╠══════════════════════════════════╣
║                                  ║
║  EINLADUNGSLINK                  ║
║  ╔════════════════════════════╗  ║
║  ║ sheetstorm.app/join/XK7-M2║  ║
║  ╚════════════════════════════╝  ║
║  [📋 Kopieren]  [📤 Teilen]      ║
║  [QR-Code anzeigen]              ║
║                                  ║
║  ─────────────────────────────   ║
║  EINLADUNGSCODE                  ║
║  ┌──────────────────────────┐    ║
║  │    K A P - 7 X 2         │    ║ ← groß, lesbar
║  └──────────────────────────┘    ║
║  [Kopieren]  [Neu generieren]    ║
║                                  ║
║  ─────────────────────────────   ║
║  DIREKT EINLADEN                 ║
║  ┌──────────────────────┐  [→]  ║
║  │ E-Mail eingeben...   │        ║
║  └──────────────────────┘        ║
║                                  ║
║  ─────────────────────────────   ║
║  AUSSTEHEND (2)                  ║
║  📧 hans@kapelle.at    3 Tage   ║
║  📧 fritz@gmail.com    1 Tag    ║
╚══════════════════════════════════╝
```

### 7.6 Kapellen-Switcher (Phone)

```
╔══════════════════════════════════╗
║ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ║
╠══╦═══════════════════════════════╣
║  ║ —                             ║
║  ╠═══════════════════════════════╣
║  ║  DEINE KAPELLEN               ║
║  ║                               ║
║  ║  ✓ 🎺 Stadtkapelle Muster...  ║ ← aktiv
║  ║      Admin · 128 Mitgl.       ║
║  ║                               ║
║  ║    🥁 Jugendblasorchester W.  ║
║  ║       Musiker · 34 Mitgl.     ║
║  ║                               ║
║  ║    📁 Meine Sammlung          ║
║  ║       Privat · 47 Stücke      ║
║  ║                               ║
║  ╠═══════════════════════════════╣
║  ║  [+ Kapelle erstellen]        ║
║  ║  [Einladungscode eingeben]    ║
╚══╩═══════════════════════════════╝
```

---

## 8. Wireframes: Tablet

### 8.1 Kapelle erstellen — Schritt 1/3 (Tablet, Landscape)

```
╔══════════════════════════════════════════════════════════════════════╗
║  ←   Neue Kapelle erstellen                              1 ●  2 ○  3 ○  ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║         ┌────────────────────────────────────────────────┐          ║
║         │                                                │          ║
║         │   Wie heißt deine Kapelle?                     │          ║
║         │                                                │          ║
║         │   ┌──────────────────────────────────────┐    │          ║
║         │   │ Stadtkapelle Musterstadt              │    │          ║
║         │   └──────────────────────────────────────┘    │          ║
║         │                                                │          ║
║         │   Ort / Region (optional)                      │          ║
║         │   ┌──────────────────────────────────────┐    │          ║
║         │   │ Bayern                                │    │          ║
║         │   └──────────────────────────────────────┘    │          ║
║         │                                                │          ║
║         │   Beschreibung (optional)                      │          ║
║         │   ┌──────────────────────────────────────┐    │          ║
║         │   │ Traditionelle Blaskapelle aus dem     │    │          ║
║         │   │ Bayerischen Voralpenland...            │    │          ║
║         │   │                                42/300 │    │          ║
║         │   └──────────────────────────────────────┘    │          ║
║         │                                                │          ║
║         │              [Weiter →]                        │          ║
║         └────────────────────────────────────────────────┘          ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```

### 8.2 Mitgliederliste (Tablet, Split-View)

```
╔═════════════════════════════════════════════════════════════════════╗
║  🎺 Stadtkapelle Musterstadt           [👤+]  [···]  [🔔]  [👤]   ║
╠════════════════════╦════════════════════════════════════════════════╣
║                    ║                                                ║
║  Mitglieder (128)  ║  👤 Max Mustermann                            ║
║  ─────────────────  ║  ─────────────────────────────────────────── ║
║  🔍 Suchen...      ║                                                ║
║                    ║  Klarinette · Notenwart · seit 15.1.2026      ║
║  [Alle][Admin][D…] ║                                                ║
║  ─────────────────  ║  ROLLEN                                       ║
║  — A —             ║  ☑ Musiker             ☑ Notenwart            ║
║  👤 Anna Berger    ║  ☐ Registerführer      ☐ Dirigent             ║
║     Flöte          ║  ☐ Admin                                       ║
║  👤 Max Muster. ●  ║                                                ║
║     Klarinette     ║  INSTRUMENTE                                   ║
║  — B —             ║  🎵 1. Klarinette      [Haupt]    [✎ Ändern] ║
║  👤 Klaus Bauer    ║  🎵 Es-Klarinette                 [✎ Ändern] ║
║     Posaune        ║  [+ Instrument hinzufügen]                     ║
║  👤 Maria Becker   ║                                                ║
║     Trompete       ║  ─────────────────────────────────────────── ║
║  — C —             ║  [Aus Kapelle entfernen]   ← rot, destructive ║
║                    ║                                                ║
╠════════════════════╩════════════════════════════════════════════════╣
║  📋  🎵  📅  👤                                                     ║
╚═════════════════════════════════════════════════════════════════════╝
```

### 8.3 Register-Verwaltung (Tablet)

```
╔═════════════════════════════════════════════════════════════════════╗
║  🎺 Stadtkapelle             Register                   [+ Register] ║
╠═══════════════════════╦═════════════════════════════════════════════╣
║                       ║                                             ║
║  HOLZBLÄSER      [✎] ║  HOLZBLÄSER · Register bearbeiten          ║
║  1. Klarinette   4   ║  ─────────────────────────────────────────  ║
║  2. Klarinette   5   ║                                             ║
║  Es-Klarinette   1   ║  Registername:  ┌──────────────────────┐   ║
║  Flöte           3   ║                 │ Holzbläser            │   ║
║  Oboe            0   ║                 └──────────────────────┘   ║
║                       ║                                             ║
║  BLECHBLÄSER     [✎] ║  Instrumente (Drag zum Sortieren):         ║
║  1. Trompete     3   ║  ⠿ 1. Klarinette    [Alias hinzufügen] [✕] ║
║  2. Trompete     4   ║  ⠿ 2. Klarinette                       [✕] ║
║  Flügelhorn      2   ║  ⠿ Es-Klarinette    Alias: Es-Klar    [✕] ║
║  Posaune         3   ║  ⠿ Flöte                               [✕] ║
║                       ║  ⠿ Oboe                                [✕] ║
║  SCHLAGWERK      [✎] ║  [+ Instrument hinzufügen]                  ║
║  Snare           2   ║                                             ║
║  Percussion      1   ║  [Speichern]       [Abbrechen]              ║
║                       ║                                             ║
╚═══════════════════════╩═════════════════════════════════════════════╝
```

---

## 9. Abhängigkeiten für Hill (Frontend)

### 9.1 Komponenten die Hill braucht

| Komponente | Beschreibung | Priorität |
|-----------|-------------|-----------|
| `KapelleCreateWizard` | 3-Schritte-Wizard mit Progress-Dots | P0 |
| `MitgliederListe` | Suchbar, filterbar, alphabetisch gruppiert | P0 |
| `RollenEditor` | Bottom Sheet (Phone) / Panel (Tablet) mit Checkbox-Liste | P0 |
| `InviteSheet` | Link, Code, QR, Direkt-E-Mail in einem Screen | P0 |
| `KapellenSwitcher` | Bottom Sheet / Dropdown mit Kapellen-Liste | P0 |
| `RegisterVerwaltung` | Zwei-Spalten Split-View mit Drag&Drop | P1 |
| `CodeInputField` | 6-Felder Eingabe-Komponente (auto-uppercase, auto-paste) | P0 |
| `KapellenAvatar` | Logo oder Emoji oder Buchstaben-Avatar | P0 |

### 9.2 API-Endpunkte (für Banner)

| Aktion | Methode | Endpunkt |
|--------|---------|----------|
| Kapelle erstellen | POST | `/api/kapellen` |
| Kapelle abrufen | GET | `/api/kapellen/{id}` |
| Mitglieder abrufen | GET | `/api/kapellen/{id}/mitglieder` |
| Rolle zuweisen | PUT | `/api/kapellen/{id}/mitglieder/{userId}/rollen` |
| Mitglied entfernen | DELETE | `/api/kapellen/{id}/mitglieder/{userId}` |
| Einladung erstellen | POST | `/api/kapellen/{id}/einladungen` |
| Einladung widerrufen | DELETE | `/api/kapellen/{id}/einladungen/{einladungId}` |
| Einladung annehmen | POST | `/api/einladungen/{token}/annehmen` |
| Register abrufen | GET | `/api/kapellen/{id}/register` |
| Register bearbeiten | PUT | `/api/kapellen/{id}/register/{registerId}` |

### 9.3 Offene Fragen für Thomas

1. **Kapellen-Sichtbarkeit:** Sollen Kapellen öffentlich durchsuchbar sein (wie Vereinssuche), oder nur per Einladung beitreten?
2. **Maximale Mitgliederzahl:** Gibt es ein Limit (z.B. für Free-Tier: 15 Mitglieder laut Preismodell)?
3. **Kapellen-Löschung:** Was passiert mit den Noten wenn eine Kapelle gelöscht wird?
4. **Aushilfen in der Kapelle:** Bekommen Aushilfen (temporärer Token) einen Eintrag in der Mitgliederliste?
