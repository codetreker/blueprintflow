# Changelog

## v1.4.1 — 2026-05-09

### Phase vs wave clarification (documentation patch)

After Phases are split, work that comes later was ambiguous: should every batch of milestones become "Phase N+1", or are some batches just waves inside the existing Phase? v1.4.0 didn't say. This patch writes the rule down.

The distinguishing question is: **did the blueprint contract itself change?** Three categories:

| Trigger | What it is | Where it lives |
|---|---|---|
| New blueprint version freezes (`blueprint-iteration`: next → current cutover) | Start a new Phase N+1 with its own value loop + exit gate | Run the full phase-plan flow |
| Current blueprint's "gap-to-target" rewrite (e.g. a `§3 with current state` table) | A milestone wave under the existing Phase | `docs/tasks/<wave-name>/phase-plan.md`, no Phase number |
| Ad-hoc bug / feature from a GitHub issue | A single milestone | `docs/tasks/<issue#>-<slug>/` |

Skill changes (3 files, 3 sections added):

- `blueprintflow-phase-plan` — new H2 "When to start a new Phase vs add a wave" between the preflight check and "How to split Phases" (covers the trigger table, wave folder layout, why the distinction matters, and three anti-patterns including Phase counter inflation)
- `blueprintflow-blueprint-iteration` — new H3 "After cutover: trigger a new Phase" inside the iteration lifecycle, naming `blueprintflow:phase-plan` as the only path that creates a new Phase
- `blueprintflow-phase-exit-gate` — new H2 "Phase exit gate vs wave closure gate" near the top, separating Phase exit (blueprint-version transition) from wave closure (milestone-set deliverable)

### Plugin version

- `plugin.json` bumped `1.4.0` → `1.4.1` (patch: documentation clarification, no flow change)

### Naming convention follow-up

`docs/tasks/` has two layers:

- **Leaf folder** (`<milestone-or-issue>`) — a single milestone or single GitHub issue
- **Container folder** (`<phase-or-wave>`) — Phase (`phase-N-{name}`) or wave (e.g. `borgee-helper-v1-release`); holds `phase-plan.md` plus leaf subfolders

A leaf can sit at the top level of `docs/tasks/` or nested inside a container (`docs/tasks/<wave>/<milestone>/`). See `blueprintflow-milestone-fourpiece` SKILL.md "Naming convention" for the worked example.

### Phase / wave numbering rules

- **Phase**: numbers only go up; no skip / no rollback / no split (1a / 1b) / no merge (1.5). A Phase that doesn't pass exit stays open as Phase N — work continues inside it.
- **Wave**: uses a descriptive name as the folder ID (`borgee-helper-v1-release/`), not a number — waves inside a Phase have no required order, so numbering would imply sequence the model doesn't carry.

See `blueprintflow-phase-plan` SKILL.md "Numbering rules" (H3 under "When to start a new Phase vs add a wave").

## v1.4.0 — 2026-05-09

### Default docs path upgrade

- Milestone artifacts default path changed from the older split layout (`docs/qa/<m>-*.md` + `docs/implementation/{modules,design}/<m>.md`) to the consolidated layout `docs/tasks/<m>/{spec,design,stance,content-lock,acceptance,progress}.md`.
- Cross-milestone index moves from `docs/implementation/PROGRESS.md` to `docs/tasks/README.md`; per-milestone progress goes into `docs/tasks/<m>/progress.md`.
- Phase exit artifacts move from `docs/qa/phase-N-{readiness-review,exit-announcement}.md` to `docs/tasks/phase-N-exit/{readiness-review,announcement}.md`.
- Closed milestones move as a whole folder to `docs/tasks/archived/<m>/`.
- Projects can still override paths via AGENTS.md / CLAUDE.md (this convention is unchanged).

Path-mapping table:

| Old path | New path |
|---|---|
| `docs/implementation/modules/<m>-spec.md` | `docs/tasks/<m>/spec.md` |
| `docs/implementation/design/<m>.md` | `docs/tasks/<m>/design.md` |
| `docs/qa/<m>-stance-checklist.md` | `docs/tasks/<m>/stance.md` |
| `docs/qa/<m>-content-lock.md` | `docs/tasks/<m>/content-lock.md` |
| `docs/qa/acceptance-templates/<m>.md` | `docs/tasks/<m>/acceptance.md` |
| `docs/implementation/PROGRESS.md` | `docs/tasks/README.md` (index) + `docs/tasks/<m>/progress.md` (per-milestone) |
| `docs/qa/phase-N-readiness-review.md` | `docs/tasks/phase-N-exit/readiness-review.md` |
| `docs/qa/phase-N-exit-announcement.md` | `docs/tasks/phase-N-exit/announcement.md` |

Affected skills (11 files, 22 path references): `blueprintflow-milestone-fourpiece`, `blueprintflow-git-workflow`, `blueprintflow-workflow`, `blueprintflow-team-roles` (pm / qa / architect references), `blueprintflow-phase-exit-gate`, `blueprintflow-implementation-design`, `blueprintflow-teamlead-slow-cron-checkin`, `blueprintflow-pr-review-flow`, `blueprintflow-phase-plan`.

### Placeholder + naming convention

- The folder placeholder is now `<milestone-or-issue>` (was `<milestone>` / `<m>`). The folder holds either a blueprint milestone or a feature/bugfix from a GitHub issue — both share the same shape (spec / stance / acceptance / etc.) and the same one-folder-one-PR rules; only the folder name varies.
- Naming rule documented in `blueprintflow-milestone-fourpiece` SKILL.md:
  - Blueprint milestone → blueprint code (e.g. `al-2a-content-lock`, `chn-4-cross-org`)
  - Feature / bugfix from a GitHub issue → `<issue#>-<short-slug>` (e.g. `698-agent-config-form-overlap`, `716-e2e-real-ui-audit`)
  - Anti-patterns: `m698-*` / `gh698-*` prefixes
- All `<milestone>` / `<m>/` placeholders across the skill set updated for consistency (worktree paths, branch names, PR titles, doc paths). Specific named placeholders like `<milestone-a>` / `<milestone-b>` (used as worked examples of parallel work) are kept.

### Plugin version

- `plugin.json` bumped `1.3.1` → `1.4.0` (minor: new default doc layout is a feature). Note: between 1.2.1 and current, main was bumped through 1.3.0 (#51) + 1.3.1 (#52); this PR is the first 1.x → 1.4.x transition.
