# Phase vs wave

**Core question: did the locked next scope introduce a new value loop?**

| Trigger | What it is | Where it lives |
|---|---|---|
| Locked next anchors define a new user value loop | New **Phase N+1** with exit gate | `docs/tasks/phase-N-<name>/phase-plan.md` |
| Gap-to-target rewrite inside an existing value loop | **Milestone wave** inside existing Phase | `docs/tasks/phase-N-<name>/<milestone>/` or `docs/tasks/<wave-name>/` |
| Ad-hoc bug / feature from GitHub issue | Task or task set under the relevant milestone | `docs/tasks/phase-N-<name>/<milestone>/<task>/` |

## Wave structure

A wave = a milestone/task set with a shared closure gate inside an existing Phase. No new Phase row in the overview.

```
docs/tasks/phase-N-<name>/
├── phase-plan.md
├── milestone-1-<name>/
│   ├── milestone.md
│   └── task-seed.md
├── milestone-2-<name>/
│   └── milestone.md
└── ...
```

Concrete task folders appear under a milestone as individual tasks start, not during wave planning.

### Planning task carries

Wave planning is not a container PR exception. If the wave needs a planning change on its own, create a real planning task folder such as `task-0-plan-wave/` for PR ownership/progress; that task has one worktree, one branch, and one PR. The planning task PR carries:

1. `phase-plan.md` — milestone list, dependency graph, closure gate
2. One subdirectory per milestone — `milestone.md` with capability goal, acceptance boundary, dependencies, and task-split trigger
3. First-milestone task seed, enough to prove the wave can start without pretending every task is known
4. (Optional) container-level pre-work (e.g. Security pre-work for sensitive paths)
5. `docs/tasks/README.md` index entry

### Planning task does NOT carry

Complete task set — created in `milestone.md` when the milestone starts.

Product task folders and task-level 4-piece (spec / PM stance / content-lock / acceptance / design) — created when each task starts.

Container planning is **Phase/Milestone plan + first task seed**, not implementation specification.

Each task is its own PR. Task PR flow inside a wave is identical to any other task PR — `bf-git-workflow` + `bf-milestone-fourpiece` + `bf-pr-review-flow` apply unchanged.

### Wave closure signoff

| Gate type | Signoff roles | Why |
|---|---|---|
| **Phase exit** | Dev + PM + QA + Teamlead | Accepted scope can promote toward current |
| **Wave closure** | Dev + PM + QA + Security | Implementation deliverable |

Wave closure can be a final task PR (scope = wave closure evidence) or Phase gate artifact, depending on project size. It follows normal task PR review. No separate skill needed.

## Numbering rules

Phase numbers are historical markers, not counters — downstream dependents (release notes, migration plans, quarterly reviews) rely on mapping "what was true at Phase N exit" to "what changed between Phase N and Phase N+1".

| Rule | Phase | Wave |
|---|---|---|
| ID format | `phase-N-{name}` (number) | `<descriptive-name>` (name, no number) |
| Monotonic? | Yes — only goes up, no skip/rollback/split/merge | N/A — waves have no required order |
| On close | Eligible for accepted-scope promotion to current | Folder or completed tasks can move to `docs/tasks/archived/` |

## Anti-patterns

- ❌ New Phase for every gap-table rewrite (Phase counter inflation)
- ❌ Ad-hoc bug fix as a wave (overhead — single milestone is enough)
- ❌ Phase number skip / rollback / split (1a/1b) / merge (1.5)
- ❌ Wave numbering (Wave-1 / Wave-2 — implies sequence that doesn't exist)
- ❌ Wave name collision
- ❌ Treating a milestone folder as a PR atom; task folders are PR atoms
- ❌ Editing archived execution-plan to add a new Phase row (history is frozen; new Phases live in `docs/tasks/`)
