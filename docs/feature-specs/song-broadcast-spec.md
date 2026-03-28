# Feature-Spezifikation: Song-Broadcast / Dirigenten-Mastersteuerung

> **Issue:** TBD  
> **Meilenstein:** MS2  
> **Autor:** Hill (Product Manager)  
> **Datum:** 2025-03-28  
> **Status:** Draft  
> **Abhängigkeiten:** #15 (Kapellenverwaltung), #25 (Spielmodus), SignalR-Setup  
> **Blocked by:** —  
> **UX-Referenz:** `docs/ux-design.md` (pending)

---

## 1. Feature-Überblick

### Beschreibung

Die **Dirigenten-Mastersteuerung** ist das zentrale Echtzeit-Koordinationswerkzeug für Proben und Konzerte. Sie ermöglicht es dem Dirigenten, ein Stück auf seinem Gerät auszuwählen — und **alle verbundenen Musiker-Tablets öffnen automatisch die richtige Stimme** dieses Stücks. Keine manuelle Navigation mehr, keine Verzögerung, keine Fehlgriffe.

**Das Problem:** In traditionellen Proben muss der Dirigent ansagen: „Wir spielen Stück 7, Radetzky-Marsch". Jeder Musiker blättert dann manuell durch seine Noten. Das kostet Zeit, führt zu Fehlern (falsches Stück, falsche Stimme), und unterbricht den Flow.

**Die Lösung:** Der Dirigent tippt auf sein Tablet → alle Musiker sehen sofort die richtigen Noten. **Broadcast-First-Prinzip:** Ein Tap, viele Geräte, Null Verzögerung.

### 1.1 Ziel

Ein Dirigent soll eine Probe oder ein Konzert dirigieren können, ohne dass Musiker ihre Geräte manuell bedienen müssen. Alle Seitenwechsel, Stückwechsel und Korrekturen werden zentral gesteuert. Die Musiker können sich vollständig auf das Spielen konzentrieren.

### 1.2 Scope MS2

| Im Scope | Außerhalb Scope (MS3+) |
|----------|------------------------|
| Dirigent wählt Stück → Broadcast an alle | Metronom-Sync (MS3) |
| SignalR WebSocket für Echtzeit-Übertragung | Tempo-Anzeige |
| Verbundene-Musiker-Zähler | Video-Sync |
| Auto-Reconnect bei Verbindungsverlust | Face-Gesten |
| Stimmen-Mapping (Musiker → Stimme) | Seitenblättern-Broadcast (MS3) |
| Session-Verwaltung (Start/Stop) | Multi-Dirigent-Modus |
| Fallback für fehlende Stimmen | Recording / Playback |
| Latenz-Anzeige (Dirigent → Musiker) | MIDI-Integration |
| Session-Historie (letztes Stück) | Annotation-Broadcast |

### 1.3 Kontext & Marktdifferenzierung

**Alleinstellungsmerkmal:** Kein bekannter Wettbewerber (forScore, MobileSheets, Konzertmeister, BAND) bietet eine vollwertige Dirigenten-Mastersteuerung mit Echtzeit-Broadcast. MobileSheets hat experimentelle „Master-Slave"-Features, aber keine konsistente Implementierung.

**Technologie:** SignalR (WebSocket-basiert) sorgt für <500ms Latenz vom Dirigenten-Tap bis zur Anzeige auf Musiker-Tablets. Automatische Fallback auf Long-Polling bei Netzwerkproblemen.

### 1.4 Performance-Ziele

| Metrik | Ziel | Kritisch |
|--------|------|----------|
| Latenz (Dirigent → Musiker) | < 500ms | < 1000ms |
| Max. verbundene Musiker | 120 gleichzeitig | 60 gleichzeitig |
| Reconnect-Zeit | < 3 Sekunden | < 10 Sekunden |
| Message-Throughput | 1000 msg/s | 500 msg/s |
| Heartbeat-Intervall | 10 Sekunden | 30 Sekunden |

---

## 2. User Stories

### US-01: Broadcast-Session starten

**Als** Dirigent  
**möchte ich** eine Broadcast-Session für meine Kapelle starten  
**damit** ich die Noten aller Musiker zentral steuern kann.

**Akzeptanzkriterien:**
- [ ] AC-01: Dirigent kann im Kapellen-Kontext auf "Broadcast starten" tippen (Bottom-Navigation → Dirigenten-Steuerung)
- [ ] AC-02: Nach Start erscheint die Mastersteuerung-Ansicht mit Stückliste (aus aktiver Setlist oder Gesamtbibliothek)
- [ ] AC-03: Oben wird angezeigt: "🎺 Broadcast aktiv — 0 Musiker verbunden"
- [ ] AC-04: Session wird in DB gespeichert mit Status `active` (Tabelle `BroadcastSession`)
- [ ] AC-05: Nur **ein** Dirigent kann pro Kapelle gleichzeitig eine aktive Session haben — wenn bereits eine läuft → Fehlermeldung "Es läuft bereits eine Session von [Dirigent-Name]. Möchtest du diese übernehmen?" mit "Ja" (forciert Stop der alten Session) oder "Abbrechen"
- [ ] AC-06: Session-Start wird als SignalR-Nachricht `SessionStarted` an alle Musiker der Kapelle gebroadcastet
- [ ] AC-07: Musiker erhalten eine Push-Benachrichtigung "Probe gestartet von [Dirigent-Name]" mit "Jetzt beitreten"-Button
- [ ] AC-08: Session bleibt aktiv, bis Dirigent sie explizit beendet oder 30 Minuten Inaktivität vergangen sind
- [ ] AC-09: **Fehlerfall:** Wenn Netzwerkverbindung fehlt → Fehlermeldung "Keine Verbindung zum Server. Broadcast kann nicht gestartet werden."

---

### US-02: Musiker treten Session bei

**Als** Musiker  
**möchte ich** der aktiven Broadcast-Session meiner Kapelle beitreten  
**damit** ich zentral gesteuerte Noten empfange.

**Akzeptanzkriterien:**
- [ ] AC-10: Wenn eine aktive Session läuft, erscheint in der App ein Banner: "🎺 Probe aktiv — Jetzt beitreten"
- [ ] AC-11: Tap auf Banner → Musiker tritt Session bei → Vollbild-Spielmodus öffnet sich
- [ ] AC-12: Beim Beitreten wird automatisch das aktuell aktive Stück der Session geladen (falls bereits ein Stück ausgewählt wurde)
- [ ] AC-13: Verbindung erfolgt über SignalR Hub `/hubs/broadcast` — Methode: `JoinSession(kapelleId, musikerId)`
- [ ] AC-14: Server antwortet mit aktuellem Session-State: `{ currentSongId, currentPage, connectedCount }`
- [ ] AC-15: Musiker-Gerät registriert einen Connection-Handler für `SongChanged`, `PageChanged` (MS3), `SessionEnded`
- [ ] AC-16: Beim erfolgreichen Beitritt wird der Verbundene-Musiker-Zähler auf dem Dirigenten-Gerät inkrementiert
- [ ] AC-17: **Fehlerfall:** Wenn Musiker keine Stimme für sein Instrument in der Kapelle hat → Fehlermeldung "Du hast noch keine Stimme zugeordnet. Bitte wende dich an deinen Admin oder Notenwart."
- [ ] AC-18: **Fehlerfall:** Wenn Session nicht mehr existiert (beendet) → Fehlermeldung "Die Probe wurde beendet."

---

### US-03: Dirigent wählt Stück → Broadcast an alle

**Als** Dirigent  
**möchte ich** ein Stück auswählen und alle verbundenen Musiker zeigen automatisch die richtige Stimme  
**damit** wir sofort spielen können ohne manuelle Navigation.

**Akzeptanzkriterien:**
- [ ] AC-19: Dirigent sieht in der Mastersteuerung eine scrollbare Liste aller Stücke (Setlist oder Bibliothek — filterbar)
- [ ] AC-20: Tap auf ein Stück → Stück wird als aktiv markiert → SignalR-Broadcast `BroadcastSong(songId)` an alle verbundenen Musiker
- [ ] AC-21: **Latenz-Ziel:** < 500ms vom Dirigenten-Tap bis zur Anzeige auf Musiker-Geräten (gemessen End-to-End)
- [ ] AC-22: Auf jedem Musiker-Gerät wird die **passende Stimme** des Stücks geladen — basierend auf der Standard-Stimme des Musikers (aus Kapellenverwaltung → Mitgliederprofil)
- [ ] AC-23: Stimmen-Mapping-Logik: Musiker mit Instrument "Trompete 1" → Stück hat Stimme "Trompete 1" → diese Stimme wird geladen
- [ ] AC-24: **Fallback:** Wenn Stück keine passende Stimme hat → Anzeige "Keine Stimme für [Instrument] vorhanden" mit Button "Andere Stimme wählen"
- [ ] AC-25: Dirigent sieht in Echtzeit, wie viele Musiker das Stück erfolgreich geladen haben (Indikator: "✓ 12/15 Musiker bereit")
- [ ] AC-26: Aktuelles Stück wird in DB persistiert (`BroadcastSession.aktives_stueck_id`) — bleibt bei Reconnect erhalten
- [ ] AC-27: Dirigent kann jederzeit ein anderes Stück wählen — vorheriges Stück wird geschlossen, neues geladen
- [ ] AC-28: **Fehlerfall:** Wenn Musiker offline → keine Benachrichtigung, aber Zähler zeigt nur Online-Musiker
- [ ] AC-29: **Fehlerfall:** Wenn Stück keine Noten hat → Fehlermeldung auf Musiker-Gerät "Noten für dieses Stück sind noch nicht verfügbar"

---

### US-04: Verbundene-Musiker-Zähler & Live-Status

**Als** Dirigent  
**möchte ich** in Echtzeit sehen, wie viele Musiker verbunden sind  
**damit** ich weiß, ob alle bereit sind.

**Akzeptanzkriterien:**
- [ ] AC-30: Mastersteuerung zeigt oben prominent: "🎺 12 Musiker verbunden"
- [ ] AC-31: Zähler aktualisiert sich automatisch bei jedem Join/Leave — keine manuelle Aktualisierung nötig
- [ ] AC-32: Tap auf Zähler → öffnet Liste aller verbundenen Musiker mit Namen, Instrument und "Bereit"-Status
- [ ] AC-33: Bereit-Status zeigt an, ob Musiker das aktuelle Stück erfolgreich geladen haben (✓ grün = bereit, ⏳ gelb = lädt, ✗ rot = Fehler)
- [ ] AC-34: Liste sortiert nach Register (wie in Kapellenverwaltung definiert)
- [ ] AC-35: Dirigent kann einzelne Musiker antippen → zeigt Details: Verbindungsqualität (Latenz in ms), letztes geladenes Stück
- [ ] AC-36: **Fehlerfall:** Wenn Musiker die Verbindung verliert → Zähler dekrementiert sofort, Musiker erscheint in Liste als "Offline" (grau)
- [ ] AC-37: **Performance:** Zähler-Update darf max. 100ms Verzögerung haben (gemessen ab Server-Event)

---

### US-05: Auto-Reconnect bei Verbindungsverlust

**Als** Musiker  
**möchte ich** bei kurzzeitigem Verbindungsverlust automatisch wieder zur Session verbunden werden  
**damit** ich nicht manuell neu beitreten muss.

**Akzeptanzkriterien:**
- [ ] AC-38: Bei Verbindungsverlust (Disconnect-Event) versucht Client automatisch Reconnect — max. 5 Versuche mit exponentiell steigendem Intervall (2s, 4s, 8s, 16s, 32s)
- [ ] AC-39: Während Reconnect-Versuchen zeigt App ein diskretes Symbol in der oberen rechten Ecke: "🔄 Verbinde neu..."
- [ ] AC-40: Bei erfolgreichem Reconnect: Client ruft `JoinSession` automatisch erneut auf → erhält aktuellen Session-State
- [ ] AC-41: Wenn Session-State sich während Offline-Zeit geändert hat (anderes Stück) → neues Stück wird automatisch geladen
- [ ] AC-42: Nach erfolgreichem Reconnect verschwindet Symbol → Musiker sieht kurze Bestätigung "✓ Verbunden"
- [ ] AC-43: **Fehlerfall:** Wenn Reconnect nach 5 Versuchen fehlschlägt → Fehlermeldung "Verbindung verloren. Bitte Netzwerk prüfen und erneut beitreten."
- [ ] AC-44: **Fehlerfall:** Wenn Session während Offline-Zeit beendet wurde → Spielmodus wird geschlossen, Hinweis "Probe wurde beendet"
- [ ] AC-45: Auto-Reconnect funktioniert auch bei Wechsel zwischen WLAN und Mobilfunk (Network-Handover)

---

### US-06: Broadcast-Session beenden

**Als** Dirigent  
**möchte ich** die Broadcast-Session explizit beenden  
**damit** Musiker wissen, dass die Probe vorbei ist.

**Akzeptanzkriterien:**
- [ ] AC-46: Dirigent kann in der Mastersteuerung auf "Session beenden" tippen (obere rechte Ecke)
- [ ] AC-47: Vor dem Beenden: Bestätigungsdialog "Möchtest du die Probe beenden? Alle verbundenen Musiker werden getrennt."
- [ ] AC-48: Nach Bestätigung: SignalR-Broadcast `SessionEnded` an alle verbundenen Musiker
- [ ] AC-49: Session-Status in DB wird auf `ended` gesetzt mit Timestamp
- [ ] AC-50: Alle Musiker-Geräte schließen den Spielmodus automatisch und kehren zur Bibliotheksansicht zurück
- [ ] AC-51: Musiker sehen eine Benachrichtigung: "Probe beendet von [Dirigent-Name]. Danke fürs Mitmachen!"
- [ ] AC-52: Session-Historie wird gespeichert: Dauer, Anzahl verbundener Musiker, gespielte Stücke (für spätere Statistiken — MS3+)
- [ ] AC-53: Nach Beenden kann derselbe oder ein anderer Dirigent sofort eine neue Session starten
- [ ] AC-54: **Fehlerfall:** Wenn Dirigent App schließt ohne Session zu beenden → Auto-Timeout nach 30 Minuten Inaktivität

---

### US-07: Fallback für fehlende Stimmen

**Als** Musiker  
**möchte ich** benachrichtigt werden, wenn ein Stück keine Stimme für mein Instrument hat  
**damit** ich weiß, dass ich eine andere Stimme wählen muss.

**Akzeptanzkriterien:**
- [ ] AC-55: Wenn Dirigent ein Stück broadcastet und Musiker hat keine passende Stimme → App zeigt Fallback-Screen
- [ ] AC-56: Fallback-Screen zeigt: "❌ Keine Stimme für [Instrument] in diesem Stück" + Liste aller verfügbaren Stimmen
- [ ] AC-57: Musiker kann manuell eine Stimme aus der Liste wählen → diese wird geladen und angezeigt
- [ ] AC-58: Gewählte Stimme wird als temporäre Präferenz gespeichert (nur für diese Session) — nicht als Standard-Stimme
- [ ] AC-59: Dirigent sieht im Musiker-Status-Indikator: "⚠️ [Musiker-Name] hat keine passende Stimme" — nicht als "bereit" markiert
- [ ] AC-60: **Edge Case:** Wenn Stück überhaupt keine Noten hat → Musiker sieht "Noten noch nicht verfügbar" ohne Auswahlmöglichkeit
- [ ] AC-61: **Performance:** Fallback-Logik darf nicht die Latenz für Musiker mit passender Stimme erhöhen

---

## 3. Akzeptanzkriterien (Feature-Level)

Diese Kriterien gelten übergreifend für das gesamte Song-Broadcast-Feature:

| ID | Kriterium | Testbar durch |
|----|-----------|---------------|
| AC-62 | End-to-End-Latenz (Dirigent-Tap → Musiker-Anzeige) < 500ms bei 60 verbundenen Musikern | Performance-Test: Stopwatch + Netzwerk-Monitoring |
| AC-63 | Max. 120 gleichzeitige Verbindungen ohne Performance-Degradation | Load-Test: 120 Clients verbinden, Stück broadcasen |
| AC-64 | Reconnect erfolgt innerhalb von 3 Sekunden nach Verbindungsverlust | Integration-Test: Verbindung kappen, Timer messen |
| AC-65 | SignalR-Nachrichten werden garantiert zugestellt (At-Least-Once Delivery) | E2E-Test: Nachricht senden, Client-ACK prüfen |
| AC-66 | Heartbeat-Intervall 10 Sekunden — inaktive Verbindungen werden nach 30s getrennt | Unit-Test: Mock-Timer, Connection-State prüfen |
| AC-67 | Session-State persistiert in DB — bei Server-Neustart wird Session wiederhergestellt | Integration-Test: Server neustarten, Session-State abrufen |
| AC-68 | Nur Benutzer mit Rolle "Dirigent" oder "Admin" können Broadcast-Session starten | API-Test: Auth-Token prüfen, 403 Forbidden für Musiker |
| AC-69 | Session-Kollision wird verhindert: Max. 1 aktive Session pro Kapelle | API-Test: Zwei parallele Session-Starts → zweiter erhält Konflikt-Meldung |
| AC-70 | Fallback auf Long-Polling wenn WebSocket fehlschlägt | Integration-Test: WebSocket blockieren, Kommunikation über Long-Polling prüfen |

---

## 4. API-Contract

### 4.1 REST-Endpunkte

**Basis-URL:** `/api/v1/broadcast`  
**Auth:** Bearer JWT (siehe Auth-Spec)  
**Content-Type:** `application/json`

#### `POST /api/v1/broadcast/sessions`

Startet eine neue Broadcast-Session.

**Authorization:** `Dirigent`, `Admin`

**Request:**
```json
{
  "kapelleId": "uuid",
  "setlistId": "uuid" // optional — wenn nicht angegeben: gesamte Bibliothek
}
```

**Response 201 Created:**
```json
{
  "sessionId": "uuid",
  "kapelleId": "uuid",
  "dirigentId": "uuid",
  "status": "active",
  "erstelltAm": "2026-03-28T14:30:00Z",
  "verbundeneMusiker": 0,
  "aktivesStückId": null
}
```

**Error 409 Conflict:**
```json
{
  "error": "SESSION_ALREADY_ACTIVE",
  "message": "Es läuft bereits eine Session von Max Mustermann",
  "activeSession": {
    "sessionId": "uuid",
    "dirigentName": "Max Mustermann",
    "gestartetAm": "2026-03-28T14:00:00Z"
  }
}
```

---

#### `GET /api/v1/broadcast/sessions/active?kapelleId={uuid}`

Gibt die aktuell aktive Session für eine Kapelle zurück.

**Authorization:** `Dirigent`, `Admin`, `Notenwart`, `Registerführer`, `Musiker`

**Response 200 OK:**
```json
{
  "sessionId": "uuid",
  "kapelleId": "uuid",
  "dirigentId": "uuid",
  "dirigentName": "Max Mustermann",
  "status": "active",
  "erstelltAm": "2026-03-28T14:30:00Z",
  "verbundeneMusiker": 12,
  "aktivesStückId": "uuid",
  "aktivesStückTitel": "Radetzky-Marsch"
}
```

**Response 404 Not Found:**
```json
{
  "error": "NO_ACTIVE_SESSION",
  "message": "Keine aktive Session für diese Kapelle"
}
```

---

#### `PUT /api/v1/broadcast/sessions/{sessionId}/song`

Ändert das aktive Stück der Session (triggert Broadcast).

**Authorization:** `Dirigent`, `Admin`

**Request:**
```json
{
  "stückId": "uuid"
}
```

**Response 200 OK:**
```json
{
  "sessionId": "uuid",
  "aktivesStückId": "uuid",
  "broadcastedAt": "2026-03-28T14:35:00Z",
  "erreichteMusikerCount": 12
}
```

**Error 404 Not Found:**
```json
{
  "error": "SONG_NOT_FOUND",
  "message": "Stück existiert nicht in der Bibliothek"
}
```

---

#### `DELETE /api/v1/broadcast/sessions/{sessionId}`

Beendet die Broadcast-Session.

**Authorization:** `Dirigent`, `Admin` (nur Session-Owner oder Admin)

**Response 204 No Content**

**Error 403 Forbidden:**
```json
{
  "error": "FORBIDDEN",
  "message": "Nur der Session-Owner oder ein Admin kann die Session beenden"
}
```

---

#### `GET /api/v1/broadcast/sessions/{sessionId}/connections`

Gibt alle verbundenen Musiker der Session zurück.

**Authorization:** `Dirigent`, `Admin`

**Response 200 OK:**
```json
{
  "sessionId": "uuid",
  "verbundeneMusiker": [
    {
      "musikerId": "uuid",
      "name": "Anna Schmidt",
      "instrument": "Trompete 1",
      "register": "Trompeten",
      "verbundenAm": "2026-03-28T14:31:00Z",
      "status": "ready",          // "ready" | "loading" | "error" | "offline"
      "letzteAktivität": "2026-03-28T14:35:00Z",
      "latenzMs": 120,
      "aktuelleStueckId": "uuid"
    }
  ],
  "totalCount": 12
}
```

---

### 4.2 SignalR Hub

**Hub-URL:** `/hubs/broadcast`  
**Transport:** WebSocket (Fallback: Server-Sent Events, Long-Polling)  
**Auth:** JWT als Query-Parameter `?access_token={jwt}`

#### Server → Client Methoden

##### `SessionStarted`

Benachrichtigt alle Musiker einer Kapelle, dass eine Session gestartet wurde.

**Payload:**
```json
{
  "sessionId": "uuid",
  "kapelleId": "uuid",
  "dirigentName": "Max Mustermann",
  "gestartetAm": "2026-03-28T14:30:00Z"
}
```

---

##### `SongChanged`

Benachrichtigt alle verbundenen Musiker über Stückwechsel.

**Payload:**
```json
{
  "sessionId": "uuid",
  "stückId": "uuid",
  "stückTitel": "Radetzky-Marsch",
  "timestamp": "2026-03-28T14:35:00Z"
}
```

**Client-Aktion:**
- Lade die Stimme des Stücks, die zum Instrument des Musikers passt
- Öffne Spielmodus mit dieser Stimme auf Seite 1
- Sende ACK an Server: `SongChangeAcknowledged(sessionId, stückId, status)`

---

##### `SessionEnded`

Benachrichtigt alle Musiker, dass die Session beendet wurde.

**Payload:**
```json
{
  "sessionId": "uuid",
  "beendetVon": "Max Mustermann",
  "beendetAm": "2026-03-28T15:00:00Z",
  "dauer": "30m"
}
```

**Client-Aktion:**
- Schließe Spielmodus
- Zeige Benachrichtigung
- Trenne Verbindung zum Hub

---

##### `ConnectionCountUpdated`

Benachrichtigt Dirigenten über Änderungen der verbundenen Musiker-Anzahl.

**Payload:**
```json
{
  "sessionId": "uuid",
  "count": 13,
  "neuVerbunden": {
    "musikerId": "uuid",
    "name": "Anna Schmidt",
    "instrument": "Trompete 1"
  } // optional — nur bei Join-Event
}
```

---

#### Client → Server Methoden

##### `JoinSession(kapelleId, musikerId)`

Musiker tritt der aktiven Session seiner Kapelle bei.

**Request:**
```json
{
  "kapelleId": "uuid",
  "musikerId": "uuid"
}
```

**Response:**
```json
{
  "sessionId": "uuid",
  "aktivesStückId": "uuid",         // null wenn noch kein Stück gewählt
  "aktivesStückTitel": "Radetzky-Marsch",
  "verbundeneMusiker": 12,
  "joinedAt": "2026-03-28T14:32:00Z"
}
```

---

##### `LeaveSession(sessionId, musikerId)`

Musiker verlässt die Session explizit.

**Request:**
```json
{
  "sessionId": "uuid",
  "musikerId": "uuid"
}
```

**Response:** ACK (no payload)

---

##### `SongChangeAcknowledged(sessionId, stückId, status)`

Client bestätigt den erfolgreichen Empfang und das Laden des neuen Stücks.

**Request:**
```json
{
  "sessionId": "uuid",
  "stückId": "uuid",
  "musikerId": "uuid",
  "status": "ready",          // "ready" | "error" | "no_voice"
  "latenzMs": 320,            // gemessene Latenz Client-seitig
  "timestamp": "2026-03-28T14:35:00.320Z"
}
```

**Response:** ACK (no payload)

---

##### `Heartbeat(sessionId, musikerId)`

Client sendet regelmäßig Heartbeat (alle 10 Sekunden).

**Request:**
```json
{
  "sessionId": "uuid",
  "musikerId": "uuid",
  "timestamp": "2026-03-28T14:35:10Z"
}
```

**Response:** ACK (no payload)

---

## 5. Datenmodell

### 5.1 Datenbank-Schema

#### Tabelle: `BroadcastSession`

Speichert aktive und beendete Broadcast-Sessions.

```sql
CREATE TABLE BroadcastSession (
    session_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kapelle_id          UUID NOT NULL REFERENCES Band(id) ON DELETE CASCADE,
    dirigent_id         UUID NOT NULL REFERENCES Musician(id) ON DELETE CASCADE,
    aktives_stueck_id   UUID NULL REFERENCES Piece(id) ON DELETE SET NULL,
    status              VARCHAR(20) NOT NULL CHECK (status IN ('active', 'ended', 'timeout')),
    erstellt_am         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    beendet_am          TIMESTAMPTZ NULL,
    dauer_minuten       INT NULL,
    
    -- Constraints
    CONSTRAINT one_active_session_per_band 
        EXCLUDE USING gist (kapelle_id WITH =, tstzrange(erstellt_am, COALESCE(beendet_am, 'infinity'::timestamptz), '[)') WITH &&)
        WHERE (status = 'active')
);

CREATE INDEX idx_broadcast_session_kapelle ON BroadcastSession(kapelle_id, status);
CREATE INDEX idx_broadcast_session_dirigent ON BroadcastSession(dirigent_id);
CREATE INDEX idx_broadcast_session_created ON BroadcastSession(erstellt_am DESC);
```

---

#### Tabelle: `BroadcastConnection`

Speichert verbundene Musiker pro Session.

```sql
CREATE TABLE BroadcastConnection (
    connection_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES BroadcastSession(session_id) ON DELETE CASCADE,
    musiker_id          UUID NOT NULL REFERENCES Musician(id) ON DELETE CASCADE,
    signalr_connection_id VARCHAR(100) NOT NULL,  -- SignalR Connection ID
    verbunden_am        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    getrennt_am         TIMESTAMPTZ NULL,
    letzter_heartbeat   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status              VARCHAR(20) NOT NULL CHECK (status IN ('connected', 'disconnected', 'timeout')),
    aktuelles_stueck_id UUID NULL REFERENCES Piece(id) ON DELETE SET NULL,
    letzte_latenz_ms    INT NULL,
    
    -- Constraints
    UNIQUE (session_id, musiker_id, status) WHERE status = 'connected'
);

CREATE INDEX idx_broadcast_connection_session ON BroadcastConnection(session_id, status);
CREATE INDEX idx_broadcast_connection_musiker ON BroadcastConnection(musiker_id);
CREATE INDEX idx_broadcast_connection_heartbeat ON BroadcastConnection(letzter_heartbeat) WHERE status = 'connected';
```

---

#### Tabelle: `BroadcastEvent`

Audit-Log für alle Broadcast-Aktionen (optional für MS2, empfohlen für Debugging).

```sql
CREATE TABLE BroadcastEvent (
    event_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id          UUID NOT NULL REFERENCES BroadcastSession(session_id) ON DELETE CASCADE,
    event_type          VARCHAR(50) NOT NULL,  -- 'song_changed', 'musiker_joined', 'musiker_left', 'session_ended'
    ausgelöst_von       UUID NOT NULL REFERENCES Musician(id) ON DELETE CASCADE,
    stueck_id           UUID NULL REFERENCES Piece(id) ON DELETE SET NULL,
    timestamp           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    payload             JSONB NULL
);

CREATE INDEX idx_broadcast_event_session ON BroadcastEvent(session_id, timestamp DESC);
CREATE INDEX idx_broadcast_event_type ON BroadcastEvent(event_type);
```

---

### 5.2 SignalR-Nachrichtenformat

Alle Nachrichten folgen diesem Schema:

```typescript
interface SignalRMessage<T> {
    type: string;              // Message Type (z.B. "SongChanged")
    sessionId: string;         // UUID der Session
    timestamp: string;         // ISO 8601 Timestamp
    payload: T;                // Typisierter Payload
}

// Beispiel: SongChanged
interface SongChangedPayload {
    stückId: string;
    stückTitel: string;
    kompositor?: string;
    dauer?: string;
}

// Beispiel: ConnectionCountUpdated
interface ConnectionCountPayload {
    count: number;
    neuVerbunden?: {
        musikerId: string;
        name: string;
        instrument: string;
    };
    getrennt?: {
        musikerId: string;
        name: string;
    };
}
```

---

## 6. Berechtigungsmatrix

| Aktion | Admin | Dirigent | Notenwart | Registerführer | Musiker |
|--------|-------|----------|-----------|----------------|---------|
| Broadcast-Session starten | ✅ | ✅ | ❌ | ❌ | ❌ |
| Broadcast-Session beenden (eigene) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Broadcast-Session beenden (fremde) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Stück auswählen & broadcasten | ✅ | ✅ | ❌ | ❌ | ❌ |
| Session beitreten (als Musiker) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Verbundene Musiker-Liste einsehen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Session-Historie einsehen | ✅ | ✅ | ❌ | ❌ | ❌ |
| Stimme manuell wechseln (im Broadcast-Modus) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Session-Statistiken einsehen | ✅ | ✅ | ❌ | ❌ | ❌ |

**Hinweise:**
- Admin kann **alle** Sessions beenden, auch fremde (für Notfälle)
- Dirigent kann **nur eigene** Sessions beenden
- Alle Rollen können einer Session als Musiker beitreten — Dirigent kann gleichzeitig steuern und selbst Noten sehen
- Registerführer haben **keine** Broadcast-Berechtigung (nur Musiker-Rolle im Broadcast)

---

## 7. Edge Cases

### 7.1 Session-Kollision: Zwei Dirigenten starten gleichzeitig

**Problem:** Zwei Dirigenten tippen zeitgleich auf "Broadcast starten" → Datenbank-Constraint `one_active_session_per_band` würde zweite Session blocken, aber beide könnten bereits UI-State haben.

**Lösung:**
1. Backend: Constraint in DB verhindert zweite Session → 409 Conflict
2. Zweiter Dirigent erhält Fehlermeldung mit Übernahme-Option
3. Bei "Übernehmen" → erste Session wird forciert beendet (`status = 'ended'`, `beendet_am = NOW()`) → zweite Session wird erstellt
4. Erster Dirigent erhält Push: "Session wurde von [Name] übernommen"

---

### 7.2 Dirigent disconnected / App-Crash

**Problem:** Dirigent verliert Verbindung oder App crashed — Session bleibt aktiv, aber kein Stück wird mehr gebroadcastet.

**Lösung:**
1. **Auto-Timeout:** Session wird nach 30 Minuten ohne Heartbeat vom Dirigenten automatisch beendet (Cronjob)
2. **Grace-Period:** Dirigent kann innerhalb von 5 Minuten reconnecten → Session bleibt erhalten
3. **Fallback-Admin:** Admin kann im Web-Dashboard aktive Sessions manuell beenden
4. **Musiker-UX:** Musiker sehen Indikator "⚠️ Dirigent offline" → können Session manuell verlassen

---

### 7.3 Musiker hat keine passende Stimme

**Problem:** Dirigent broadcastet Stück "Radetzky-Marsch" → Musiker spielt "Posaune 2" → Stück hat nur "Posaune 1" als Stimme.

**Lösung:**
1. **Fallback-Screen:** Musiker sieht "Keine Stimme für Posaune 2 vorhanden"
2. **Vorschläge:** App zeigt ähnliche Stimmen (z.B. "Posaune 1", "Posaune 3")
3. **Manuelle Wahl:** Musiker wählt Ersatz-Stimme → wird geladen
4. **Dirigent-Feedback:** Dirigent sieht in Musiker-Status "⚠️ [Name] hat keine passende Stimme" → kann nach Probe Notenwart informieren

---

### 7.4 Netzwerk-Latenz > 1000ms

**Problem:** Musiker mit schlechter Verbindung (z.B. mobiles Internet in ländlicher Region) hat >1s Latenz.

**Lösung:**
1. **Toleranz:** Broadcast funktioniert weiterhin — Musiker ist nur verzögert
2. **Visuelles Feedback:** Musiker sieht Indikator "🔄 Langsame Verbindung"
3. **Dirigent-Info:** Dirigent sieht in Musiker-Liste Latenz-Wert (z.B. "1200ms") in Rot
4. **Keine Blockierung:** Andere Musiker werden nicht verzögert — jeder Client lädt unabhängig

---

### 7.5 Stück hat keine Noten (Upload fehlt)

**Problem:** Dirigent wählt Stück aus Setlist → Stück existiert in DB, aber keine Notenblätter verknüpft.

**Lösung:**
1. **API-Validierung:** Backend prüft beim Broadcast, ob Stück Noten hat
2. **Fehler 422:** API gibt `UNPROCESSABLE_ENTITY` zurück mit Hinweis
3. **Dirigent-Feedback:** "Stück hat keine Noten. Bitte Notenwart kontaktieren."
4. **Musiker:** Erhalten keinen Broadcast → sehen weiterhin vorheriges Stück

---

### 7.6 Mehrere Geräte pro Musiker

**Problem:** Musiker hat Tablet und Handy gleichzeitig in Session eingeloggt.

**Lösung:**
1. **Erlaubt:** Beide Geräte können verbunden sein
2. **Zähler:** Dirigent sieht "12 Geräte, 11 Musiker" (Hinweis auf Duplikate)
3. **Identifikation:** `BroadcastConnection` hat `signalr_connection_id` → jedes Gerät eigene Connection
4. **Keine Konflikte:** Beide Geräte empfangen Broadcast unabhängig

---

### 7.7 Session-Start während Probe läuft

**Problem:** Musiker proben bereits mit Papier-Noten → Dirigent startet Session.

**Lösung:**
1. **Opt-In:** Musiker müssen aktiv "Beitreten" tappen → kein Force-Join
2. **Banner:** Musiker sehen Banner "Probe aktiv — Jetzt beitreten" → können ignorieren
3. **Schrittweiser Beitritt:** Nicht alle Musiker müssen sofort beitreten — Dirigent sieht Live-Count

---

## 8. Abhängigkeiten

### 8.1 Direkte Abhängigkeiten (Blocker)

| Feature | Abhängigkeit | Grund |
|---------|--------------|-------|
| Kapellenverwaltung (#15) | ✅ MS1 | Benötigt Kapellen-Kontext, Mitglieder, Stimmen-Mapping |
| Spielmodus (#25) | ✅ MS1 | Musiker müssen Noten im Vollbild sehen können |
| SignalR-Setup | ⚠️ MS2 | SignalR muss konfiguriert und getestet sein |
| Auth & JWT | ✅ MS1 | Broadcast-Session benötigt Authentifizierung |
| Noten-Import (#11) | ✅ MS1 | Stücke müssen Notenblätter haben |

### 8.2 Optionale Abhängigkeiten

| Feature | Beziehung | Hinweis |
|---------|-----------|---------|
| Setlist-Management | Empfohlen für MS2 | Dirigent kann Setlist als Stückliste nutzen |
| Push-Benachrichtigungen | Nice-to-Have | Musiker werden über Session-Start benachrichtigt |
| Metronom-Sync (MS3) | Folgt auf Broadcast | Nutzt dieselbe SignalR-Infrastruktur |

### 8.3 Infrastruktur-Anforderungen

- **SignalR Configured:** ASP.NET Core SignalR Hub registriert, CORS konfiguriert
- **WebSocket-Support:** Server muss WebSocket unterstützen (IIS 8+, Kestrel)
- **Skalierung:** Redis Backplane für Multi-Server-Setup (optional für MS2, kritisch für Produktion)
- **Monitoring:** Application Insights / Serilog für SignalR-Connection-Tracking
- **Datenbank:** PostgreSQL 14+ mit `gen_random_uuid()` und GIST Index-Support

---

## 9. Definition of Done

### 9.1 Funktional

- [ ] **DoD-01:** Dirigent kann Broadcast-Session starten → Session wird in DB persistiert
- [ ] **DoD-02:** Musiker können Session beitreten → Verbindung über SignalR Hub hergestellt
- [ ] **DoD-03:** Dirigent wählt Stück → alle verbundenen Musiker laden automatisch passende Stimme
- [ ] **DoD-04:** Verbundene-Musiker-Zähler aktualisiert sich in Echtzeit (<100ms Verzögerung)
- [ ] **DoD-05:** Auto-Reconnect funktioniert bei Verbindungsverlust (max. 5 Versuche)
- [ ] **DoD-06:** Dirigent kann Session beenden → alle Musiker werden getrennt und benachrichtigt
- [ ] **DoD-07:** Fallback-Screen für Musiker ohne passende Stimme funktioniert
- [ ] **DoD-08:** Session-Kollision wird verhindert (max. 1 aktive Session pro Kapelle)

### 9.2 Technisch

- [ ] **DoD-09:** Latenz < 500ms bei 60 verbundenen Musikern (gemessen in Load-Test)
- [ ] **DoD-10:** SignalR-Nachrichten werden garantiert zugestellt (At-Least-Once)
- [ ] **DoD-11:** API-Endpunkte entsprechen REST-Contract (Request/Response validiert)
- [ ] **DoD-12:** Datenbank-Schema deployed, Indizes erstellt, Constraints aktiv
- [ ] **DoD-13:** Integration-Tests für alle SignalR Hub-Methoden (min. 80% Coverage)
- [ ] **DoD-14:** E2E-Test: Dirigent → Stück wählen → Musiker sieht richtige Stimme
- [ ] **DoD-15:** Performance-Test: 120 Clients, 1000 msg/s, keine Timeouts
- [ ] **DoD-16:** Fehlerbehandlung: Alle Edge Cases aus §7 getestet

### 9.3 Dokumentation

- [ ] **DoD-17:** API-Dokumentation (Swagger) aktualisiert mit neuen Endpunkten
- [ ] **DoD-18:** SignalR-Nachrichten-Referenz dokumentiert (TypeScript-Interfaces)
- [ ] **DoD-19:** README mit Setup-Anleitung für SignalR (CORS, WebSocket)
- [ ] **DoD-20:** UX-Spec von Wanda abgestimmt (Mockups für Mastersteuerung)
- [ ] **DoD-21:** Admin-Guide für Troubleshooting (Session-Timeout, Reconnect)

### 9.4 Testing

- [ ] **DoD-22:** Unit-Tests für SignalR Hub-Logik (min. 90% Coverage)
- [ ] **DoD-23:** Integration-Tests für REST-API (alle Endpunkte)
- [ ] **DoD-24:** E2E-Test: Session-Start → Broadcast → Session-Ende
- [ ] **DoD-25:** Load-Test: 120 Clients, Stück broadcasten, Latenz messen
- [ ] **DoD-26:** Chaos-Test: Dirigent disconnecten während Broadcast
- [ ] **DoD-27:** Chaos-Test: Musiker reconnect während Stückwechsel
- [ ] **DoD-28:** Accessibility-Test: Screen-Reader-Kompatibilität für Dirigenten-UI

### 9.5 Berechtigungen & Sicherheit

- [ ] **DoD-29:** Nur Dirigent/Admin können Session starten (Auth-Policy)
- [ ] **DoD-30:** JWT-Token wird bei SignalR-Connection validiert
- [ ] **DoD-31:** Session-Übernahme erfordert Bestätigung (kein forcierter Abbruch ohne Warnung)
- [ ] **DoD-32:** Audit-Log für alle Broadcast-Aktionen (optional für MS2, empfohlen)

### 9.6 UX & Usability

- [ ] **DoD-33:** Dirigenten-UI zeigt Bereit-Status aller Musiker (✓/⏳/✗)
- [ ] **DoD-34:** Musiker sehen diskretes Reconnect-Symbol (keine Pop-ups)
- [ ] **DoD-35:** Fallback-Screen für fehlende Stimmen ist benutzerfreundlich
- [ ] **DoD-36:** Push-Benachrichtigung bei Session-Start (wenn App im Hintergrund)

---

## 10. Open Questions / Entscheidungen

| ID | Frage | Status | Entscheidung |
|----|-------|--------|--------------|
| Q-01 | Soll Dirigent einzelne Seiten broadcasten können (MS2 oder MS3)? | ⚠️ Open | **Entscheidung Hill:** MS3 — MS2 fokussiert auf Stückwechsel |
| Q-02 | Redis Backplane für SignalR in MS2 oder erst Produktion? | ⚠️ Open | **Vorschlag Banner:** MS2 Optional, Produktion Pflicht |
| Q-03 | Maximale Session-Dauer (30 Min. Timeout ausreichend)? | ✅ Decided | **30 Minuten** — bei längeren Proben muss Dirigent reaktivieren |
| Q-04 | Soll Musiker Broadcast temporär pausieren können (Toilette)? | ⚠️ Open | **Vorschlag Hill:** Ja, "Pause"-Button → kein Broadcast bis "Fortsetzen" |
| Q-05 | Soll Session-Historie gespeichert werden (Analytics)? | ⚠️ Open | **Vorschlag Hill:** Ja, Tabelle `BroadcastEvent` für spätere Statistiken |
| Q-06 | Soll Admin Dashboard Sessions live monitoren können? | ⚠️ Open | **Nice-to-Have** für MS2+, nicht kritisch |

---

## 11. Glossar

| Begriff | Definition |
|---------|------------|
| **Broadcast-Session** | Aktive Verbindung zwischen Dirigent und Musikern für zentralisierte Notensteuerung |
| **Mastersteuerung** | UI des Dirigenten zur Kontrolle der Broadcast-Session |
| **SignalR Hub** | Server-seitiger Endpoint für bidirektionale Echtzeit-Kommunikation |
| **Connection** | Einzelne WebSocket-Verbindung zwischen Musiker-Gerät und Server |
| **Heartbeat** | Regelmäßiges Signal vom Client an Server zur Bestätigung der Verbindung (alle 10s) |
| **Stimmen-Mapping** | Zuordnung zwischen Musiker-Instrument und Stück-Stimme |
| **Fallback-Screen** | Anzeige wenn keine passende Stimme verfügbar ist |
| **Session-Kollision** | Konflikt wenn zwei Dirigenten gleichzeitig Session starten wollen |
| **Auto-Reconnect** | Automatische Wiederherstellung der Verbindung bei Disconnect |
| **Latenz** | Zeit von Dirigenten-Aktion bis Anzeige auf Musiker-Gerät (Ziel: <500ms) |

---

**Ende der Spezifikation**

---

**Review-Kommentare:**

> *Hill:* Diese Spec ist bereit für Banner (Backend) und Romanoff (Frontend). SignalR-Setup muss parallel laufen.  
> *Nächste Schritte:* Wanda erstellt UX-Mockups für Mastersteuerung → Banner implementiert SignalR Hub → Romanoff baut Flutter-Integration.  
> *Kritischer Pfad:* SignalR-Infrastruktur muss vor Sprint-Start deployed sein, sonst Blocker.

