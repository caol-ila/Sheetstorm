# Decision: App Foundation Scope & Structure

**Datum:** 2026-04-20  
**Entscheidung von:** Stark (Lead Architect)  
**Kontext:** Issue #126 — Rahmenanwendung Foundation  
**Status:** PROPOSED (zur Review für Thomas)

---

## Entscheidungen

### 1. Neuer Branch `feat/app-scaffold` off `main` (nicht off `feat/124`)

**Warum:**

- **Isolation:** PDF Labeler (Issue #124, Branch `feat/124-pdf-labeler-mvp`) ist ein eigenständiges WinUI-Tool, **kein** Teil der Haupt-App. Die Rahmenanwendung (Flutter + ASP.NET Core) hat keine Code-Abhängigkeit zu WinUI-Code.
- **Merge-Konflikt-Vermeidung:** `feat/124` kann jederzeit gemerged werden, ohne dass die Foundation-Session blockiert wird (oder umgekehrt).
- **Scope-Klarheit:** Foundation ist "die App", PDF Labeler ist "ein Tool". Beide bauen auf der Framework-Spec auf, aber sie sind parallel entwickelbar.
- **Worktree-Policy-Konform:** `.squad/skills/git-worktree/SKILL.md` §2.3 (Branching-Strategie): Feature-Branches off `main`, nicht verschachtelt.

**Alternative (verworfen):**

- Branch off `feat/124`: Würde WinUI-Code als Basis importieren, obwohl er irrelevant ist. Verwirrt Dependency-Graph.

**Risiko:**

- Wenn beide Branches gleichzeitig `.editorconfig`, `.gitignore` oder `docs/specs/00-framework-and-process.md` ändern, gibt es Merge-Konflikte → Mitigation: Framework-Spec ist bereits auf `docs/framework-and-process-spec` gemerged (oder wird es sein), beide Branches ziehen von dort.

---

### 2. `sheetstorm_app/` als Subfolder im Monorepo (nicht Root)

**Warum:**

- **Konvention:** Flutter-Apps in .NET-Repos typischerweise als Subfolder (z.B. `src/WebUI/` bei .NET-Templates, oder `app/` bei Mono-Repos).
- **Build-Isolation:** `dotnet build` im Repo-Root baut nur .NET-Projekte. `flutter build` im Subfolder stört nicht. CI-Workflows können klar trennen (`.github/workflows/backend.yml` vs. `flutter.yml`).
- **Aspire-Integration:** Aspire-AppHost kann Flutter-Web als Executable-Resource referenzieren — Pfad ist `sheetstorm_app/`, nicht `.`.
- **Skalierbarkeit:** Wenn später ein zweites Flutter-Projekt (z.B. Admin-Panel oder Second-Screen-App) dazukommt, ist das Schema etabliert.

**Alternative (verworfen):**

- Flutter-App als Repo-Root: Dann müsste Backend in `backend/` oder `src/` leben → Umgekehrte Logik, verwirrt .NET-Entwickler. Aspire-Hosting wäre dann "im Subfolder", obwohl es der Orchestrator ist.

**Konsequenz:**

- README.md im Root muss klar machen: "Monorepo mit Backend (src/) + Frontend (sheetstorm_app/)".
- `.gitignore` braucht sowohl .NET- als auch Flutter-Patterns.

---

### 3. Verzeichnisstruktur: `src/` (Backend), `tests/` (Backend-Tests), `sheetstorm_app/` (Flutter)

**Warum:**

- **Framework-Spec §3.2:** 3-Schichten-Architektur (Api, Domain, Infrastructure) → alle in `src/`.
- **Testcontainers-Konvention:** `tests/` neben `src/` ist Standard in .NET-Projekten.
- **Aspire-Konvention:** AppHost und ServiceDefaults leben in `src/`, nicht in Root.
- **Symmetrie:** `src/` für .NET, `sheetstorm_app/` für Flutter, `docs/` für Specs, `.github/` für CI → klare Trennung.

**Alternative (verworfen):**

- Alle Projekte flach im Root → Wird bei 6+ Projekten unübersichtlich.
- `backend/` statt `src/` → Weniger idiomatisch für .NET-Repos.

**Dateien in Root (max. Übersicht):**

- `.editorconfig`, `.gitignore`, `.gitattributes`
- `README.md`, `LICENSE` (künftig)
- `global.json` (für .NET SDK-Pin)
- `Sheetstorm.sln` (künftig — Solution-Datei im Root referenziert `src/**/*.csproj`)

---

### 4. Kein `docs/adr/` für diese Entscheidungen (stattdessen `inbox/`)

**Warum:**

- **ADR-Format (MADR)** ist für **Architektur**-Entscheidungen gedacht (z.B. "Warum Postgres statt MongoDB?", "Warum Riverpod statt Bloc?").
- **Diese Entscheidungen** sind **Projekt-Struktur** und **Branching-Strategie** — operational, nicht architektonisch.
- **Inbox** ist für "schnelle Entscheidungen, die später konsolidiert werden" → Thomas kann diese akzeptieren/ablehnen, dann werden sie in `.squad/decisions.md` (zentral) übernommen oder in ein ADR umgewandelt.

**Konsequenz:**

- Wenn Thomas zustimmt, wird diese Datei nach `.squad/decisions/accepted/` verschoben oder in `.squad/decisions.md` referenziert.
- Wenn Thomas ablehnt, kommt sie nach `.squad/decisions/rejected/` mit Begründung.

---

## Offene Fragen (für Thomas)

1. **Monorepo langfristig?** — Oder soll Flutter-App später in eigenes Repo ausgelagert werden? (Framework-Spec §8 erwähnt das als offene Frage.)  
   → **Meine Empfehlung:** Monorepo beibehalten, solange Flutter-Build-Zeit < 2 min in CI.

2. **Solution-Datei im Root?** — Soll `Sheetstorm.sln` alle Backend-Projekte referenzieren (inkl. Tests), oder arbeiten wir mit Directory.Build.props und manueller Projektreferenz?  
   → **Meine Empfehlung:** Ja, Solution-Datei im Root für IDE-Integration (Rider, Visual Studio).

3. **global.json für .NET SDK-Pin?** — Framework-Spec erwähnt es in §7.5 implizit ("Risiko: SDK-Version mismatch").  
   → **Meine Empfehlung:** Ja, `global.json` mit `"version": "10.0.100"` (oder aktuelle .NET 10-Preview).

---

## Referenzen

- Issue #126: https://github.com/caol-ila/Sheetstorm/issues/126
- Framework-Spec: `git show docs/framework-and-process-spec:docs/specs/00-framework-and-process.md`
- Worktree-Skill: `.squad/skills/git-worktree/SKILL.md`
- Plan: `docs/specs/app-foundation-plan.md`
