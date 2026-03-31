# Feature-Spezifikation: Annotationen-Sync (Erweitert)

> **Meilenstein:** MS3  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2026-03-29  
> **Status:** Draft  
> **Abhängigkeiten:** MS1 (Annotationen-Spec #38, Spielmodus, Kapellenverwaltung, Auth + SignalR)  
> **UX-Referenz:** `docs/ux-specs/annotationen.md` (MS1), `docs/ux-specs/annotationen-sync.md` (TBD — Wanda)

---

## Inhaltsverzeichnis

1. [Feature-Überblick](#1-feature-überblick)
2. [User Stories](#2-user-stories)
3. [Akzeptanzkriterien (Feature-Level)](#3-akzeptanzkriterien-feature-level)
4. [API-Contract & Protokoll-Spezifikation](#4-api-contract--protokoll-spezifikation)
5. [Datenmodell](#5-datenmodell)
6. [Konflikt-Behandlung](#6-konflikt-behandlung)
7. [Edge Cases & Fehlerszenarien](#7-edge-cases--fehlerszenarien)
8. [Abhängigkeiten](#8-abhängigkeiten)
9. [Definition of Done](#9-definition-of-done)

---

## 1. Feature-Überblick

### 1.1 Ziel

MS1 legt das Fundament für Annotationen (3 Sichtbarkeitsebenen: Privat, Stimme, Orchester). MS3 bringt das Echtzeit-Sync: Stimmen-Annotationen werden sofort für alle Musiker derselben Stimme sichtbar; Orchester-Annotationen für alle Kapellenmitglieder. Dirigenten können ihre Markierungen live an die Kapelle übertragen.

**Kernwert:** Ein Dirigent markiert im Partitur — alle Musiker sehen es sofort auf ihren Noten. Ein Registerführer korrigiert einen Fingersatz in der Stimme — alle Musiker des Registers sehen es in Echtzeit.

### 1.2 Abgrenzung zu MS1

| MS1 (Basis) | MS3 (Sync-Erweiterung) |
|-------------|------------------------|
| Lokales Speichern aller 3 Ebenen | Echtzeit-Übertragung zu anderen Geräten |
| Basis-Sync bei App-Start (Pull) | Push-Sync via SignalR (Echtzeit) |
| Konflikt: „letzter Schreiber gewinnt" (offline) | Operationale Konflikt-Behandlung (online) |
| Annotations-Schema in DB | Δ-Operationen (Add/Update/Delete Operation-Log) |

### 1.3 Scope MS3

| Im Scope | Außerhalb Scope |
|----------|-----------------|
| Echtzeit-Sync Stimmen-Annotationen (alle Stimmen-Mitglieder) | Kollaboratives gleichzeitiges Zeichnen (CRDT) |
| Echtzeit-Sync Orchester-Annotationen (alle Kapellenmitglieder) | Audio-Annotationen |
| Konflikt-Behandlung: Last-Operation-Wins | Annotationen-Export (PDF mit Einzeichnungen) |
| Offline → Sync bei Verbindung | Annotationen-Versionierung (History) |
| Presence-Indicator (wer ist online) | Kommentare / Chat zu Annotationen |
| Delta-Operations (kein Full-Resync) | Annotationen zwischen Kapellen teilen |

### 1.4 Nutzungskontext

| Persona | Situation | Ziel |
|---------|-----------|------|
| Dirigent | Probe — Takt 12 markieren | Alle Musiker sehen seine Markierung sofort |
| Registerführer | Fingersatz für 2. Klarinette korrigieren | Alle 2. Klarinettisten erhalten Update |
| Musiker | Probe — Annotation des Dirigenten sehen | Reaktion ohne physisches Herumlaufen |
| Musiker | Offline in der Generalprobe | Änderungen kommen rein sobald WiFi verfügbar |

---

## 2. User Stories

### US-01: Stimmen-Annotation in Echtzeit empfangen

> *Als Klarinettist (2. Stimme) möchte ich, dass Annotationen meines Registerführers oder Mitspielers auf unserer gemeinsamen Stimme sofort auf meinem Gerät erscheinen, damit wir nicht warten müssen.*

**Akzeptanzkriterien:**
1. Registrierter Musiker öffnet eine Stimme → automatisch in Stimmen-Sync-Channel eingetreten
2. Neue Stimmen-Annotation von einem anderen Gerät erscheint auf dem eigenen Gerät in ≤ 500ms
3. Angezeigte Annotation ist visuell identisch (gleiche Position, gleiche Farbe, gleiches Werkzeug)
4. Gelöschte Annotation (von anderem Gerät) verschwindet in ≤ 500ms
5. Stimmen-Sync läuft nur für die aktive Stimme (nicht alle Stimmen gleichzeitig)
6. Eigene Privat-Annotationen bleiben lokal — keine Übertragung

---

### US-02: Orchester-Annotation in Echtzeit empfangen

> *Als Musiker möchte ich Annotationen des Dirigenten (Orchester-Ebene) sofort auf meinen Noten sehen, damit ich seine Anweisungen direkt am richtigen Takt sehe.*

**Akzeptanzkriterien:**
1. Alle Kapellenmitglieder im selben Stück empfangen Orchester-Annotationen in ≤ 500ms
2. Orchester-Annotationen des Dirigenten sind nur für Admin/Dirigent bearbeitbar (MS1-Sichtbarkeitsregeln bleiben)
3. Annotationen erscheinen auf der richtigen Seite (relative Position korrekt)
4. Wenn Musiker eine andere Seite betrachtet als die Annotation: keine Benachrichtigung (keine Push-Unterbrechung)
5. Presence-Indicator: kleines Punkt-Icon pro Stimme zeigt wie viele Musiker gerade online sind

---

### US-03: Offline-Annotationen nach Verbindungsaufbau synchronisieren

> *Als Musiker möchte ich in der Probe ohne WLAN annotieren können, und die Annotations sollen sich automatisch beim nächsten Verbindungsaufbau synchronisieren.*

**Akzeptanzkriterien:**
1. Offline-Annotationen werden lokal in Drift/SQLite gespeichert
2. Bei Verbindungsaufbau: Offline-Queue wird abgespielt (alle Operationen in Reihenfolge)
3. Wenn ein anderes Gerät in der Zwischenzeit dieselbe Stelle verändert hat: Last-Operation-Wins (neuester Timestamp gewinnt)
4. Toast-Benachrichtigung nach Sync: „Y Annotationen synchronisiert"
5. Keine Doppelanzeige (Annotation erscheint genau einmal auch wenn Queue-Replay)

---

### US-04: Annotation-Presence (Wer bearbeitet gerade?)

> *Als Dirigent möchte ich sehen, welche Musiker gerade welche Stimme geöffnet haben, damit ich weiß wer meine Orchester-Annotationen gerade sieht.*

**Akzeptanzkriterien:**
1. Orchester-Annotation-Panel zeigt: Anzahl aktiver Nutzer im Stück (nicht Namen, nur Zahl — Datenschutz)
2. Optional konfigurierbar per Kapelle: „Namen anzeigen" (Off by Default)
3. Presence-Daten sind ephemer (kein Speichern, nur In-Memory im SignalR-Hub)
4. Wenn Nutzer App verlässt oder schließt: Presence entfernt innerhalb 5 Sekunden

---

## 3. Akzeptanzkriterien (Feature-Level)

| ID | Kriterium | Messbar |
|----|-----------|---------|
| AC-01 | Stimmen-Annotation erscheint auf zweitem Gerät in ≤ 500ms (LAN) | E2E-Test: Zeitmessung A→B |
| AC-02 | Orchester-Annotation erscheint bei allen Geräten in ≤ 500ms (LAN) | E2E-Test mit 5 Geräten |
| AC-03 | Offline-Queue korrekt abgespielt nach Verbindungsaufbau | Test: 20 Offline-Ops, dann sync |
| AC-04 | Last-Operation-Wins: Konflikte korrekt aufgelöst (10 Testszenarien) | Unit-Tests |
| AC-05 | Keine Doppelanzeige von Annotationen bei Reconnect | E2E-Test: Disconnect/Reconnect |
| AC-06 | Presence-Daten ≤ 5s nach Trennung aktualisiert | Test: App schließen, Hub prüfen |
| AC-07 | Privat-Annotationen werden nicht übertragen | Netzwerk-Monitoring: kein Sichtbarkeit=Privat in Sync |
| AC-08 | 20 gleichzeitige Annotierungen ohne Latenz-Degradation | Load-Test |
| AC-09 | Sync funktioniert bei Stimmenwechsel (korrekte Channel-Umschaltung) | Integration-Test |
| AC-10 | Delta-Operationen: nur geänderte/neue/gelöschte Annotationen übertragen | Netzwerk-Analyse |

---

## 4. API-Contract & Protokoll-Spezifikation

### 4.1 SignalR Hub für Annotationen-Sync

**Hub-URL:** `/hubs/annotationen`

**Client → Server (Kommandos):**
```csharp
// Neue Annotation erstellen
SendAnnotation(annotation: AnnotationDto)

// Annotation aktualisieren (z.B. Move/Resize)
UpdateAnnotation(annotationId: string, changes: AnnotationPatchDto)

// Annotation löschen
DeleteAnnotation(annotationId: string)

// Stimme betreten (Channel beitreten)
JoinStimme(stimmeId: string, stueckId: string)

// Stimme verlassen
LeaveStimme(stimmeId: string)
```

**Server → Client (Events):**
```csharp
// Neue Annotation von anderem Gerät
AnnotationAdded(annotation: AnnotationDto, vonGeraet: string)

// Annotation aktualisiert
AnnotationUpdated(annotationId: string, changes: AnnotationPatchDto, vonGeraet: string)

// Annotation gelöscht
AnnotationDeleted(annotationId: string, vonGeraet: string)

// Presence-Update
PresenceUpdated(activeUserCount: int, sichtbareMitglieder?: string[])

// Sync-Fehler (z.B. Konflikt nicht auflösbar)
SyncError(annotationId: string, fehler: string)
```

### 4.2 Annotation-DTO

```json
{
  "id": "uuid",
  "stimme_id": "uuid",
  "seite_nr": 2,
  "sichtbarkeit": "stimme",  // "privat" | "stimme" | "orchester"
  "typ": "stift",            // "stift" | "text" | "textmarker" | "stempel" | "highlight"
  "svg_daten": "<path d='...'/>",
  "position_x_pct": 0.342,  // relative Position (0..1)
  "position_y_pct": 0.127,
  "erstellt_am": "2026-03-29T18:00:00.000Z",
  "geaendert_am": "2026-03-29T18:00:05.000Z",
  "geraet_id": "uuid",
  "nutzer_id": "uuid"
}
```

### 4.3 REST-Endpunkte (initialer Lade-Sync)

```
GET /api/v1/kapellen/{id}/stuecke/{stueckId}/annotationen
    ?stimme_id={id}
    &sichtbarkeit=stimme,orchester  // privat: nur eigene
    &seit_version={version}         // Delta-Sync
    → { annotationen: [...], version: 12350 }

POST /api/v1/kapellen/{id}/stuecke/{stueckId}/annotationen
     Body: AnnotationDto
     → 201 Created mit vollständiger Annotation

PATCH /api/v1/kapellen/{id}/stuecke/{stueckId}/annotationen/{annotationId}
      Body: AnnotationPatchDto
      → 200 OK

DELETE /api/v1/kapellen/{id}/stuecke/{stueckId}/annotationen/{annotationId}
       → 204 No Content
```

---

## 5. Datenmodell

### 5.1 Erweiterungen der bestehenden Annotations-Tabelle (MS1)

```sql
-- Bestehende Tabelle aus MS1 (annotationen) bekommt:
ALTER TABLE annotationen
  ADD COLUMN sync_version     BIGINT      NOT NULL DEFAULT 0,
  ADD COLUMN geloescht_am     TIMESTAMPTZ,      -- Soft-Delete für Sync
  ADD COLUMN geloescht_von    UUID REFERENCES nutzer(id);

-- Index für Delta-Sync
CREATE INDEX idx_annotationen_sync ON annotationen (
  stimme_id, sichtbarkeit, sync_version
) WHERE geloescht_am IS NULL;
```

### 5.2 Operations-Log (für Offline-Queue-Replay)

```sql
CREATE TABLE annotation_operations (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  annotation_id   UUID        NOT NULL,
  kapelle_id      UUID        NOT NULL REFERENCES kapellen(id),
  stimme_id       UUID,
  operation       TEXT        NOT NULL,   -- 'add', 'update', 'delete'
  nutzer_id       UUID        NOT NULL REFERENCES nutzer(id),
  geraet_id       UUID        NOT NULL REFERENCES nutzer_geraete(id),
  payload         JSONB       NOT NULL,
  timestamp_utc   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  verarbeitet     BOOLEAN     NOT NULL DEFAULT FALSE,
  
  INDEX idx_ann_ops_stimme_ts (stimme_id, timestamp_utc)
);
-- Retention: Operationen nach 24h löschen (nicht für History gedacht)
```

---

## 6. Konflikt-Behandlung

### 6.1 Strategie: Last-Operation-Wins

```
Gerät A löscht Annotation X @ T=100
Gerät B aktualisiert Annotation X @ T=99

Server empfängt beide:
  Delete T=100 > Update T=99 → Delete gewinnt
  Annotation X ist gelöscht

Alternativ:
Gerät A: Update annotation.color = "red"  @ T=100
Gerät B: Update annotation.position = (x,y) @ T=101

→ Patch auf Feldebene: beide Patches angewendet
  (color = "red", position = (x,y)) — kein Verlust
```

### 6.2 Operationale Reihenfolge (Online)

Wenn beide Geräte online sind und gleichzeitig annotieren:
- Beide senden über SignalR Hub
- Server serialisiert via sequenzieller Hub-Verarbeitung (kein echtes paralleles Problem)
- Broadcast an alle anderen Clients in Reihenfolge des Eintreffens

### 6.3 Offline-Queue-Replay

```
1. Client wiederverbindet
2. Client sendet: "Ich hatte letzte Version X, hier meine Offline-Ops seit X"
3. Server: Ops seitdem bestimmen + Client-Ops einarbeiten
4. Konflikte: Neuerer Timestamp gewinnt pro Feld
5. Server broadcastet resultierende Änderungen an alle verbundenen Clients
6. Client erhält seine eigene Ops zurück als Bestätigung (Idempotenz-Prüfung)
```

---

## 7. Edge Cases & Fehlerszenarien

### 7.1 Musiker wechselt Stimme während Sync
- **Szenario:** Musiker ist in Stimmen-Channel „2. Klarinette" und wechselt zu „1. Klarinette".
- **Verhalten:** LeaveStimme(2. Klarinette) → JoinStimme(1. Klarinette). Keine Annotationen der alten Stimme mehr empfangen. Nahtlos.

### 7.2 Dirigent sendet 50 Orchester-Annotationen schnell hintereinander
- **Szenario:** Dirigent markiert schnell alle 16 Takte einer Wiederholung.
- **Verhalten:** Batching: 50 Annotationen werden in max. 5 Batches gebündelt übertragen. Clients verarbeiten Queue sequenziell, kein Frame-Drop. Maximale Latenz: 2s bis alle sichtbar.

### 7.3 Annotation auf Seite die ein Gerät nicht geöffnet hat
- **Szenario:** Dirigent markiert Seite 5, Musiker hat Seite 2 geöffnet.
- **Verhalten:** Annotation wird empfangen und lokal gespeichert, aber nicht angezeigt. Wenn Musiker zu Seite 5 navigiert, erscheint sie sofort aus lokalem Cache.

### 7.4 Gelöschter Nutzer hat Annotationen
- **Szenario:** Kapellenmitglied wird entfernt, hinterlässt Stimmen-Annotationen.
- **Verhalten:** Annotationen bleiben (anonymisiert: nutzer_id auf null setzen). Stimmen-Annotationen bleiben sichtbar. Nur Orchester-Annotationen können nach Ermessen des Dirigenten einzeln gelöscht werden.

### 7.5 Hub-Verbindung unterbrochen kurz (< 10s)
- **Szenario:** Kurzes WLAN-Flackern.
- **Verhalten:** Automatisches Reconnect (SignalR Reconnect-Policy: 3 Versuche, exponentielles Backoff 1s/3s/10s). Verpasste Operationen werden per Delta-Sync beim Reconnect nachgeholt.

### 7.6 Sehr alte Offline-Annotationen (> 7 Tage)
- **Szenario:** Musiker war 2 Wochen offline, stellt Verbindung her.
- **Verhalten:** Operations-Log auf Server nur 24h. Für sehr alte Offline-Daten: Client führt Full-Pull der aktuellen Annotationen durch (kein Delta mehr möglich). Offline-Queue wird verworfen mit Warnung „Ältere Annotationen konnten nicht synchronisiert werden".

---

## 8. Abhängigkeiten

### 8.1 Blockierende Abhängigkeiten

| Feature | Warum | Meilenstein |
|---------|-------|-------------|
| Annotationen MS1 (#38) | Schema, Sichtbarkeitsregeln, Client-Zeichenwerkzeuge | MS1 |
| Auth + SignalR (MS1 Backend) | Hub-Infrastruktur, JWT-Auth für Hub | MS1 |
| Kapellenverwaltung + Rollen (MS1) | Wer darf Orchester-Annotation schreiben/lesen | MS1 |
| Stimmenauswahl (MS1) | Welche Stimmen-Channel der Musiker beitreten soll | MS1 |

### 8.2 Parallele MS3-Features

| Feature | Beziehung |
|---------|-----------|
| Cloud-Sync (MS3) | Gleiche Sync-Infrastruktur, aber separater Hub + separates Schema |
| Echtzeit-Metronom (MS3) | Gleiche SignalR-Infrastruktur, separater Hub |

---

## 9. Definition of Done

### Funktional
- [ ] US-01: Stimmen-Annotationen in Echtzeit (≤ 500ms)
- [ ] US-02: Orchester-Annotationen in Echtzeit (≤ 500ms)
- [ ] US-03: Offline-Queue funktioniert (alle Op-Typen)
- [ ] US-04: Presence-Indicator angezeigt
- [ ] Alle AC-01 bis AC-10 erfüllt und gemessen

### Qualität
- [ ] Unit-Tests: Konflikt-Auflösung (Last-Operation-Wins, 15+ Szenarien)
- [ ] Integration-Tests: 2-Gerät-Sync (Add/Update/Delete)
- [ ] Integration-Tests: Offline → Reconnect → Queue-Replay
- [ ] Load-Test: 20 gleichzeitige Annotierungen
- [ ] Test: Privat-Annotationen werden nicht übertragen
- [ ] Code Coverage ≥ 80%

### UX
- [ ] UX-Review durch Wanda abgenommen
- [ ] Presence-Indicator korrekt angezeigt (Datenschutz: keine Namen by Default)
- [ ] Keine sichtbaren Konflikte / Duplikate in der UI

### Deployment
- [ ] SignalR Hub `/hubs/annotationen` deployed und erreichbar
- [ ] Retention-Job für annotation_operations (24h) eingerichtet
- [ ] Swagger-Dokumentation für REST-Endpunkte
