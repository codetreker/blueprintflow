# Current Promotion Checklist

Use after next work is accepted and `docs/blueprint/next/README.md` rows are ready for `COMPLETED` / current sync.

## Preconditions

- Relevant task PRs are merged.
- Acceptance evidence is complete.
- Required milestone, wave, or Phase gates are recorded.
- `docs/current` sync is done or explicitly N/A.
- User/PM acceptance is recorded for user-perceivable behavior.

## Steps

1. Read accepted next anchors and cited task evidence.
2. Update `docs/blueprint/current/` with implemented-and-accepted product truth only.
3. Preserve version frontmatter: `accepted`, `prev`, and target version.
4. Update `docs/blueprint/_meta/<target-version>/source-issues.md` traceability if needed.
5. Mark corresponding `docs/blueprint/next/README.md` rows `Work=COMPLETED` or confirm already current-synced.
6. Tag `blueprint-vN.M` when the accepted scope is promoted.
7. Record promotion summary in the PR body or task/milestone closure summary.

## Checks

- No planned or speculative behavior enters `current`.
- Every current change maps to accepted evidence.
- Reopened or partially accepted anchors stay in `next` with `Decision=REOPENED` or `Work=IMPLEMENTING`.
- `docs/current` and `docs/blueprint/current` do not contradict each other.

## Anti-patterns

- Promoting because implementation merged but acceptance is incomplete.
- Copying `next` wholesale into `current`.
- Removing next rows without traceability.
- Tagging before gates and current sync are recorded.
