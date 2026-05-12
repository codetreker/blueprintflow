# Phase vs wave

**Core question: did the blueprint contract change?**

| Trigger | What it is | Where it lives |
|---|---|---|
| New blueprint version freezes | New **Phase N+1** with exit gate | `docs/tasks/phase-N-{name}/phase-plan.md` |
| Gap-to-target rewrite (same blueprint) | **Milestone wave** inside existing Phase | `docs/tasks/<wave-name>/phase-plan.md` |
| Ad-hoc bug / feature from GitHub issue | Single milestone | `docs/tasks/<issue#>-<slug>/` |

## Wave structure

A wave = a milestone set with a shared closure gate. No new Phase row in the overview — just a folder under `docs/tasks/`.

```
docs/tasks/<wave-name>/
├── phase-plan.md           # milestone list + closure gate
├── <milestone-1>/          # leaf folder
├── <milestone-2>/
└── ...
```

### Wave container PR carries

1. `phase-plan.md` — milestone list, dependency graph, closure gate
2. One subdirectory per milestone — placeholder `spec.md` (≤30 lines). Full 4-piece fills in when the milestone actually starts
3. (Optional) container-level pre-work (e.g. Security pre-work for sensitive paths)
4. `docs/tasks/README.md` index entry

### Wave container PR does NOT carry

Leaf-level 4-piece (PM stance / content-lock / acceptance / design) — those live with each leaf milestone when it starts. Container PR is **plan + placeholders**, not specifications.

Each leaf milestone is its own PR; the wave container PR is already merged by then. Leaf milestone PR flow inside a wave is identical to any other milestone PR — `bf-milestone-fourpiece` + `bf-pr-review-flow` apply unchanged.

### Wave closure signoff

| Gate type | Signoff roles | Why |
|---|---|---|
| **Phase exit** | Dev + PM + QA + Teamlead | Blueprint-version transition |
| **Wave closure** | Dev + PM + QA + Security | Implementation deliverable |

Wave closure = a regular milestone PR (scope = wave's full deliverable). Follows `bf-milestone-fourpiece` + `bf-pr-review-flow`. No separate skill needed.

## Numbering rules

Phase numbers are historical markers, not counters — downstream dependents (release notes, migration plans, quarterly reviews) rely on mapping "what was true at Phase N exit" to "what changed between Phase N and Phase N+1".

| Rule | Phase | Wave |
|---|---|---|
| ID format | `phase-N-{name}` (number) | `<descriptive-name>` (name, no number) |
| Monotonic? | Yes — only goes up, no skip/rollback/split/merge | N/A — waves have no required order |
| On close | Transitions to Phase N+1 | Folder moves to `docs/tasks/archived/<wave>/` |

## Anti-patterns

- ❌ New Phase for every gap-table rewrite (Phase counter inflation)
- ❌ Ad-hoc bug fix as a wave (overhead — single milestone is enough)
- ❌ Phase number skip / rollback / split (1a/1b) / merge (1.5)
- ❌ Wave numbering (Wave-1 / Wave-2 — implies sequence that doesn't exist)
- ❌ Wave name collision
- ❌ Editing archived execution-plan to add a new Phase row (history is frozen; new Phases live in `docs/tasks/`)
