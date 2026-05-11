# Phase vs wave

Phase split is a **blueprint-level** action — you split into Phases when a blueprint version freezes. After Phases are split, work that comes later belongs to one of three categories:

| Trigger | What it is | Where it lives |
|---|---|---|
| New blueprint version freezes (`blueprint-iteration`: next → current cutover) | Start a new **Phase N+1** with its own value loop + exit gate | Run the full phase-plan flow → `docs/tasks/phase-N-{name}/phase-plan.md` |
| Current blueprint's "gap-to-target" rewrite (e.g. a `§3 with current state` table that documents work still pending) | A **milestone wave** under the existing Phase | `docs/tasks/<wave-name>/phase-plan.md` (no Phase number; the wave itself names the work) |
| Ad-hoc bug / feature from a GitHub issue | A single milestone, no wave, no new Phase | `docs/tasks/<issue#>-<slug>/` |

The distinguishing question is: **did the blueprint contract itself change?** A new blueprint version means the product-shape source of truth changed — that warrants a new Phase boundary with its own exit gate. Rewriting the gap table inside an existing blueprint chapter doesn't change the contract; it just builds toward the existing target. That's a wave.

### Wave structure

A wave is just a milestone set with a shared closure gate. You don't create a new `Phase 5` row in the project's overview; you create a folder under `docs/tasks/` that holds the wave's milestones, and the closure milestone (often the most demonstrable one — a release demo, a fault-tolerance proof) carries the gate signoffs.

Wave folder layout:

```
docs/tasks/<wave-name>/
├── phase-plan.md           # the wave's milestone list + closure gate
├── <milestone-1>/          # leaf folder, normal milestone structure
├── <milestone-2>/
└── ...
```

`<wave-name>` and `phase-N-{name}` are **container folders**; the milestone subdirectories inside are **leaf folders**. See `blueprintflow-milestone-fourpiece` "Naming convention" for the leaf vs container split.

#### What goes in the wave container PR

The wave container itself is a milestone (one milestone, one PR — same rule). The container PR carries:

1. **`phase-plan.md`** — the wave's table of contents: milestone list (entry / exit per milestone), dependency graph, closure gate definition
2. **One subdirectory per planned milestone** — each holding a placeholder `spec.md` (≤30 lines: entry / exit / blueprint anchor). The full 4-piece for each milestone fills in later, when that milestone actually starts.
3. **(Optional) container-level pre-work** — e.g. a Security pre-work doc when the wave touches sensitive paths (auth / API keys / runtime install). Only for waves where pre-work is genuinely worth doing up front.
4. **`docs/tasks/README.md`** index entry pointing at the container

#### What the container PR does NOT carry

The container PR does **not** carry leaf-level 4-piece (PM stance / content-lock / acceptance template / Dev implementation design). Those live with each leaf milestone:

- Drafting them at container time is too abstract — execution context only becomes concrete when the leaf milestone actually starts
- Writing them in the container plus rewriting them in the leaf creates duplicates that drift apart
- A heavy container PR is harder to review

The container PR is intentionally light: **plan + placeholders**, not specifications.

#### When does the leaf milestone fill in 4-piece?

When a leaf milestone actually starts (Dev claims it, worktree opens), the four roles (Architect / PM / QA / Dev) write the leaf's 4-piece into the leaf folder using `blueprintflow-milestone-fourpiece`. Each leaf is its own PR; the wave container PR is already merged by then.

Leaf milestone PR flow inside a wave is identical to any other milestone PR — `milestone-fourpiece` + `pr-review-flow` apply unchanged.

#### Wave closure signoff

The closure milestone runs a 4-role signoff applied to the wave's specific deliverable, not to a Phase boundary. **The signoff roles are different from Phase exit**:

| Gate type | Signoff roles | Why |
|---|---|---|
| **Phase exit** (`phase-exit-gate`) | Dev + PM + QA + Teamlead | Phase boundary = blueprint-version transition; Teamlead coordinates the handoff and the project moves into the next Phase |
| **Wave closure** (closure milestone PR) | Dev + PM + QA + Security | Wave = implementation deliverable inside an existing blueprint; Security reviews the shipped code (not a Phase boundary), Dev signs off own implementation |

Wave closure is just a regular milestone PR whose scope is the wave's full deliverable. It follows the normal `blueprintflow-milestone-fourpiece` + `blueprintflow-pr-review-flow` process — no separate skill needed. The 4-role signoff above is what `pr-review-flow` already requires for any milestone PR; the wave-closure framing simply notes that this particular milestone is the wave's closure.

### Why this distinction matters

If you start a new Phase for every milestone wave, the Phase number loses its meaning (it just becomes a counter). Phases mark **blueprint-version transitions** so that dependents downstream (release notes, migration plans, quarterly reviews) can map "what was true at Phase N exit" to "what changed between Phase N and Phase N+1". A wave inside one blueprint version doesn't change what's true; it just fills in already-planned work.

Anti-patterns:

- ❌ Starting a Phase 5 for every gap-table rewrite (Phase counter inflation)
- ❌ Treating an ad-hoc bug fix as a wave (overhead — a single milestone is enough)
- ❌ Editing the `_archive`-d execution-plan.md to add a new Phase row (history is frozen; new Phases live in `docs/tasks/`)

### Numbering rules

**Phase numbers are monotonic and irreversible**:

- Phase numbers only go up. After Phase N is opened, the next Phase is N+1, never N+2 (no skipping).
- Phase exits don't roll back. If Phase N's exit gate doesn't pass, work continues inside Phase N — you don't drop back to Phase N-1.
- Phase exits don't split or merge. Trying to split Phase 1 into 1a / 1b means the work that justified the original Phase boundary was wrong; instead, use waves to organize internal subdivisions while keeping Phase 1 as one boundary. Likewise, merging Phase 1 + 2 into "Phase 1.5" is an anti-pattern.
- Phase numbers are historical markers — "Phase 1 closed = users can sign up and send messages" is a recorded fact, not a counter to increment.

**Waves use names, not numbers**:

- Inside a Phase, multiple waves may run with no required order between them. Numbering implies sequence, but waves don't need a sequence.
- Use a descriptive name as the folder ID: `helper-v1-release/`, `mobile-onboarding-rebuild/`, `eu-data-residency-rollout/`.
- Wave closure = the wave's whole folder moves to `docs/tasks/archived/<wave-name>/`.

**Anti-patterns**:

- ❌ Phase number skip (going from Phase 4 to Phase 6)
- ❌ Phase number rollback (dropping back to Phase 3 because Phase 4 didn't pass exit)
- ❌ Phase split (Phase 1a / Phase 1b)
- ❌ Phase merge (Phase 1 + 2 = Phase 1.5)
- ❌ Wave numbering (Wave-1 / Wave-2)
- ❌ Wave name collision (two folders named the same wave)
