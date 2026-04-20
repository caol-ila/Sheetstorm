# Ceremonies

> Team meetings that happen before or after work. Each squad configures their own.

## Issue Lifecycle — Worktree Step

| Field | Value |
|-------|-------|
| **Trigger** | auto |
| **When** | before any issue-scoped implementation work |
| **Condition** | work will produce commits on a feature/fix branch |
| **Facilitator** | coordinator |
| **Participants** | coordinator + assigned agent(s) |
| **Time budget** | quick |
| **Enabled** | ✅ yes |

**Agenda:**
1. Coordinator checks `git worktree list` for an existing worktree on the target branch.
2. If missing: `git worktree add C:\Privat\Sheetstorm-worktrees\{branch-slug} -b {type}/{issue-nr}-{slug} origin/main`.
3. Coordinator spawns the agent with `WORKTREE ROOT` set to the absolute worktree path.
4. After PR merge or abort: `git worktree remove …` + `git worktree prune` + delete the branch.

Full policy: `.squad/skills/git-worktree/SKILL.md`.

---

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
2. Agree on interfaces and contracts between components
3. Identify risks and edge cases
4. Assign action items

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
