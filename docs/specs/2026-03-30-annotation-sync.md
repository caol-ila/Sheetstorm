# Feature: Annotationen-Sync

**Datum:** 2026-03-30
**Autor:** Stark (Lead / Architect)
**Status:** Draft
**Referenz:** `docs/specs/2026-03-30-ms3-architecture.md` §5

## Kontext

Annotationen in Sheetstorm haben drei Sichtbarkeitsebenen:
- **Privat:** Nur für den Ersteller (kein Echtzeit-Sync nötig, nur Cloud-Backup)
- **Stimme:** Alle Musiker derselben Stimme sehen und bearbeiten (Echtzeit-Sync)
- **Orchester:** Alle Musiker der Band sehen und bearbeiten (Echtzeit-Sync)

Bisher waren Annotationen rein client-seitig (Dart-Objekte in Flutter). MS3 führt serverseitige Persistierung und Echtzeit-Synchronisation ein.

## Anforderungen

### Must-Have
- [ ] Server-Persistierung aller Annotationen (alle Levels)
- [ ] Echtzeit-Sync für Stimmen- und Orchester-Annotationen via SignalR
- [ ] Offline-Fähigkeit: Lokale Annotationen funktionieren ohne Verbindung
- [ ] Konflikt-Behandlung bei gleichzeitiger Bearbeitung (LWW per Element)
- [ ] Initial-Sync: Beim Öffnen einer Seite alle Annotationen laden
- [ ] Inkrementeller Sync: Nur Änderungen seit letztem Sync

### Nice-to-Have
- [ ] Undo/Redo über Geräte hinweg (Echtzeit)
- [ ] "Wer hat was annotiert" — Autor-Info pro Element
- [ ] Annotations-Locking: Element sperren während Bearbeitung

## Technisches Design

### Warum nicht CRDT oder OT?

| Kriterium | CRDT | OT | Op-Log + LWW |
|-----------|------|----|-------------|
| Komplexität | Hoch (State-CRDT für SVG-Paths nicht trivial) | Hoch (Transformationsfunktionen) | Niedrig |
| Konflikt-Häufigkeit | Gut für häufige Konflikte | Gut für häufige Konflikte | Akzeptabel bei seltenen Konflikten |
| Payload-Größe | Groß (State-Vector bei jedem Update) | Klein (Operationen) | Klein (Operationen) |
| Passt zum Datenmodell? | Nein (SVG-Elemente sind keine konvergenten Typen) | Nein (keine lineare Sequenz) | **Ja** (unabhängige Elemente) |
| Server-Last | Niedrig (merge lokal) | Hoch (Server transformiert) | Niedrig (Server speichert + broadcastet) |

**Entscheidung: Op-Log mit LWW per Element.** Annotationen sind unabhängige grafische Elemente. Zwei Musiker bearbeiten selten dasselbe Element gleichzeitig. Wenn doch, ist der Verlust eines einzelnen Strichs akzeptabel.

### Datenmodell

**Annotation (Container):**
- Gruppiert Elemente pro Seite und Sichtbarkeitsebene
- Eine Annotation pro `(PiecePageId, Level, VoiceId?)` Kombination

**AnnotationElement (Einzelnes grafisches Element):**
- Strich (Pencil/Highlighter): Points + BBox + Style
- Text: BBox + Text-Inhalt
- Stempel: BBox + StampCategory + StampValue
- Versioniert: `Version` Feld inkrementiert bei jeder Änderung
- Soft-Delete: `IsDeleted` Flag statt physischem Löschen (für Sync-Konsistenz)

### SignalR-Gruppierung

```
Stimmen-Annotationen:
  Gruppe: "annotation-voice-{bandId}-{voiceId}-{piecePageId}"
  Mitglieder: Alle Musiker mit dieser Stimme in dieser Band

Orchester-Annotationen:
  Gruppe: "annotation-orchestra-{bandId}-{piecePageId}"
  Mitglieder: Alle Musiker dieser Band

Private Annotationen:
  Keine SignalR-Gruppe (nur REST-Backup)
```

### Sync-Flows

#### Flow 1: Musiker A zeichnet Stimmen-Annotation

```
Musiker A (Klarinette 1)           Server              Musiker B (Klarinette 1)
         │                            │                          │
         │ commitStroke()              │                          │
         │ → Lokal in State            │                          │
         │                             │                          │
         │── POST /elements ─────────►│                          │
         │   { tool: "Pencil",        │                          │
         │     points: [...],         │                          │
         │     level: "Voice" }       │                          │
         │                             │                          │
         │◄── { id: "...",            │                          │
         │      version: 1 } ────────│                          │
         │                             │                          │
         │                             │── OnElementAdded ──────►│
         │                             │   { element: {...} }     │
         │                             │                          │
         │                             │               In State einfügen
         │                             │               UI aktualisiert
```

#### Flow 2: Gleichzeitige Bearbeitung (Konflikt)

```
Musiker A                        Server                    Musiker B
    │                               │                          │
    │ Edit Element X                │                 Edit Element X
    │ (version: 5)                  │                 (version: 5)
    │                               │                          │
    │── PUT element X ────────────►│                          │
    │   { version: 5,              │                          │
    │     changedAt: 10:00:05 }    │                          │
    │                               │                          │
    │◄── { version: 6 } ──────────│                          │
    │                               │── OnElementUpdated ─────►│
    │                               │                          │
    │                               │◄── PUT element X ───────│
    │                               │   { version: 5,          │
    │                               │     changedAt: 10:00:03 }│
    │                               │                          │
    │                               │   Conflict: B's version (5)
    │                               │   != server version (6)
    │                               │                          │
    │                               │── 409 Conflict ─────────►│
    │                               │   { serverVersion: 6,    │
    │                               │     serverData: {...} }  │
    │                               │                          │
    │                               │            Client B übernimmt
    │                               │            Server-Version
```

**Konflikt-Auflösung:** Server prüft `version` im Request. Wenn `version != aktuelle Server-Version`, wird 409 zurückgegeben mit aktuellen Server-Daten. Client übernimmt Server-Version und kann erneut versuchen.

### API-Endpunkte

```
# Annotationen für eine Seite laden (mit Level-Filter)
GET  /api/bands/{bandId}/annotations/{piecePageId}
     ?level=Voice&voiceId={voiceId}
     Response: AnnotationWithElementsDto[]

# Element erstellen
POST /api/bands/{bandId}/annotations/{annotationId}/elements
     Body: CreateAnnotationElementDto
     Response: 201 + AnnotationElementDto

# Element aktualisieren
PUT  /api/bands/{bandId}/annotations/{annotationId}/elements/{elementId}
     Body: UpdateAnnotationElementDto (muss version enthalten)
     Response: 200 + AnnotationElementDto
     Error: 409 bei Versions-Konflikt

# Element löschen (Soft-Delete)
DELETE /api/bands/{bandId}/annotations/{annotationId}/elements/{elementId}
     Response: 204

# Bulk-Sync (Initial Load oder nach Offline-Phase)
POST /api/bands/{bandId}/annotations/{piecePageId}/sync
     Body: { sinceVersion: 42, level: "Voice", voiceId: "..." }
     Response: { elements: [...], currentVersion: 47 }

# Persönliche Annotationen (kein Band-Scope)
GET  /api/annotations/personal/{piecePageId}
POST /api/annotations/personal/{piecePageId}/elements
PUT  /api/annotations/personal/elements/{elementId}
DELETE /api/annotations/personal/elements/{elementId}
```

### SignalR Hub

```csharp
[Authorize]
public class AnnotationSyncHub(IAnnotationSyncService syncService) : Hub
{
    // ── Client → Server ──

    /// Tritt einer Annotations-Gruppe bei (Voice oder Orchestra)
    Task JoinAnnotationGroup(Guid bandId, Guid piecePageId, string level, Guid? voiceId);

    /// Verlässt eine Annotations-Gruppe
    Task LeaveAnnotationGroup(Guid bandId, Guid piecePageId, string level, Guid? voiceId);

    /// Informiert andere über neue/geänderte/gelöschte Elemente
    /// (Redundant zum REST-Call — dient als schnelle Benachrichtigung)
    Task NotifyElementChange(ElementChangeNotification notification);

    // ── Server → Client ──

    // OnElementAdded(AnnotationElementDto element)
    // OnElementUpdated(AnnotationElementDto element)
    // OnElementDeleted(Guid elementId, Guid annotationId)
}
```

**Architektur-Hinweis:** Der REST-Call ist die "Source of Truth" für Persistierung. Der SignalR-Broadcast ist ein Performance-Shortcut für Echtzeit-Updates. Wenn ein Client den SignalR-Broadcast verpasst (Verbindungsabbruch), holt er sich die Daten beim nächsten Bulk-Sync.

### Erweiterung des bestehenden Flutter-Moduls

Die bestehende `Annotation`-Klasse (Dart) bleibt strukturell gleich. Änderungen:

1. **ID-Management:** `id` wird zur Server-synced UUID (bisher lokal generiert — bleibt so, Server akzeptiert Client-UUIDs)
2. **Version-Feld:** Neues `int version` Feld auf jedem Element
3. **Sync-Hook im Notifier:** `commitStroke()`, `addTextAnnotation()`, `addStampAnnotation()`, `eraseAt()` lösen bei `level != private` einen REST-Call + SignalR-Notify aus
4. **Neuer `AnnotationSyncNotifier`:** Verwaltet SignalR-Verbindung, empfängt Remote-Änderungen, merged sie in den lokalen State

```dart
// Erweiterung in annotation_notifier.dart
void commitStroke({
  required List<StrokePoint> points,
  required AnnotationLevel level,
  // ... bestehende Parameter
}) {
  final annotation = Annotation(/* ... bestehende Logik */);
  state = state.copyWith(annotations: [...state.annotations, annotation]);

  // NEU: Sync-Hook
  if (level != AnnotationLevel.private) {
    ref.read(annotationSyncNotifierProvider.notifier)
        .pushElement(annotation, AnnotationOperation.add);
  }
}
```

## File-Structure-Map

**CREATE:**
- `src/Sheetstorm.Domain/Entities/Annotation.cs`
- `src/Sheetstorm.Domain/Entities/AnnotationElement.cs`
- `src/Sheetstorm.Domain/Enums/AnnotationLevel.cs`
- `src/Sheetstorm.Domain/Enums/AnnotationTool.cs`
- `src/Sheetstorm.Domain/Annotations/IAnnotationSyncService.cs`
- `src/Sheetstorm.Domain/Annotations/AnnotationModels.cs`
- `src/Sheetstorm.Infrastructure/Annotations/AnnotationSyncService.cs`
- `src/Sheetstorm.Infrastructure/Persistence/Configurations/AnnotationConfiguration.cs`
- `src/Sheetstorm.Infrastructure/Persistence/Configurations/AnnotationElementConfiguration.cs`
- `src/Sheetstorm.Api/Controllers/AnnotationController.cs`
- `src/Sheetstorm.Api/Hubs/AnnotationSyncHub.cs`
- `sheetstorm_app/lib/features/annotations/application/annotation_sync_notifier.dart`
- `sheetstorm_app/lib/features/annotations/data/models/annotation_sync_models.dart`
- `sheetstorm_app/lib/features/annotations/data/services/annotation_sync_service.dart`
- `sheetstorm_app/lib/features/annotations/data/services/annotation_realtime.dart`

**MODIFY:**
- `src/Sheetstorm.Infrastructure/Persistence/AppDbContext.cs` — neue DbSets
- `src/Sheetstorm.Api/Program.cs` — Hub-Mapping + DI
- `sheetstorm_app/lib/features/annotations/application/annotation_notifier.dart` — Sync-Hooks
- `sheetstorm_app/lib/features/annotations/data/models/annotation_models.dart` — version Feld

## Offene Fragen

- [ ] Soll der Autor eines Elements sichtbar sein? (Empfehlung: Ja, als Tooltip)
- [ ] Max. Anzahl Elemente pro Seite? (Empfehlung: 1000 — danach Warnung)
- [ ] Soll es ein "Bearbeitung gesperrt"-Feature geben, damit der Dirigent allein annotieren kann? (Empfehlung: Nein für MS3, Nice-to-Have für MS5)
