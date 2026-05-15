# Slow-cron execution logic


`bf-teamlead-role-reminder` owns active-work wake-up, utilization, and parallel-dispatch discipline. Slow-cron pushes drift correction. They don't overlap.

Before auditing, read the Teamlead notebook at `~/.blueprint/<repo-dir>/teamlead.md` using `using-plueprint/references/teamlead-notebook.md`. Reconcile notebook state with live docs, PRs, issues, and worktrees. After any drift finding, assignment, blocker, or no-drift conclusion, update the notebook in the same turn.

## Four audit categories (priority order)

### 1. Is PROGRESS current?
- Read `docs/blueprint/next/README.md`, `docs/tasks/README.md`, and per-task `progress.md` rows; look at each Phase / Milestone / Task status.
- Reconcile against PRs merged since the last slow-cron checkpoint. If a PR merged but progress wasn't flipped → assign the Architect to patch it (small doc PR).
- Watch the Phase overview in `docs/tasks/README.md` carefully — it drifts the most.

### 2. Blueprint drift scan
- `git diff <last-slow-cron-sha>..HEAD --name-only` lists code-change files since the last slow-cron checkpoint.
- Files matching keywords (admin / auth / message / channel / agent) changed but no blueprint files changed in the same window — that's normal (blueprint changes drive code, not the other way around).
- **But** if code introduces a new concept (PR title contains "add" / "extend" / "feat:" but the description doesn't reference a blueprint section) → assign the Architect to audit and decide if the change needs to be reflected back into the blueprint.

### 3. docs/current cross-PR drift accumulation
- `git diff main HEAD docs/current/ <server-package>/ <client-package>/`
- Rule 6 is enforced at the PR level; slow-cron looks at cross-PR accumulation.
- If server / client changed but docs/current didn't follow → assign QA to patch.
- If docs/current changed but reads like code tour / PR history / test log / endpoint catalog → assign Architect + QA to repair using `bf-current-doc-standard`.
- A "carry-over: N/A — <reason>" opt-out is fine (consistent with the rule 6 lint), but check that the reason is genuinely reasonable.

### 4. Delayed flips
- A PR has been merged past the drift threshold, but its acceptance template is still ⚪ — flip was missed.
- Assign QA to flip it.
- If the project has its own regression / registry consistency math (active + pending = total), audit it here.

### 5. Open-PR task-completion audit (not just CI)

Under the protocol — one task, one PR — PRs are opened when the task branch is ready for review and everyone stacks required commits inside them. Slow-cron looks at how many `[ ]` items remain in each open PR's Acceptance / Test plan:

- `gh pr view <N> --json body | jq -r .body | grep -E "^- \\[ \\]"` lists the unticked items.
- Many `[ ]` items + no commits past the task-completion threshold → assign the matching role to commit into the worktree.
- **Don't rush to merge.** Green CI + LGTMs but Acceptance still has `[ ]` → leave a PR comment "waiting on role X to add Y", don't merge.

**Typical sticking points:**
- Dev's code has landed and e2e is green, but the acceptance template is still ⚪ → QA hasn't committed.
- Implementation is all in, but docs/current sync hasn't been patched → assign Dev to patch.
- The four-piece spec is in an old PR on main and was not included in the task worktree → assign the Architect to commit it into the worktree.

### 6. "Triaged but no native type" review-queue audit

`bf-issue-triage` allows a triager to apply only the `triaged` label (no native type, no status) when an issue is genuinely unclear. These accumulate into the user's manual review queue. Slow-cron checks the queue size:

```bash
gh api graphql -f query='query($owner:String!, $repo:String!) { repository(owner:$owner, name:$repo) { issues(first:100, states:OPEN, filterBy:{labels:["triaged"]}) { nodes { number title issueType { name } } } } }' -f owner=<o> -f repo=<r> \
  | jq '[.data.repository.issues.nodes[] | select(.issueType == null)] | length'
```

- If the count ≤ project threshold (default 5) → no flag, normal.
- If > threshold → flag in the cron report so the user knows to review. Don't escalate to Teamlead — these need human judgment, not coordination.
- AGENTS.md can override the threshold:
  ```yaml
  issue-triage:
    triaged-no-type-threshold: 5
  ```

Use the project-defined manual review cadence. Slow-cron only surfaces the count; the user decides each issue's type manually (which moves it into regular routing).

## Task state accuracy check

Confirm `docs/tasks/README.md`, `milestone.md`, and task `progress.md` match reality:
- A PR is merged and acceptance evidence exists → `bf-milestone-progress` must reconcile the task row, Active Task Resume, and milestone summary.
- A task is in progress → it must remain in Active Task Resume and must not be marked `ACCEPTED`.
- Anything inconsistent → run `bf-task-state-standard`, then dispatch the owning skill.

**Anti-patterns:**
- Accepted but still in Active Task Resume.
- In progress but marked `ACCEPTED`.

## Out-of-date red line (catch-all)

- If a next-blueprint file has not been reviewed past the drift threshold while the matching milestone/task has been progressing → assign the Architect to update the next status ledger or add a "Last reviewed: <date>" line to that blueprint file.
- This prevents the "blueprint left to rot" kind of drift.

## Output format

- All in sync: "docs in sync, no drift".
- Drift found: list specific PR # / files / who you're assigning.
- Dispatch drift fixes to the owning skill or role immediately; use `bf-teamlead-role-reminder` when utilization or parallel dispatch is the issue.
- Confirm the notebook was reconciled and updated, or state why no notebook change was needed.

## Anti-patterns

- Treating audit as forward motion (audit must end in dispatch, otherwise it's wasted).
- Running all four categories before producing any output (any single finding triggers immediate dispatch — don't wait for the rest).
- Mixing it with utilization management (slow-cron is dedicated to audit; `bf-teamlead-role-reminder` owns idle-team discipline).
- Auditing from memory without first reconciling `~/.blueprint/<repo-dir>/teamlead.md` against live sources of truth.
