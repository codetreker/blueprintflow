# Changelog

## v2.1.1 — 2026-05-13

### Activation standby boundary

- Clarified in `bf-workflow` that bare workflow activation is standby only: Teamlead reports runtime/boundaries and waits for a concrete objective instead of inspecting issues, PRs, git history, task docs, blueprint docs, worktrees, or spawning roles.
- Added an activation state table (`Standby` / `Assigned` / `Running` / `Paused`) plus an explicit pre-assignment Teamlead may/must-not boundary.
- Changed the bootstrap and cron language so role dispatch and cron setup start only after a named milestone, issue, PR, Phase, review, audit, or cron check-in.
- Narrowed the Codex adapter rule so activation authorizes role/helper delegation only after the user names a concrete Blueprintflow-scoped objective.

### Plugin version

- `plugin.json` bumped `2.1.0` → `2.1.1` (patch: activation standby boundary clarification).

## v2.1.0 — 2026-05-13

### Current docs standard

- Added `bf-current-doc-standard` for creating, updating, and reviewing `docs/current` as current implementation documentation, with anti-patterns and an on-demand initial template in `references/`.
- Wired the standard into Rule 6 current-sync checks, milestone execution, PR review, Teamlead cron audits, and role prompts.
- Added update/review guidance: integrate changes into the existing doc set from code context, then reread for flow and contradictions.

### Plugin version

- `plugin.json` bumped `2.0.3` → `2.1.0` (minor: new public skill for current-system documentation quality).

## v2.0.3 — 2026-05-13

### Skill composition rule

- Clarified in `bf-workflow` that Blueprintflow is the controlling workflow when active, and other process/implementation skills run only inside Blueprintflow role and stage boundaries.
- Added the rule that Teamlead dispatches leaf work such as context exploration, design, implementation, testing, verification, and review to roles/helpers instead of doing it directly.
- Documented serial fallback: if the runtime cannot support role/helper agents, Teamlead must declare the downgrade before doing role-lens work.
- Clarified in the Codex adapter that Blueprintflow activation authorizes role/helper delegation for Blueprintflow-scoped work.

### Plugin version

- `plugin.json` bumped `2.0.2` → `2.0.3` (patch: workflow composition clarification).

## v2.0.2 — 2026-05-12

### Codex marketplace package layout

- Moved the installable plugin package to `plugins/blueprintflow/` so Codex marketplace entries resolve to a real plugin subdirectory.
- Restored `.agents/plugins/marketplace.json` with `source.local.path = "./plugins/blueprintflow"`, matching Codex marketplace expectations.
- Removed duplicate root Codex plugin/skill content; `plugins/blueprintflow/skills/` is now the single source for public skills.
- Pointed the Claude marketplace entry at the same `plugins/blueprintflow/` package to keep one installable package layout.
- Added `scripts/validate-plugin-layout.sh` to catch duplicate root plugin content, marketplace path drift, and manifest version mismatches.
- Added GitHub Actions CI for JSON metadata, single-source plugin layout, skill frontmatter/reference integrity, whitespace, and required release-version bumps.

### Plugin version

- `plugin.json` bumped `2.0.1` → `2.0.2` (patch: installable marketplace package layout fix).

## v2.0.1 — 2026-05-12

### Codex root plugin install

- Removed the repo-local `.agents/plugins/marketplace.json` collection index so Codex installs Blueprintflow from the root `.codex-plugin/plugin.json`.
- Updated README Codex install instructions to use `codex plugin marketplace add codetreker/blueprintflow` for published installs.

### Plugin version

- `plugin.json` bumped `2.0.0` → `2.0.1` (patch: Codex install metadata fix).

## v2.0.0 — 2026-05-12

### Short skill names

- Renamed all public skill packages from `blueprintflow-*` to `bf-*`.
- Updated skill frontmatter names, README links, startup prompts, automation examples, and cross-skill references to use the new `bf-*` names.
- Kept the plugin/package brand name as `blueprintflow`; only individual skill entrypoints changed.

### Plugin version

- `plugin.json` bumped `1.5.2` → `2.0.0` (major: public skill trigger names changed).

## v1.5.2 — 2026-05-12

### Team role coordinator mode

- Clarified the Teamlead / role agent / helper execution layers in `bf-team-roles` using a structured coordinator-mode table.
- Added concise coordinator-mode guidance to Architect, PM, Dev, QA, Designer, and Security role prompts.
- Standardized helper delegation: role agents split bounded helper/reviewer tasks, require evidence, and summarize decisions, risks, and handoff to Teamlead.
- Replaced stale Dev prompt wording that suggested throwaway clones; Devs now use Teamlead-assigned `.worktrees/<milestone-or-issue>` worktrees.

### Plugin version

- `plugin.json` bumped `1.5.1` → `1.5.2` (patch: team role execution-boundary clarification).

## v1.5.1 — 2026-05-12

### Codex reasoning policy

- Added Codex `reasoning_effort` guidance by task type: `low` for mechanical/sleeper work, `medium` for bounded validation, `high` for implementation or ambiguous architecture/QA/CI work, and `xhigh` for security review or high-impact planning.
- Clarified that long-lived Teamlead and role coordinators inherit the current session effort, while short-lived helpers set effort by task type.

### Plugin version

- `plugin.json` bumped `1.5.0` → `1.5.1` (patch: Codex adapter guidance clarification).

## v1.5.0 — 2026-05-11

### Codex native packaging and adapter draft

- Added `.codex-plugin/plugin.json` so Blueprintflow can be installed as a Codex plugin while reusing the existing `skills/` directory.
- Added `.agents/plugins/marketplace.json` as the repo Codex marketplace index.
- Reworked `bf-runtime-adapter/references/codex.md` around Codex CLI, Codex App automations, cloud-task usage, activation checks, sleeper-subagent heartbeat fallback, role context reuse, and subagent capacity checks (`max_depth = 2`, `max_threads >= 24` for full team mode).
- Documented optional target-project `.codex/agents/` role templates without installing project-local Codex config from the marketplace repo.
- README now includes a Codex startup prompt.

### Plugin version

- `plugin.json` bumped `1.4.16` → `1.5.0` (minor: new Codex native packaging and runtime adapter support).

## v1.4.2 — 2026-05-09

### Wave container PR scope clarified

`bf-phase-plan` SKILL.md "Wave structure" gets new subsections explaining:

- What goes in a wave container PR (plan + placeholders, not full 4-piece)
- What does NOT go in (leaf-level 4-piece — those live with each leaf milestone)
- When the leaf milestone fills in its 4-piece (when the milestone actually starts)

Surfaced by Borgee PR #720 (`borgee-helper-v1-release` wave): the team initially planned to add PM stance / Security pre-design / acceptance template at the container level, but realized the container is just `plan + placeholders` — full 4-piece belongs to each leaf milestone when it starts.

### Plugin version

- `plugin.json` bumped `1.4.1` → `1.4.2` (patch — documentation clarification, no behavior change)

## v1.4.1 — 2026-05-09

### Phase vs wave clarification (documentation patch)

After Phases are split, work that comes later was ambiguous: should every batch of milestones become "Phase N+1", or are some batches just waves inside the existing Phase? v1.4.0 didn't say. This patch writes the rule down.

The distinguishing question is: **did the blueprint contract itself change?** Three categories:

| Trigger | What it is | Where it lives |
|---|---|---|
| New blueprint version freezes (`bf-blueprint-iteration`: next → current cutover) | Start a new Phase N+1 with its own value loop + exit gate | Run the full bf-phase-plan flow |
| Current blueprint's "gap-to-target" rewrite (e.g. a `§3 with current state` table) | A milestone wave under the existing Phase | `docs/tasks/<wave-name>/phase-plan.md`, no Phase number |
| Ad-hoc bug / feature from a GitHub issue | A single milestone | `docs/tasks/<issue#>-<slug>/` |

Skill changes (3 files, 3 sections added):

- `bf-phase-plan` — new H2 "When to start a new Phase vs add a wave" between the preflight check and "How to split Phases" (covers the trigger table, wave folder layout, why the distinction matters, and three anti-patterns including Phase counter inflation)
- `bf-blueprint-iteration` — new H3 "After cutover: trigger a new Phase" inside the iteration lifecycle, naming `bf-phase-plan` as the only path that creates a new Phase
- `bf-phase-exit-gate` — new H2 "Phase exit gate vs wave closure gate" near the top, separating Phase exit (blueprint-version transition) from wave closure (milestone-set deliverable)

### Plugin version

- `plugin.json` bumped `1.4.0` → `1.4.1` (patch: documentation clarification, no flow change)

### Naming convention follow-up

`docs/tasks/` has two layers:

- **Leaf folder** (`<milestone-or-issue>`) — a single milestone or single GitHub issue
- **Container folder** (`<phase-or-wave>`) — Phase (`phase-N-{name}`) or wave (e.g. `helper-v1-release`); holds `phase-plan.md` plus leaf subfolders

A leaf can sit at the top level of `docs/tasks/` or nested inside a container (`docs/tasks/<wave>/<milestone>/`). See `bf-milestone-fourpiece` SKILL.md "Naming convention" for the worked example.

### Phase / wave numbering rules

- **Phase**: numbers only go up; no skip / no rollback / no split (1a / 1b) / no merge (1.5). A Phase that doesn't pass exit stays open as Phase N — work continues inside it.
- **Wave**: uses a descriptive name as the folder ID (`helper-v1-release/`), not a number — waves inside a Phase have no required order, so numbering would imply sequence the model doesn't carry.

See `bf-phase-plan` SKILL.md "Numbering rules" (H3 under "When to start a new Phase vs add a wave").

### Wave closure signoff + index responsibilities

- **Wave closure 4-role signoff comparison table**: `bf-phase-plan` SKILL.md "Wave structure" now contrasts Phase exit (Dev + PM + QA + Teamlead) against wave closure (Dev + PM + QA + Security) — different role mix because Phase exit transitions blueprint versions while wave closure ships an implementation deliverable. Wave closure is just a regular milestone PR following `bf-milestone-fourpiece` + `bf-pr-review-flow`; no separate skill needed.
- **`README.md` vs `<container>/phase-plan.md` responsibilities**: `bf-milestone-fourpiece` SKILL.md "Naming convention" gets a new H3 — `docs/tasks/README.md` is the cross-folder index (lists top-level entries only, no recursion into containers); `<container>/phase-plan.md` is the container's own table of contents (lists the milestones inside that container + the closure gate).
- **Generic examples in rule body**: per the project-generic convention, rule-body examples now use generic names (`helper-v1-release`, `install-butler`); the Borgee-specific names live in a `> **Real example (Borgee):**` block under the mixed example.

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

Affected skills (11 files, 22 path references): `bf-milestone-fourpiece`, `bf-git-workflow`, `bf-workflow`, `bf-team-roles` (pm / qa / architect references), `bf-phase-exit-gate`, `bf-implementation-design`, `bf-teamlead-slow-cron-checkin`, `bf-pr-review-flow`, `bf-phase-plan`.

### Placeholder + naming convention

- The folder placeholder is now `<milestone-or-issue>` (was `<milestone>` / `<m>`). The folder holds either a blueprint milestone or a feature/bugfix from a GitHub issue — both share the same shape (spec / stance / acceptance / etc.) and the same one-folder-one-PR rules; only the folder name varies.
- Naming rule documented in `bf-milestone-fourpiece` SKILL.md:
  - Blueprint milestone → blueprint code (e.g. `al-2a-content-lock`, `chn-4-cross-org`)
  - Feature / bugfix from a GitHub issue → `<issue#>-<short-slug>` (e.g. `698-agent-config-form-overlap`, `716-e2e-real-ui-audit`)
  - Anti-patterns: `m698-*` / `gh698-*` prefixes
- All `<milestone>` / `<m>/` placeholders across the skill set updated for consistency (worktree paths, branch names, PR titles, doc paths). Specific named placeholders like `<milestone-a>` / `<milestone-b>` (used as worked examples of parallel work) are kept.

### Plugin version

- `plugin.json` bumped `1.3.1` → `1.4.0` (minor: new default doc layout is a feature). Note: between 1.2.1 and current, main was bumped through 1.3.0 (#51) + 1.3.1 (#52); this PR is the first 1.x → 1.4.x transition.
