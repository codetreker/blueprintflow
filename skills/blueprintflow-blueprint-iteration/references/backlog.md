# Backlog: GitHub issues as SSOT

The backlog's source of truth is GitHub issues, marked with the `backlog` label.

### Tag system (3 dimensions)

Each issue must carry a **native issue type** + at least one status label. Priority labels are project-optional. The native type comes from GitHub's built-in issue type field (Bug / Feature / Task), not from `type:*` labels.

**Type** (required, native field — set via GraphQL `updateIssueIssueType`):
- **Bug** — current blueprint says X but execution drifted / blueprint typo / constraint anchor missing
- **Feature** — new stance / new module / new requirement
- **Task** — technical debt accrued during execution (refactor / test coverage / docs lagging)
- For "unsure whether bug or feature, needs Architect / Teamlead to call", **don't set a type yet** — apply only the `triaged` label. The user reviews "triaged but no native type" issues periodically and decides type manually

**Status** (required, label, pick one):
- `backlog` — unplanned, waiting for the next-version discussion to pick it up
- `current-iteration` — pulled into the current iteration (bugfix / patch milestone)
- `next-iteration` — pulled into the next-version blueprint (blueprint-next stage)
- `archived` — kept for history, not handled (context value)
- `wont-fix` — evaluated and decided not to do, closed

**Priority (project-optional)**:
- `p0-blocker` / `p1-high` / `p2-normal` / `p3-low`

### Issue routing rules

New issues come in through **the entry-point triage**, which is `blueprintflow-issue-triage` (cron scan + Teamlead first call + Architect/PM/QA role classification + native type set + `triaged` label). This skill governs the **state-machine routing after triage**:

```
issue triaged (native type + triaged label applied) → state-machine routing:
  ├── Bug + covered by current blueprint → label `current-iteration` + assign patch / bugfix milestone
  ├── Feature / Task → label `backlog`, wait for next version
  └── (no type yet, only `triaged` label) → user reviews periodically + decides type

Next-version discussion opens → scan all `backlog` issues (review one by one):
  ├── Pulled in → move label from `backlog` → `next-iteration`
  ├── Rejected → label `wont-fix` + close
  └── Kept → keep `backlog` (but update issue body with "why still kept")
```

### Required fields in a backlog issue body

Every backlog issue body must contain (against "the title alone isn't enough"):

- **Source**: who proposed it / which PR # triggered it / which discussion
- **Why it goes here**: the real reason it isn't a bug — new stance / new module / low priority / not yet sure
- **Out of scope**: the boundary against the current iteration (so it doesn't get mistakenly stuffed back in)

### Constraints

- Every issue dropped into the backlog must explain "why it goes here"; the body can't be just a title
- **No automatic cleanup**, but **manually scan all `backlog` issues** every time a next-version discussion opens (miss this window and the backlog piles up)
- A bugfix issue must link to the current iteration's patch / bugfix milestone (issue and PR are bidirectionally traceable)
