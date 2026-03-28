# Ceremonies

> Team meetings that happen before or after work. Each squad configures their own.

## Design Review

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | before |
| **Condition** | multi-agent task involving 2+ agents modifying shared systems |
| **Facilitator** | lead |
| **Participants** | all-relevant |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**
1. Review the task and requirements
2. **File-Structure-Mapping prüfen** — CREATE/MODIFY/DELETE-Liste als Pflicht-Input
3. Agree on interfaces and contracts between components
4. Identify risks and edge cases
5. Assign action items

---

## Two-Pass Code Review

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | implementation complete, PR ready for review |
| **Facilitator** | lead |
| **Participants** | two separate reviewers |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

Nach jeder Implementierung: **ZWEI separate Review-Durchläufe**, nicht ein kombinierter.

### Pass 1: Spec Review

| Aspekt | Prüffrage |
|--------|-----------|
| **Vollständigkeit** | Sind alle Anforderungen implementiert? |
| **Korrektheit** | Entspricht die Logik der Spezifikation? |
| **Edge Cases** | Sind Randfälle aus der Spec abgedeckt? |
| **Fehlende Features** | Fehlt etwas, das in der Spec steht? |
| **Scope** | Wurde Over-Engineering vermieden? |

### Pass 2: Code Quality Review

| Aspekt | Prüffrage |
|--------|-----------|
| **Best Practices** | Hält sich der Code an Projekt-Standards? |
| **Lesbarkeit** | Ist der Code selbsterklärend? Sinnvolle Namen? |
| **Testabdeckung** | Sind Tests vorhanden und aussagekräftig? |
| **Performance** | Gibt es offensichtliche Performance-Probleme? |
| **Sicherheit** | Gibt es Security-Risiken? |
| **Wartbarkeit** | Ist der Code leicht änderbar? |

**Regel:** Diese MÜSSEN separate Dispatches sein — nicht ein kombinierter Review-Pass. Verschiedene Reviewer für jeden Pass bevorzugt.

---

## Retrospective

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | after |
| **Condition** | build failure, test failure, or reviewer rejection |
| **Facilitator** | lead |
| **Participants** | all-involved |
| **Time budget** | focused |
| **Enabled** | ✅ yes |

**Agenda:**
1. What happened? (facts only)
2. Root cause analysis
3. What should change?
4. Action items for next iteration
