---
name: "git-worktree"
description: "Worktree policy for parallel Squad agent work on Sheetstorm (Windows)"
domain: "version-control"
confidence: "high"
source: "team-decision"
---

## Context

Sheetstorm is developed by multiple Squad agents (Stark, Parker, Rogers, Pepper, Shuri, Banner, Romanoff, Scribe, Ralph) that may run **in parallel**. Two agents writing into the same working directory at the same time causes:

- Git index races and `.lock` file collisions
- Build races (shared `bin/obj`, `.dart_tool/`, generated files)
- Lost edits when one agent overwrites another's uncommitted file

The remedy is **Git Worktrees**: each parallel strand of work gets its own checkout on its own branch, backed by the same `.git` object store. This skill is the single source of truth for when and how to use them in Sheetstorm.

> **Windows note:** All examples use PowerShell and backslash paths. Do not translate to POSIX.

## When to Use a Worktree

| Situation | Worktree? |
|-----------|-----------|
| Issue-scoped feature or bugfix work | ✅ **Mandatory** |
| Two or more agents working the same repo simultaneously | ✅ **Mandatory** (one worktree per agent/branch) |
| Preparing a PR / review branch | ✅ **Mandatory** |
| Read-only research, grep, code reading | ❌ Not needed — use the main clone |
| Pure documentation edit on a short-lived branch, no parallel work | ❌ Not needed |
| Session artefacts (session-state, scratch notes outside the repo) | ❌ Not needed |

Rule of thumb: **if you are going to `git commit`, you should be in a worktree** — unless you are alone on the repo and on a dedicated branch already.

## Naming Conventions

- **Worktree root:** `C:\Privat\Sheetstorm-worktrees\{branch-slug}` — always a **sibling** of the main repo, never nested inside it.
- **Branch name:** `{type}/{issue-nr}-{kebab-slug}` — matches the commit convention.
  - Examples: `feat/124-pdf-labeler-mvp`, `fix/198-login-race`, `chore/squad-worktree-policy`
- **1 worktree = 1 branch = 1 issue / feature.** No shared worktrees across unrelated issues.

The `{branch-slug}` in the path is the branch name with `/` replaced by `-` (Windows-safe): `feat/124-pdf-labeler-mvp` → `feat-124-pdf-labeler-mvp`.

## Commands (PowerShell)

```powershell
# Create a worktree + branch off the current HEAD
git worktree add C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp -b feat/124-pdf-labeler-mvp

# Create a worktree off origin/main explicitly (recommended for fresh features)
git fetch origin
git worktree add C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp -b feat/124-pdf-labeler-mvp origin/main

# Switch into it
Set-Location C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp

# List all worktrees (run from anywhere inside the repo)
git worktree list

# Remove a worktree after the PR is merged
git worktree remove C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp

# Reap stale metadata (run when a worktree directory was deleted manually)
git worktree prune

# Delete the merged branch locally and on the remote
git branch -d feat/124-pdf-labeler-mvp
git push origin --delete feat/124-pdf-labeler-mvp
```

## Coordination Rules for Squad

1. **Coordinator provisions the worktree.** Before spawning an agent on issue-bound work, the Coordinator:
   - checks `git worktree list` for an existing worktree for the branch,
   - creates one if missing (`git worktree add …`),
   - includes the absolute path as `WORKTREE ROOT` in the spawn prompt.
2. **Agents stay inside `WORKTREE ROOT`.** No `cd` back into the main clone to write. All `git add`, `git commit`, `git push`, builds, tests, edits happen in the assigned worktree.
3. **`TEAM ROOT` resolves to the worktree, not the main clone.** Every worktree has its own copy of `.squad/`. Read and write `.squad/decisions/inbox/*`, logs, memos in the **current worktree**. They converge back on merge.
4. **`.squad/` strategy is Option A — per-worktree, git-native.** We do **not** symlink or junction `.squad/`. Append-only files (`history.md`, `decisions.md`, `log/*.md`) are handled by the `merge=union` gitattribute — union-merge reconciles parallel append edits automatically. Consequence: **never rewrite or reorder existing lines in `.squad/` append-only files inside a worktree** — only append. Rewrites lose data on merge.
5. **Two agents on the same issue share one worktree.** Commits are sequential. No parallel writes to the same file. If parallelism is needed inside one issue, split into two sub-branches + two worktrees instead.
6. **Clean up on merge or abort.** After the PR merges (or the work is abandoned), run `git worktree remove …` and, if needed, `git worktree prune` + delete the branch locally and on the remote.

## Windows Specifics

- **Backslash paths only.** Every script, prompt, or doc example inside Sheetstorm uses `C:\...` — do not generate `/c/...` or POSIX paths.
- **Avoid junctions / symlinks** for `.squad/` or source directories. Permission and reparse-point issues eat hours of debugging.
- **Per-worktree build caches are fine.** `bin/`, `obj/`, `.dart_tool/`, `node_modules/` live inside each worktree, so builds do not collide — at the cost of disk. This is the intended trade-off.
- **Flutter:** Run `flutter pub get` once per new worktree (`.dart_tool/` is worktree-local).
- **.NET:** `dotnet restore` + `dotnet build` work per worktree without extra setup.
- **PowerShell:** Use `Set-Location`, not `cd` from CMD. Keep `--no-pager` off any `git` call — `git` on Windows already paginates to stdout when no TTY.

## Example Workflow — Issue #124 (PDF Labeler MVP)

```powershell
# 1. Coordinator: provision the worktree
Set-Location C:\Privat\Sheetstorm
git fetch origin
git worktree add C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp -b feat/124-pdf-labeler-mvp origin/main

# 2. Spawn Parker with:
#    TEAM ROOT   = C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp
#    WORKTREE ROOT = C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp

# 3. Parker (inside the worktree):
Set-Location C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp
flutter pub get
# … implement, test, commit …
git add -A
git commit -m "feat: add pdf labeler widget (#124)"
git push -u origin feat/124-pdf-labeler-mvp

# 4. After PR merge: Coordinator cleans up
Set-Location C:\Privat\Sheetstorm
git worktree remove C:\Privat\Sheetstorm-worktrees\feat-124-pdf-labeler-mvp
git worktree prune
git branch -d feat/124-pdf-labeler-mvp
```

## Anti-Patterns

- ❌ Two agents writing into `C:\Privat\Sheetstorm` at the same time.
- ❌ Creating a worktree **inside** the main repo (e.g. `C:\Privat\Sheetstorm\worktrees\…`) — git refuses and/or the nested worktree pollutes status.
- ❌ Running `git` commands from the wrong worktree (check `git rev-parse --show-toplevel` before committing).
- ❌ Rewriting / reordering lines in `.squad/` append-only files inside a worktree. Only append.
- ❌ Forgetting `git worktree remove` / `git worktree prune` → zombie worktrees and stale branches accumulate.
- ❌ Spawning an agent without `WORKTREE ROOT` in the prompt.
- ❌ Symlinking `.squad/` across worktrees. Use per-worktree copies + union merge.

## Related

- `.squad/templates/skills/git-workflow/SKILL.md` — branch naming and PR flow (upstream reference).
- `.github/copilot-instructions.md` — short project-level summary of this policy.
- `.squad/routing.md` — coordinator duty to provision worktrees before spawn.
