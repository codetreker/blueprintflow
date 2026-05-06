---
name: blueprintflow-teamlead-slow-cron-checkin
description: "Part of the Blueprintflow methodology. Use on 2-4h cron tick or when drift signals appear - Teamlead audits blueprint drift, docs/current sync, delayed acceptance flips, and stale worktrees."
---

# Teamlead slow-cron check-in

`blueprintflow:teamlead-fast-cron-checkin` pushes idle dispatches forward; slow-cron pushes drift correction. They don't overlap.

## Four audit categories (priority order)

### 1. Is PROGRESS.md current?
- Read `docs/implementation/PROGRESS.md` and look at each Phase / milestone row's ✅ / ⚪ / 🔄 status.
- Reconcile against PRs merged in the last 2-4 hours. If a PR merged but PROGRESS wasn't flipped → assign the Architect to patch it (≤30 LOC doc PR).
- Watch the Phase overview row carefully — it drifts the most.

### 2. Blueprint drift scan
- `git log --since="4 hours ago" --name-only` lists code-change files.
- Files matching keywords (admin / auth / message / channel / agent) changed but no blueprint files changed in the same window — that's normal (blueprint changes drive code, not the other way around).
- **But** if code introduces a new concept (PR title contains "add" / "extend" / "feat:" but the description doesn't reference a blueprint section) → assign the Architect to audit and decide if the change needs to be reflected back into the blueprint.

### 3. docs/current cross-PR drift accumulation
- `git diff main HEAD docs/current/ <server-package>/ <client-package>/`
- Rule 6 is enforced at the PR level; slow-cron looks at cross-PR accumulation.
- If server / client changed but docs/current didn't follow → assign QA to patch.
- A "carry-over: N/A — <reason>" opt-out is fine (consistent with the rule 6 lint), but check that the reason is genuinely reasonable.

### 4. Delayed flips
- A PR has been merged for more than 2-4 hours, but its acceptance template is still ⚪ — flip was missed.
- Assign QA to flip it.
- If the project has its own regression / registry consistency math (active + pending = total), audit it here.

### 5. Open-PR task-completion audit (not just CI)

Under the new protocol — one milestone, one PR — PRs are opened early and everyone stacks commits inside them. Slow-cron looks at how many `[ ]` items remain in each open PR's Acceptance / Test plan:

- `gh pr view <N> --json body | jq -r .body | grep -E "^- \\[ \\]"` lists the unticked items.
- Many `[ ]` items + no commits for a long time (≥4h) → assign the matching role to commit into the worktree.
- **Don't rush to merge.** Green CI + LGTMs but Acceptance still has `[ ]` → leave a PR comment "waiting on role X to add Y", don't merge.

**Typical sticking points:**
- Dev's code has landed and e2e is green, but the acceptance template is still ⚪ → QA hasn't committed.
- Implementation is all in, but docs/current sync hasn't been patched → assign Dev to patch.
- The four-piece spec is in an old PR on main and was not cherry-picked into the milestone worktree → assign the Architect to commit it into the worktree.

## PROGRESS accuracy check

Confirm PROGRESS.md matches reality:
- A PR is merged → the matching milestone must already be ticked ✅.
- A task is in progress → it must not be marked Done.
- Anything inconsistent → fix it immediately.

**Anti-patterns:**
- Done but not ticked.
- Not done but marked Done.

## Out-of-date red line (catch-all)

- If any blueprint file has mtime > 1 day and the matching milestone has been progressing in recent PRs → assign the Architect to add a "Last reviewed: <date>" line to that blueprint file.
- This prevents the "blueprint left to rot" kind of drift.

## Output format

- All in sync: "docs in sync, no drift".
- Drift found: list specific PR # / files / who you're assigning.
- Dispatch priority follows fast-cron's order (unblock > follow-up > forward > maintenance).

## Anti-patterns

- Treating audit as forward motion (audit must end in dispatch, otherwise it's wasted).
- Running all four categories before producing any output (any single finding triggers immediate dispatch — don't wait for the rest).
- Mixing it with fast-cron's idle dispatch (slow-cron is dedicated to audit, fast-cron is dedicated to idle).

## How to invoke

Set the cron prompt to:
```
[drift audit · 2 hours]
follow skill blueprintflow-teamlead-slow-cron-checkin
```

## Companion

- Fast-paced idle dispatch goes through `blueprintflow:teamlead-fast-cron-checkin`. The two don't overlap.
