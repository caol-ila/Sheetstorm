# Backend Code Review — Strange (Principal Backend Engineer)
**Datum:** 2025-07-17T00:12:00Z
**Reviewer:** Strange
**Model:** claude-opus-4.6
**Scope:** Backend (Domain, API, Infrastructure)

## Zusammenfassung

Der MS2-Backend-Code zeigt eine solide Clean-Architecture-Umsetzung mit konsistenter Service-Layer-Abstraktion und guter EF Core-Nutzung. Die Security-Basis (JWT, bcrypt, Rate Limiting, Token-Hashing) ist stark — jedoch gibt es **drei kritische Autorisierungslücken** im SignalR Hub und beim Password-Reset-Token-Handling, die vor dem Merge behoben werden müssen. Insgesamt ein beeindruckend umfangreicher Feature-Umfang für MS2 mit durchgängig sauberem Code.

## Kritische Issues (MUST FIX vor Merge)

### K1: SongBroadcastHub — Keine Band-Membership- oder Rollenprüfung
- **Datei:** `src/Sheetstorm.Api/Hubs/SongBroadcastHub.cs`
- **Zeile:** 32–101
- **Problem:** Der Hub prüft nur `[Authorize]` (= User ist authentifiziert), aber **nicht**, ob der User Mitglied der Band ist, auf deren Broadcast er zugreift. `StartBroadcast`, `SetCurrentSong`, `StopBroadcast`, `NextSong`, `PreviousSong` akzeptieren eine beliebige `bandId` ohne Membership-Check. `JoinBroadcast` erlaubt jedem authentifizierten User, beliebige Band-Broadcasts zu beobachten. Der Kommentar in Zeile 31 ("Only conductors/admins should call this") wird nicht durchgesetzt.
- **Fix:** Inject `AppDbContext` in den Hub. Vor jeder Band-Operation `RequireMembershipAsync(bandId, userId)` aufrufen. Für `StartBroadcast`/`SetCurrentSong`/`StopBroadcast`/`NextSong`/`PreviousSong` zusätzlich prüfen, dass der User Conductor oder Admin ist. Für `StopBroadcast` ggf. auch prüfen, dass nur der startende Conductor oder ein Admin stoppen darf.
- **Begründung:** Ohne diese Prüfung kann jeder authentifizierte User a) Broadcasts fremder Bands beobachten (Datenleck: Song-Auswahl, Teilnehmerzahl), b) fremde Broadcasts starten/stoppen/manipulieren (Sabotage). Dies ist eine **Broken Access Control**-Schwachstelle (OWASP Top 10 #1).

### K2: Password-Reset-Token wird im Klartext gespeichert
- **Datei:** `src/Sheetstorm.Infrastructure/Auth/AuthService.cs`
- **Zeile:** 154, 172
- **Problem:** In `ForgotPasswordAsync` (Z.154) wird der Reset-Token direkt gespeichert: `Musician.PasswordResetToken = GenerateSecureToken("reset_");`. In `ResetPasswordAsync` (Z.172) wird er direkt verglichen: `FirstOrDefaultAsync(m => m.PasswordResetToken == request.Token)`. Im Gegensatz dazu werden Refresh-Tokens (Z.246) und Email-Verification-Tokens (Z.44) korrekt als SHA-256-Hash gespeichert. Diese Inkonsistenz bedeutet, dass bei einem DB-Dump die Reset-Tokens im Klartext vorliegen und sofort nutzbar sind.
- **Fix:** Wie bei den anderen Tokens: `Musician.PasswordResetToken = HashToken(GenerateSecureToken("reset_"));` setzen und in `ResetPasswordAsync` `HashToken(request.Token)` zum Lookup verwenden.
- **Begründung:** Password-Reset-Tokens sind sicherheitskritisch — sie ermöglichen Account-Übernahme. Die Inkonsequenz gegenüber dem ansonsten korrekten Token-Hashing deutet auf ein Versehen hin.

### K3: Keine CORS-Policy für Production
- **Datei:** `src/Sheetstorm.Api/Program.cs`
- **Zeile:** 91–103
- **Problem:** Es wird nur eine `DevPolicy` definiert (Z.92–95: `AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()`), die ausschließlich in Development aktiv ist (Z.102). In Production wird **keine CORS-Policy** angewendet. Browser-basierte Clients von einer anderen Origin (z.B. die Flutter-Web-App) werden von der Same-Origin-Policy blockiert. Zudem fehlt bei der DevPolicy `.AllowCredentials()`, was für SignalR mit Cookies/Auth-Headers problematisch sein kann.
- **Fix:** Eine restriktive Production-CORS-Policy definieren und außerhalb des `IsDevelopment()`-Blocks anwenden:
  ```csharp
  options.AddPolicy("ProdPolicy", policy =>
      policy.WithOrigins("https://app.sheetstorm.io")
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials());
  ```
  Und in Production: `app.UseCors("ProdPolicy");`
- **Begründung:** Ohne Production-CORS sind alle Browser-Clients blockiert. Die DevPolicy mit `AllowAnyOrigin` darf niemals in Production aktiv sein.

### K4: AuthExceptionMiddleware hat keinen generischen Catch-All
- **Datei:** `src/Sheetstorm.Api/Middleware/AuthExceptionMiddleware.cs`
- **Zeile:** 13–31
- **Problem:** Die Middleware fängt nur `DomainException` und `AuthException`. Jede andere Exception (z.B. `NullReferenceException`, `DbUpdateException`, `InvalidOperationException`) propagiert ungefangen und wird vom ASP.NET-Default-Handler behandelt — der in Development Stacktraces exponiert und in Production einen generischen 500er ohne strukturierten Body liefert. Ein `DbUpdateException` könnte z.B. Tabellen-/Spaltennamen leaken.
- **Fix:** Einen generischen `catch (Exception ex)` Block hinzufügen, der einen 500er mit `{ error: "INTERNAL_ERROR", message: "An unexpected error occurred." }` zurückgibt und die Exception loggt (ohne Details in der Response).
- **Begründung:** Ohne Catch-All können interne Implementierungsdetails (DB-Schema, Stacktraces) an Clients exponiert werden. Das ist ein Informationsleck.

## Empfehlungen (SHOULD — nice-to-have)

### E1: SongBroadcastHub — Statischer In-Memory-State skaliert nicht
- **Datei:** `src/Sheetstorm.Api/Hubs/SongBroadcastHub.cs`
- **Zeile:** 13–16
- **Problem:** `ActiveBroadcasts` und `BandConnections` sind statische `ConcurrentDictionary`-Felder. In einem Multi-Server-Deployment (Load Balancer, K8s) hat jede Instanz ihren eigenen State. Zudem hat das `state with { ParticipantCount = count }`-Pattern (Z.116, 134, 159) eine TOCTOU-Race-Condition: zwischen `TryGetValue` und dem Schreiben kann ein anderer Thread den State ändern.
- **Fix:** Für MS2 als Single-Server akzeptabel. Für Skalierung: Redis-Backplane für SignalR + SharedState in Redis oder DB.

### E2: Setlist DuplicateAsync gibt leere Entries zurück
- **Datei:** `src/Sheetstorm.Infrastructure/Setlists/SetlistService.cs`
- **Zeile:** 338–386
- **Problem:** Nach dem Anlegen des Duplikats werden Entries direkt via `db.Set<SetlistEntry>().Add()` hinzugefügt — nicht über die `duplicate.Entries`-Navigation-Property. Die Zeile 358 (`duplicate.Entries.OrderBy(...)`) greift auf eine leere Collection zu, da EF die Navigation-Property nicht automatisch füllt. Der Response enthält daher 0 Entries.
- **Fix:** Entweder `duplicate.Entries.Add(duplicateEntry)` verwenden oder nach dem `SaveChangesAsync` die Setlist mit `GetByIdAsync` neu laden.

### E3: Keine Pagination auf Listen-Endpoints
- **Datei:** Alle List-Endpoints (Events, Posts, Polls, Pieces, Setlists, ShiftPlans, MediaLinks, Substitutes)
- **Problem:** Alle `GetAll`/`GetEvents`/etc. Endpoints laden die komplette Liste in den Speicher. Für eine kleine Blaskapelle ist das akzeptabel, aber bei wachsender Nutzung (viele Events über Jahre, viele Posts) wird dies zum Performance-Problem.
- **Fix:** Cursor-basierte Pagination einführen (z.B. `?cursor=...&limit=20`). Die Setlist- und Event-Endpoints wären die Ersten, die davon profitieren.

### E4: Duplizierter RequireMembershipAsync-Code in jedem Service
- **Datei:** Alle Services (EventService, BandService, PostService, PollService, SetlistService, etc.)
- **Problem:** Jeder Service hat seine eigene Kopie von `RequireMembershipAsync` und `RequireConductorOrAdminAsync`. Teilweise mit leicht unterschiedlichen Error-Codes (`BAND_NOT_FOUND` vs `NOT_FOUND`).
- **Fix:** Einen gemeinsamen `MembershipGuard`-Service oder eine Base-Class extrahieren.

### E5: Inkonsistente Error-Codes bei Membership-Checks
- **Datei:** Verschiedene Services
- **Problem:** BandService/PostService/PollService verwenden `BAND_NOT_FOUND`, während EventService/GemaService/ShiftService `NOT_FOUND` verwenden. Clients können sich nicht auf einen konsistenten Error-Code verlassen.
- **Fix:** Einheitlich `FORBIDDEN` oder `NOT_MEMBER` verwenden, wenn der User kein Mitglied ist. `NOT_FOUND` sollte für tatsächlich nicht existierende Ressourcen reserviert sein.

### E6: BandService-Methoden akzeptieren kein CancellationToken
- **Datei:** `src/Sheetstorm.Infrastructure/Band/BandService.cs`
- **Problem:** Im Gegensatz zu allen anderen Services (EventService, PostService, etc.) nimmt BandService kein `CancellationToken` entgegen. Bei langsamen DB-Queries kann der Request nicht abgebrochen werden.
- **Fix:** `CancellationToken ct` als Parameter hinzufügen und an alle DB-Operationen durchreichen.

### E7: Attendance-Stats werden komplett im Speicher berechnet
- **Datei:** `src/Sheetstorm.Infrastructure/Attendance/AttendanceService.cs`
- **Zeile:** 174–233
- **Problem:** `GetStatsAsync` lädt ALLE AttendanceRecords für eine Band in den Speicher und gruppiert/zählt in C#. Bei vielen Proben über Jahre hinweg wird das speicherintensiv.
- **Fix:** GroupBy + Count als SQL-Query ausführen (EF Core `GroupBy` + `Select` mit Aggregation).

### E8: HealthController hat abweichenden Route-Prefix
- **Datei:** `src/Sheetstorm.Api/Controllers/HealthController.cs`
- **Zeile:** 6
- **Problem:** HealthController nutzt `[Route("api/v1/[controller]")]` → `/api/v1/health`, während alle anderen Controller `api/...` ohne Version nutzen. Zudem gibt es bereits ein `/health`-Endpoint via `app.MapHealthChecks("/health")` in Program.cs (Z.120), der einen standardisierten Health-Check mit DB-Connectivity-Prüfung bietet.
- **Fix:** Den redundanten HealthController entfernen oder den Route-Prefix an die anderen Controller angleichen.

### E9: Piece-CRUD hat keine Rollen-Prüfung
- **Datei:** `src/Sheetstorm.Infrastructure/Import/ImportService.cs`
- **Zeile:** 112–184
- **Problem:** `CreatePieceAsync`, `UpdatePieceAsync` und `DeletePieceAsync` prüfen nur Membership, nicht die Rolle. Jedes Band-Mitglied (auch ein normales `Musician`) kann Stücke anlegen, bearbeiten und löschen. Das könnte gewollt sein, aber typischerweise sollte zumindest das Löschen auf Admins/Conductors/SheetMusicManagers beschränkt sein.
- **Fix:** Mindestens für Delete eine Rollen-Prüfung einführen.

### E10: VoicePreselection.UserInstrumentID — Inkonsistente Naming-Convention
- **Datei:** `src/Sheetstorm.Domain/Entities/VoicePreselection.cs`
- **Zeile:** 15
- **Problem:** `UserInstrumentID` verwendet den Suffix `ID` statt dem überall sonst konsistent genutzten `Id` (z.B. `MusicianId`, `BandId`, `PieceId`). Dies ist ein Minor-Issue, kann aber bei Code-Generierung oder Convention-basiertem EF-Mapping Probleme verursachen.
- **Fix:** Zu `UserInstrumentId` umbenennen (erfordert Migration).

### E11: GemaService XML-Export nutzt manuelle String-Konkatenation
- **Datei:** `src/Sheetstorm.Infrastructure/Gema/GemaService.cs`
- **Zeile:** 337–371
- **Problem:** Der XML-Export baut den XML-String manuell auf. Die `EscapeXml`-Funktion (Z.380–381) escapet `&`, `<`, `>`, `"`, aber **nicht** Single-Quotes (`'` → `&apos;`). Bei Verwendung in einem XML-Parser ist das unproblematisch (Single-Quotes in Element-Content sind valid XML), aber es wäre sicherer, `XmlWriter` oder `XDocument` zu verwenden.
- **Fix:** `System.Xml.Linq.XDocument` für den XML-Export verwenden.

### E12: GemaController ExportReport — Kein Null-Check auf format-Parameter
- **Datei:** `src/Sheetstorm.Api/Controllers/GemaController.cs`
- **Zeile:** 176
- **Problem:** Der `format`-Query-Parameter ist als `string` deklariert ohne `[Required]`. Wenn kein `?format=...` übergeben wird, ist `format` null und `format.ToLowerInvariant()` in Z.179 wirft eine `NullReferenceException`.
- **Fix:** `[Required] string format` oder Null-Check im Controller.

### E13: Duplicate SaveChangesAsync in Poll-Create
- **Datei:** `src/Sheetstorm.Infrastructure/Polls/PollService.cs`
- **Zeile:** 91, 104
- **Problem:** `CreateAsync` ruft zweimal `SaveChangesAsync` auf — einmal für die Poll (Z.91), dann für die Options (Z.104). Dies könnte in einer einzigen Transaktion erfolgen, was atomarer und performanter wäre.
- **Fix:** Poll und Options in einem einzigen `SaveChangesAsync`-Call speichern (Options via Navigation-Property hinzufügen).

## Positives

- **Starke Security-Basis:** JWT mit korrekter Validierung (Issuer, Audience, Lifetime, ClockSkew=30s), bcrypt für Passwörter, SHA-256-Hashing für Refresh/Verification-Tokens, Rate Limiting auf Auth-Endpoints, Refresh-Token-Rotation mit Family-basierter Reuse Detection — das ist vorbildlich.
- **Konsistente Clean Architecture:** Domain → Infrastructure → API-Schichtentrennung durchgängig eingehalten. Kein Raw SQL, keine Domain-Logik in Controllern, Services über Interfaces injiziert.
- **Durchdachte Entity-Konfigurationen:** EF Core Configurations mit korrekten Indexes (Composite-Keys, Filtered Indexes), angemessene OnDelete-Behavior (Cascade vs Restrict vs SetNull), MaxLength-Constraints überall.
- **Gute Controller-Konventionen:** Alle Controller nutzen `[ApiController]`, korrekte HTTP-Verben, konsistente StatusCodes (201 für Create, 204 für Delete), `ProducesResponseType`-Annotations, ModelState-Validation, CancellationToken-Support.
- **Sinnvolle Business-Logik:** Letzter Admin kann nicht entfernt/degradiert werden, einmalige Invitation-Codes, GEMA-Report-Finalisierungs-Flow mit Status-Guarding, maximal 3 gepinnte Posts, Poll-Expiry-Check vor Vote, Substitute-Token-Hashing.
- **Sauberer Input-Handling:** Durchgängig `.Trim()` auf User-Input, E-Mail-Normalisierung via `.ToLowerInvariant()`, Guid-Constraints in Routes.
- **Audit-Trail:** `BaseEntity` mit `CreatedAt`/`UpdatedAt` automatisch via `SaveChangesAsync` Override, `ConfigAudit` für Konfigurationsänderungen.

## Bewertung

- **Architektur:** ⭐⭐⭐⭐⭐ / Saubere Schichtentrennung, konsistente Patterns, gute DI-Struktur. Minimal: Duplizierter Membership-Guard-Code sollte extrahiert werden.
- **Security:** ⭐⭐⭐ / Starke Grundlage (JWT, bcrypt, Token-Hashing, Rate Limiting), aber kritische Lücken: Hub ohne Autorisierung (K1), Plaintext-Reset-Tokens (K2), fehlende CORS für Production (K3), kein Exception-Catch-All (K4).
- **API-Design:** ⭐⭐⭐⭐ / RESTful, konsistente Konventionen, gute Status-Codes. Abzüge für fehlende Pagination und den inkonsistenten HealthController-Route.
- **Domain-Logik:** ⭐⭐⭐⭐⭐ / Business Rules korrekt implementiert, Edge Cases (letzter Admin, abgelaufene Tokens, geschlossene Polls) gut behandelt.
- **Performance:** ⭐⭐⭐ / Gute Index-Definitionen, aber fehlende Pagination, In-Memory-Stats-Berechnung und Eager-Loading aller Reactions/Votes sind Schwächen für langfristige Skalierung.
- **Code-Qualität:** ⭐⭐⭐⭐ / Konsistentes Naming, gute Null-Safety (null-forgiving nur bei guaranteed navigations), sinnvolle Exception-Typen. Minor: Inkonsistente Error-Codes, fehlende CancellationTokens in BandService.
