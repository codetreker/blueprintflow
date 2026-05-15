# Phase vs Milestone

**Core question: does the locked next scope need a separate dependency or integration stage?**

Create a new Phase only for staged progress inside the active major iteration: prerequisite dependencies, ordered rollout, or a later integration boundary. Keep a major iteration to <=3 Phases by default. Before adding a fourth Phase, stop and ask whether the split dimension is wrong, whether Phases can merge, or whether some scope is only a Milestone inside an existing Phase.

| Trigger | What it is | Where it lives |
|---|---|---|
| Locked next anchors require a prerequisite, ordered rollout, or integration boundary | New **Phase N+1** with exit gate | `docs/tasks/phase-N-<name>/phase-plan.md` |
| Gap-to-target rewrite inside an existing Phase boundary | **Milestone** inside existing Phase | `docs/tasks/phase-N-<name>/<milestone>/` |
| Ad-hoc bug / feature from GitHub issue | Task work under the relevant Milestone | `docs/tasks/phase-N-<name>/<milestone>/<task>/` |

## Milestone Structure

Keep related milestone work inside an existing Phase. Do not add a new Phase row when there is no new dependency or integration boundary.

Keep a Phase to <=3 user-facing Milestones by default. Before adding a fourth Milestone, stop and ask whether the split dimension is wrong, whether Milestones can merge, or whether task-level detail is being treated as Milestone scope.

Treat top-level wave folders such as `docs/tasks/<wave-name>/` as legacy or migration-only. Put new waves under the existing Phase so the Phase -> Milestone -> Task hierarchy stays intact.

```
docs/tasks/phase-N-<name>/
├── phase-plan.md
├── milestone-1-<name>/
│   └── milestone.md
├── milestone-2-<name>/
│   └── milestone.md
└── ...
```

Task folders do not appear during Phase/Milestone planning. Concrete tasks are created during task execution from the current Milestone context.

### Planning task carries

Phase/Milestone planning is not a container PR exception. If the plan needs a PR on its own, create a real planning change with one worktree, one branch, and one PR. The planning PR carries:

1. `phase-plan.md` — milestone list, dependency graph, closure gate
2. One subdirectory per Milestone — `milestone.md` with capability goal, acceptance direction, boundaries, coarse dependencies, known risks, and readiness questions
3. (Optional) Phase-level pre-work notes, such as Security questions for sensitive paths
4. `docs/tasks/README.md` index entry

### Planning task does NOT carry

Task seed files, likely-first-task guesses, task skeleton folders, dependency order, parallelism plan, and `task.md` contracts.

Task baseline docs (spec / PM stance / acceptance / optional content-lock) and later `design.md` — created only when each task starts.

Container planning is **Phase/Milestone plan only**, not implementation specification.

Each task is its own PR. Task PR flow inside a Milestone is identical to any other task PR — `bf-git-workflow` + `bf-task-fourpiece` + `bf-pr-review-flow` apply unchanged.

### Milestone Closure Signoff

| Gate type | Signoff roles | Why |
|---|---|---|
| **Phase exit** | Dev + PM + QA + Teamlead | Accepted scope can promote toward current |
| **Milestone closure** | Dev + PM + QA + Security when sensitive | Implementation deliverable |

Milestone closure can be a final task PR or milestone closure summary, depending on project size. Use `bf-milestone-progress` to record the closure decision before Phase exit.

## Numbering rules

Phase numbers are historical markers, not counters — downstream dependents (release notes, migration plans, quarterly reviews) rely on mapping "what was true at Phase N exit" to "what changed between Phase N and Phase N+1".

| Rule | Phase | Milestone |
|---|---|---|
| ID format | `phase-N-{name}` (number) | `phase-N-{name}/milestone-M-{name}` or sibling milestone folders under the existing Phase |
| Monotonic? | Yes — only goes up, no skip/rollback/split/merge | Ordered only by real dependency |
| On close | Eligible for accepted-scope promotion to current | Folder or completed tasks can move to `docs/tasks/archived/` |

## Anti-patterns

- ❌ New Phase for every gap-table rewrite (Phase counter inflation)
- ❌ Ad-hoc bug fix as a Milestone when normal task work is enough
- ❌ Phase number skip / rollback / split (1a/1b) / merge (1.5)
- ❌ Milestone numbering without real dependency order
- ❌ Milestone name collision
- ❌ Treating a milestone folder as a PR atom; task folders are PR atoms
- ❌ Editing archived execution-plan to add a new Phase row (history is frozen; new Phases live in `docs/tasks/`)
