# Feature-Spezifikation: Cloud-Sync (Persönliche Sammlung)

> **Meilenstein:** MS3  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-29  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Noten-Import, Spielmodus, Konfigurationssystem, Auth)  
> **UX-Referenz:** `docs/ux-specs/cloud-sync.md` (TBD — Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien (Feature-Level)](#3-akzeptanzkriterien-feature-level)
4. [API-Contract](#4-api-contract)
5. [Datenmodell](#5-datenmodell)
6. [Sync-Protokoll](#6-sync-protokoll)
7. [Edge Cases & Fehlerszenarien](#7-edge-cases--fehlerszenarien)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

Die persönliche Notensammlung eines Musikers wird automatisch über alle seine Geräte synchronisiert. Noten, Annotationen und Metadaten bleiben konsistent — ob das Tablet zuhause liegt, das Handy in der Probe ist oder beide offline waren.

**Kernwert:** „Meine Noten sind immer auf jedem meiner Geräte." Kein manuelles Exportieren, kein USB-Stick, kein Neueinscannen.

### 1.2 Das Kernproblem

**Status Quo:**
- Musiker scannen Noten auf einem Gerät, haben sie auf anderen Geräten nicht
- Annotationen gehen verloren wenn Gerät gewechselt wird
- Kein Backup wenn Gerät verloren geht oder kaputtgeht

**Sheetstorm-Lösung:**
- Delta-Sync: Nur Änderungen (nicht der gesamte Bestand) werden übertragen
- Versionierung: Jede Änderung hat einen Version-Counter, kein "blindes" Überschreiben
- Offline-Fähigkeit: App funktioniert vollständig ohne Netz, Sync läuft wenn Verbindung wiederhergestellt
- Scope MS3: Nur „Meine Musik" (persönliche Sammlung), nicht Kapellen-Bibliothek (MS5+)

### 1.3 Scope MS3

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Sync „Meine Musik" zwischen eigenen Geräten | Sync der Kapellen-Bibliothek (andere teilen Noten) |
| Delta-Sync für Metadaten (Stücke, Notenblätter) | Echtzeit-Sync für Annotationen (separates Feature) |
| Last-Write-Wins Konflikt-Auflösung (per Feld) | Merge/3-Way-Diff für Konflikte |
| PDF-Binärdaten Sync (Blob-Storage) | CRDT-basierte Konflikt-Auflösung |
| Offline-Queue + automatisches Retry | Shared Drives / Externe Cloud (Google Drive, Dropbox) |
| Sync-Status-Anzeige in der UI | Selektiver Sync (bestimmte Stücke offline verfügbar) |
| Geräteliste anzeigen und verwalten | Familien-/Freundes-Sharing |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Musiker | Neue Note auf Handy eingescannt | Auf Tablet sehen ohne zu warten |
| Musiker | Probe ohne Internet | Normal spielen, Sync läuft später |
| Musiker | Zweites Gerät angemeldet | Gesamte Sammlung automatisch heruntergeladen |
| Musiker | Gerät verloren | Auf neuem Gerät anmelden, alles da |

---

## 2. User Stories

### US-01: Automatische Sync zwischen Geräten

> *Als Musiker möchte ich, dass meine persönliche Notensammlung automatisch auf allen meinen Geräten synchronisiert wird, damit ich auf jedem Gerät meine aktuellen Noten habe.*

**Akzeptanzkriterien:**
1. Sync startet automatisch wenn App geöffnet wird und Netzverbindung besteht
2. Sync läuft im Hintergrund, App bleibt vollständig nutzbar während Sync
3. Neue Stücke auf Gerät A erscheinen auf Gerät B innerhalb von 30 Sekunden (bei aktiver Verbindung)
4. Gelöschte Stücke werden auf allen Geräten als gelöscht markiert (Soft-Delete, 30 Tage Wiederherstellung)
5. Geänderte Metadaten (Titel, Komponist, Tags) werden synchronisiert
6. PDF-Binärdaten werden nur übertragen wenn noch nicht auf dem Gerät vorhanden (Content-Hash-Prüfung)
7. Sync-Status in der UI: „Synchronisiert", „Synchronisiert gerade", „Ausstehende Änderungen" + Zeitstempel

---

### US-02: Offline arbeiten mit automatischem Sync

> *Als Musiker möchte ich meine Noten auch ohne Internetverbindung bearbeiten können, und die Änderungen sollen sich automatisch synchronisieren sobald ich wieder online bin.*

**Akzeptanzkriterien:**
1. App zeigt klar an wenn sie offline ist (Status-Indikator, kein Fehler-Dialog)
2. Alle Offline-Aktionen (Stück hinzufügen, Metadaten ändern, Annotationen) werden in einer **Offline-Queue** gespeichert
3. Wenn Netzverbindung wiederhergestellt: Offline-Queue wird automatisch abgespielt (ohne Nutzer-Intervention)
4. Nutzer sieht Anzahl ausstehender Sync-Operationen
5. Beim Sync nach Offline: Konflikte werden nach Last-Write-Wins-Regel gelöst (kein Dialog, kein Nutzer-Eingriff)
6. Offline-Queue überlebt App-Neustart (persistiert in lokaler DB)
7. Offline-Anzeige: Wenn Stück auf Server gelöscht wurde während offline, erscheint nach Sync eine Benachrichtigung „X Stücke wurden von einem anderen Gerät gelöscht"

---

### US-03: Erstes Gerät hinzufügen (Full-Download)

> *Als Musiker möchte ich auf einem neuen Gerät meine gesamte Sammlung herunterladen können, damit ich sofort alle meine Noten verfügbar habe.*

**Akzeptanzkriterien:**
1. Beim ersten Login auf einem neuen Gerät: automatischer Full-Download der gesamten Sammlung wird gestartet
2. Download-Fortschritt sichtbar: „X von Y Stücken heruntergeladen", Gesamtdateigröße
3. App ist sofort nutzbar — bereits heruntergeladene Stücke sind spielbar während Rest noch lädt
4. Download kann pausiert und fortgesetzt werden (Resume-Support, auch nach App-Neustart)
5. Bei sehr großer Sammlung (> 1 GB): Hinweis „Bitte WiFi verwenden für Download"
6. Optional: Nutzer kann wählen „Nur Metadaten jetzt, PDFs bei Bedarf" (Lazy-Download-Modus)

---

### US-04: Sync-Status und Geräteliste verwalten

> *Als Musiker möchte ich sehen, welche meiner Geräte synchronisiert sind, und im Notfall ein Gerät aus meiner Sync-Gruppe entfernen können.*

**Akzeptanzkriterien:**
1. Einstellungen → Sync → Liste aller registrierten Geräte mit: Name, Plattform, Letzter Sync, Online/Offline
2. Nutzer kann ein Gerät „deregistrieren" (entfernt es aus Sync-Gruppe, lokale Daten bleiben)
3. Maximale Geräteanzahl: **10 Geräte** pro Nutzer
4. Wenn Gerät > 90 Tage nicht synchronisiert hat: Hinweis „Dieses Gerät ist lange offline"
5. Kein manueller „Sync erzwingen"-Button nötig (automatisch), aber vorhanden für Power-User

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Messbar |
|----|-----------|---------|
| AC-01 | Neue Änderung erscheint auf zweitem Gerät in ≤ 30s (online) | E2E-Test: Gerät A schreibt, Gerät B prüft nach 30s |
| AC-02 | Offline-Queue persistiert über App-Neustart | Test: Queue schreiben, App schließen, neu starten, prüfen |
| AC-03 | Delta-Sync überträgt nur geänderte Felder (nicht ganzes Objekt) | Netzwerk-Monitoring: SQL-Patch nicht Full-Object |
| AC-04 | PDF-Binärdaten werden nicht nochmals übertragen wenn Content-Hash identisch | Hash-Prüfung im Upload-Endpoint |
| AC-05 | Last-Write-Wins korrekt: späterer Timestamp gewinnt, älterer wird verworfen | Unit-Test: 2 Geräte ändern gleiches Feld gleichzeitig |
| AC-06 | Sync bei 100 Stücken (Metadaten) in ≤ 5s | Performance-Test |
| AC-07 | Full-Download 1 GB in ≤ 5 Minuten bei 100 Mbit | Netzwerk-Test |
| AC-08 | Soft-Delete: gelöschte Stücke 30 Tage wiederherstellbar | DB-Test |
| AC-09 | Max. 10 Geräte pro Nutzer: 11. Gerät erhält Fehlermeldung | API-Test |
| AC-10 | Sync-Status in UI korrekt (kein "Synchronisiert" wenn Queue noch offen) | UI-Test |

---

## 4. API-Contract

### 4.1 Delta-Sync Endpunkt

```
POST /api/v1/sync/meine-musik/delta
Authorization: Bearer {jwt}

Body:
{
  "geraet_id": "uuid",
  "letzte_sync_version": 12345,
  "lokale_aenderungen": [
    {
      "entity_type": "stueck",
      "entity_id": "uuid",
      "operation": "upsert",  // oder "delete"
      "version": 12346,
      "geaendert_am": "2026-03-29T18:00:00Z",
      "felder": { "titel": "Böhmischer Wind", "komponist": "..." }
    }
  ]
}

Response:
{
  "neue_server_version": 12350,
  "server_aenderungen": [
    {
      "entity_type": "stueck",
      "entity_id": "uuid",
      "operation": "upsert",
      "version": 12348,
      "felder": { ... }
    }
  ],
  "konflikte": [
    {
      "entity_id": "uuid",
      "gewonnene_version": { ... },
      "verlorene_version": { ... }
    }
  ]
}
```

### 4.2 PDF-Upload / Download

```
POST /api/v1/sync/meine-musik/blobs
Authorization: Bearer {jwt}
Content-Type: multipart/form-data

Body: { notenblatt_id, content_hash (SHA-256), file: binary }
Response: { blob_id, url, bereits_vorhanden: true/false }

---

GET /api/v1/sync/meine-musik/blobs/{blob_id}
Authorization: Bearer {jwt}
→ Redirect zu Blob-Storage-URL (Azure Blob Storage / S3)
   URL ist signiert + hat 1h TTL
```

### 4.3 Geräte-Management

```
GET    /api/v1/nutzer/geraete
       → [{ geraet_id, name, platform, letzte_sync, online }]

POST   /api/v1/nutzer/geraete/registrieren
       Body: { name, platform, push_token? }
       → { geraet_id }

DELETE /api/v1/nutzer/geraete/{geraet_id}
       → 204 No Content

GET    /api/v1/nutzer/sync-status
       → { ausstehende_aenderungen, letzte_sync, naechste_sync }
```

### 4.4 Full-Download (Erstes Gerät)

```
GET /api/v1/sync/meine-musik/full-snapshot
Authorization: Bearer {jwt}

Response:
{
  "snapshot_version": 12350,
  "stuecke": [...],
  "notenblatter": [...],
  "stimmen": [...],
  "blob_urls": { "notenblatt_id": "signed_url" }
}
```

---

## 5. Datenmodell

### 5.1 Neue Tabellen (Backend)

```sql
-- Sync-Versionen pro Nutzer
CREATE TABLE sync_versionen (
  nutzer_id       UUID        NOT NULL REFERENCES nutzer(id),
  version         BIGINT      NOT NULL DEFAULT 0,
  letzte_sync_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (nutzer_id)
);

-- Change-Log für Delta-Sync
CREATE TABLE sync_changes (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nutzer_id       UUID        NOT NULL REFERENCES nutzer(id),
  entity_type     TEXT        NOT NULL,  -- 'stueck', 'notenblatt', 'stimme'
  entity_id       UUID        NOT NULL,
  operation       TEXT        NOT NULL,  -- 'upsert', 'delete'
  version         BIGINT      NOT NULL,
  geaendert_am    TIMESTAMPTZ NOT NULL,
  felder          JSONB       NOT NULL,  -- nur geänderte Felder
  geraet_id       UUID,                  -- welches Gerät hat die Änderung gemacht
  
  INDEX idx_sync_changes_nutzer_version (nutzer_id, version)
);

-- Geräte pro Nutzer
CREATE TABLE nutzer_geraete (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  nutzer_id       UUID        NOT NULL REFERENCES nutzer(id),
  name            TEXT        NOT NULL,  -- "Mein iPad"
  platform        TEXT        NOT NULL,  -- 'ios', 'android', 'windows', 'web'
  letzte_sync_at  TIMESTAMPTZ,
  push_token      TEXT,                  -- für Push-Benachrichtigungen (später)
  registriert_am  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  CONSTRAINT max_geraete CHECK (
    (SELECT COUNT(*) FROM nutzer_geraete WHERE nutzer_id = nutzer_id) <= 10
  )
);
```

### 5.2 Bestehende Tabellen (Erweiterungen für Versionierung)

```sql
-- Alle Entitäten in „Meine Musik" bekommen:
ALTER TABLE stuecke     ADD COLUMN sync_version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE stuecke     ADD COLUMN geloescht_am TIMESTAMPTZ;  -- Soft-Delete
ALTER TABLE notenblatter ADD COLUMN sync_version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE notenblatter ADD COLUMN geloescht_am TIMESTAMPTZ;
ALTER TABLE stimmen     ADD COLUMN sync_version BIGINT NOT NULL DEFAULT 0;
ALTER TABLE stimmen     ADD COLUMN geloescht_am TIMESTAMPTZ;
```

### 5.3 Lokale Client-DB (Drift/SQLite — Erweiterung)

```sql
-- Offline-Queue
CREATE TABLE sync_queue (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  entity_type     TEXT    NOT NULL,
  entity_id       TEXT    NOT NULL,
  operation       TEXT    NOT NULL,
  felder          TEXT    NOT NULL,  -- JSON
  erstellt_am     INTEGER NOT NULL,  -- Unix timestamp
  versuche        INTEGER NOT NULL DEFAULT 0,
  naechster_versuch INTEGER          -- Unix timestamp für exponentielles Backoff
);
```

---

## 6. Sync-Protokoll

### 6.1 Delta-Sync Ablauf

```
Client                          Server
  │                               │
  ├── POST /sync/delta ──────────►│
  │   { letzte_version: 100,      │
  │     lokale_aenderungen: [...] }│
  │                               │── Konflikt-Auflösung
  │                               │   Last-Write-Wins per Feld
  │                               │── Server-Änderungen seit v100 laden
  │◄── Response ──────────────────┤
  │   { neue_version: 105,        │
  │     server_aenderungen: [...],│
  │     konflikte: [...] }        │
  │                               │
  ├── Lokale DB aktualisieren     │
  ├── letzte_version = 105        │
  └── Queue leeren                │
```

### 6.2 Last-Write-Wins Konflikt-Auflösung

```
Gerät A ändert: stueck.titel = "Böhmischer Wind" @ T=100
Gerät B ändert: stueck.titel = "Böhmischer Traum" @ T=101

Server empfängt beide:
  → Feld "titel": T=101 > T=100 → Gerät B gewinnt
  → Resultat: "Böhmischer Traum"

KEIN Dialog, KEIN Nutzer-Eingriff nötig.
Verlierenden Client: zeige Toast „Einige Änderungen wurden von einem anderen Gerät überschrieben"
```

### 6.3 Exponentielles Backoff für Retry

```
Versuch 1: sofort
Versuch 2: 30 Sekunden
Versuch 3: 2 Minuten
Versuch 4: 10 Minuten
Versuch 5+: 1 Stunde
Max Queue-Größe: 1000 Einträge (älteste werden bei Overflow verworfen mit Warnung)
```

---

## 7. Edge Cases & Fehlerszenarien

### 7.1 Gleichzeitige Löschung und Bearbeitung
- **Szenario:** Gerät A löscht Stück, Gerät B ändert Metadaten, beide offline.
- **Verhalten:** Löschen gewinnt immer über Bearbeiten (Delete hat höchste Priorität). Gerät B erhält nach Sync Toast: „1 Stück wurde gelöscht". Soft-Delete erlaubt 30-Tage-Wiederherstellung.

### 7.2 PDF-Upload schlägt fehl (Netzwerk-Fehler)
- **Szenario:** Stück mit PDF wird erstellt, Upload schlägt bei 80% fehl.
- **Verhalten:** Upload-Chunk-Mechanismus: Upload kann von letztem Chunk fortgesetzt werden (Content-Range Header). Metadaten-Sync und PDF-Sync sind unabhängige Queue-Einträge. Stück erscheint auf anderen Geräten ohne PDF, holt PDF nach wenn Upload abgeschlossen.

### 7.3 Extrem viele Offline-Änderungen (> 1000 Stücke)
- **Szenario:** Musiker war 6 Monate offline und hat 1000 neue Stücke eingescannt.
- **Verhalten:** Delta-Sync in Batches (max. 100 Einträge pro Request). Progress-Anzeige. Kein Timeout. Hintergrundaufgabe, App bleibt nutzbar.

### 7.4 Zweites Gerät — Full-Download bei schwacher Verbindung
- **Szenario:** Erstes Login in Mobilnetz (3G), 500 Noten verfügbar.
- **Verhalten:** Warnung bei > 50MB über Mobilnetz. Option: „Nur Metadaten (keine PDFs)". PDFs werden dann on-demand bei Öffnen eines Stücks geladen (Lazy-Download).

### 7.5 Versionsnummer-Überlauf
- **Szenario:** Nutzer macht > 9 Quintillionen Änderungen (theoretisch).
- **Verhalten:** BIGINT reicht für > 9 × 10^18 — keine praktische Grenze.

### 7.6 Nutzer löscht Account
- **Szenario:** Nutzer löscht seinen Account.
- **Verhalten:** GDPR: alle Sync-Daten, Blobs, Change-Logs werden innerhalb 30 Tagen gelöscht. Lokale Daten bleiben auf Geräten (nur Server-Daten gelöscht). Geräte-Registration wird sofort invalidiert.

### 7.7 Storage-Quota überschritten
- **Szenario:** Nutzer hat mehr als 10 GB persönlicher Noten (PDF-Dateien).
- **Verhalten:** Upload schlägt fehl mit klarer Fehlermeldung + Link zu Einstellungen. Keine stumme Ablehnung. Quota-Anzeige in Einstellungen.

---

## 8. Abhängigkeiten

### 8.1 Blockierende Abhängigkeiten

| Feature | Warum | Meilenstein |
|---------|-------|-------------|
| Auth & JWT (MS1) | Sync ist nutzerbezogen, braucht Auth | MS1 |
| Noten-Import (MS1) | Entitäten die synchronisiert werden (stuecke, notenblatter) | MS1 |
| Konfigurationssystem (MS1) | Sync-Einstellungen (WiFi-Only, Lazy-Download) | MS1 |
| Blob-Storage (Azure/S3) — Backend-Infrastruktur | PDF-Binärdaten | MS1 Backend |

### 8.2 Parallele Features

| Feature | Beziehung |
|---------|-----------|
| Annotationen-Sync (MS3) | Nutzt dasselbe Delta-Sync-Fundament, aber eigenes Schema |
| Aufgabenverwaltung (MS3) | Unabhängig, aber könnte später Sync nutzen |

---

## 9. Definition of Done

### Funktional
- [ ] US-01: Automatische Sync in ≤ 30s auf zweitem Gerät
- [ ] US-02: Offline-Queue persistent, automatisches Retry
- [ ] US-03: Full-Download auf neuem Gerät mit Progress-Anzeige
- [ ] US-04: Geräteliste, max. 10 Geräte, Deregistrierung
- [ ] Alle AC-01 bis AC-10 erfüllt und gemessen

### Qualität
- [ ] Unit-Tests: Last-Write-Wins Konflikt-Auflösung (10+ Szenarien)
- [ ] Unit-Tests: Delta-Sync Algorithmus
- [ ] Integration-Tests: 2-Gerät-Sync-Szenarien
- [ ] Test: Offline → Online → Queue abgearbeitet
- [ ] Test: Gleichzeitiges Löschen + Bearbeiten
- [ ] Performance-Test: 100 Stücke-Sync ≤ 5s
- [ ] Code Coverage ≥ 80%

### UX
- [ ] UX-Review durch Wanda abgenommen
- [ ] Sync-Status immer korrekt und verständlich
- [ ] WiFi-Warnung bei großem Download über Mobilnetz

### Deployment
- [ ] Blob-Storage konfiguriert (Azure Blob Storage)
- [ ] Storage-Quota konfigurierbar
- [ ] GDPR-Löschung dokumentiert und getestet
- [ ] Swagger-Dokumentation für alle Sync-Endpunkte
