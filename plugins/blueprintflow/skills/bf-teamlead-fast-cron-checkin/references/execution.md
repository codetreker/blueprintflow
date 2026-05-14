# Fast-cron execution logic


The cron is not a status report. It is a forward-motion action. Every check-in must hand out new work to every idle role; otherwise you've failed the job.

Before dispatching, read the Teamlead notebook at `~/.blueprint/<repo-dir>/teamlead.md` using `bf-workflow/references/teamlead-notebook.md`. After assigning work, recording a legitimate wait state, flagging a blocker, or making a merge-gate decision, update the notebook in the same turn.

## Sections

| Section | Use |
|---|---|
| 1-3 | Idle-role dispatch and priority |
| 3.1 | `docs/tasks` resume-state dispatch |
| 4 | Cron output format |
| 5 | Merge gate and task-completion check |
| Default dispatch list | Per-role fallback work |
| PR BLOCKED routing | Assign blocked PR fixes |
| Anti-patterns | Avoid audit-only or CI-only decisions |

### 1. The cron must ACT, not just audit
Every idle role must walk away with new work. Only two exceptions:
- They are waiting on a specific blocker (write down the PR # / dependency).
- Their current in-flight task hasn't been wrapped up yet.

### 2. When "waiting on X" counts as legitimate idle

**Legitimate**: the agent is genuinely in a wait state (continuously listening for task completion / continuously polling PR CI status), not just having said something and stopped.

**Not legitimate**: the agent sent one message and went idle without actually waiting for anything. Kick them with new work.

How to tell: if an agent has had no new output for 5+ minutes, it has most likely just stopped after speaking. Hand it new work. While the merge agent is running, everyone else can work in parallel:
- Dev → start implementing the next ready task in its own worktree
- Architect → next batch of task spec briefs / blueprint patches / reviewing older PRs
- PM → next batch of stance cross-checks / content lock / demo screenshots
- QA → next batch of acceptance templates / REG flips / e2e flake fixes

### 3. Pick-1-of-4 dispatch priority
Look for new work in this order:
- a) **unblock**: there's a concrete blocker holding other people up — fix that first
- b) **follow-up**: an issue exposed by the last merged PR, or a flip that was left as carry-over
- c) **forward**: the next task from `docs/tasks` (spec / acceptance / implementation / stance)
- d) **maintenance**: REG audit / docs lint / out-of-date blueprint

### 3.1 If a role goes idle, scan `docs/tasks` first

Before reaching for the default dispatch list, read `docs/blueprint/next/README.md` and `docs/tasks/README.md`, then pick the highest-priority active task that fits the idle role. These files are the workflow source of truth after backlog selection. Use GitHub issues only for source trace (`Closes gh#NNN`) or initial backlog intake; do not scan `current-iteration` / `next-iteration` labels as the active queue.

For each idle role:
1. Find `LOCKED` next anchors whose execution state is `NO_PLAN`, `MILESTONE_PLANNED`, `TASKING`, `READY_FOR_IMPL`, `IMPLEMENTING`, or `ACCEPTING`.
2. If state is `NO_PLAN`, dispatch Architect to run `bf-phase-plan` for Phase/Milestone planning before task work.
3. If state is `MILESTONE_PLANNED`, dispatch milestone-start work only for the highest-priority unblocked milestone; split the complete task set for that milestone and start the first ready task.
4. For task-level states, pick the highest-priority task by blocker > dependency order > phase/milestone priority.
5. Skip if already assigned or already linked to an open PR.
6. Dispatch the exact role action needed in the milestone plan, task folder, or task worktree.
7. Only if no active planned milestone or task needs the role, fall back to the default dispatch list below.

If a `LOCKED` next anchor stays `NO_PLAN` for more than 24h, or the currently selected milestone has no task seed/task set/first-task owner when its dependencies are clear, that's a stuck signal — flag it in the cron report and the Teamlead investigates. A later milestone without a task set is not stuck until it is selected to start.

### 4. Cron output format
- One sentence reporting current forward motion (PR # + one-line goal).
- Hard blockers (PR check failing for too long / review unanswered for too long) listed separately with details.
- Confirm the notebook was updated, or state why no notebook change was needed.

### 5. When to merge — look at task completion, not just the green CI

**Merge gate** (under the "one task, one PR" protocol):

CI green + required LGTMs collected ≠ ready to merge. **You must check that the task's actual work is done** — every item under Acceptance / Test plan in the PR body is checked off. Only then do you merge.

**What "actually done" means** (by task type):

| Task type | "Done" criteria |
|---|---|
| Schema + server + client end-to-end | schema migration + server endpoint + client UI + e2e + `docs/current` sync checked with `bf-current-doc-standard` + REG flipped to green + acceptance template ⚪→✅ + PROGRESS [x] **all in place** |
| Spec / four-piece set | The four-piece set is committed to the worktree by every owner (Architect spec / QA acceptance / PM stance + content-lock), not just one piece |
| Closure / status flip | Lands in the same PR as the implementation, not in a follow-up |

**Read the PR body's Acceptance + Test plan**. Required. Any remaining `[ ]` item = **do not merge**, even with green CI and double LGTM. Send it back to the author / role to commit the missing piece.

**Anti-examples (never do)**:
- "CI is green and we have two LGTMs, just squash" — you didn't check that Acceptance still has 4 unticked items.
- "Almost done, let's merge first and follow up later" — under "one task, one PR" there is no room for follow-ups.
- "The review subagent reported LGTM, merge now" — a subagent doesn't check task completion. The Teamlead must read the PR body in person.

**Correct flow**:
1. CI fully green (never admin / ruleset bypass — see `bf-pr-review-flow`).
2. Every required reviewer for the task content has non-author LGTM; code tasks include Security.
3. **Teamlead reads the PR body's Acceptance + Test plan; merge only when every item is ticked.**
4. If any `[ ]` remains → ping the matching role to commit; do not merge.
5. All ticked + steps 1+2 → standard squash merge.

## Default dispatch list (per role)

**Dev**: implement the next ready task / firefighting bugs exposed by the last PR / schema spike for the next task.
**Architect**: review queue / next task spec brief / patches to accepted current or locked next blueprints.
**PM**: stance cross-check sheet / demo screenshot copy / README / onboarding content lock.
**QA**: acceptance template / REG flip / e2e flake fix.
**Designer**: visual spec / component library / writing the visual lock that pairs with PM's content lock.
**Security**: review of sensitive PRs / privacy stance / audit log review.

## PR BLOCKED routing

When a PR is blocked, **look at the type of block first**, then decide who to assign it to:

| Block type | Assign to | Why |
|---|---|---|
| **rebase / merge conflict** (DIRTY) | **subagent** | Cross-PR work; the author can't see the accumulated conflicts. A subagent batch-handles them quickly. |
| **CI fail** (cov / test / e2e / lint) | **author** | The author understands their own task's stance and implementation best. A fresh-context subagent is more likely to break the byte-identical lock chain. |
| **PR body missing a section** (mechanical N/A fillers, etc.) | **subagent** | Pure mechanical work (PATCH the body + empty commit + re-lint). |
| **review pending > 1h** | **ping the reviewer** | Not a block; just nudge the reviewing role. |

> **Note on flaky CI:** red CI always blocks merge. If a failure appears unrelated to this PR, open an issue to track the flake and assign a fix, but do not merge until the required checks are green. See `bf-pr-review-flow`, "Flaky test" section.

**Right examples:**
- 10 PRs hit main and went DIRTY at the same time → batch rebase subagent (resolve in one go).
- 7 PRs are missing the N/A section in PR-lint → subagent mechanically fills + pushes empty commit.
- Author A's PR is at 83.9% cov → assign author A to add unit tests.
- Author B's PR has a test violation → assign author B to fix.

**Wrong examples:**
- See cov fail and dispatch a subagent to add unit tests — the author knows where coverage is low; send it back to the author.
- See a test violation and dispatch a subagent — the author wrote the mock; send it back to the author.
- See a real e2e bug and dispatch a subagent — the author wrote the spec and the implementation; send it back to the author.
- See a merge conflict and dispatch the author — this is cross-PR work; a batch subagent is faster.

## Anti-patterns

- Outputting "everyone is idle waiting on merge" without dispatching any work (even if waiting, the idle ones must be doing something else).
- Using "waiting for review feedback" as an idle excuse (the waiter who isn't in a wait state needs new work).
- Treating audit as forward motion (audit + dispatch is forward motion).
- Assuming "parallel will conflict" and refusing to parallelize (under the protocol, one task has one worktree; independent tasks run in parallel naturally).
- **Skipping the `docs/tasks` queue and going straight to the default dispatch list** — if there are active tasks, an idle role should pick one up before maintenance work (see §3.1).
- **A `LOCKED` next anchor sitting for >24h with `NO_PLAN`** — that's stuck, not parked. Flag it and unblock.
- **A selected milestone sitting with no task seed/task set/first-task owner while dependencies are clear** — split the milestone task set and assign the first ready task.
- **"CI is green so merge"** — you must first read the PR body's Acceptance / Test plan and confirm every item is ticked (see §5).
- **"subagent LGTM = merge signal"** — a subagent doesn't audit task completion. The Teamlead reads the PR body in person.
- **CI fail → grab a subagent** — the author knows their own task best. Send it back to the author (see "PR BLOCKED routing").
- Treating the review dispatch as the only merge gate — review is a quality check; **task completion + CI + LGTM is the three-way signoff that lets you merge**.
- Dispatching or reporting status without reconciling `~/.blueprint/<repo-dir>/teamlead.md` first.
