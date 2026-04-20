# Spezifikationen

> Versionierte Feature-Spezifikationen, committed in Git für Traceability.

## Konvention

Specs werden als Markdown-Dateien in diesem Verzeichnis gespeichert:

```
docs/specs/YYYY-MM-DD-{feature-slug}.md
```

### Beispiele

```
docs/specs/2025-01-15-offline-sync.md
docs/specs/2025-02-03-role-based-access.md
docs/specs/2025-03-10-push-notifications.md
```

### Regeln

1. **Dateiname:** `YYYY-MM-DD` ist das Erstellungsdatum, `{feature-slug}` beschreibt das Feature in Kebab-Case
2. **Git-versioniert:** Specs werden committed — Änderungen sind im Git-Log nachvollziehbar
3. **Unveränderlichkeit:** Nach Abnahme wird eine Spec nicht geändert, sondern eine neue Version erstellt (`-v2` Suffix)
4. **Referenzierung:** In Issues und PRs auf die Spec-Datei verlinken
5. **Sprache:** Deutsch, konsistent mit der Projektdokumentation

### Template

```markdown
# Feature: [Name]

**Datum:** YYYY-MM-DD
**Autor:** [Squad-Mitglied]
**Status:** Draft | Review | Accepted | Superseded

## Kontext

[Warum brauchen wir das?]

## Anforderungen

### Must-Have
- [ ] ...

### Nice-to-Have
- [ ] ...

## Technisches Design

[Architektur, Interfaces, Datenmodell]

## File-Structure-Map

**CREATE:**
- ...

**MODIFY:**
- ...

## Offene Fragen

- [ ] ...
```
