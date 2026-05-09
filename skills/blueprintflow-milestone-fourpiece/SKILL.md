---
name: blueprintflow-milestone-fourpiece
description: "Part of the Blueprintflow methodology. Use when a milestone starts and code has not begun - establishes the 4 baseline docs (spec brief, stance, content lock, acceptance template) inside one milestone PR."
---

# Milestone 4 pieces

Each milestone goes in **one PR, merged once**: the 4 pieces + three execution segments + e2e + docs/current sync + REG flip + acceptance ⚪→✅ + PROGRESS [x] **all in the same PR**. No more splitting spec / acceptance / content lock / stance into 4 separate doc PRs, and no more splitting schema / server / client into 3 separate execution PRs.

**Git workflow companion** (see `blueprintflow-git-workflow`):
- Teamlead creates `.worktrees/<milestone-or-issue>` + branch `feat/<milestone-or-issue>`
- The 4-piece authors (Architect / QA / PM) **don't open separate PRs** — everyone stacks commits in the same worktree
- Once everyone has committed → Teamlead is the sole PR opener

**Counter-example (the old way)**: a milestone split into 8-10 PRs, each with dual review + CI + rebase + serial writes on §5 totals + closure follow-up trailing behind. In practice it's much slower than "one PR for the whole milestone".

## Default doc layout: one folder per milestone

All milestone artifacts live together under `docs/tasks/<milestone-or-issue>/`:

```
docs/tasks/<milestone-or-issue>/
├── spec.md           # Architect spec brief (the §0-§4 four pieces)
├── stance.md         # PM stance checklist
├── content-lock.md   # PM content lock (client UI milestones only)
├── acceptance.md     # QA acceptance template
├── design.md         # Dev implementation design
└── progress.md       # per-milestone progress (✅ / ⚪ / 🔄 + REG flips)
```

Phase exit gate artifacts go under `docs/tasks/phase-N-exit/` (readiness-review.md / announcement.md). The cross-milestone index lives at `docs/tasks/README.md`.

When a milestone fully closes (acceptance ✅ + REG flipped + PROGRESS [x]), the whole folder moves to `docs/tasks/archived/<milestone-or-issue>/`. One move, one place to look.

**Why one folder per milestone**: the older layout split things by artifact type — acceptance templates lived in `docs/qa/acceptance-templates/`, spec briefs in `docs/implementation/modules/`, stance / content-lock in `docs/qa/<m>-*.md`. A single milestone's 5-6 artifacts ended up spread across 4-6 directories. Finding "everything about milestone X" meant grepping across the whole tree, and closing a milestone meant touching files in multiple directories. The new layout keeps the work unit intact: one milestone is one folder, and closing it is one folder move.

**Project override**: projects can adjust paths via AGENTS.md / CLAUDE.md (the convention from `blueprintflow-workflow` still holds). The defaults below assume the new layout.

## Naming convention

`docs/tasks/` holds two kinds of folders:

- **Leaf folders** (`<milestone-or-issue>`) — a single piece of work
  - Blueprint milestone: use the blueprint code (e.g. `al-2a-content-lock`, `chn-4-cross-org`)
  - GitHub issue: use `<issue#>-<short-slug>` (e.g. `698-agent-config-form-overlap`, `716-e2e-real-ui-audit`)
  - Anti-pattern: `m698-*` / `gh698-*` prefixes — folder name describes *what the work is about*, not *which milestone code*

- **Container folders** (`<phase-or-wave>`) — a group of related milestones with a shared closure gate
  - Phase (new blueprint version): `phase-N-{name}` (e.g. `phase-5-multi-host`)
  - Wave (gap-table rewrite inside an existing blueprint version): the wave's name (e.g. `helper-v1-release`)
  - Container folders hold a `phase-plan.md` at the top (the container's gate + milestone list) plus the milestone leaf folders inside

Mixed example:

```
docs/tasks/
├── 698-agent-config-form-overlap/         # leaf (issue)
├── al-2a-content-lock/                    # leaf (blueprint milestone)
├── helper-v1-release/                     # container (wave)
│   ├── phase-plan.md
│   ├── install-butler/                    # leaf inside container
│   ├── manifest-signing/
│   └── devagent-demo/
└── archived/
```

> **Real example (Borgee):** Borgee uses `borgee-helper-v1-release/` (wave) holding `HB-7-install-butler/`, `HB-8-manifest-signing/`, `HB-14-devagent-demo/` (leaves), driven by issue #681 — see `docs/tasks/borgee-helper-v1-release/phase-plan.md`.

### README.md vs container phase-plan.md

- **`docs/tasks/README.md`** is the cross-folder index. It lists every entry directly inside `docs/tasks/` — both leaf folders (single milestones / issues) and container folders (phases / waves). It does NOT recursively list the milestones inside a container.
- **`<container>/phase-plan.md`** is the container's own table of contents — it lists the milestones inside that container, the closure gate, and any container-specific context.

When a Dev wants "everything inside wave X", they open `docs/tasks/<X>/phase-plan.md`. When they want "all in-flight work across the project", they open `docs/tasks/README.md`.

Both leaf kinds share the same folder shape (spec / stance / acceptance / etc.) and the same one-folder-one-PR rules; only the folder name varies.

## The 4 pieces

### 1. Architect spec brief
**Path**: `docs/tasks/<milestone-or-issue>/spec.md` (≤80 lines)

> **Note**: spec brief covers only §0-§4. §5+ sections (dispatch / self-review / changelog) are not allowed (see anti-patterns).

Structure:
- §0 key constraints (3 stances)
- §1 segmentation ≤3 PRs (schema / server / client)
- §2 carry-over boundary (interfaces with other milestones)
- §3 reverse-check grep anchors (including constraints)
- §4 not in scope (kept for v2+)

> **Real example (Borgee):** see RT-1 / CHN-1 / AL-3 / CV-1 / AL-4 spec briefs — each 50-80 lines, with schema + server + client segmentation.

### 2. PM stance checklist
**Path**: `docs/tasks/<milestone-or-issue>/stance.md` (≤80 lines)

Structure:
- 5-7 stances, each one sentence anchored to §X.Y + constraint (X is, Y isn't) + v0/v1
- Blacklist grep + not-in-scope + acceptance hooks
- v0/v1 transition criteria (if needed, follow the same PR # lock rules as v1 transition)

### 3. QA acceptance template
**Path**: `docs/tasks/<milestone-or-issue>/acceptance.md` (≤50 lines)

Structure:
- 1:1 aligned with the segmentation (§1 schema / §2 server / §3 client)
- Acceptance four-choice: E2E / blueprint behavior comparison / data contract / behavior invariants
- REG-* register placeholders (⚪ awaiting execution to flip 🟢)
- Reverse-check anchors + exit conditions

### 4. PM content lock (only required for client UI milestones)
**Path**: `docs/tasks/<milestone-or-issue>/content-lock.md` (≤40 lines)

Structure:
- DOM literal lock (data-* attributes / copy byte-identical)
- Constraint: synonym blacklist + reverse grep
- Demo screenshot path prepared

If the milestone introduces new visual components, this links into the Designer's design system (future extension).

## Step 5: Dev writes the implementation design before code

Once the 4 pieces are in place, before splitting and starting execution, Dev writes an implementation design (`docs/tasks/<milestone-or-issue>/design.md`). It's reviewed by Architect / PM / Security / QA, and **only released to write code once all 4 sign off ✅**.

Scope:
- ✅ Any milestone that touches code **must** go through it (any change to schema / server / client)
- ❌ Non-code milestones (docs-only / config-only / literal-only adjustments) can skip

PR protocol:
- The design document is **not a separate PR** — it's stacked as a commit in the same worktree as the 4 pieces, all inside the milestone PR (sticking to the "one milestone, one PR" rule)
- Review goes through worktree-internal communication / PR comments, not via opening a separate PR

Full spec in `blueprintflow-implementation-design`.

## Hard condition: literal consistency across the 4 pieces

spec / stance / acceptance / content-lock cite each other's §X.Y anchors. Any drift gets caught during the others' reviews (cross-PR drift gets caught).

> **Real example (Borgee):** QA self-check found that field names in the acceptance template had drifted from the spec brief (a field rename hadn't been propagated). Patched on the spot to align (the dual review rails worked).

## Dispatch template

When the milestone starts (**Teamlead is the sole** worktree creator and dispatcher):

```bash
# 1. Teamlead creates the worktree (one milestone, one worktree)
cd <repo-root>
git worktree add .worktrees/<milestone-or-issue> -b feat/<milestone-or-issue> origin/main
```

```
2. Dispatch Architect (in .worktrees/<milestone-or-issue>): spec brief, commit + push, no PR
3. Dispatch PM (same worktree): stance checklist + content lock, commit + push, no PR
4. Dispatch QA (same worktree): acceptance template, commit + push, no PR
5. Dispatch Dev (same worktree): write implementation design (docs/tasks/<milestone-or-issue>/design.md), commit + push
6. Dispatch Architect / PM / Security / QA to review the design; only release once all ✅
7. Dispatch Dev (same worktree): three execution segments + e2e + docs/current sync + REG/acceptance/PROGRESS flips, commit + push, no PR
8. Everyone ready → Teamlead is the sole PR opener (gh pr create)
9. PR merged → Teamlead removes the worktree
```

Detailed git protocol in `blueprintflow-git-workflow` (roles don't open PRs / Teamlead is the sole PR opener / one worktree per milestone).

## Segmented execution (committed sequentially in the same PR)

Everyone stacks commits in the **same worktree + same branch** (no role opens a PR; Teamlead opens it at the end):
- 1.1 schema (migration v=N + tables + drift test) — Dev
- 1.2 server (API + business logic + reverse-assertion test) — Dev
- 1.3 client (UI + e2e) — Dev
- 1.4 docs/current sync (server / client docs) — Dev
- 1.5 REG-* flipped 🟢 + acceptance template ⚪→✅ + PROGRESS [x] — QA / Dev
- (parallel) spec brief — Architect
- (parallel) stance + content lock — PM
- (parallel) acceptance template — QA

Worktree protocol:

```bash
# Teamlead creates (sole)
cd <repo-root>
git worktree add .worktrees/<milestone-or-issue> -b feat/<milestone-or-issue> origin/main

# Roles work (multiple people, multiple commits OK; everyone pushes the same branch)
cd .worktrees/<milestone-or-issue>
# ... work ...
git push origin feat/<milestone-or-issue>

# Teamlead opens the sole PR (after every role is ready)
gh pr create --title "feat(<milestone-or-issue>): ..." --body "..."

# After PR merge, Teamlead removes the worktree (sole)
cd <repo-root>
git worktree remove .worktrees/<milestone-or-issue>
```

## Closure lands in the same PR; no follow-up

acceptance ⚪→✅ + REG-* + PROGRESS [x] all land in the same PR as the implementation, on the same commit run. **No closure follow-up PR.**

## File-naming convention

Code files are named by **actual functionality**, not by milestone number.

**Good patterns:**
- `agent_status.go` — obviously about agent status
- `canvas_renderers_test.ts` — obviously testing the canvas renderers
- `privacy_promise.tsx` — obviously the privacy-promise component

**Anti-patterns:**
- ❌ `al_1b_2_status.go` — six months later nobody remembers what milestone `al_1b` was
- ❌ `cv_3_3_renderers_test.ts` — you have to look up which milestone `cv-3-3` is to know what's being tested
- ❌ `cm5stance/` — directory name is the milestone number concatenated; should just be `stance_checklist/`

**Principle:** milestone numbers are a project-management concept and don't belong in filenames. Filenames are read by humans and code tools — they should be self-explanatory. Cite milestone numbers in PR descriptions and commit messages; that's enough.

## Anti-patterns

- ❌ Skipping the 4 pieces and going straight to execution (stance drift can't be caught)
- ❌ Splitting into multiple PRs (spec / schema / server / client / closure each their own PR — actually slower)
- ❌ Execution PR doesn't cite spec § anchors (cross-PR drift can't be caught)
- ❌ Using `/tmp/<work>` as a temporary clone (use `.worktrees/<milestone-or-issue>` instead)
- ❌ One milestone on multiple branches (collisions + dirty history)
- ❌ **spec brief writing §5/§6/§7 sections (dispatch / Architect self-review / changelog)**

  **Background**: those trailing sections are all duplication — dispatch records are already in PR body + communication history; Architect self-review goes through PR review comments; changelog is implicit in git log + git blame. And the trailing narrative changelog is the main cause of doc collisions (shared changelog / closure section / the last few lines of the spec brief all become the bottleneck where parallel waves try to flip status at once).

  > **Real example (Borgee):** 60+ spec briefs all hit it; the trailing narrative changelog crowded into `phase-4.md` / `closure §1` / the spec brief's last few lines.

  **How to apply**: spec brief stays ≤80 lines, only §0-§4 (key constraints / segmentation / carry-over / reverse-check grep / not in scope). Dispatch goes through notification / Task; self-review goes through PR review comment; changelog goes through git log + PR body. Don't pile a narrative changelog at the bottom of the spec brief.

- ❌ **Content lock written too far ahead of implementation, not cross-grepped against existing code**

  **Background**: the literal copy in the content lock draft drifts from existing implementation because no cross-grep was done. Later execution aligns with existing code (reasonably), and the content-lock document becomes an orphan.

  **How to apply**: before writing the content lock, run a reverse-check grep against existing implementation: `grep -rnE "<candidate-literal>" <client-package>/ <server-package>/`. If existing literals are matched, align the content lock to them rather than inventing literals from a draft. If existing implementation conflicts with the stance, change both implementation and content lock together so they end up byte-identical.
