# Feature: Cloud-Sync Protokoll (Persönliche Sammlung)

**Datum:** 2026-03-30
**Autor:** Stark (Lead / Architect)
**Status:** Draft
**Referenz:** `docs/specs/2026-03-30-ms3-architecture.md` §4

## Kontext

Die persönliche Sammlung ("Meine Musik") wird über das Sheetstorm-Backend synchronisiert, damit Musiker ihre Noten auf allen Geräten verfügbar haben. Delta-Sync mit Versionierung minimiert Datenübertragung. Last-Write-Wins per Feld löst Konflikte automatisch.

## Anforderungen

### Must-Have
- [ ] Delta-Sync: Nur geänderte Felder übertragen
- [ ] Versionierung: Monoton steigende Version pro Nutzer
- [ ] Last-Write-Wins per Feld bei Konflikten
- [ ] Offline-Queue: Änderungen im Offline-Modus puffern
- [ ] Auto-Sync bei App-Foreground und alle 5 Minuten
- [ ] Binärdaten (Notenbilder) über S3, nicht über Sync-API

### Nice-to-Have
- [ ] Konflikt-Anzeige im UI (Toast bei überschriebener Änderung)
- [ ] Sync-History: Letzte N Sync-Operationen anzeigen
- [ ] Selektiver Sync: Nur bestimmte Stücke synchronisieren

## Technisches Design

### Versionierungs-Modell

Jeder Nutzer hat einen monoton steigenden Versions-Zähler. Jede Änderung (Push) inkrementiert die Version um 1.

```
Version 0: Initial (kein Sync)
Version 1: Stück "Polka" erstellt
Version 2: Stück "Polka" Titel geändert
Version 3: Stück "Marsch" erstellt
Version 4: Stück "Polka" Komponist geändert
...
```

### API-Spezifikation

#### GET /api/sync/state

**Response:**
```json
{
  "currentVersion": 42,
  "lastSyncAt": "2026-03-30T10:00:00Z",
  "pendingServerChanges": 3
}
```

#### POST /api/sync/pull

**Request:**
```json
{
  "sinceVersion": 38
}
```

**Response:**
```json
{
  "changes": [
    {
      "version": 39,
      "entityType": "Piece",
      "entityId": "550e8400-...",
      "operation": "Update",
      "fieldName": "title",
      "newValue": "Neue Polka",
      "changedAt": "2026-03-30T09:55:00Z"
    },
    {
      "version": 40,
      "entityType": "SheetMusic",
      "entityId": "6ba7b810-...",
      "operation": "Create",
      "fields": {
        "pieceId": "550e8400-...",
        "voiceName": "Klarinette 1",
        "instrumentType": "Bb",
        "sortOrder": 1
      },
      "changedAt": "2026-03-30T09:56:00Z"
    },
    {
      "version": 41,
      "entityType": "Piece",
      "entityId": "550e8400-...",
      "operation": "Update",
      "fieldName": "composer",
      "newValue": "Franz Lehár",
      "changedAt": "2026-03-30T09:57:00Z"
    }
  ],
  "currentVersion": 42,
  "hasMore": false
}
```

**Pagination:** Wenn `hasMore: true`, Client ruft erneut `pull` mit letzter empfangener Version auf.

#### POST /api/sync/push

**Request:**
```json
{
  "baseVersion": 42,
  "changes": [
    {
      "clientChangeId": "local-uuid-1",
      "entityType": "Piece",
      "entityId": "550e8400-...",
      "operation": "Update",
      "fieldName": "title",
      "newValue": "Polka Reloaded",
      "changedAt": "2026-03-30T10:05:00Z"
    },
    {
      "clientChangeId": "local-uuid-2",
      "entityType": "Piece",
      "entityId": null,
      "operation": "Create",
      "fields": {
        "title": "Neuer Marsch",
        "composer": "Unbekannt"
      },
      "changedAt": "2026-03-30T10:06:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "accepted": [
    {
      "clientChangeId": "local-uuid-1",
      "serverVersion": 43,
      "serverEntityId": "550e8400-..."
    },
    {
      "clientChangeId": "local-uuid-2",
      "serverVersion": 44,
      "serverEntityId": "7c9e6679-..."
    }
  ],
  "conflicts": [],
  "newVersion": 44
}
```

**Konflikt-Response (bei LWW-Verlust):**
```json
{
  "accepted": [],
  "conflicts": [
    {
      "clientChangeId": "local-uuid-1",
      "entityType": "Piece",
      "entityId": "550e8400-...",
      "fieldName": "title",
      "clientValue": "Polka Alt",
      "serverValue": "Polka Neu",
      "serverChangedAt": "2026-03-30T10:04:00Z",
      "resolution": "ServerWins"
    }
  ],
  "newVersion": 43
}
```

### Sync-Engine (Client-seitig)

```dart
class SyncEngine {
  /// Vollständiger Sync-Zyklus
  Future<SyncResult> sync() async {
    // 1. Pull: Server-Änderungen holen
    final pullResponse = await syncService.pull(sinceVersion: localVersion);

    // 2. Merge: Server-Änderungen in lokale DB anwenden
    await applyServerChanges(pullResponse.changes);

    // 3. Push: Lokale Änderungen an Server senden
    final localChanges = await getLocalPendingChanges();
    if (localChanges.isNotEmpty) {
      final pushResponse = await syncService.push(
        baseVersion: pullResponse.currentVersion,
        changes: localChanges,
      );

      // 4. Konflikte behandeln
      for (final conflict in pushResponse.conflicts) {
        await resolveConflict(conflict);
      }

      // 5. Akzeptierte Änderungen als synced markieren
      await markAsSynced(pushResponse.accepted);
    }

    // 6. Lokale Version aktualisieren
    await updateLocalVersion(pushResponse?.newVersion ?? pullResponse.currentVersion);
  }
}
```

### Offline-Queue (Drift)

```dart
// In Drift-Schema
class PendingSyncChanges extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get operation => text()();
  TextColumn get fieldName => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  DateTimeColumn get changedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Sync-fähige Entitäten und Felder

| Entität | Sync-Felder | Hinweise |
|---------|------------|----------|
| `Piece` | title, composer, arranger, genre, key, notes | Nur persönliche (Band.IsPersonal = true) |
| `SheetMusic` | voiceName, instrumentType, sortOrder | Gehört zu Piece |
| `PiecePage` | pageNumber, sortOrder, blobUrl | blobUrl → separater S3-Sync |

### Binärdaten-Sync (S3)

Notenbilder werden **nicht** über die Sync-API übertragen. Stattdessen:

1. Client lädt Bild zu S3 hoch (Pre-signed URL vom Server)
2. Sync-Changelog enthält nur die S3-URL-Änderung
3. Andere Geräte laden Bild von S3 herunter

```
Client A                    Server              S3
  │                            │                 │
  │── PUT (Pre-signed URL) ──────────────────► │
  │                            │                 │ ✓ Upload
  │── POST /sync/push ──────► │                 │
  │   { field: "blobUrl",     │                 │
  │     value: "s3://..." }   │                 │
  │                            │                 │
  │              Client B Pull:                  │
  │              blobUrl changed                 │
  │              → GET s3://... ──────────────► │
```

## File-Structure-Map

**CREATE:**
- `src/Sheetstorm.Domain/Entities/SyncVersion.cs`
- `src/Sheetstorm.Domain/Entities/SyncChangelog.cs`
- `src/Sheetstorm.Domain/Enums/SyncOperation.cs`
- `src/Sheetstorm.Domain/Sync/ISyncService.cs`
- `src/Sheetstorm.Domain/Sync/SyncModels.cs`
- `src/Sheetstorm.Infrastructure/Sync/SyncService.cs`
- `src/Sheetstorm.Infrastructure/Persistence/Configurations/SyncVersionConfiguration.cs`
- `src/Sheetstorm.Infrastructure/Persistence/Configurations/SyncChangelogConfiguration.cs`
- `src/Sheetstorm.Api/Controllers/SyncController.cs`
- `sheetstorm_app/lib/features/cloud_sync/` (gesamtes Modul)

**MODIFY:**
- `src/Sheetstorm.Domain/Entities/Musician.cs` — SyncVersion Navigation Property
- `src/Sheetstorm.Infrastructure/Persistence/AppDbContext.cs` — DbSet hinzufügen
- `src/Sheetstorm.Api/Program.cs` — DI-Registrierung

## Offene Fragen

- [ ] Sync-Limit: Maximale Anzahl Changes pro Push/Pull-Request? (Empfehlung: 500)
- [ ] Garbage Collection: Alte SyncChangelog-Einträge löschen? (Empfehlung: nach 90 Tagen)
- [ ] Kompression: Sollen Pull-Responses gzipped werden? (Empfehlung: Ja, ab >10KB)
