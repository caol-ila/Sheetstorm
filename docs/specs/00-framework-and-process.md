# Sheetstorm — Entwicklungsrahmen & Prozess

> **Status:** Living Document
> **Zweck:** Verbindliche Meta-Spec für Tech-Stack, Plattformen, Qualitäts- und
> Prozess-Anforderungen. Alle Feature-Specs in `docs/specs/` unterliegen diesem Rahmen.
> **Sprache:** Deutsch (de-DE) — Primärsprache des Projekts.
> **Nummerierung:** Das Präfix `00-` signalisiert: übergeordnetes Dokument, gilt für
> alle folgenden Feature-Specs.

Dieses Dokument **ergänzt** und **konsolidiert** — es dupliziert nicht. Detail-Regeln,
die bereits in `.github/copilot-instructions.md`, `.squad/skills/git-worktree/SKILL.md`
oder anderen Quellen stehen, werden hier referenziert statt wiederholt.

---

## 1. Produkt-Rahmen (Scope-Definition)

Sheetstorm ist eine **App für Blaskapellen** — Noten- und Vereinsverwaltung in einem.
Zielgruppen sind Musiker:innen (mobile Noten am Pult), Notenwart:innen (Verwaltung,
Archivierung, Import) und Vorstände/Kassiere (Mitgliederdaten, Register, Termine).

Produkt-Kontext und Wettbewerbsanalyse: siehe
[`docs/market-analysis/noten-und-vereinsverwaltung.md`](../market-analysis/noten-und-vereinsverwaltung.md).

Diese Meta-Spec definiert **nicht** Features, sondern den **Rahmen**, in dem Features
gebaut werden.

---

## 2. Zielplattformen

### 2.1 Pflicht (MUSS im MVP lauffähig)

| Plattform | Formfaktor | Minimale Version | Begründung |
|---|---|---|---|
| **Android** | Phone + Tablet | **Android 10 (API 29)** | 95 %+ aktive Geräte-Abdeckung; Edge-to-Edge und Scoped Storage sauber unterstützt. |
| **iOS / iPadOS** | Phone + Tablet | **iOS/iPadOS 15** | Abdeckt alle von Apple aktiv gewarteten Geräte; SwiftUI-Interop und moderner PDFKit verfügbar. |
| **Windows Desktop** | Desktop + Tablet-Mode | **Windows 10 21H2** / **Windows 11** | Letzte Win10-Version mit MSIX-Unterstützung; WinUI 3 / WebView2 verlässlich. |

### 2.2 Stretch / später

- **Web (responsive)** — nur wenn Flutter-Web-Rendering (CanvasKit) für die Noten-Anzeige
  in echten Probenbedingungen akzeptabel ist. Entscheidung nach Prototyp (siehe §8).
- **macOS / Linux** — als Flutter-Desktop-Build machbar, aber nicht Release-Ziel vor
  den Pflicht-Plattformen.

### 2.3 Primär-Formfaktoren

- **Tablet 10"+** — primäre Notenständer-Nutzung (Anzeige, Annotation, Pagination).
- **Phone** — Proben-Planung, schnelle Aktionen, Benachrichtigungen.
- **Desktop (Windows)** — Notenwart-Workflows (Bulk-Import, Scan, Katalogisierung).

Jedes Feature-Spec MUSS seine Layout-Anforderungen für alle drei Formfaktoren explizit
machen.

---

## 3. Tech-Stack

### 3.1 Orchestrierung — .NET Aspire

- **AppHost** koordiniert Backend-API, PostgreSQL, ggf. Worker-Services und
  Observability-Stack.
- **ServiceDefaults** liefern OpenTelemetry, Health-Checks, Service-Discovery und
  Resilience-Policies (Polly) für alle .NET-Projekte.
- **Aspire Dashboard** ist der **einheitliche DevLoop-Einstiegspunkt** — Logs, Traces,
  Metriken, Test-Runs und Ressourcen-Status in einer Oberfläche.
- **Container-Ressourcen** (PostgreSQL, ggf. Redis, SignalR-Backplane, Seq) werden
  über Aspire-Resources deklariert, nicht über handgepflegte `docker-compose.yml`.

Doku: <https://learn.microsoft.com/dotnet/aspire/>.

### 3.2 Backend — C# / ASP.NET Core 10 (.NET 10 LTS)

- **3-Schichten-Architektur**: `Api → Domain → Infrastructure`
  (Details siehe [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md)).
- **Persistenz**: EF Core + Npgsql + PostgreSQL. Migrationen als Code, versioniert.
- **Auth**: JWT Access-Tokens + Refresh-Tokens. Secrets via Aspire-Parameter bzw.
  Key-Vault-kompatibler Abstraktion.
- **Realtime**: SignalR für Annotation-Sync und Metronom/Dirigat-Features.
- **Contract-first**: OpenAPI (aus Attribute-Annotationen) ist die verbindliche
  Schnittstelle — der Flutter-Client generiert sich daraus.

### 3.3 Frontend — Flutter / Dart

- **State**: Riverpod 3.x — Provider für **alle** Geschäftslogik, keine direkten
  API-Aufrufe in Widgets (siehe copilot-instructions, Flutter-Abschnitt).
- **Routing**: GoRouter, deklarative Routen.
- **Offline-Persistenz**: Drift (SQLite), typsichere Queries, Migrationen als Code.
- **Responsive**: `LayoutBuilder` + Breakpoints (Phone < 600 dp, Tablet 600–1200 dp,
  Desktop ≥ 1200 dp). Layout-Entscheidung zentral, nicht ad-hoc pro Widget.
- **Platform-adaptive Widgets**: Cupertino für System-Dialoge/Datumspicker auf iOS,
  Material 3 als Default.
- **i18n**: `flutter_localizations` + ARB-Dateien ab Tag 1 — keine hardcodierten
  Nutzer-Strings (siehe §4.3).

### 3.4 Desktop-Spezialfälle

- **WinUI 3** wird **ausschließlich** für den **PDF Labeler** eingesetzt
  (eigenständiges Tool, siehe [`docs/specs/mvp-pdf-labeler.md`](mvp-pdf-labeler.md)).
  WinUI ist **kein** Teil der Kern-App.
- Die **Haupt-App auf Windows** läuft als **Flutter-Desktop-Build** — eine Codebase
  für alle drei Pflicht-Plattformen.

---

## 4. Qualitätsanforderungen

### 4.1 Usability

Die App MUSS sich an gängige UX-Best-Practices halten:

- **Design-System**: Material 3 (Android/Windows), Cupertino-Akzente (iOS).
- **Navigation**: Bottom Nav auf Phone, Navigation Rail auf Tablet/Desktop.
  Innerhalb eines Features konsistent — keine zwei Navigationsparadigmen im selben Flow.
- **Optimistic UI**: Schreiboperationen spiegeln sofort lokal, mit klarem Feedback bei
  Sync-Fehlern (nicht-blockierende Toasts + Retry-Pfad).
- **Touch-Targets**: min. **48 × 48 dp** für alle interaktiven Elemente
  (Bühnen-Nutzung, ggf. mit Handschuhen oder schwachem Licht).
- **Cognitive Load**: max. **3 primäre Aktionen** pro Screen, sekundäres in
  Overflow-Menüs.
- **Theme**: Dark-Mode + High-Contrast-Variante für Probenlokal-Beleuchtung sind
  **Pflicht**, nicht optional.
- **Offline-First**: Keine "No-Network"-Deadends. Jeder Lese-Workflow MUSS offline
  funktionieren (siehe §4.4).

### 4.2 Accessibility (Pflicht, nicht Bonus)

**WCAG 2.2 Level AA** ist der **Mindeststandard** für alle UI-Komponenten.
Referenz: <https://www.w3.org/TR/WCAG22/>.

- **Screen-Reader**: TalkBack, VoiceOver, Narrator — semantische Labels an **allen**
  interaktiven und informativen Elementen.
- **Keyboard-Navigation**: Auf Desktop vollständig navigierbar — durchdachte
  Tab-Reihenfolge, sichtbarer Fokus-Indikator, Shortcuts für häufige Aktionen
  dokumentiert.
- **Kontrast**: min. **4.5:1** für Fließtext, **3:1** für UI-Komponenten und große
  Texte (≥ 18 pt / 14 pt bold).
- **Text-Skalierung**: bis **200 %** ohne Layout-Bruch, ohne horizontales Scrollen.
- **Motion-Reduce**: `MediaQuery.disableAnimations` respektieren — alternative,
  nicht-animierte Übergänge anbieten.
- **Touch-Target**: min. 48 × 48 dp (konsistent mit §4.1).
- **Alt-Text / Semantics**: für alle Icons, Bilder und dynamischen Noten-Elemente.
- **Test-Pflicht**: Jedes Widget-Test-File MUSS mindestens **einen Semantics-Check**
  enthalten (z. B. `expect(tester.getSemantics(find.byKey(...)), matchesSemantics(...))`).

Doku: Flutter-Accessibility <https://docs.flutter.dev/accessibility-and-internationalization/accessibility>.

### 4.3 Lokalisierung (i18n)

- **Primärsprache**: **Deutsch (de-DE)**.
- Die Architektur MUSS **ab Tag 1** i18n-tauglich sein:
  - **Flutter**: `flutter_localizations` + ARB-Dateien, generierte
    `AppLocalizations`-Klasse. **Keine** hardcodierten Nutzer-Strings im Code.
    Doku: <https://docs.flutter.dev/accessibility-and-internationalization/internationalization>.
  - **Backend**: `IStringLocalizer<T>` bzw. Resource-Dateien (`.resx`) für
    Fehlermeldungen und Notifications. Kein String-Literal in `throw`-Statements
    für nutzersichtbaren Text.
- **Sprach-Switcher** im MVP nicht Pflicht, aber die **Infrastruktur muss stehen**.
- **Formatierung**: Datums-, Zahlen- und Währungsformate via `Intl` (Flutter) bzw.
  `CultureInfo` (.NET). Keine manuelle `"dd.MM.yyyy"`-Formatierung.
- **Roadmap**: Englisch (en) → Französisch (fr-CH) / Italienisch (it-IT) für
  Südtirol und die Schweiz.

### 4.4 Performance-Budgets

Grobrichtwerte — Feature-Specs dürfen diese verfeinern, aber nicht lockern ohne ADR:

| Messgröße | Budget | Baseline-Gerät |
|---|---|---|
| App-Start (Cold) | **< 3 s** | Samsung Galaxy Tab A8 (Mittelklasse-Tablet) |
| PDF-Seitenumbruch | **< 100 ms** | Baseline-Tablet, gecachte Seite |
| API p95 für Listen-Endpoints | **< 300 ms** | Backend hinter Aspire, lokaler Bench |
| Offline-Verfügbarkeit aller **Lese-Workflows** | **100 %** | Phone + Tablet ohne Netz |

Jedes Feature-Spec MUSS betroffene Budgets benennen und deren Einhaltung im Test
nachweisen.

---

## 5. Test-Strategie (Teil der Entwicklung, nicht optional)

TDD bleibt strikt verbindlich — Details in
[`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).

### 5.1 Test-Pyramide

- **Unit-Tests (breit)**
  - Backend: **xUnit** + **FluentAssertions** + **NSubstitute**.
  - Frontend: `flutter test`. **Widget-Tests** für jede eigene Komponente.
- **Integration-Tests (mittel)**
  - Backend: `WebApplicationFactory<TEntryPoint>` + **Testcontainers-Postgres**
    (keine In-Memory-Fakes für EF — echte DB).
  - Frontend: Notifier-Level-Tests für Riverpod-Flows, Drift-DB-Tests mit echter
    SQLite-Instanz.
- **E2E-Tests (schmal, aber entscheidend)**
  - **Playwright** (TypeScript) für Web-Flows und orchestrierte Stacks — siehe
    `sheetstorm_app/playwright.config.ts` und den E2E-Abschnitt in
    [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md).
  - **Aspire hostet den vollständigen Stack** (Backend + DB + Worker) als
    Integrationsumgebung. Playwright läuft gegen Flutter-Web auf Port 8080 mit
    echter Aspire-AppHost-Session.
  - Zusätzlich für **nativen Desktop**: Flutter `integration_test`-Suite für den
    Notenwart-Workflow auf Windows (Playwright approximiert hier nur Flutter-Web).

### 5.2 Aspire als Test-Orchestrator

- **`aspire run`** in CI startet das komplette System (Backend, DB, optional Worker)
  reproduzierbar.
- **`flutter run -d chrome --web-port 8080`** wird als **Aspire-Resource** eingebunden,
  damit ein Befehl den ganzen Stack hochzieht.
- **Playwright-Tests** konsumieren Ressourcen-URLs entweder aus
  `aspire.resources.json` oder aus den vom Aspire-Dashboard exportierten
  Environment-Variablen — **keine** hartkodierten Ports in Test-Code.
- Lokaler DevLoop identisch zu CI — derselbe `aspire run` startet dieselben
  Ressourcen.

### 5.3 Abdeckung / Disziplin

- **TDD strikt** (siehe copilot-instructions) — RED → GREEN → REFACTOR.
- **Neue Features erfordern**:
  - Unit-Tests (**immer**)
  - Integration-Tests (wenn DB- oder HTTP-Grenze berührt wird)
  - E2E-Test (wenn ein nutzersichtbarer Workflow entsteht oder sich ändert)
- **Keine PR ohne grüne Tests.** Harte CI-Gate-Regel (siehe §7.4).

---

## 6. Dokumentations-Pflicht

Dokumentation ist Teil der **Definition of Done**, nicht Nachgang:

- **Code-Doc**: Öffentliche APIs mit **XML-Doc** (.NET) bzw. **Dartdoc** (Flutter).
- **Feature-Spec**: Jedes Feature hat `docs/specs/<slug>.md` **bevor** gecodet wird.
  Bestehendes Beispiel: [`mvp-pdf-labeler.md`](mvp-pdf-labeler.md).
- **ADRs**: Architekturentscheidungen in `docs/adr/NNNN-<slug>.md` im **MADR-Format**
  (<https://adr.github.io/madr/>). Jede Stack-, Plattform- oder Grenzen-Änderung
  braucht ein ADR.
- **README** der App bleibt aktuell (Setup, DevLoop, Plattformen).
- **API-Doc**: OpenAPI wird aus Attribute-Annotationen **automatisch** generiert und
  nach `docs/api/` exportiert (Teil der CI-Pipeline).

---

## 7. Entwicklungsprozess

### 7.1 Git-Worktrees (Pflicht)

**Alle** Feature-Arbeit findet in einem dedizierten Worktree statt.
Single Source of Truth: [`.squad/skills/git-worktree/SKILL.md`](../../.squad/skills/git-worktree/SKILL.md).

Kurzform:

- **1 Worktree = 1 Branch = 1 Issue.**
- **Coordinator (Stark)** provisioniert den Worktree **vor** dem Agent-Spawn und
  legt den Pfad als `WORKTREE ROOT` im Spawn-Prompt fest.
- **Schema**: `C:\Privat\Sheetstorm-worktrees\{branch-slug}` — Geschwister des
  Hauptrepos, niemals darin verschachtelt.
- **Nach Merge**: `git worktree remove …` + `git worktree prune` + Branch lokal
  und remote löschen.

### 7.2 Issue → Branch → PR

1. **Issue zuerst.** Kein PR ohne verlinktes Issue — einzige Ausnahme: trivialste
   `chore`-Commits (Typos, Formatting o. Ä.).
2. **Lead (Stark)** triagiert und vergibt `squad:{member}`-Label
   (siehe [`.squad/routing.md`](../../.squad/routing.md)).
3. Der zugewiesene Agent legt den Worktree an und branched nach Conventional-Commit-
   Schema:
   - `feat/{issue-nr}-{slug}` — neue Funktionalität
   - `fix/{issue-nr}-{slug}` — Bugfix
   - `chore/{slug}` — Infrastruktur, Tooling
   - `docs/{slug}` — Dokumentation
   - `refactor/{slug}` — Umstrukturierung ohne Verhaltensänderung
4. **TDD-Zyklus**: RED → GREEN → REFACTOR → Commit.
5. **Vor PR**: Build grün, Tests grün, Lint grün, Docs aktualisiert.
6. **PR** erstellen mit `Closes #<issue>` im Body.

### 7.3 PR-Review-Gate (Multi-Model-Review, Pflicht)

Jeder PR MUSS durch folgende Reviewer-Kette laufen, **bevor** er merged werden darf:

| Reviewer | Modell | Rolle | Fokus |
|---|---|---|---|
| **Reviewer A** | **Claude Opus 4.6** | Senior Engineer | Korrektheit, Logik, Edge Cases |
| **Reviewer B** | **Claude Sonnet 4.6** | Security / Quality | Sicherheit, Performance, Wartbarkeit |
| **Reviewer C** | **GPT-5.4** | Architect | Architektur, API-Design, Konsistenz |

**Workflow**:

1. Die drei Reviewer laufen **parallel** als Background-Agents.
2. Jeder liefert strukturiertes Feedback — Findings mit Severity
   **`BLOCKER` / `MAJOR` / `MINOR` / `NIT`**.
3. **Lead Architect (Stark, Opus 4.7)** konsolidiert die drei Reviews:
   - **Einarbeiten**: `BLOCKER`/`MAJOR`-Findings im PR-Scope.
   - **Neues Issue**: Out-of-Scope-Findings werden als Follow-up-Issues angelegt
     und im PR-Kommentar verlinkt.
   - **Verwerfen**: Falsch-Positive mit **begründeter** Ablehnung im PR-Kommentar.
4. **Erst nach** Stark-Konsolidierung und Durcharbeiten der `BLOCKER`-Findings ist
   Merge möglich.
5. Stark dokumentiert seine Entscheidung **je Finding** als PR-Kommentar — für
   Nachvollziehbarkeit und spätere Audits.

### 7.4 Merge-Voraussetzungen (harte Gates)

Ein PR DARF NUR gemerged werden, wenn **alle** folgenden Punkte erfüllt sind:

- [ ] **Issue verlinkt** (`Closes #<nr>`)
- [ ] **Alle Unit-Tests grün**
- [ ] **Alle Integration-Tests grün**
- [ ] **E2E-Tests grün**, wenn ein nutzersichtbarer Workflow betroffen ist
- [ ] **Build grün auf allen Zielplattformen** (Android, iOS, Windows)
- [ ] **Lint clean** — `dotnet format --verify-no-changes` + `flutter analyze`
- [ ] **Accessibility-Smoke-Test** durchgelaufen (Semantics-Checks, Kontrast-Scan)
- [ ] **Dokumentation aktualisiert** (Spec, README, ADR falls relevant)
- [ ] **3 Reviewer-Runs** abgeschlossen (Opus 4.6, Sonnet 4.6, GPT-5.4)
- [ ] **Stark-Konsolidierung** dokumentiert
- [ ] **Alle `BLOCKER`/`MAJOR`-Findings adressiert** (eingearbeitet **oder** als
      Follow-up-Issue erfasst)
- [ ] **Keine** ungelösten `TODO: SECURITY` / `TODO: BLOCKER`-Marker

**Keine vollständig funktionierende Anwendung → kein Merge. Punkt.**

### 7.5 DevLoop

Der DevLoop MUSS zu jeder Zeit funktional und effizient sein:

- **`aspire run`** startet lokal alles (Backend, DB, Worker, Frontend-Ressourcen)
  in **< 60 s**.
- **Hot-Reload** aktiv: Flutter (`flutter run`) + Backend (`dotnet watch`).
- **Tests lokal** (Unit + Integration): **< 2 min**.
- **E2E-Full-Suite**: **< 10 min**.
- **`main`-Branch ist immer lauffähig** — CI stellt das sicher, kein Commit ohne
  Green-Status.
- **Rollback-freundlich**: Jeder Merge ist ein isolierter Commit, reversibel per
  `git revert`.

### 7.6 CI/CD

- **GitHub Actions**
  - **Pull Request**: Build + Test + Lint auf allen Plattformen (Matrix-Strategie).
  - **Multi-Model-Review-Agents** laufen als **separater** Workflow, getriggert
    per PR-Label `review-ready` (siehe §7.3).
  - **Merge-Queue**: sequentieller Merge nach Green-Status — keine Race-Conditions
    auf `main`.
- **Releases**: Git-Tag → automatische Builds
  - Android: **AAB** (Google Play Bundle)
  - iOS: **IPA** (App Store Connect)
  - Windows: **MSIX**

---

## 8. Offene Entscheidungen / Follow-ups

Die folgenden Punkte sind **bewusst offen** und brauchen eine explizite Entscheidung
(ADR), bevor die betroffenen Features starten:

- **Push-Notifications**: FCM + APNS direkt vs. OneSignal (Abstraktions-Layer,
  Kostenmodell).
- **Web-Build Ja/Nein**: Entscheidung nach Flutter-Web-Notenanzeige-Prototyp.
  CanvasKit-Größe und Rendering-Qualität müssen gegen echten Probenstand getestet
  werden.
- **Monorepo** (aktuell) **vs. Frontend-Auslagerung** in eigenes Repo — abhängig
  davon, wie stark Flutter-Build-Zeiten die .NET-CI blockieren.

---

## 9. Referenzen

- [`.github/copilot-instructions.md`](../../.github/copilot-instructions.md) —
  Coding-Standards, TDD, Testing-Anti-Patterns, E2E-Konventionen.
- [`.squad/skills/git-worktree/SKILL.md`](../../.squad/skills/git-worktree/SKILL.md)
  — Worktree-Policy (Pflichtlektüre vor erstem Commit).
- [`.squad/routing.md`](../../.squad/routing.md) — Rollen- und Routing-Matrix.
- [`.squad/team.md`](../../.squad/team.md) — Squad-Mitglieder und Verantwortungen.
- [`.squad/ceremonies.md`](../../.squad/ceremonies.md) — Ceremonies (Design
  Review, Retrospektive etc.).
- [`docs/market-analysis/noten-und-vereinsverwaltung.md`](../market-analysis/noten-und-vereinsverwaltung.md)
  — Produkt-Kontext und Marktanalyse.
- WCAG 2.2 — <https://www.w3.org/TR/WCAG22/>
- Flutter i18n — <https://docs.flutter.dev/accessibility-and-internationalization/internationalization>
- .NET Aspire — <https://learn.microsoft.com/dotnet/aspire/>
- MADR (ADR-Format) — <https://adr.github.io/madr/>
