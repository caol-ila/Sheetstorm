# Feature-Spezifikation: Aushilfen-Zugang

> **Issue:** TBD  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-04-15  
> **Status:** Entwurf  
> **Abhängigkeiten:** #10 (Auth & Onboarding), #15 (Kapellenverwaltung), Notenbibliothek-Feature, Termine-Feature  
> **Meilenstein:** MS2  
> **UX-Referenz:** TBD (wird von Wanda erstellt)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien](#3-akzeptanzkriterien)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Berechtigungsmatrix](#6-berechtigungsmatrix)
7. [Edge Cases](#7-edge-cases)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Beschreibung

Der **Aushilfen-Zugang** ermöglicht es, externe Musiker temporär und ohne Account-Erstellung Zugriff auf eine spezifische Stimme für einen bestimmten Termin zu geben. Aushilfsmusiker erhalten einen Link oder QR-Code, öffnen die Web-Ansicht im Browser und können ihre Stimme im bekannten Spielmodus-Renderer ansehen und abspielen — ohne App-Download und ohne Registrierung.

**Kernversprechen:**  
*"QR-Code teilen → Aushilfsmusiker öffnet Link → Stimme ist spielbereit — in unter 30 Sekunden."*

### 1.2 Ziel

Ein Dirigent oder Admin kann kurzfristig Aushilfen einbinden (z.B. für Konzerte, Festzelte, Ausnahmesituationen), ohne dass diese die App installieren oder einen Account erstellen müssen. Der Aushilfsmusiker bekommt temporären, stark limitierten Zugriff auf **genau eine Stimme** für **genau einen Termin** — und sieht sonst nichts von der Kapelle (keine Mitglieder, keine anderen Noten, keine Board-Posts).

### 1.3 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| Temporärer Token-basierter Zugang (kein Login) | Aushilfe kann Annotationen erstellen |
| Web-Ansicht (responsive) ohne App-Installation | Aushilfe kann Fragen im Chat stellen |
| Nur zugewiesene Stimme für zugewiesenen Termin sichtbar | Aushilfe bekommt Benachrichtigungen (z.B. Termin-Änderungen) |
| QR-Code-Sharing (Client-seitig generiert) | Aushilfe kann auf Proben-Aufnahmen zugreifen |
| Konfigurierbare Gültigkeitsdauer (Default: Termin + 1 Tag) | Multi-Termin-Zugang (aktuell: 1 Termin = 1 Link) |
| Admin/Dirigent kann Zugang widerrufen | Aushilfe wird in Anwesenheitsliste erfasst |
| Offline-fähige Web-Ansicht (Service Worker Cache) | Aushilfe kann Noten herunterladen/exportieren |
| Name + Instrument des Aushilfsmusiker anzeigen | Analytics: Wie oft/lange wurden Noten geöffnet |

### 1.4 Kontext & Use Case

**Typisches Szenario:**
1. Die 2. Trompete der Kapelle fällt kurzfristig aus
2. Dirigent findet einen Aushilfsmusiker (z.B. aus Nachbarkapelle)
3. Dirigent erstellt in Sheetstorm einen Aushilfen-Zugang: Termin auswählen → Stimme "2. Trompete" → Name "Max Muster" eingeben → Link generieren
4. Dirigent teilt den Link per WhatsApp oder zeigt QR-Code vor Ort
5. Aushilfsmusiker öffnet Link im Browser → sieht sofort seine Stimme im Spielmodus
6. Nach dem Termin (Standard: +1 Tag) verfällt der Link automatisch

**Differenzierung zu Einladungslinks (MS1):**
- Einladungslink → dauerhaftes Mitglied → Zugriff auf gesamte Kapelle
- Aushilfen-Zugang → temporär → Zugriff auf genau 1 Stimme für 1 Termin

### 1.5 Marktdifferenzierung

**Kein Wettbewerber bietet temporären Gast-Zugang mit QR-Code-Sharing:**
- **forScore / MobileSheets:** Teilen ist nur über Cloud-Bibliotheken möglich, kein temporärer Zugang
- **Konzertmeister:** Keine Mehrbenutzer-Features
- **BAND:** Einladung erfordert Account-Erstellung

Sheetstorm ist der erste Notenverwaltungs-App, die **No-Account-Guest-Access** mit **Termin-spezifischem Scoping** kombiniert.

---

## 2. User Stories

### US-01: Aushilfen-Zugang erstellen

> *Als Dirigent möchte ich einen temporären Zugangslink für einen Aushilfsmusiker erstellen, damit dieser kurzfristig Zugriff auf eine bestimmte Stimme für einen Termin bekommt — ohne App-Installation oder Registrierung.*

**Kontext:** Dirigent bereitet einen Termin vor und erfährt, dass ein Stammmusiker ausfällt. Er findet einen Aushilfsmusiker und möchte diesem Zugriff geben.

**Akzeptanzkriterien:**
1. Ich kann aus der Termin-Detailansicht auf "+ Aushilfe hinzufügen" tippen
2. Dialog öffnet sich mit Feldern:
   - **Name:** Pflichtfeld, 1–100 Zeichen (z.B. "Max Muster")
   - **Instrument:** Pflichtfeld, Dropdown aus den Registern der Kapelle
   - **Stimme:** Pflichtfeld, Dropdown der Stimmen für gewähltes Stück (Kontext: Setlist des Termins)
   - **Gültig bis:** Optional, Standard = Termin-Datum + 1 Tag (konfigurierbar: +1h, +6h, +1d, +3d, +7d, "kein Ablauf")
   - **Optionale Notiz:** Max. 200 Zeichen (z.B. "Bitte Dämpfer mitbringen")
3. Nach "Erstellen": System generiert kryptographisch sicheren Token (256-bit, URL-safe)
4. Ich sehe eine Übersicht mit:
   - **Link:** `https://app.sheetstorm.io/aushilfe/{token}` (Kopier-Button)
   - **QR-Code:** Inline-Anzeige (kann gescannt oder als PNG heruntergeladen werden)
   - **Details:** Name, Stimme, Gültig bis
5. Link und QR-Code können sofort per WhatsApp, E-Mail oder Ausdruck geteilt werden
6. Der Aushilfen-Zugang erscheint in der Teilnehmer-Liste des Termins mit Label "Aushilfe" (visuell abgesetzt von Mitgliedern)

**INVEST-Bewertung:**
- **I**ndependent ✓ — unabhängig von Einladungssystem (verwendet ähnlichen Token-Mechanismus, aber separate Tabelle)
- **N**egotiable ✓ — Ablaufdauer und Felder sind konfigurierbar
- **V**aluable ✓ — Kernversprechen des Features, ohne diesen Flow kein Aushilfen-Zugang
- **E**stimable ✓ — 1 Sprint (Token-Generation, API, UI)
- **S**mall ✓ — klar abgegrenzt: Erstellen + Link teilen
- **T**estable ✓ — messbar: Token ist gültig, QR-Code funktioniert, Link öffnet Web-Ansicht

---

### US-02: Aushilfen-Zugang nutzen (Musiker-Sicht)

> *Als Aushilfsmusiker möchte ich einen geteilten Link/QR-Code öffnen und sofort meine Stimme sehen, damit ich mich auf den Termin vorbereiten kann — ohne App-Download oder Registrierung.*

**Kontext:** Aushilfsmusiker erhält Link per WhatsApp oder scannt QR-Code vor Ort.

**Akzeptanzkriterien:**
1. Ich öffne den Link `https://app.sheetstorm.io/aushilfe/{token}` in meinem Browser (Desktop, Tablet, Phone)
2. Kein Login-Screen — direkter Zugang zur Stimme
3. Ich sehe:
   - **Header:** "Aushilfe für [Kapellenname] — [Termin-Name]" (z.B. "Aushilfe für MV Musterstadt — Frühlingskonzert am 15.04.2026")
   - **Meine Rolle:** "Du spielst: [Instrument] ([Stimme])" (z.B. "Du spielst: Trompete (2. Trompete)")
   - **Setlist des Termins:** Liste aller Stücke mit meiner Stimme
   - **Spielmodus:** Tap auf Stück öffnet bekannten Spielmodus-Renderer (Blättern, Zoom, Metronom, Play-Along)
4. Ich sehe **keine** anderen Inhalte der Kapelle:
   - Keine Bibliothek
   - Keine anderen Termine
   - Keine Mitglieder-Liste
   - Keine Board-Posts
   - Keine anderen Stimmen
5. Navigation ist reduziert: Nur "Zurück zur Setlist" und "Über diesen Zugang" (zeigt Gültigkeitsdatum)
6. **Offline-Fähigkeit:** Nach initialem Laden (alle PDFs gecacht) funktioniert die Ansicht auch ohne Internet (Service Worker Cache)
7. **Responsive:** Funktioniert auf Desktop, Tablet und Phone (optimiert für Tablet + Notenständer)

**INVEST-Bewertung:**
- **I**ndependent ✓ — separater User-Flow, nutzt aber bestehenden Spielmodus-Renderer
- **N**egotiable ✓ — Umfang der Offline-Fähigkeit diskutierbar
- **V**aluable ✓ — Kernerlebnis für Aushilfsmusiker
- **E**stimable ✓ — 1 Sprint (Web-Ansicht, Token-Validierung, Spielmodus-Integration)
- **S**mall ✓ — klar abgegrenzt: Read-only Zugriff auf 1 Stimme
- **T**estable ✓ — E2E-Test: Link öffnen → Stimme laden → Spielmodus funktioniert

---

### US-03: Aushilfen-Zugang verwalten

> *Als Admin oder Dirigent möchte ich aktive Aushilfen-Zugänge sehen und bei Bedarf widerrufen, damit ich Kontrolle über temporäre Zugänge behalte.*

**Kontext:** Dirigent hat mehrere Aushilfen-Zugänge erstellt oder ein Aushilfsmusiker ist doch nicht verfügbar.

**Akzeptanzkriterien:**
1. Ich sehe in der Termin-Detailansicht eine Liste aller Aushilfen-Zugänge für diesen Termin
2. Liste zeigt: Name, Instrument/Stimme, Erstellt am, Gültig bis, Status (aktiv/widerrufen/abgelaufen)
3. Ich kann auf ⋮ neben einem Zugang tippen → Menü öffnet sich:
   - "Link erneut kopieren"
   - "QR-Code anzeigen"
   - "Widerrufen" (nur bei aktiven Zugängen)
   - "Gültigkeit verlängern" (Dialog: +1d, +3d, +7d)
4. Nach "Widerrufen": Zugang wird sofort ungültig — nächster Aufruf des Links zeigt Fehlermeldung
5. Widerruf ist **nicht rückgängig machbar** — neuer Zugang muss erstellt werden
6. Abgelaufene Zugänge werden automatisch aus der Liste entfernt (nach 7 Tagen, Soft-Delete)
7. **Übersicht über alle Aushilfen:** Kapellen-Einstellungen → "Aushilfen-Zugänge" → Liste aller aktiven Zugänge über alle Termine (Admin/Dirigent)

**INVEST-Bewertung:**
- **I**ndependent ✓ — kann nach US-01 jederzeit nachträglich erfolgen
- **N**egotiable ✓ — Verlängern ist optional (kann in MS3 verschoben werden)
- **V**aluable ✓ — ohne Widerruf-Option unsicher
- **E**stimable ✓ — 0.5 Sprints
- **S**small ✓ — CRUD-Operation
- **T**estable ✓ — widerrufener Token führt zu 403, Verlängerung ändert `gueltig_bis`

---

### US-04: QR-Code vor Ort teilen

> *Als Dirigent möchte ich vor Ort (z.B. bei der Probe) einen QR-Code auf meinem Tablet zeigen, damit ein Aushilfsmusiker schnell Zugriff bekommt — ohne dass ich einen Link tippen oder teilen muss.*

**Kontext:** Dirigent ist bei der Probe, Aushilfsmusiker steht mit eigenem Tablet daneben.

**Akzeptanzkriterien:**
1. Ich öffne die Aushilfen-Details (aus Termin → Teilnehmer → Aushilfe)
2. QR-Code wird in Vollbild angezeigt (Button "QR-Code zeigen")
3. QR-Code ist scanbar von allen Standard-QR-Scannern (iOS Kamera, Android Kamera, QR-Scanner-Apps)
4. QR-Code enthält den vollständigen Link: `https://app.sheetstorm.io/aushilfe/{token}`
5. Optionaler Download als PNG (Button "Als Bild speichern") — z.B. für Ausdruck oder digitalen Versand
6. QR-Code-Generierung erfolgt **client-seitig** (keine separate API-Anfrage)

**INVEST-Bewertung:**
- **I**ndependent ✓ — UI-Erweiterung von US-01
- **N**egotiable ✓ — PNG-Download ist optional
- **V**aluable ✓ — beschleunigt Sharing vor Ort massiv (kein Tippen, kein Messenger)
- **E**stimable ✓ — 0.5 Sprints (QR-Code-Library einbinden)
- **S**mall ✓ — nur QR-Generierung
- **T**estable ✓ — QR-Code scannen führt zu korrektem Link

---

## 3. Akzeptanzkriterien

> **Feature-Level Akzeptanzkriterien** — Diese müssen alle erfüllt sein, damit das Feature als "Done" gilt.

| ID | Kriterium | Testmethode | Priorität |
|----|-----------|-------------|-----------|
| **AC-01** | Admin/Dirigent kann Aushilfen-Zugang erstellen (Name, Instrument, Stimme, Ablauf konfigurierbar) | E2E-Test | Must-have |
| **AC-02** | Generierter Link/QR-Code ist teilbar und funktioniert im Browser (Desktop, Tablet, Phone) | E2E-Test | Must-have |
| **AC-03** | Aushilfsmusiker sieht nur zugewiesene Stimme für zugewiesenen Termin (keine anderen Kapellen-Inhalte) | Integration Test | Must-have |
| **AC-04** | Web-Ansicht nutzt bestehenden Spielmodus-Renderer (Blättern, Zoom, Metronom funktionieren) | E2E-Test | Must-have |
| **AC-05** | Token-basierter Zugang funktioniert ohne Login/Registrierung | Integration Test | Must-have |
| **AC-06** | Zugang wird automatisch ungültig nach Ablaufdatum | Unit Test (Cron-Job) | Must-have |
| **AC-07** | Admin/Dirigent kann aktiven Zugang widerrufen → Token wird sofort ungültig | Integration Test | Must-have |
| **AC-08** | QR-Code ist scanbar und führt zu korrektem Link | E2E-Test | Must-have |
| **AC-09** | Web-Ansicht ist offline-fähig nach initialem Laden (Service Worker Cache) | E2E-Test (Offline-Modus) | Should-have |
| **AC-10** | Rate-Limiting auf Token-Endpunkt verhindert Brute-Force-Angriffe (max. 20 Versuche / Min / IP) | Integration Test | Must-have |
| **AC-11** | Token-Format ist URL-safe und kryptographisch sicher (256-bit) | Unit Test | Must-have |
| **AC-12** | Aushilfe sieht keine Mitglieder-Daten der Kapelle (Name, E-Mail, etc.) | Security Test | Must-have |

---

## 4. API-Contract

> **Basis-URL:** `https://api.sheetstorm.io/api/v1`  
> **Auth:** JWT Bearer Token für authentifizierte Endpunkte; Token-basiert für Aushilfen-Endpunkte (kein JWT)

### 4.1 Aushilfen-Zugang erstellen

**POST** `/api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen`

**Beschreibung:** Erstellt einen neuen Aushilfen-Zugang für einen Termin.

**Auth:** JWT (Admin oder Dirigent)

**Request Body:**
```json
{
  "name": "Max Muster",
  "instrument": "Trompete",
  "stimmeId": "uuid-der-stimme",
  "gueltigBis": "2026-04-16T23:59:59Z",
  "notiz": "Bitte Dämpfer mitbringen"
}
```

| Feld | Typ | Pflicht | Beschreibung |
|------|-----|---------|--------------|
| `name` | string | ✅ | Name des Aushilfsmusiker (1–100 Zeichen) |
| `instrument` | string | ✅ | Instrument (muss zu einem Register der Kapelle gehören) |
| `stimmeId` | UUID | ✅ | ID der Stimme aus der Setlist des Termins |
| `gueltigBis` | ISO 8601 | ❌ | Ablaufdatum (Default: Termin-Datum + 1 Tag) |
| `notiz` | string | ❌ | Optionale Notiz für den Aushilfsmusiker (max. 200 Zeichen) |

**Response 201 Created:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "kapelleId": "uuid-kapelle",
  "terminId": "uuid-termin",
  "name": "Max Muster",
  "instrument": "Trompete",
  "stimmeId": "uuid-stimme",
  "stimmeName": "2. Trompete",
  "token": "ash_3kd92jsldf8s9dfjkl2j3lk4j5lk6j7lk8j9lk0jalksjdflkajsdf",
  "gueltigBis": "2026-04-16T23:59:59Z",
  "status": "aktiv",
  "notiz": "Bitte Dämpfer mitbringen",
  "link": "https://app.sheetstorm.io/aushilfe/ash_3kd92jsldf8s9dfjkl2j3lk4j5lk6j7lk8j9lk0jalksjdflkajsdf",
  "qrCodeData": "data:image/png;base64,iVBORw0KGgo...",
  "erstelltAm": "2026-04-10T14:30:00Z",
  "erstelltVon": {
    "id": "uuid-dirigent",
    "name": "Anna Schmidt"
  }
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 400 | `INVALID_STIMME` | Stimme gehört nicht zur Setlist des Termins |
| 400 | `INVALID_INSTRUMENT` | Instrument gehört nicht zu einem Register der Kapelle |
| 400 | `INVALID_ABLAUF` | `gueltigBis` liegt in der Vergangenheit |
| 403 | `INSUFFICIENT_PERMISSIONS` | Nutzer ist weder Admin noch Dirigent |
| 404 | `TERMIN_NOT_FOUND` | Termin existiert nicht |
| 422 | `VALIDATION_ERROR` | Name leer oder zu lang |

---

### 4.2 Aushilfen-Zugang abrufen (Aushilfsmusiker)

**GET** `/api/v1/aushilfe/{token}`

**Beschreibung:** Ruft die Details eines Aushilfen-Zugangs ab. **Keine Authentifizierung erforderlich** — Zugriff erfolgt über den Token.

**Auth:** Keine (Token in URL ist Authentifizierung)

**Response 200 OK:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "name": "Max Muster",
  "instrument": "Trompete",
  "stimme": {
    "id": "uuid-stimme",
    "name": "2. Trompete",
    "pdfUrl": "/api/v1/aushilfe/ash_3kd.../stimme/pdf"
  },
  "termin": {
    "id": "uuid-termin",
    "name": "Frühlingskonzert",
    "datum": "2026-04-15T19:00:00Z",
    "ort": "Stadthalle Musterstadt"
  },
  "kapelle": {
    "name": "MV Musterstadt"
  },
  "setlist": [
    {
      "stueckId": "uuid-stueck-1",
      "titel": "Böhmische Liebe",
      "komponist": "Ernst Mosch",
      "stimme": {
        "id": "uuid-stimme-1",
        "name": "2. Trompete",
        "pdfUrl": "/api/v1/aushilfe/ash_3kd.../stuecke/uuid-stueck-1/pdf"
      }
    },
    {
      "stueckId": "uuid-stueck-2",
      "titel": "Auf der Vogelwiese",
      "komponist": "Traditional",
      "stimme": {
        "id": "uuid-stimme-2",
        "name": "2. Trompete",
        "pdfUrl": "/api/v1/aushilfe/ash_3kd.../stuecke/uuid-stueck-2/pdf"
      }
    }
  ],
  "gueltigBis": "2026-04-16T23:59:59Z",
  "notiz": "Bitte Dämpfer mitbringen"
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 403 | `TOKEN_REVOKED` | Zugang wurde widerrufen |
| 404 | `TOKEN_NOT_FOUND` | Token existiert nicht oder ist ungültig |
| 410 | `TOKEN_EXPIRED` | Token ist abgelaufen (zeigt `gueltigBis` im Response) |
| 429 | `RATE_LIMIT_EXCEEDED` | Rate-Limit überschritten (max. 20 Anfragen / Min / IP) |

**Rate-Limiting:**
- Max. 20 Anfragen pro Minute pro IP-Adresse (verhindert Token-Enumeration)
- Bei Überschreitung: HTTP 429 mit `Retry-After: 60` Header

---

### 4.3 Stimmen-PDF abrufen (Aushilfsmusiker)

**GET** `/api/v1/aushilfe/{token}/stuecke/{stueckId}/pdf`

**Beschreibung:** Lädt die PDF-Datei der Stimme für ein Stück herunter.

**Auth:** Keine (Token in URL ist Authentifizierung)

**Response 200 OK:**
- Content-Type: `application/pdf`
- Body: PDF-Binärdaten
- Header: `Content-Disposition: inline; filename="bohmische-liebe-2-trompete.pdf"`
- Header: `Cache-Control: private, max-age=3600` (1h Cache)

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 403 | `TOKEN_REVOKED` | Zugang wurde widerrufen |
| 404 | `STUECK_NOT_IN_SETLIST` | Stück gehört nicht zur Setlist des Termins |
| 404 | `PDF_NOT_FOUND` | PDF für diese Stimme existiert nicht |
| 410 | `TOKEN_EXPIRED` | Token ist abgelaufen |

---

### 4.4 Aushilfen-Zugang widerrufen

**DELETE** `/api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen/{aushilfeId}`

**Beschreibung:** Widerruft einen aktiven Aushilfen-Zugang. Token wird sofort ungültig.

**Auth:** JWT (Admin oder Dirigent)

**Response 200 OK:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "status": "widerrufen",
  "widerrufenAm": "2026-04-12T10:15:00Z",
  "widerrufenVon": {
    "id": "uuid-admin",
    "name": "Thomas Müller"
  }
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 403 | `INSUFFICIENT_PERMISSIONS` | Nutzer ist weder Admin noch Dirigent |
| 404 | `AUSHILFE_NOT_FOUND` | Aushilfen-Zugang existiert nicht |
| 409 | `ALREADY_REVOKED` | Zugang wurde bereits widerrufen |

---

### 4.5 Aushilfen-Zugänge auflisten

**GET** `/api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen`

**Beschreibung:** Listet alle Aushilfen-Zugänge für einen Termin auf.

**Auth:** JWT (Admin, Dirigent, Notenwart, Registerführer, Musiker)

**Response 200 OK:**
```json
{
  "aushilfen": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "name": "Max Muster",
      "instrument": "Trompete",
      "stimmeName": "2. Trompete",
      "gueltigBis": "2026-04-16T23:59:59Z",
      "status": "aktiv",
      "erstelltAm": "2026-04-10T14:30:00Z",
      "erstelltVon": {
        "id": "uuid-dirigent",
        "name": "Anna Schmidt"
      }
    },
    {
      "id": "b2c3d4e5-f6g7-8901-bcde-fg2345678901",
      "name": "Lisa Schneider",
      "instrument": "Klarinette",
      "stimmeName": "1. Klarinette",
      "gueltigBis": "2026-04-16T23:59:59Z",
      "status": "widerrufen",
      "erstelltAm": "2026-04-09T11:00:00Z",
      "widerrufenAm": "2026-04-11T08:30:00Z"
    }
  ],
  "total": 2
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 403 | `INSUFFICIENT_PERMISSIONS` | Nutzer ist kein Mitglied der Kapelle |
| 404 | `TERMIN_NOT_FOUND` | Termin existiert nicht |

---

### 4.6 Gültigkeit verlängern

**PATCH** `/api/v1/kapellen/{kapelleId}/termine/{terminId}/aushilfen/{aushilfeId}`

**Beschreibung:** Verlängert die Gültigkeit eines aktiven Aushilfen-Zugangs.

**Auth:** JWT (Admin oder Dirigent)

**Request Body:**
```json
{
  "gueltigBis": "2026-04-20T23:59:59Z"
}
```

**Response 200 OK:**
```json
{
  "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "gueltigBis": "2026-04-20T23:59:59Z",
  "aktualisiert_am": "2026-04-12T14:00:00Z"
}
```

**Fehler:**
| HTTP | Error-Code | Beschreibung |
|------|-----------|--------------|
| 400 | `INVALID_DATE` | Neues Ablaufdatum liegt in der Vergangenheit |
| 403 | `INSUFFICIENT_PERMISSIONS` | Nutzer ist weder Admin noch Dirigent |
| 404 | `AUSHILFE_NOT_FOUND` | Aushilfen-Zugang existiert nicht |
| 409 | `AUSHILFE_REVOKED` | Widerrufene Zugänge können nicht verlängert werden |

---

## 5. Datenmodell

### 5.1 Tabelle: aushilfen_zugang

```sql
CREATE TYPE aushilfen_status AS ENUM ('aktiv', 'widerrufen', 'abgelaufen');

CREATE TABLE aushilfen_zugang (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id      UUID         NOT NULL REFERENCES kapellen(id) ON DELETE CASCADE,
    termin_id       UUID         NOT NULL REFERENCES termine(id) ON DELETE CASCADE,
    stimme_id       UUID         NOT NULL REFERENCES stimmen(id) ON DELETE RESTRICT,
    token           VARCHAR(64)  NOT NULL UNIQUE,  -- kryptographisch sicher, URL-safe, 256-bit
    name_aushilfe   VARCHAR(100) NOT NULL,
    instrument      VARCHAR(100) NOT NULL,
    gueltig_bis     TIMESTAMPTZ  NOT NULL,
    status          aushilfen_status NOT NULL DEFAULT 'aktiv',
    notiz           VARCHAR(200),
    erstellt_am     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    erstellt_von    UUID         NOT NULL REFERENCES musiker(id),
    widerrufen_am   TIMESTAMPTZ,
    widerrufen_von  UUID         REFERENCES musiker(id),
    letzter_zugriff TIMESTAMPTZ,
    zugriffe_anzahl INTEGER      DEFAULT 0,
    geloescht_am    TIMESTAMPTZ           -- Soft-Delete nach 7 Tagen nach Ablauf
);

CREATE INDEX idx_aushilfen_token      ON aushilfen_zugang(token) WHERE status = 'aktiv' AND gueltig_bis > NOW();
CREATE INDEX idx_aushilfen_termin     ON aushilfen_zugang(termin_id) WHERE geloescht_am IS NULL;
CREATE INDEX idx_aushilfen_kapelle    ON aushilfen_zugang(kapelle_id) WHERE geloescht_am IS NULL;
CREATE INDEX idx_aushilfen_ablauf     ON aushilfen_zugang(gueltig_bis) WHERE status = 'aktiv';
```

**Hinweise:**
- `token`: Format `ash_[43 Zeichen base64url]` (Base64-URL-Encoding, kein Padding) → z.B. `ash_3kd92jsldf8s9dfjkl2j3lk4j5lk6j7lk8j9lk0jalksjdflkajsdf`
- Token-Generierung: `crypto.randomBytes(32).toString('base64url')` + Prefix `ash_`
- Unique Constraint auf `token` verhindert Kollisionen (Wahrscheinlichkeit: ~10⁻⁷⁷ bei 1 Mrd. Tokens)
- `status` wird automatisch auf `'abgelaufen'` gesetzt via Cron-Job (läuft stündlich)
- `letzter_zugriff` + `zugriffe_anzahl` für Analytics (MS3)

### 5.2 Referenzen

**Abhängigkeiten zu bestehenden Tabellen:**
- `kapellen` (aus Kapellenverwaltung-Feature)
- `termine` (aus Termine-Feature, MS2)
- `stimmen` (aus Notenbibliothek-Feature, MS1/MS2)
- `musiker` (aus Auth-Feature, MS1)

### 5.3 Cron-Job: Token-Ablauf

```sql
-- Läuft stündlich (z.B. via pg_cron oder Backend-Scheduler)
UPDATE aushilfen_zugang
SET status = 'abgelaufen'
WHERE status = 'aktiv'
  AND gueltig_bis < NOW();

-- Soft-Delete abgelaufener Zugänge nach 7 Tagen
UPDATE aushilfen_zugang
SET geloescht_am = NOW()
WHERE status = 'abgelaufen'
  AND gueltig_bis < NOW() - INTERVAL '7 days'
  AND geloescht_am IS NULL;
```

---

## 6. Berechtigungsmatrix

> **Prinzip:** RBAC pro Kapelle (wie in Kapellenverwaltung). **Aushilfe** ist eine **Sonderrolle ohne Mitgliedschaft** — Zugriff erfolgt rein über Token.

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker | **Aushilfe** |
|--------|:-----:|:--------:|:---------:|:--------------:|:-------:|:------------:|
| **Aushilfen-Zugang erstellen** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Aushilfen-Zugang widerrufen** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Aushilfen-Zugang verlängern** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Aushilfen-Liste für Termin sehen** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Aushilfen-Details sehen (inkl. Token)** | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Zugewiesene Stimme ansehen** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (nur eigene) |
| **Stimme herunterladen (PDF)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ (nur eigene) |
| **Setlist des Termins sehen** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ (nur eigene Stücke) |
| **Andere Stimmen sehen** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Mitglieder-Liste sehen** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Kapellen-Bibliothek sehen** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| **Annotationen erstellen** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ (MS3) |

**Besonderheiten:**
- **Aushilfe = Nicht-authentifizierter Gast** — keine JWT-Authentifizierung, nur Token-basiert
- Aushilfe sieht **nur**:
  - Name der Kapelle (schreibgeschützt)
  - Name + Datum + Ort des Termins (schreibgeschützt)
  - Eigene Stimme für alle Stücke der Setlist (PDF + Metadaten)
- Aushilfe sieht **nicht**:
  - Namen oder Kontaktdaten von Mitgliedern
  - Andere Termine der Kapelle
  - Bibliothek oder andere Stücke außerhalb der Setlist
  - Board-Posts oder Ankündigungen
- **Privacy-Schutz:** Aushilfe kann nicht erraten, welche anderen Stimmen existieren (keine Enumeration möglich)

---

## 7. Edge Cases

### 7.1 Abgelaufener Token

**Szenario:** Aushilfsmusiker öffnet Link nach Ablaufdatum (`gueltig_bis` ist in Vergangenheit).

**Verhalten:**
- `GET /api/v1/aushilfe/{token}` → `410 Gone`
- Response:
  ```json
  {
    "fehler": "TOKEN_EXPIRED",
    "nachricht": "Dieser Zugang ist abgelaufen (Gültigkeit bis 16.04.2026, 23:59 Uhr).",
    "gueltigBis": "2026-04-16T23:59:59Z",
    "kontakt": "Bitte kontaktiere den Dirigenten der Kapelle für einen neuen Zugang."
  }
  ```
- Frontend zeigt freundliche Fehlermeldung mit Erklärung

**Automatische Ablauf-Prüfung:**
- Cron-Job läuft stündlich und setzt `status = 'abgelaufen'` für alle Tokens mit `gueltig_bis < NOW()`
- API prüft zusätzlich bei jedem Request: Wenn Token aktiv ist, aber `gueltig_bis` abgelaufen → Error 410

---

### 7.2 Widerrufener Token

**Szenario:** Admin/Dirigent widerruft Zugang während Aushilfsmusiker die Noten liest.

**Verhalten:**
- `GET /api/v1/aushilfe/{token}` → `403 Forbidden`
- Response:
  ```json
  {
    "fehler": "TOKEN_REVOKED",
    "nachricht": "Dieser Zugang wurde widerrufen.",
    "widerrufenAm": "2026-04-12T10:15:00Z"
  }
  ```
- Alle laufenden Requests mit diesem Token schlagen ab sofort fehl
- Offline gecachte PDFs funktionieren weiterhin (Service Worker Cache läuft lokal)
  - **Diskussionspunkt:** Soll Cache gelöscht werden bei Widerruf? → Nein, da technisch nicht durchsetzbar (Browser-Cache ist nicht remote-löschbar)

---

### 7.3 Token-Enumeration / Brute-Force

**Szenario:** Angreifer versucht, durch Raten gültige Tokens zu finden.

**Verhalten:**
- Rate-Limit: Max. 20 Requests pro Minute pro IP-Adresse auf `/api/v1/aushilfe/{token}`
- Nach Überschreitung: HTTP 429 mit `Retry-After: 60`
- Token-Format: 256-bit → 2²⁵⁶ = 10⁷⁷ mögliche Werte
- Wahrscheinlichkeit, einen Token zu erraten: ~10⁻⁷⁵ bei 1 Mio. aktiven Tokens
- **Zusätzliche Sicherheit:** Token-Prefix `ash_` verhindert Verwechslung mit anderen Token-Typen (z.B. Einladungs-Tokens)

---

### 7.4 Stimme gehört nicht zur Setlist

**Szenario:** Aushilfsmusiker manipuliert die URL und versucht, eine andere Stimme abzurufen (`/api/v1/aushilfe/{token}/stuecke/{andereStueckId}/pdf`).

**Verhalten:**
- Backend prüft: Gehört `stueckId` zur Setlist des Termins?
- Falls nein → `404 Not Found` (nicht 403, um keine Hinweise auf Existenz anderer Stücke zu geben)
- Response:
  ```json
  {
    "fehler": "STUECK_NOT_FOUND",
    "nachricht": "Dieses Stück ist nicht Teil deiner Setlist."
  }
  ```
- Verhindert Enumeration: Aushilfe kann nicht erraten, welche anderen Stücke existieren

---

### 7.5 Termin wird verschoben/abgesagt

**Szenario:** Termin wird auf ein anderes Datum verschoben oder abgesagt, nachdem Aushilfen-Zugang erstellt wurde.

**Verhalten:**
- **Termin verschoben:** Zugang bleibt aktiv, aber `gueltig_bis` wird **nicht** automatisch angepasst
  - Dirigent muss manuell verlängern (via PATCH-Endpunkt)
  - Aushilfe sieht neues Datum in der Web-Ansicht (da `termin.datum` live abgerufen wird)
- **Termin abgesagt:** Dirigent sollte alle Aushilfen-Zugänge widerrufen
  - **Automatik (Optional für MS3):** Bei Termin-Absage → Dialog "Möchtest du alle Aushilfen-Zugänge widerrufen?"

---

### 7.6 Stimme wird aus Setlist entfernt

**Szenario:** Dirigent entfernt ein Stück aus der Setlist, nachdem Aushilfen-Zugang erstellt wurde.

**Verhalten:**
- Zugang bleibt aktiv (Token ist nicht ungültig)
- Aushilfe sieht das entfernte Stück nicht mehr in der Web-Ansicht (da Setlist live abgerufen wird)
- **Falls zugewiesene Stimme komplett entfernt wird:**
  - Backend-Constraint: `ON DELETE RESTRICT` auf `stimme_id` → Löschen wird blockiert, solange aktive Aushilfen-Zugänge existieren
  - Fehlermeldung: "Diese Stimme kann nicht gelöscht werden, da aktive Aushilfen-Zugänge existieren. Bitte widerrufe zuerst die Zugänge."

---

### 7.7 QR-Code wird fotografiert und weitergegeben

**Szenario:** Aushilfsmusiker fotografiert den QR-Code und teilt ihn ungewollt weiter (z.B. in WhatsApp-Gruppe).

**Verhalten:**
- **Technisch:** Token ist teilbar → jeder mit dem Link kann zugreifen
- **Sicherheit:** Rate-Limiting verhindert massenhaften Missbrauch
- **Empfehlung (UX):**
  - Hinweis beim Erstellen: "Teile diesen Link nur mit der Aushilfe. Jeder mit dem Link kann auf die Stimme zugreifen."
  - Option: "Link nach einmaligem Zugriff deaktivieren" (MS3-Feature)
- **Widerruf:** Dirigent kann bei Missbrauch sofort widerrufen → alle Zugriffe gestoppt

---

### 7.8 Offline-Modus: Service Worker Cache

**Szenario:** Aushilfsmusiker lädt die Web-Ansicht, cacht alle PDFs, verliert dann Internet — spielt Noten offline.

**Verhalten:**
- **Initial Load:**
  1. Browser öffnet `/aushilfe/{token}`
  2. Service Worker registriert sich
  3. Alle PDFs der Setlist werden gecacht (via `Cache API`)
  4. Spielmodus-Assets (CSS, JS, Fonts) werden gecacht
- **Offline:**
  1. Aushilfsmusiker verliert Internet
  2. Service Worker liefert gecachte Ressourcen
  3. Spielmodus funktioniert (Blättern, Zoom, Metronom)
  4. **Einschränkung:** Keine Live-Updates (z.B. bei Setlist-Änderungen)
- **Online wieder:**
  1. Service Worker prüft Token-Gültigkeit (Background Sync)
  2. Falls widerrufen → Fehlermeldung beim nächsten Request

**Cache-Strategie:**
- **Cache-First** für PDFs (da sich Noten nicht ändern)
- **Network-First** für Setlist-Daten (um Änderungen zu reflektieren)
- **Stale-While-Revalidate** für Spielmodus-Assets

---

### 7.9 Gleichzeitige Zugriffe auf denselben Token

**Szenario:** Aushilfsmusiker öffnet Link auf Tablet + Phone gleichzeitig (oder teilt Link versehentlich).

**Verhalten:**
- **Technisch erlaubt:** Token ist wiederverwendbar (kein Single-Use-Token)
- **Tracking:** Jeder Request erhöht `zugriffe_anzahl` und aktualisiert `letzter_zugriff`
- **Rate-Limiting gilt pro IP** — beide Geräte derselben IP teilen sich Limit
- **Logging (MS3):** Admin/Dirigent kann in Analytics sehen, wie oft der Token verwendet wurde (ohne IP-Adressen zu loggen — DSGVO)

---

## 8. Abhängigkeiten

### 8.1 Blockiert durch

| Issue | Titel | Typ | Beschreibung |
|-------|-------|-----|--------------|
| **#10** | Auth & Onboarding | Feature | Token-Mechanismus + Security-Patterns (Rate-Limiting, Hashing) sind Vorlage |
| **#15** | Kapellenverwaltung | Feature | Einladungslinks-Implementierung als technische Basis; `kapellen` + `musiker` Tabellen |
| **TBD** | Notenbibliothek | Feature | `stimmen` Tabelle + PDF-Storage + Spielmodus-Renderer |
| **TBD** | Termine-Feature | Feature | `termine` Tabelle + Setlist-Management |

### 8.2 Benötigt von

| Issue | Titel | Typ | Beschreibung |
|-------|-------|-----|--------------|
| **TBD (MS3)** | Aushilfen-Annotationen | Feature | Aushilfe soll Annotationen erstellen können (erweitert dieses Feature) |
| **TBD (MS3)** | Aushilfen-Analytics | Feature | Tracking wie oft/lange Noten geöffnet wurden |

### 8.3 Technische Voraussetzungen

**Backend (ASP.NET Core):**
- PostgreSQL mit bestehenden Tabellen: `kapellen`, `musiker`, `termine`, `stimmen`
- Token-Generierung: `System.Security.Cryptography.RandomNumberGenerator`
- Rate-Limiting: `AspNetCoreRateLimit` NuGet-Package
- Cron-Job: `Hangfire` oder `Quartz.NET` für Token-Ablauf-Checks

**Frontend (Web-Ansicht):**
- **Framework:** React oder Vue.js (leichtgewichtig, kein Flutter-Web nötig)
- **Spielmodus-Renderer:** Wiederverwendung des bestehenden Renderers (PDF.js + Canvas)
- **Service Worker:** Für Offline-Cache
- **QR-Code:** `qrcode.js` oder `qrcode-generator` (client-seitig)
- **Responsive:** TailwindCSS oder Material-UI

**Infrastruktur:**
- CDN für PDF-Auslieferung (z.B. Azure CDN oder Cloudflare) → schnelle Ladezeiten
- HTTPS Pflicht (QR-Codes mit HTTP würden von iOS/Android geblockt)

---

## 9. Definition of Done

### 9.1 Funktional

- [ ] Alle 4 User Stories (US-01 bis US-04) sind vollständig implementiert
- [ ] Alle 12 Feature-Level Akzeptanzkriterien (AC-01 bis AC-12) sind erfüllt
- [ ] Alle API-Endpunkte (§4.1–4.6) sind implementiert und dokumentiert
- [ ] Alle Edge Cases (§7.1–7.9) sind behandelt und getestet
- [ ] QR-Code-Generierung funktioniert (client-seitig, scanbar von Standard-Scannern)
- [ ] Web-Ansicht ist responsive (Desktop, Tablet, Phone)
- [ ] Offline-Modus funktioniert nach initialem Laden (Service Worker Cache)

### 9.2 Qualität

**Backend:**
- [ ] Unit Tests für Token-Generierung (Kollisionsfreiheit, Format, Länge)
- [ ] Unit Tests für Token-Validierung (abgelaufen, widerrufen, ungültig)
- [ ] Unit Tests für Rate-Limiting-Logik
- [ ] Integration Tests für alle API-Endpunkte (200, 403, 404, 410, 429)
- [ ] Cron-Job für Token-Ablauf läuft und setzt Status korrekt
- [ ] Test-Coverage Backend: ≥ 80% für Aushilfen-Modul

**Frontend (Web-Ansicht):**
- [ ] E2E-Test: Link öffnen → Stimme laden → Spielmodus funktioniert
- [ ] E2E-Test: QR-Code scannen → Web-Ansicht öffnet
- [ ] E2E-Test: Offline-Modus (Network-Tab "Offline" → Noten blättern funktioniert)
- [ ] E2E-Test: Widerruf während Nutzung → Fehlermeldung erscheint
- [ ] Responsive-Tests auf echten Geräten (iOS Safari, Android Chrome, Desktop)

**Security:**
- [ ] Rate-Limiting funktioniert (20 Requests / Min / IP)
- [ ] Token-Enumeration ist nicht möglich (Brute-Force-Test)
- [ ] Aushilfe kann keine anderen Stimmen/Stücke abrufen (Security-Test)
- [ ] Aushilfe sieht keine Mitglieder-Daten (Privacy-Test)
- [ ] Security-Review durch Stark abgenommen

### 9.3 UX & Design

- [ ] UX-Spec von Wanda erstellt und abgenommen (Wireframes, Flows)
- [ ] Web-Ansicht folgt UX-Spec (Screens, Navigation, Fehlermeldungen)
- [ ] QR-Code ist groß genug zum Scannen (min. 200×200px)
- [ ] Fehlermeldungen sind freundlich und hilfreich (kein "Error 403" — stattdessen "Dieser Zugang wurde widerrufen")
- [ ] Touch-Targets mindestens 44×44px (Tablet + Phone)

### 9.4 Performance

- [ ] Web-Ansicht lädt in < 3 Sekunden (3G-Netz, ohne Cache)
- [ ] PDFs werden progressiv geladen (erste Seite sofort sichtbar)
- [ ] Service Worker Cache reduziert wiederholte Ladezeiten auf < 1 Sekunde
- [ ] Rate-Limiting hat keine negativen Auswirkungen auf legitime Nutzer

### 9.5 Dokumentation

- [ ] API-Endpunkte in OpenAPI/Swagger dokumentiert
- [ ] README-Eintrag: "Aushilfen-Zugang — So funktioniert's" (für Dirigenten)
- [ ] Inline-Hilfe in der App: "Was ist ein Aushilfen-Zugang?" (Tooltip/Dialog)
- [ ] Diese Feature-Spec ist vollständig und von Thomas abgenommen

### 9.6 Deployment & Monitoring

- [ ] Datenbank-Migration ist idempotent und rollback-fähig
- [ ] Cron-Job für Token-Ablauf ist konfiguriert und läuft stündlich
- [ ] Monitoring: Alert bei > 50 fehlgeschlagenen Token-Requests / Min (mögliche Brute-Force)
- [ ] Logging: Alle Aushilfen-Zugriffe werden geloggt (für DSGVO-Compliance: ohne IP-Adressen)
- [ ] Feature-Flag "Aushilfen-Zugang" ermöglicht kontrollierten Rollout

### 9.7 Stakeholder-Abnahme

- [ ] Demo für Thomas (Product Owner) → Abnahme bestätigt
- [ ] Demo für 3 Pilotkapellen → Feedback eingearbeitet
- [ ] Security-Review durch Stark (Security-Verantwortlicher) → Abnahme bestätigt
- [ ] UX-Review durch Wanda → Abnahme bestätigt

---

**Ende der Feature-Spezifikation**

> **Nächste Schritte:**  
> 1. UX-Spec von Wanda erstellen lassen (`docs/ux-specs/aushilfen.md`)  
> 2. Technisches Design-Doc vom Backend-Team (Banner)  
> 3. Ticket-Split in Subtasks (Banner + Romanoff koordinieren)  
> 4. Sprint-Planung: Geschätzte Komplexität 21–34 Story Points (3–4 Sprints)
