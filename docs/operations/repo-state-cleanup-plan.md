# Repo State Cleanup Plan

Status: **Proposed** — awaiting PR reviews/merges.
Author: Copilot (chore/repo-state-cleanup worktree)

## Context

After the "archive docs, remove all implementation code" reset on `main`
(87df63b), several streams of work started in parallel without a shared base
commit that contains repo hygiene, Squad platform files, or team-level
documentation. This left `main` unable to serve as a solid base and produced
a swarm of untracked artefacts in the working tree of the active feature
worktree (`feat/124-pdf-labeler-mvp`).

This plan sequences the cleanup into small, reviewable PRs, without touching
the active feature branch's working tree.

## Classification of current untracked entries

Enumerated from `git ls-files --others --exclude-standard` in the main
worktree (`C:\Privat\Sheetstorm`, on `feat/124-pdf-labeler-mvp`).

| Path / prefix                                    | Classification              | Rationale |
|--------------------------------------------------|-----------------------------|-----------|
| `.claude/`                                       | **IGNORE** (PR1)            | User/tool specific cache for Claude Code; per-user, not shared. |
| `.github/skills/`                                | **TRACK** (future PR, scope TBD) | Reference docs for Copilot CLI skills; shared developer aid. Should be reviewed for duplication with `.squad/skills/` before tracking. |
| `.squad/agents/*/charter.md` (banner, parker, pepper, rogers, romanoff, shuri, stark) | **Already tracked on `chore/squad-worktree-policy`** | Will arrive on `main` via PR2. |
| `.squad/agents/*/history.md`                     | **UNCLEAR → likely IGNORE** | Runtime narrative of agent sessions. Should probably join the existing `.squad/sessions/` ignore pattern. Needs team decision. |
| `.squad/agents/ralph/charter.md`, `.squad/agents/scribe/charter.md` | **UNCLEAR → likely TRACK** | New agent charters not yet on `chore/squad-worktree-policy`. Recommend bundling into PR2 or a follow-up PR. |
| `.squad/casting/{history,policy,registry}.json` | **UNCLEAR → likely split**  | `policy.json` and `registry.json` look like configuration (TRACK). `history.json` is runtime (IGNORE). |
| `.squad/config.json`                             | **UNCLEAR → likely TRACK**  | Squad project configuration. Verify no secrets before committing. |
| `.squad/decisions.md`                            | **TRACK** (follow-up PR)    | Team decision log, already referenced from `.github/copilot-instructions.md`. |
| `.squad/identity/{now,wisdom}.md`                | **UNCLEAR → likely IGNORE** | Session-scoped identity notes; resembles runtime state. |
| `.squad/team.md`                                 | **TRACK** (follow-up PR)    | Team roster referenced from copilot instructions. |
| `.squad/templates/**`                            | **UNCLEAR**                 | Large reference corpus. Needs owner decision whether these are authoritative templates (TRACK) or a local scratchpad (IGNORE or move). |
| `.squad/ceremonies.md`, `.squad/routing.md`, `.squad/skills/git-worktree/SKILL.md` | **Already on `chore/squad-worktree-policy`** | Arrives via PR2. |
| `docs/market-analysis/noten-und-vereinsverwaltung.md` | **TRACK** (PR3)             | Shared research artefact. |
| `bin/`, `obj/`, `.dart_tool/`, `build/`, `.idea/`, `.vs/`, `node_modules/`, `TestResults/`, etc. | **IGNORE** (PR1)            | Tool/build output. |

> For everything marked **UNCLEAR**, PR2's owner (Squad platform) should
> make the call during review. This plan intentionally does not pre-empt
> that decision.

## PR sequence

### PR1 — `chore/repo-state-cleanup` → `main`
- Extends `.gitignore` with entries for `.claude/`, `.idea/`, Flutter
  `build/` + iOS/Android outputs, Node/Playwright artefacts, test/coverage
  output, and OS junk.
- No content changes beyond `.gitignore`.
- **Must merge first.** Every subsequent branch benefits from the wider
  ignore set.

### PR2 — `chore/squad-worktree-policy` → `main` (already exists)
- Existing branch adds Squad agent charters, routing, ceremonies, and the
  `git-worktree` skill.
- After PR1 merges, rebase `chore/squad-worktree-policy` onto the updated
  `main`:
  ```powershell
  git fetch origin
  git switch chore/squad-worktree-policy
  git rebase origin/main
  git push --force-with-lease
  ```
- Optionally bundle the currently-untracked `.squad/agents/ralph/charter.md`
  and `.squad/agents/scribe/charter.md` into this PR (owner's call).
- **Do not** include runtime state (`history.md`, `identity/now.md`, etc.).

### PR3 — `docs/market-analysis` → `main`
- Adds `docs/market-analysis/noten-und-vereinsverwaltung.md`.
- Independent of PR2; can merge any time after PR1.

### PR4 — `docs/framework-and-process-spec` → `main` (already exists)
- Existing branch adds `docs/specs/00-framework-and-process.md`.
- Currently branched off `chore/squad-worktree-policy`. After PR2 merges,
  rebase onto updated `main`:
  ```powershell
  git switch docs/framework-and-process-spec
  git rebase origin/main
  git push --force-with-lease
  ```

### Feature branch `feat/124-pdf-labeler-mvp`
- **Not touched by this plan.** Owned by the `squad-impl-124` agent.
- After PR1 merges, that owner should rebase:
  ```powershell
  git -C C:\Privat\Sheetstorm fetch origin
  git -C C:\Privat\Sheetstorm rebase origin/main
  # resolve any conflicts in .gitignore only
  ```

## Recommended merge order

1. **PR1** (`chore/repo-state-cleanup`) — unblocks everything else.
2. **PR2** (`chore/squad-worktree-policy`, rebased) — establishes Squad
   platform baseline on `main`.
3. **PR3** (`docs/market-analysis`) — independent, low-risk docs.
4. **PR4** (`docs/framework-and-process-spec`, rebased) — depends on PR2
   only for being semantically grouped; technically mergeable after PR1.
5. Notify `squad-impl-124` to rebase `feat/124-pdf-labeler-mvp` onto the
   new `main`.

## Risks

- **Rebasing shared branches (PR2, PR4):** only safe if no other agent has
  unpushed work on them. Coordinate with Squad owners before force-pushing.
- **Untracked `.squad/` content classification:** this plan punts the final
  TRACK/IGNORE call to PR2's owner. If the decision drifts, follow-up PRs
  may be needed to add missing `.gitignore` entries (e.g. for `history.md`
  files) or to track config files.
- **`feat/124-pdf-labeler-mvp` rebase conflicts:** unlikely given PR1 only
  touches `.gitignore`, but `squad-impl-124` should confirm that no
  previously-ignored files were accidentally committed on their branch.

## Rollback plan

Each PR is self-contained and revertable by a single `git revert <sha>` on
`main`. No history rewrites on `main` are proposed. If PR2's rebase of
`chore/squad-worktree-policy` produces unexpected conflicts, abort with
`git rebase --abort`; the branch's original tip is still referenced by the
remote until the force-push succeeds.

## Follow-up actions after all merges

1. `squad-impl-124` rebases `feat/124-pdf-labeler-mvp` (see command block
   above).
2. Owner of Squad platform decides the fate of currently UNCLEAR paths
   (`.squad/templates/`, `.squad/casting/*.json`, `.squad/config.json`,
   `.squad/identity/`, `.squad/agents/*/history.md`) and opens follow-up
   PRs to either track them or extend `.gitignore`.
3. Review whether `.github/skills/` is still needed given `.squad/skills/`;
   de-duplicate before tracking.
