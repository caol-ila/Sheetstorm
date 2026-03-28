# Feature-Spec: Noten-Import & Labeling — Sheetstorm

> **Issue:** #20
> **Version:** 1.0
> **Status:** Entwurf
> **Autor:** Hill (Product Manager)
> **Datum:** 2026-03-28
> **Meilenstein:** M1 — Kern: Noten & Kapelle
> **UX-Referenz:** `docs/ux-specs/noten-import.md` (Branch `squad/14-19-kapelle-import-ux`, Issue #19)
> **Abhängigkeiten:** Depends on #19 (UX); Blocks #21 (Dev Backend), #22 (Dev Frontend), #23 (Tests)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien](#3-akzeptanzkriterien)
4. [API Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [AI-Integration](#6-ai-integration)
7. [Berechtigungen](#7-berechtigungen)
8. [Edge Cases](#8-edge-cases)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Das Kernproblem

**Der Noten-Import ist das kritischste Feature von Sheetstorm.**

Ein Notenwart einer Blaskapelle verwaltet typischerweise 200–500 Notenblätter — physische Scans, PDF-Archive, Kamera-Fotos. Diese liegen als Dateien vor, die organisiert, einem Stück zugeordnet, mit Metadaten versehen und der gesamten Kapelle zugänglich gemacht werden müssen.

**Ohne einen funktionierenden Import gibt es keine Noten in der App. Ohne Noten gibt es keine App.**

Das heutige Problem:
- Noten werden als PDF-Dateien per WhatsApp oder E-Mail geteilt — keine Struktur, kein Wiederauffinden
- Ein einzelnes PDF enthält oft mehrere Stücke für verschiedene Stimmen (z.B. "Neujahrskonzert 2024 — alle Stimmen")
- Manuelle Zuordnung jedes Blatts wäre prohibitiv zeitaufwändig
- Ohne AI-Unterstützung muss der Notenwart Titel, Stimme und Tonart für jedes Blatt von Hand eingeben

**Unser Ansatz:** Upload zuerst, KI arbeitet im Hintergrund, Notenwart bestätigt/korrigiert — nicht neu eingibt. Ein Batch-Import von 50 PDFs soll in unter 10 Minuten abgeschlossen sein.

### 1.2 Scope MS1

**In Scope:**
- PDF- und Bild-Upload (Drag & Drop, Dateidialog, Kamera, Share-Sheet)
- Batch-Import (mehrere Dateien gleichzeitig)
- Seitenvorschau und Labeling-Workflow (Seiten → Stücke)
- AI-gestützte Metadaten-Erkennung (Azure AI Vision als erster Provider)
- Manuelle Metadaten-Eingabe (vollständig ohne AI nutzbar)
- Stimmen-Zuordnung pro Stück
- Persönliche Sammlung (Musiker ohne Kapellenzugehörigkeit)
- Berechtigungsprüfung (Notenwart vs. Musiker)

**Out of Scope (MS1):**
- IMSLP-Integration (MS2)
- Direktimport aus Cloud-Storage (OneDrive, Dropbox, Google Drive) — könnte MS1 sein, TBD
- MIDI-Dateien
- Audio-/Video-Dateien
- OCR für Notentext (AI erkennt Metadaten, kein vollständiges Musik-OCR)
- Automatische Stimmenzuordnung ohne Bestätigung

### 1.3 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Notenwart | Sitzt am Desktop, hat 50 neue PDFs vom Dirigenten | Batch-Import, schnelles Labeling, Kapelle soll Noten sehen |
| Notenwart | Unterwegs mit Tablet, nach der Probe neue Noten erhalten | Import per Share-Sheet, Labeling auf Tablet |
| Musiker | Hat persönliche Noten auf dem Handy (Kamera-Fotos) | In persönliche Sammlung importieren |
| Musiker | Hat PDF von Kollegen erhalten | Zur persönlichen Sammlung hinzufügen |

---

## 2. User Stories

### US-01: PDF/Bild-Upload

> **Als Notenwart möchte ich PDFs und Bilder hochladen können, damit ich das bestehende Notenarchiv meiner Kapelle in Sheetstorm importieren kann.**

**Kontext:** Die primäre Arbeitssituation ist Desktop/Tablet, wo ein Batch von Dateien vorliegt.

**Akzeptanzkriterien:** → AC-01 bis AC-05

**Kriterien (INVEST):**
- **Independent:** Steht für sich, kein anderes Feature blockiert dies
- **Negotiable:** Cloud-Storage-Picker kann für MS1 entfallen
- **Valuable:** Ohne Upload keine App
- **Estimable:** ~5-8 Tage Backend + Frontend
- **Small:** Fokussiert auf Upload-Mechanismus (Labeling ist US-03)
- **Testable:** Klare Dateiformate und Größenlimits prüfbar

---

### US-02: Kamera-Scan

> **Als Notenwart möchte ich mit der Kamera meines Geräts Noten direkt fotografieren können, damit ich auch physische Notenblätter ohne Scanner importieren kann.**

**Kontext:** Unterwegs oder in der Probe, kein Scanner verfügbar. Mehrseitige Aufnahme (Seite 1, 2, 3 … in einer Session).

**Akzeptanzkriterien:** → AC-06, AC-07

**Kriterien (INVEST):**
- **Independent:** Kamera-Flow ist separater Einstiegspunkt
- **Valuable:** Erfasst Nutzer ohne Scanner (Mehrheit in kleinen Kapellen)
- **Estimable:** ~3 Tage (Flutter Camera-Plugin)
- **Testable:** Bild wird korrekt erfasst und in Upload-Queue eingereiht

---

### US-03: Seiten-Labeling

> **Als Notenwart möchte ich hochgeladene Seiten verschiedenen Liedern zuordnen können, damit ein PDF mit mehreren Stücken korrekt strukturiert wird.**

**Kontext:** Nach dem Upload werden alle Seiten als Thumbnails angezeigt. Der Notenwart markiert Stückgrenzen und benennt Stücke.

**Akzeptanzkriterien:** → AC-08 bis AC-11

**Kriterien (INVEST):**
- **Independent:** Funktioniert auch ohne AI (manuelle Eingabe)
- **Valuable:** Kernproblem — ohne Labeling ist alles ein Blob
- **Estimable:** ~8 Tage (komplexer UX-Flow)
- **Testable:** Stückgrenzen werden korrekt gespeichert, Seitenreihenfolge stimmt

---

### US-04: AI-Metadaten-Korrektur

> **Als Notenwart möchte ich die von der KI erkannten Metadaten (Titel, Stimme, Tonart) überprüfen und korrigieren können, damit ich nicht jedes Feld manuell eingeben muss.**

**Kontext:** Nach dem Labeling schlägt die AI Metadaten vor. Der Notenwart sieht Vorschläge mit Konfidenz-Indikator und kann bestätigen oder überschreiben.

**Akzeptanzkriterien:** → AC-12 bis AC-15

**Kriterien (INVEST):**
- **Independent:** Kann ohne AI übersprungen werden (immer leeres Formular als Fallback)
- **Valuable:** Reduziert Eingabeaufwand drastisch
- **Estimable:** ~5 Tage (AI-Adapter + UI)
- **Testable:** Vorschläge werden korrekt angezeigt; manuelle Überschreibung wird gespeichert

---

### US-05: Persönliche Sammlung

> **Als Musiker möchte ich Noten zu meiner persönlichen Sammlung hinzufügen können, damit ich eigene Noten unabhängig von einer Kapelle verwalten kann.**

**Kontext:** Musiker ohne Notenwart-Rolle; Noten gehören nur ihm, nicht der Kapelle.

**Akzeptanzkriterien:** → AC-16, AC-17

**Kriterien (INVEST):**
- **Independent:** Separate Upload-Ziel-Auswahl (Kapelle vs. persönlich)
- **Valuable:** Bindet Einzelmusiker und Schüler an die App
- **Estimable:** ~2 Tage (gleicher Code-Pfad, nur andere Ziel-ID)
- **Testable:** Noten erscheinen nur in persönlicher Sammlung, nicht in Kapellen-Bibliothek

---

## 3. Akzeptanzkriterien

### Upload (AC-01 bis AC-07)

**AC-01 — Unterstützte Formate**
- Upload akzeptiert: PDF, JPG/JPEG, PNG, TIFF, HEIC/HEIF
- Abgelehnte Formate erhalten HTTP 415 mit klarer Fehlermeldung
- Max. Dateigröße: 100 MB pro Datei (konfigurierbar per Umgebungsvariable)
- Max. Seiten pro Upload-Session: 500 Seiten

**AC-02 — Batch-Upload**
- Mindestens 20 Dateien können gleichzeitig hochgeladen werden
- Jede Datei hat einen eigenen Fortschrittsbalken
- Einzelne Datei-Fehler brechen nicht den Gesamt-Upload ab
- Erfolgreich hochgeladene Dateien werden sofort für Labeling bereitgestellt

**AC-03 — Fortschrittsanzeige**
- Upload-Fortschritt wird in Prozent angezeigt (kein Fake-Progress)
- Bei Verbindungsabbruch: Automatischer Retry (max. 3 Versuche, exponentielles Backoff)
- Upload-Status bleibt sichtbar wenn Nutzer innerhalb der App navigiert (persistenter Banner)

**AC-04 — Seiten-Extraktion aus PDF**
- Jede PDF-Seite wird serverseitig in ein Bild (WebP, max. 2480×3508px, 150 DPI) konvertiert
- Konvertierungs-Fortschritt ist sichtbar
- Originalformat (PDF) bleibt serverseitig erhalten

**AC-05 — Drag & Drop (Desktop/Web/Tablet)**
- Dateien können aus dem Dateimanager in die Upload-Zone gezogen werden
- Visuelles Feedback beim Hover (Zone leuchtet auf)
- Mehrere Dateien gleichzeitig per Drag & Drop möglich

**AC-06 — Kamera-Scan**
- Kamera-Option ist auf Phone/Tablet sichtbar (Desktop: ausgeblendet)
- Nutzer kann mehrere Fotos in einer Session aufnehmen (Seite 1, 2, 3 …)
- Vorschau nach jeder Aufnahme mit Option "nochmal" oder "weiter"
- Alle aufgenommenen Fotos werden als Paket in die Upload-Queue eingereiht

**AC-07 — Share-Sheet (Mobile)**
- App registriert sich als Share-Ziel für PDF, JPG, PNG
- Geteilte Dateien landen direkt im Import-Flow (kein zusätzlicher Schritt)

---

### Labeling (AC-08 bis AC-11)

**AC-08 — Seitenvorschau**
- Nach vollständigem Upload aller Seiten: Thumbnails aller Seiten werden in Reihenfolge angezeigt
- Thumbnails sind klickbar (Vollbild-Vorschau der Seite)
- Seitenreihenfolge kann per Drag & Drop geändert werden

**AC-09 — Stückgrenzen setzen**
- Nutzer kann jede Seite als "Beginn eines neuen Stücks" markieren
- Default: alle Seiten = ein Stück
- Visueller Trenner zwischen Stücken
- Einzelne Seiten können nachträglich verschoben werden (Drag & Drop zwischen Stücken)

**AC-10 — Stück-Metadaten (manuell)**
- Pro Stück-Gruppe: Eingabeformular für Titel, Stimme, Tonart, Taktart, Komponist/Arrangeur
- Pflichtfeld: Titel (darf auch "Unbekannt" sein)
- Optionale Felder: alle anderen
- Stücke können ohne vollständige Metadaten gespeichert werden (ergänzbar später)

**AC-11 — Stimmen-Zuordnung im Labeling**
- Beim Zuordnen einer Stimme: Dropdown mit vorhandenen Stimmen der Kapelle + "Neue Stimme anlegen"
- Neue Stimme wird sofort im Kapellen-Register angelegt
- Eine Seiten-Gruppe kann nur genau einer Stimme zugeordnet werden

---

### AI-Metadaten (AC-12 bis AC-15)

**AC-12 — AI-Vorschläge**
- Wenn AI konfiguriert: Pro Stück werden KI-Erkennungs-Vorschläge angezeigt
- Vorschläge erscheinen als vorausgefüllte Felder (editierbar)
- Konfidenz-Indikator pro Feld: Hoch (grün) / Mittel (gelb) / Niedrig (rot/grau)
- Felder ohne Erkennung bleiben leer (kein Raten)

**AC-13 — AI läuft asynchron**
- AI-Analyse startet sofort nach Seiten-Upload (nicht erst nach Labeling)
- Nutzer kann mit Labeling beginnen während AI noch analysiert
- Wenn AI-Ergebnis fertig: Felder werden live aktualisiert (Toast: "KI-Vorschläge eingetroffen")

**AC-14 — Manuelle Überschreibung**
- Jedes KI-vorgeschlagene Feld kann manuell überschrieben werden
- Manuelle Werte werden eindeutig als "vom Nutzer bestätigt" markiert (visuell + in DB)
- Manuell korrigierte Felder werden nicht erneut durch AI überschrieben

**AC-15 — Kein AI-Zwang**
- Alle Import-Funktionen sind vollständig ohne AI nutzbar
- Wenn kein AI-Key konfiguriert: Formular startet leer (kein Fehler, kein Banner)
- App meldet fehlendes AI-Config nur im Einstellungs-Bereich (nicht im Import-Flow)

---

### Persönliche Sammlung (AC-16, AC-17)

**AC-16 — Upload-Ziel**
- Bei Import-Start: Auswahl "Zur Kapelle hinzufügen" (nur mit Berechtigung sichtbar) vs. "Persönliche Sammlung"
- Default: Persönliche Sammlung (wenn keine Berechtigung für Kapelle)

**AC-17 — Isolation**
- Noten in persönlicher Sammlung sind für andere Nutzer nicht sichtbar
- Persönliche Noten werden primär lokal gespeichert; optional Cloud-Sync
- Cloud-Sync-Status ist für den Nutzer sichtbar

---

## 4. API Contract

> Alle Endpunkte unter `/api/noten/`. Authentifizierung via Bearer-Token (JWT). Fehlerformat: `{ "error": "code", "message": "...", "details": {} }`.

### 4.1 POST /api/noten/upload

Startet einen Upload-Batch. Multipart/form-data.

**Request:**
```
POST /api/noten/upload
Content-Type: multipart/form-data
Authorization: Bearer {token}

files[]        — Datei(en); PDF, JPG, PNG, TIFF, HEIC
ziel           — "kapelle" | "persoenlich"
kapelle_id     — UUID (nur wenn ziel="kapelle"; muss Berechtigungsprüfung bestehen)
```

**Response 202 Accepted:**
```json
{
  "upload_id": "uuid",
  "status": "processing",
  "dateien": [
    {
      "datei_id": "uuid",
      "dateiname": "konzert2024.pdf",
      "status": "uploaded",
      "seiten_count": 0,
      "seiten_extracted": 0
    }
  ]
}
```

**Response 400 Bad Request:** Ungültige Dateiformate, Größenlimit überschritten  
**Response 403 Forbidden:** Keine Berechtigung für `ziel=kapelle`  
**Response 415 Unsupported Media Type:** Dateiformat nicht unterstützt

**GET /api/noten/upload/{upload_id}** — Polling für Fortschritt:
```json
{
  "upload_id": "uuid",
  "status": "processing" | "ready_for_labeling" | "completed" | "failed",
  "dateien": [...],
  "seiten": [
    {
      "seite_id": "uuid",
      "datei_id": "uuid",
      "seite_nr": 1,
      "thumbnail_url": "https://cdn.sheetstorm.app/...",
      "ai_status": "pending" | "processing" | "done" | "failed"
    }
  ]
}
```

---

### 4.2 POST /api/noten/{upload_id}/labeling

Speichert die Seiten-zu-Stück-Zuordnung.

**Request:**
```json
{
  "stuecke": [
    {
      "temp_id": "client-uuid-1",
      "seiten_ids": ["seite-uuid-1", "seite-uuid-2"],
      "reihenfolge": [1, 2],
      "stimme_id": "stimme-uuid-oder-null"
    },
    {
      "temp_id": "client-uuid-2",
      "seiten_ids": ["seite-uuid-3"],
      "reihenfolge": [1],
      "stimme_id": null
    }
  ]
}
```

**Response 200 OK:**
```json
{
  "stuecke": [
    {
      "temp_id": "client-uuid-1",
      "notenblatt_id": "uuid",
      "status": "labeled"
    }
  ]
}
```

**Response 409 Conflict:** Seite bereits einem anderen Notenblatt zugeordnet

---

### 4.3 POST /api/noten/{notenblatt_id}/metadata

Triggert AI-Erkennung für ein Notenblatt (wird normalerweise automatisch nach Upload ausgelöst; kann auch manuell erneut gestartet werden).

**Request:**
```json
{
  "force": false
}
```
`force: true` — AI-Analyse auch wenn bereits durchgeführt (Re-Analyse nach Korrektur der Seitenzuordnung)

**Response 202 Accepted:**
```json
{
  "job_id": "uuid",
  "status": "queued",
  "estimated_seconds": 5
}
```

**GET /api/noten/{notenblatt_id}/metadata/status** — Polling:
```json
{
  "status": "queued" | "processing" | "done" | "failed",
  "vorschlaege": {
    "titel": { "wert": "Böhmischer Traum", "konfidenz": 0.92 },
    "stimme": { "wert": "1. Klarinette", "konfidenz": 0.78 },
    "tonart": { "wert": "B-Dur", "konfidenz": 0.45 },
    "taktart": { "wert": "3/4", "konfidenz": 0.88 },
    "komponist": { "wert": null, "konfidenz": 0.0 }
  }
}
```

---

### 4.4 PUT /api/noten/{notenblatt_id}/metadata

Speichert manuell korrigierte oder bestätigte Metadaten.

**Request:**
```json
{
  "titel": "Böhmischer Traum",
  "komponist": "Karel Vacek",
  "arrangeur": null,
  "tonart": "B-Dur",
  "taktart": "3/4",
  "genre": "Polka",
  "schwierigkeitsgrad": 2,
  "tags": ["konzert", "2024"],
  "felder_bestaetigt": ["titel", "tonart", "taktart"]
}
```

`felder_bestaetigt` — Liste der Felder, die manuell bestätigt wurden (werden nicht mehr durch AI überschrieben)

**Response 200 OK:** Gespeicherte Metadaten

**Response 404 Not Found:** `notenblatt_id` existiert nicht  
**Response 403 Forbidden:** Keine Schreib-Berechtigung

---

### 4.5 POST /api/noten/{notenblatt_id}/stimmen

Ordnet einem Notenblatt eine Stimme zu (kann auch mehrfach aufgerufen werden für verschiedene Stimmen desselben Blatts — z.B. wenn ein Blatt für Klarinette 1+2 gilt).

**Request:**
```json
{
  "stimme_id": "uuid",
  "stimme_neu": {
    "name": "3. Trompete",
    "instrument": "Trompete",
    "register_id": "uuid-oder-null"
  }
}
```

Entweder `stimme_id` (vorhandene Stimme) **oder** `stimme_neu` (neue Stimme anlegen).

**Response 200 OK:**
```json
{
  "stimm_zuordnung_id": "uuid",
  "stimme_id": "uuid",
  "stimme_name": "3. Trompete"
}
```

**Response 404 Not Found:** `notenblatt_id` oder `stimme_id` nicht gefunden  
**Response 409 Conflict:** Stimme bereits zugeordnet

**DELETE /api/noten/{notenblatt_id}/stimmen/{stimme_id}** — Zuordnung entfernen

---

## 5. Datenmodell

### 5.1 Überblick (Entity Relationship)

```
Stueck (1) ──── (n) Notenblatt (1) ──── (n) Seite
                        │
                        └─── (n) StimmZuordnung ──── (1) Stimme
```

### 5.2 Stueck

```sql
CREATE TABLE stuecke (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kapelle_id    UUID REFERENCES kapellen(id) ON DELETE CASCADE,
  musiker_id    UUID REFERENCES users(id) ON DELETE CASCADE,
  titel         TEXT NOT NULL DEFAULT 'Unbekannt',
  komponist     TEXT,
  arrangeur     TEXT,
  tonart        TEXT,
  taktart       TEXT,
  genre         TEXT,
  schwierigkeitsgrad SMALLINT CHECK (schwierigkeitsgrad BETWEEN 1 AND 5),
  tags          TEXT[],
  erstellt_am   TIMESTAMPTZ DEFAULT NOW(),
  aktualisiert_am TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT stueck_besitzer CHECK (
    (kapelle_id IS NOT NULL AND musiker_id IS NULL) OR
    (kapelle_id IS NULL AND musiker_id IS NOT NULL)
  )
);

-- Entweder Kapelle oder Musiker — nie beides, nie keins
CREATE INDEX idx_stuecke_kapelle ON stuecke(kapelle_id) WHERE kapelle_id IS NOT NULL;
CREATE INDEX idx_stuecke_musiker ON stuecke(musiker_id) WHERE musiker_id IS NOT NULL;
CREATE INDEX idx_stuecke_titel ON stuecke USING GIN (to_tsvector('german', titel));
```

**Anmerkung:** Persönliche Sammlung = `musiker_id` gesetzt, `kapelle_id` NULL — gleiche Tabelle, gleiche Mechanismen (Architektur-Entscheidung Stark, siehe `.squad/decisions.md`).

### 5.3 Notenblatt

```sql
CREATE TABLE notenblaetter (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stueck_id        UUID REFERENCES stuecke(id) ON DELETE CASCADE,
  upload_id        UUID REFERENCES uploads(id),
  reihenfolge      SMALLINT NOT NULL DEFAULT 1,

  -- AI-Metadaten
  ai_titel         TEXT,
  ai_stimme        TEXT,
  ai_tonart        TEXT,
  ai_taktart       TEXT,
  ai_komponist     TEXT,
  ai_konfidenz     JSONB,      -- { "titel": 0.92, "stimme": 0.78, ... }
  ai_status        TEXT CHECK (ai_status IN ('pending','processing','done','failed')) DEFAULT 'pending',
  ai_provider      TEXT,       -- "azure_ai_vision", "openai_vision", ...
  ai_analysiert_am TIMESTAMPTZ,

  -- Manuell bestätigte Felder (werden nicht durch AI überschrieben)
  felder_bestaetigt TEXT[] DEFAULT '{}',

  erstellt_am      TIMESTAMPTZ DEFAULT NOW(),
  aktualisiert_am  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notenblaetter_stueck ON notenblaetter(stueck_id);
CREATE INDEX idx_notenblaetter_ai_status ON notenblaetter(ai_status) WHERE ai_status != 'done';
```

### 5.4 Seite

```sql
CREATE TABLE seiten (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notenblatt_id   UUID REFERENCES notenblaetter(id) ON DELETE CASCADE,
  datei_id        UUID REFERENCES upload_dateien(id),
  seite_nr        SMALLINT NOT NULL,     -- Seite im Originaldokument
  reihenfolge     SMALLINT NOT NULL,     -- Anzeigereihenfolge im Notenblatt

  -- Gespeicherte Bilder (unterschiedliche Auflösungen)
  bild_url        TEXT NOT NULL,         -- WebP, 150 DPI (Anzeige)
  bild_url_hoch   TEXT,                  -- WebP, 300 DPI (Druck/Zoom)
  thumbnail_url   TEXT NOT NULL,         -- WebP, 200px Breite (Thumbnails)
  original_url    TEXT,                  -- Original (PDF-Seite oder Kamera-Bild)

  breite_px       INTEGER,
  hoehe_px        INTEGER,

  erstellt_am     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_seiten_notenblatt ON seiten(notenblatt_id, reihenfolge);
```

### 5.5 Stimme

```sql
CREATE TABLE stimmen (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kapelle_id   UUID REFERENCES kapellen(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,         -- z.B. "1. Klarinette", "Flügelhorn"
  instrument   TEXT,                  -- normalisiert, z.B. "Klarinette"
  register_id  UUID REFERENCES register(id),
  reihenfolge  SMALLINT DEFAULT 99,
  erstellt_am  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (kapelle_id, name)
);
```

### 5.6 StimmZuordnung

```sql
CREATE TABLE stimm_zuordnungen (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notenblatt_id  UUID REFERENCES notenblaetter(id) ON DELETE CASCADE,
  stimme_id      UUID REFERENCES stimmen(id) ON DELETE RESTRICT,
  erstellt_am    TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (notenblatt_id, stimme_id)
);

CREATE INDEX idx_stimm_zuordnungen_stimme ON stimm_zuordnungen(stimme_id);
```

### 5.7 Upload-Hilfstabellen

```sql
CREATE TABLE uploads (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES users(id),
  kapelle_id   UUID REFERENCES kapellen(id),   -- NULL = persönlich
  ziel         TEXT CHECK (ziel IN ('kapelle','persoenlich')),
  status       TEXT CHECK (status IN ('uploading','processing','ready_for_labeling','completed','failed')) DEFAULT 'uploading',
  erstellt_am  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE upload_dateien (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_id    UUID REFERENCES uploads(id) ON DELETE CASCADE,
  dateiname    TEXT NOT NULL,
  dateityp     TEXT NOT NULL,           -- "pdf", "jpg", "png", ...
  groesse_bytes BIGINT,
  seiten_count SMALLINT DEFAULT 0,
  status       TEXT CHECK (status IN ('uploaded','extracting','done','failed')) DEFAULT 'uploaded',
  fehler       TEXT,
  erstellt_am  TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 6. AI-Integration

### 6.1 Konfiguration (Dual-Key-Modell)

Gemäß Architektur-Entscheidung (`.squad/decisions.md` — AI-Architektur, Fallback-Kette):

| Ebene | Key-Typ | Verwaltet von | Fallback |
|-------|---------|---------------|---------|
| User | Eigener API-Key | Nutzer selbst (Profil-Einstellungen) | → Kapellen-Key |
| Kapelle | Kapellen-API-Key | Admin der Kapelle (Kapellen-Einstellungen) | → keine AI |
| Default | — | — | Formular bleibt leer |

**Fallback-Kette:** User-Key → Kapellen-Key → keine AI (nie ein Fehler, nur stille Deaktivierung)

**Key-Validierung:** Bei Eingabe eines neuen Keys → Test-Request (1 Seite senden) → Erfolg/Fehler-Feedback in Echtzeit

**Key-Speicherung:**
- Serverseitig: AES-256 verschlüsselt in PostgreSQL
- Clientseitig (User-Key): Flutter Secure Storage (Keychain/Keystore)
- Keys erscheinen **nie** in API-Responses oder Logs (nur: `"key_configured": true`)

### 6.2 Service-Adapter-Pattern

```
AIService (Interface)
    ├── AzureAIVisionAdapter   ← erster Provider (MS1)
    ├── OpenAIVisionAdapter    ← MS2
    └── GoogleCloudVisionAdapter ← MS2
```

**Interface-Kontrakt:**
```dart
abstract class AINotesMetadataService {
  Future<AIMetadataResult> analyzeSheet(
    List<Uint8List> pageImages,
    AIServiceConfig config,
  );
}

class AIMetadataResult {
  final String? titel;
  final String? stimme;
  final String? tonart;
  final String? taktart;
  final String? komponist;
  final Map<String, double> konfidenz;  // 0.0–1.0
  final String provider;
  final DateTime analyzedAt;
}
```

**Konfidenz-Schwellen (konfigurierbar):**
| Konfidenz | Anzeige | Farbe |
|-----------|---------|-------|
| ≥ 0.85 | Hoch | Grün |
| 0.60–0.84 | Mittel | Gelb |
| < 0.60 | Niedrig | Rot |

### 6.3 Erkannte Felder

| Feld | Quelle | Konfidenz-Typ |
|------|--------|---------------|
| Titel | Kopfzeile des Notenblatts | Hoch bei klarer Schrift |
| Interpret/Komponist | Kopfzeile / Impressum | Mittel |
| Stimmenbezeichnung | Kopfzeile links/rechts | Hoch bei Standard-Bezeichnungen |
| Tonart | Notenschlüssel-Kontext | Mittel (erfordert Musikverständnis) |
| Taktart | Erste Taktangabe | Hoch bei klaren Ziffern |

### 6.4 Azure AI Vision (MS1-Implementierung)

- **Service:** Azure AI Vision v4.0 — OCR + Image Analysis
- **Endpoint:** `https://{resource}.cognitiveservices.azure.com/vision/v4.0/analyze`
- **Features:** `read`, `caption`
- **Bildformat:** WebP oder JPEG, max. 4 MB pro API-Call
- **Kosten-Optimierung:** Nur die erste Seite des Notenblatts analysieren (Kopfzeile enthält alle relevanten Metadaten)

---

## 7. Berechtigungen

### 7.1 Berechtigungsmatrix

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|-------|----------|-----------|----------------|---------|
| Noten zur Kapelle hochladen | ✅ | ✅ | ✅ | ❌ | ❌ |
| Labeling für Kapellen-Noten | ✅ | ✅ | ✅ | ❌ | ❌ |
| Kapellen-Noten bearbeiten (Metadaten) | ✅ | ✅ | ✅ | ❌ | ❌ |
| Kapellen-Noten löschen | ✅ | ❌ | ✅ | ❌ | ❌ |
| Stimmen anlegen/verwalten | ✅ | ✅ | ✅ | ✅ | ❌ |
| Upload-Berechtigung konfigurieren | ✅ | ❌ | ❌ | ❌ | ❌ |
| Kapellen-AI-Key hinterlegen | ✅ | ❌ | ❌ | ❌ | ❌ |
| Eigene Noten in pers. Sammlung | ✅ | ✅ | ✅ | ✅ | ✅ |

**Anmerkungen:**
- Standard-Konfiguration (konfigurierbar per Kapelle über Admin)
- Jeder Nutzer mit Kapellen-Zugehörigkeit kann immer zur persönlichen Sammlung importieren
- Server-side Enforcement ist nicht verhandelbar — Frontend blendet aus, Server prüft

### 7.2 Konfigurierbare Upload-Berechtigungen

Kapellen-Admins können die Default-Matrix anpassen:
- "Alle Musiker dürfen Noten hochladen" (z.B. für kleine Kapellen ohne Notenwart)
- "Nur Notenwart darf hochladen" (strenger als Default — Dirigent ausgeschlossen)
- Konfiguration liegt in `kapellen.upload_berechtigungen` (JSONB)

---

## 8. Edge Cases

### 8.1 Große Dateien (> 20 MB)

**Szenario:** Notenwart lädt 200-seitiges PDF mit 80 MB hoch.

**Verhalten:**
- Upload läuft (max. 100 MB erlaubt)
- Seiten-Extraktion dauert 30–120 Sekunden → Fortschrittsanzeige mit ehrlicher Schätzung
- Timeout serverseitig: 5 Minuten für Extraktion, danach Status `failed` + Retry-Angebot
- Nutzer kann App benutzen während Extraktion läuft (persistenter Fortschritts-Banner)

### 8.2 Schlechte Bildqualität

**Szenario:** Kamera-Foto ist verwackelt, Seite ist geknickt.

**Verhalten:**
- Upload und Seiten-Extraktion laufen normal
- AI meldet niedrige Konfidenz (< 0.40) für alle Felder → alle Felder rot markiert
- Formular bleibt leer; Nutzer wird nicht blockiert — kann manuell eingeben
- Qualitäts-Hinweis wird angezeigt: "Die Bildqualität könnte die Texterkennung beeinträchtigen"
- Kein harter Fehler, kein Upload-Abbruch

### 8.3 Mehrere Lieder pro Dokument

**Szenario:** Ein PDF enthält 40 Seiten für 8 verschiedene Stücke.

**Verhalten:**
- AI erkennt mögliche Stückgrenzen und schlägt Trennpunkte vor (als Vorschlag, nicht automatisch)
- Konfidenz-Schwelle für Stückgrenze-Vorschlag: > 0.80
- Nutzer kann Vorschläge annehmen, ablehnen oder selbst anpassen
- Jede Seite kann nur einem Stück zugeordnet sein

### 8.4 Duplikat-Erkennung

**Szenario:** Notenwart lädt dasselbe PDF zweimal hoch.

**Verhalten:**
- Hash-Vergleich (SHA-256) nach Upload
- Wenn Duplikat: Warnung "Diese Datei wurde bereits am [Datum] importiert — [Stückname]"
- Nutzer kann trotzdem fortfahren (Import als neue Version)
- Automatische Ablehnung gibt es nicht

### 8.5 Upload-Abbruch / Verbindungsverlust

**Szenario:** Verbindung bricht bei Seite 3 von 8 ab.

**Verhalten:**
- Retry automatisch (3 Versuche, exponentielles Backoff: 2s, 4s, 8s)
- Upload-State bleibt serverseitig erhalten (30 Minuten)
- Nutzer kann Upload-Session wiederaufnehmen (URL-State oder Local Storage)
- Bereits extrahierte Seiten müssen nicht neu hochgeladen werden

### 8.6 Unsupported PDF Features

**Szenario:** PDF ist passwortgeschützt, DRM, oder enthält nur Vektorgrafiken (kein Raster).

**Verhalten:**
- Passwortgeschützt: Fehler "Diese PDF-Datei ist passwortgeschützt. Bitte entfernen Sie den Schutz vor dem Upload."
- DRM: Gleiches Fehlerformat
- Vektor-PDF: Wird rasterisiert (pdfrx), normale Behandlung

### 8.7 Stimme existiert noch nicht

**Szenario:** AI erkennt "3. Trompete" — aber diese Stimme gibt es im Kapellen-Register noch nicht.

**Verhalten:**
- AI-Vorschlag wird angezeigt
- Nutzer kann "Neue Stimme anlegen" wählen — Stimme wird sofort im Register angelegt
- Kein Blocking: Notenblatt kann auch ohne Stimmen-Zuordnung gespeichert werden

### 8.8 Labeling nach langer Pause

**Szenario:** Upload ist seit 2 Stunden abgeschlossen, Nutzer beginnt erst jetzt mit Labeling.

**Verhalten:**
- Upload-State bleibt 7 Tage gespeichert (danach: Job-Cleanup, aber Dateien bleiben)
- Labeling kann jederzeit fortgesetzt werden
- AI-Analyse: Ergebnis wird gecacht; kein erneuter API-Call wenn bereits analysiert

---

## 9. Definition of Done

### Funktional
- [ ] Upload: PDF, JPG, PNG, TIFF, HEIC werden akzeptiert
- [ ] Batch-Upload: Mindestens 20 Dateien gleichzeitig
- [ ] PDF-Extraktion: Alle Seiten werden korrekt als WebP-Bilder gespeichert
- [ ] Kamera-Scan: Mehrseitige Aufnahme auf Phone/Tablet möglich
- [ ] Share-Sheet: iOS und Android können Dateien an Sheetstorm teilen
- [ ] Labeling: Stückgrenzen setzen, Seiten verschieben, Metadaten eingeben
- [ ] AI: Azure AI Vision erkennt Metadaten und zeigt Konfidenz an
- [ ] AI: Manuelle Überschreibung wird korrekt gespeichert (kein AI-Override)
- [ ] AI: Deaktivierbar; App ist vollständig ohne AI nutzbar
- [ ] Persönliche Sammlung: Import ohne Kapellen-Zugehörigkeit möglich
- [ ] Berechtigungen: Server-side Enforcement aller Rollen-Regeln

### Qualität
- [ ] Unit Tests: AI-Adapter (mocked), Upload-Validierung, Permission-Logic
- [ ] Integration Tests: Upload → Extraktion → Labeling → Speichern (E2E)
- [ ] Testabdeckung: ≥ 80% für Backend-Kernlogik
- [ ] Performance: Upload von 10 MB PDF in < 5 Sekunden (100 Mbit LAN)
- [ ] Performance: Seiten-Extraktion von 20-seitigem PDF in < 10 Sekunden
- [ ] Performance: Thumbnail-Anzeige nach Upload in < 2 Sekunden pro Seite

### UX / Accessibility
- [ ] UX-Review bestanden (Wanda, Issue #19)
- [ ] Fortschrittsanzeigen sind ehrlich (kein Fake-Progress)
- [ ] Fehlermeldungen sind nutzerfreundlich (kein technischer Stack-Trace)
- [ ] Screenreader: Upload-Status und Labeling-Flow navigierbar
- [ ] Touch: Alle Labeling-Aktionen mit Touch/Stylus bedienbar (kein Maus-Only)

### Technisch / Deployment
- [ ] API-Dokumentation in OpenAPI 3.1
- [ ] Migrations: Alle DB-Tabellen via EF Core Migrations deployt
- [ ] Blob Storage: Azure Blob Storage für Bilder konfiguriert
- [ ] CDN: Thumbnail-URLs über Azure CDN ausgeliefert
- [ ] Logs: Upload-Events in AppInsights (keine personenbezogenen Daten in Logs)
- [ ] AI-Keys: AES-256-Verschlüsselung serverseitig implementiert

### Abhängigkeiten erfüllt
- [ ] #19 (Wanda UX-Spec) abgenommen
- [ ] Kapellen-Register (Stimmen-Verwaltung) aus Kapellenverwaltung (#15) verfügbar
- [ ] Auth-System (#10) für Berechtigungsprüfung verfügbar
