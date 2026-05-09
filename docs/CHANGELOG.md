# Changelog

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

### Plugin version

- `plugin.json` bumped `1.2.1` → `1.4.0`. This also fixes a historical bug where the v1.3.x release tags landed in the marketplace but `main` plugin.json was never bumped past 1.2.1.
