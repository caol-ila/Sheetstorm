# 04 — Datenmodell (initial)

Konzeptioneller Überblick. Genauer EF-Mapping in Code; hier nur die
Kern-Entitäten und Beziehungen. Felder mit `*` sind Pflicht.

## Identity & Membership

### `User` (ASP.NET Identity erweitert)
* `Id*` (Guid)
* `Email*`, `EmailConfirmed`
* `UserName*` (= Email Default)
* `DisplayName*`
* `AvatarBlobKey?`
* `PreferredCulture` (z.B. `de-DE`)
* `CreatedAt*`

Erweiterung über `IdentityUser<Guid>`.

### `Band`
* `Id*` (Guid)
* `Slug*` (eindeutig, URL-tauglich)
* `Name*`
* `Description`
* `LogoBlobKey?`
* `City`, `PostalCode`, `Country` (Default DE)
* `AssociationName` (Verbandsname)
* `OwnerId*` → `User`
* `CreatedAt*`

### `Membership`
* `Id*` (Guid)
* `BandId*` → `Band`
* `UserId*` → `User`
* `Roles*` (Flags-Set: Mitglied, Dirigent, Lehrer, Admin, Owner)
* `Status*` (`Pending`, `Active`, `Suspended`)
* `JoinedAt`
* Indizes: `(BandId, UserId)` unique.

### `BandInvitation`
* `Id*`, `BandId*`, `Email*`, `Token*` (hash), `ExpiresAt*`,
  `RolesToGrant`, `CreatedById*`, `AcceptedAt?`, `AcceptedById?`.

### `BandJoinCode`
* `Id*`, `BandId*`, `Code*` (hash), `MaxUses`, `UsesCount`,
  `ExpiresAt?`, `CreatedById*`, `Active*`.

### `MembershipInstrument`
Bevorzugte Stimme(n) eines Mitglieds.
* `Id*`, `MembershipId*`, `InstrumentId*`, `Transposition`,
  `RegisterPreference` (Reihenfolge), `IsPrimary*`.

## Notenmanagement

### `Instrument` (Stamm­daten / Taxonomie)
* `Id*`, `Family*` (Holz/Blech/Schlag/Sonst), `Name*`
  (z.B. „Klarinette"), `DefaultTransposition?`.

### `Piece` (Werk)
* `Id*`, `BandId?` (null = persönliche Bibliothek),
  `OwnerUserId?` (für persönliche), `Title*`, `Subtitle`,
  `Composer`, `Arranger`, `Publisher`, `PublisherNumber`,
  `KeySignature`, `TimeSignature`, `Tempo`, `DurationSeconds`,
  `Difficulty` (1–6), `Genre[]`, `Tags[]`, `Notes`,
  `CoverBlobKey?`, `CreatedAt*`, `UpdatedAt*`, `DeletedAt?`
  (soft delete).

### `Part` (Stimme)
* `Id*`, `PieceId*`, `InstrumentId*`, `Transposition`,
  `Register`, `DisplayName*` (z.B. „Klarinette 1 in B"),
  `OrderHint`, `Retired*`, `CreatedAt*`.

### `PartFile`
* `Id*`, `PartId*`, `Kind*` (`Pdf`, `MusicXml`, `Mp3`, `Midi`),
  `BlobKey*`, `Pages`, `SizeBytes`, `CreatedAt*`.

### `Annotation`
* `Id*`, `PartId*`, `UserId*` (oder `MembershipId?` falls geteilt
  später), `Page*`, `LayerJson*` (Vector-Strokes), `UpdatedAt*`,
  `Version*` (für LWW-Sync).

### `Collection` (Sammlung)
* `Id*`, `BandId*`, `Name*`, `Description`, `CreatedById*`.
* Linker: `CollectionPiece(CollectionId, PieceId, Position)`.

### `SetList`
* `Id*`, `BandId*`, `Name*`, `Description`, `EventId?` (gekoppelt),
  `CreatedById*`, `CreatedAt*`.
* Linker: `SetListItem(SetListId, Position, PieceId, TransitionNote,
  KeyOverride)`.

### `Playlist` (persönlich)
* `Id*`, `UserId*`, `Name*`.
* Linker: `PlaylistItem(PlaylistId, Position, PieceId)`.

### `OfflineWish`
* `Id*`, `UserId*`, `PieceId*`, `MarkedAt*`. Treibt Sync-Worker.

## OMR

### `OmrJob`
* `Id*`, `PieceId*`, `Status*` (`Queued`, `Running`, `Done`,
  `Failed`), `InputFileBlobKey*`, `Progress`, `ErrorMessage?`,
  `OutputMusicXmlBlobKey?`, `DetectedPartsJson?`, `CreatedAt*`,
  `CompletedAt?`.

## Termine

### `Event`
* `Id*`, `BandId*`, `Type*` (`Konzert`, `Probe`, `Arbeitseinsatz`,
  `Sonstiges`), `Title*`, `Description`, `Location`,
  `LocationMapUrl`, `StartUtc*`, `EndUtc*`, `MeetUtc?`,
  `DressCode`, `SetListId?`, `RecurrenceRule?` (RRULE),
  `CreatedById*`, `Cancelled?`.

### `EventAttendance`
* `Id*`, `EventId*`, `UserId*`, `Status*` (`Yes`, `No`, `Maybe`,
  `Unknown`), `Reason`, `RespondedAt?`.

### `EventShift` (Arbeitseinsatz)
* `Id*`, `EventId*`, `Title*`, `StartUtc*`, `EndUtc*`,
  `RequiredCount`.
* Linker: `ShiftAssignment(ShiftId, UserId)`.

### `EventAttachment`
* `Id*`, `EventId*`, `BlobKey*`, `FileName*`, `Kind`.

## Conductor Sync

### `EventSyncSession`
* `Id*`, `EventId*`, `PublicKey*` (Ed25519), `EncryptedPrivateKey*`
  (verschlüsselt mit Server-Master-Key, Dirigent-Geräte
  decrypten via PKCE-Token o.ä.), `StartedAt*`, `EndedAt?`.

### `EventSyncEvent` (Audit + Fallback-Stream)
* `Id*`, `SessionId*`, `Kind*` (`PieceOpened`, `PageTurned`,
  `Stopped`), `PayloadJson*`, `OccurredAt*`.

## Audit & Notification

### `AuditLog`
* `Id*`, `BandId?`, `ActorUserId*`, `Action*`, `EntityType*`,
  `EntityId?`, `MetadataJson?`, `OccurredAt*`.

### `NotificationOutbox`
* `Id*`, `UserId*`, `Channel*` (`Push`, `Email`), `PayloadJson*`,
  `ScheduledAt*`, `SentAt?`, `Failures`, `LastError?`.

## Indizes / Performance-Hinweise

* Volltext: `Piece.Title`, `Composer`, `Tags` → PostgreSQL `tsvector`
  generated column, GIN-Index.
* `Membership(BandId, UserId)` unique.
* `Annotation(PartId, UserId)` unique.
* `EventAttendance(EventId, UserId)` unique.
* `EventSyncEvent(SessionId, OccurredAt DESC)` für Stream-Read.

## Soft-Delete-Strategie
* Werke, Stimmen, Mitgliedschaften → soft delete (`DeletedAt`).
* Verein-Löschung → asynchroner Job kaskadiert hart, vorher
  Export-Pflicht.
