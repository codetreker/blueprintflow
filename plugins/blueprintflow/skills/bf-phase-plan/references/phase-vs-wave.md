# Phase vs wave

**Core question: does the locked next scope require a new dependency-ordered stage or later integration boundary?**

Create a new Phase only for staged progress inside the active major iteration when prerequisite dependencies or integration boundaries make it useful. Keep a major iteration to <=3 Phases by default. Before adding a fourth Phase, stop and ask whether the split dimension is wrong, Phases can merge, or some work belongs as a milestone wave inside an existing Phase.

| Trigger | What it is | Where it lives |
|---|---|---|
| Locked next anchors define a real prerequisite or integration boundary | New **Phase N+1** with exit gate | `docs/tasks/phase-N-<name>/phase-plan.md` |
| Gap-to-target rewrite inside an existing Phase boundary | **Milestone wave** inside existing Phase | `docs/tasks/phase-N-<name>/<milestone>/` |
| Ad-hoc bug / feature from GitHub issue | Task or task set under the relevant milestone | `docs/tasks/phase-N-<name>/<milestone>/<task>/` |

## Wave structure

Keep each wave inside an existing Phase. Do not add a new Phase row for a wave.

Keep a Phase to <=3 user-facing milestones by default. Before adding a fourth Milestone, stop and ask whether the split dimension is wrong, Milestones can merge, or task-level detail is being misclassified as Milestone scope.

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

Task folders do not appear during wave planning.

### Planning change carries

Wave planning is not a container PR exception. If the wave needs a planning change on its own, publish one planning change when feasible. The planning change carries:

1. `phase-plan.md` — milestone list, dependency graph, closure gate
2. One subdirectory per milestone — `milestone.md` with `Readiness State: PLANNED`, capability goal, acceptance boundary, coarse dependencies, and readiness direction
3. (Optional) container-level pre-work (e.g. Security pre-work for sensitive paths)
4. `docs/tasks/README.md` index entry

### Planning change does NOT carry

Task folders, task skeletons, likely first tasks, and `task.md` contracts.

Task baseline docs (spec / PM stance / acceptance / optional content-lock) and later `design.md` — created only when each task starts.

Container planning is **Phase/Milestone plan**, not implementation specification.

Each task is its own PR. Task PR flow inside a wave is identical to any other task PR — `bf-git-workflow` + `bf-task-fourpiece` + `bf-pr-review-flow` apply unchanged.

### Wave closure signoff

| Gate type | Signoff roles | Why |
|---|---|---|
| **Phase exit** | Dev + PM + QA + Teamlead | Accepted scope can promote toward current |
| **Wave closure** | Dev + PM + QA + Security | Implementation deliverable |

Wave closure can be a final task PR (scope = wave closure evidence) or milestone closure summary, depending on project size. Use `bf-milestone-progress` to record the closure decision before Phase exit.

## Numbering rules

Phase numbers are historical markers, not counters — downstream dependents (release notes, migration plans, quarterly reviews) rely on mapping "what was true at Phase N exit" to "what changed between Phase N and Phase N+1".

| Rule | Phase | Milestone wave |
|---|---|---|
| ID format | `phase-N-{name}` (number) | `phase-N-{name}/milestone-M-{name}` or sibling milestone folders under the existing Phase |
| Monotonic? | Yes — only goes up, no skip/rollback/split/merge | N/A — waves have no required order |
| On close | Eligible for accepted-scope promotion to current | Folder or completed tasks can move to `docs/tasks/archived/` |

## Anti-patterns

- ❌ New Phase for every gap-table rewrite (Phase counter inflation)
- ❌ Ad-hoc bug fix as a wave (overhead — single milestone is enough)
- ❌ Creating more than 3 Phases or more than 3 Milestones per Phase without stopping to question the split
- ❌ Phase number skip / rollback / split (1a/1b) / merge (1.5)
- ❌ Wave numbering (Wave-1 / Wave-2 — implies sequence that doesn't exist)
- ❌ Wave name collision
- ❌ Treating a milestone folder as a PR atom; task folders are PR atoms
- ❌ Editing archived execution-plan to add a new Phase row (history is frozen; new Phases live in `docs/tasks/`)
