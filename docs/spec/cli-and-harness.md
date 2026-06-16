# CLI And Harness

This page records the `bf` and `bf-harness` command contracts.

## `bf`

`bf` runs from the BF installation directory and provides read-only metadata plus
install management.

### `list-roles`

Lists roles under `roles/`, plus pack-private and extension roles when applicable.

Output includes:

- role file path;
- role id;
- description;
- capabilities;
- source.

### `list-packs`

Lists installed packs under `packs/`.

Output includes:

- pack id;
- description;
- one or more pack.md paths in layer order.

### `list-pipelines`

Lists task pipelines available for the effective pack registry.

Output includes:

- pipeline id;
- description;
- path.

### `install`

Installs host discovery snapshots for supported LLM hosts. Without `--target`,
the command auto-detects existing host roots and installs every detected target.
With `--target claude|codex|copilot`, it installs only that target.

Codex discovery uses `$CODEX_HOME/skills/bf` when `CODEX_HOME` is set. Otherwise
it uses `<home>/.codex/skills/bf`.

Copilot discovery uses `<home>/.copilot/skills/bf`. Automatic discovery includes
Copilot when `<home>/.copilot` or `<home>/.copilot/skills/bf` exists.

Output includes:

- BF package version;
- detected targets, or the explicit target;
- one status line per target;
- the unchanged global extension location.

Target status values:

- `installed`: target snapshot did not exist;
- `updated`: target snapshot existed with a different BF install metadata version;
- `refreshed`: target snapshot existed with the same BF install metadata version;
- `updated-from-unknown`: target snapshot existed without readable BF install metadata.

Each discovery snapshot includes `.bf-install.json` with schema, package name,
package version, target, and install timestamp. This file is metadata for BF
install status only; the discovery snapshot remains a generated host-readable
copy, not an npm package mirror.

The supported targets are concrete user-level host targets. BF install does not
write project-local `.github/skills/bf`, does not write generic
`.agents/skills/bf`, and does not invoke GitHub CLI skill preview commands.

### `uninstall`

Removes BF host discovery snapshots for supported LLM hosts. Without `--target`,
the command auto-detects existing host roots or snapshots and removes every
detected BF snapshot. With `--target claude|codex|copilot`, it removes only that
target's BF snapshot.

Copilot uninstall removes `<home>/.copilot/skills/bf`. It does not remove other
Copilot files under `<home>/.copilot`.

### `update`

Updates the global BF npm package to the latest published version by running:

```text
npm install -g @codetreker/bf@latest
```

The command accepts no arguments. On start it prints:

```text
BF update: npm install -g @codetreker/bf@latest
```

Snapshot refresh is handled by the updated package's `postinstall` hook, which
continues to run `bf install`. `bf update` does not run an additional manual
`bf install` refresh after npm completes.

## `bf-harness`

`bf-harness` controls BF work-object state under the resolved BF state home.

In Git repositories, the default state home is the primary worktree `.bf`, even
when commands run from linked worktrees. Outside Git, the default state home is
`<cwd>/.bf`.

Work objects live under `<state-home>/works/<bf-wo>`.

### `list`

Lists project work objects under the state home.

Output includes:

- id;
- description;
- state;
- updated timestamp.

### `status <bf-wo>`

Reports one work object's current state and task states without mutation.

Applies when:

- scope is `<bf-wo>`.

Behavior:

- Loads the work object from the resolved state home.
- Prints the work-object id and `bf.md.State`.
- Prints task totals by state.
- Prints one task id and state line per task.
- Does not inspect Git, create worktrees, advance state, write timestamps, or
  suggest the next command.

### `lint`

Validates a draft work object.

Checks:

- `bf.md` and task `spec.md` shape.
- Required fields.
- Task ids in `bf.md` task list.
- Task dependencies, including unknown ids and cycles.
- AC capability registry: every `{capability}` marker must be declared by at least one role.
- Task pipeline registry: each task has `Pipeline`; task frontmatter does not have `Capability`; the selected pipeline exists in the bf-wo local pipeline registry or selected pack.
- Task worktree contract: each task has `Requires-Worktree: true|false`.
- BF-WO local pipelines: local pipeline files are valid YAML, have matching filename/id, do not collide with selected pack pipeline ids, have instruction and stages, use known stage capabilities, and are referenced by at least one task.
- Task evidence: `## Evidence` exists; each task AC has evidence; evidence ids are unique; evidence AC refs exist; kind is valid; requirement text is non-empty.
- State is valid for the phase.

Success returns `SUCCESS`. Failure returns errors for the LLM to fix before rerunning.

### `start-review <bf-wo>|<bf-wo>/<task>`

Starts a new review round.

Behavior:

- Finds the largest existing `round_N`.
- Creates `round_{N+1}`.
- Returns the absolute path of the new review directory.

### `next`

Returns the next eligible task batch.

Eligibility:

- task is `Ready` or already `Tasking`;
- dependencies are complete;
- returned tasks do not depend on each other;
- dependency graph is valid.

Behavior:

- Returns up to five eligible tasks in bf.md task-list order.
- Marks returned `Ready` tasks `Tasking`.
- Validates returned `Tasking` worktree metadata.
- Moves bf.md from `Accepted` to `Implementing` on the first returned `Ready`
  task.
- Internal structured data includes task directory, spec path, task description,
  `Pipeline`, resolved `Pipeline path`, and pack id.
- CLI output is one text block per task with `Task`, `Pipeline`,
  `Pipeline path`, `Pack`, `Spec`, `Dir`, and optional `Branch`, `Worktree`,
  and `Pull-Request`.
- For `Requires-Worktree: false`, does not create branch/worktree execution
  metadata.
- For returned `Ready` tasks with `Requires-Worktree: true` in managed Git mode,
  fetches `origin`, creates branch `bf/<bf-wo>/<task-id>` from `origin/HEAD`,
  creates worktree `<primary-worktree>/.worktrees/works/<bf-wo>/<task-id>`,
  records `Branch` and `Worktree`, and returns both values.
- Retry safety requires any existing branch, worktree, and task metadata to
  match exactly. Conflicts fail before contract mutation and do not clean up
  user files.

Managed Git mode requires a Git worktree, an `origin` remote, `origin/HEAD`,
and the primary-worktree `.bf` state home.

### `attach-pr <bf-wo>/<task> <github-pr-url>`

Records a GitHub PR URL for a claimed worktree-required task.

Behavior:

- Requires task state `Tasking`.
- Requires `Requires-Worktree: true`.
- Recomputes the harness-owned worktree (`<primary-worktree>/.worktrees/works/<bf-wo>/<task>`)
  and branch (`bf/<bf-wo>/<task>`) and requires the recorded `Branch` and
  `Worktree` metadata to match them; rejects missing or non-harness-owned values.
- Requires the harness-owned task worktree `origin` remote and the PR URL to
  refer to the same GitHub repository.
- Requires the PR head branch to equal the harness-owned task branch
  unconditionally; a merged-but-unrelated PR is rejected.
- Writes task-level `Pull-Request` metadata and synchronizes `Updated`.

### `verify <bf-wo>` / `verify <bf-wo>/<task>`

Verifies review results. Scope and `bf.md.State` select one of three modes.

#### Spec Review

Applies when:

- scope is `<bf-wo>`;
- `bf.md.State` is `Draft`.

Behavior:

- Reads the latest `<work-object>/runs/reviews/round_N/`.
- Parses all `result_<role>_<idx>.md` files.
- Any Blocker or High finding fails the round.
- Clean review results return success.
- Does not flip ACs or change state. User approval and `accept` remain separate.

#### Task Verification

Applies when:

- scope is `<bf-wo>/<task>`;
- `bf.md.State` is `Accepted` or `Implementing`.
- task `spec.md` state is `Tasking`.

Behavior:

- Reads the latest `<work-object>/<task>/runs/reviews/round_N/`.
- Parses `## Results` and `## Accepted Criteria`.
- Severity detection is tolerant: severity headings (`### Blocker`/`### High`/
  `### Minor`/`### Nit`) match case-insensitively, accept the singular or plural
  spelling, and any heading depth below `## Results`; every non-empty content line
  under a severity heading is a finding, and findings written directly under
  `## Results` are treated as blocking.
- Fails closed on an unrecognized review result: a file that signs off acceptance
  criteria but has no recognized `## Results` structure — either no `## Results`
  section, or a `## Results` with no recognized severity subheading and no direct
  finding line — is a parse error; verify fails and that file's accepted-criteria
  ids are not honored. Empty recognized severity subheadings count as recognized
  structure with no findings.
- Any Blocker or High finding fails without mutation.
- For each task AC, finds roles that provide the AC capability.
- An AC is signed when at least one provider role review file accepts that AC id.
- Multiple provider roles do not all need to sign; the orchestrator chooses the relevant reviewer role before review.
- Signed ACs flip from `[ ]` to `[x]`.
- `Updated:` is synchronized when ACs flip.
- Writes `verify-result.md` to the active task review round.
- Does not check PR merge status.
- Does not move the task from `Tasking` to `Completed`.

#### Final Acceptance

Applies when:

- scope is `<bf-wo>`;
- `bf.md.State` is `Implementing`;
- status shows all tasks are completed.

Behavior:

- Reads the latest bf-level review round created after task completion.
- Applies task verification-style block and sign-off logic to bf.md ACs.
- Fails closed on a stale or invalid round: a round whose files predate the
  latest task completion is stale, and a Completed task whose `Updated` is
  missing or unparseable is treated as a stale/invalid error rather than "fresh".
- On success, flips bf.md ACs to `[x]`.
- Synchronizes `Updated:` when ACs flip.
- Writes `verify-result.md` to the active bf-level review round.
- Does not move bf.md from `Implementing` to `Completed`.

BF-level final review does not currently enforce actor-instance identity across
all task work. It is an integrative review; strict final-review IV can be added
later if needed.

#### Phase Mismatch

Unsupported verify scope or state returns a setup error. Work-object phase
mismatches use:

```text
phase mismatch: cannot verify <scope> when bf.md.State = <X>
```

Task verification also checks the task state after the bf-level phase allows
task verification. A non-`Tasking` task returns:

```text
phase mismatch: cannot verify <bf-wo>/<task> when task spec State = <X>
```

#### Verify Output

`verify` has three output classes:

- Success: stdout `SUCCESS <absolute-file-path>`, exit 0.
- Verification failure: stdout `FAIL <absolute-file-path>`, exit 1.
- Setup error: stderr `bf-harness verify: <message>`, exit 1, stdout empty.

Success and verification failure write `verify-result.md` to the active review
round. Setup errors do not write a verify result. Reviewer or fixer actors
should read the file path instead of receiving the full verify result in prompt
context.

#### verify-result.md

```markdown
---
Result: SUCCESS|FAIL
Mode: Spec Review|Task Verification|Final Acceptance
Scope: <bf-wo> or <bf-wo>/<task>
Round: <N>
Timestamp: <yyyy-mm-dd hh:MM>
---

## Issues
// FAIL only; grouped by severity with file:line and description.

### Blocker
### High

## AC Sign-off
// Task Verification / Final Acceptance only.
- AC-1: signed (by tester, security)
- AC-2: missing (need: security; got: tester only)
- AC-3: blocked (Blocker raised; not yet evaluated)

## Flipped
// Task Verification / Final Acceptance; newly flipped AC ids.

## State Changes
// Empty for Spec Review, Task Verification, and Final Acceptance.
// Terminal transitions are recorded by `complete`, not `verify`.
```

### `complete <bf-wo>` / `complete <bf-wo>/<task>`

Advances terminal state after successful verification.

Task scope applies when:

- task `spec.md` state is `Tasking`;
- all task ACs are checked;
- latest task `verify-result.md` is `SUCCESS`, `Mode: Task Verification`, and matches the task scope;
- the task spec has not changed after that verify result;
- for GitHub worktree tasks, the recorded same-repository PR is merged and its
  head branch equals the recomputed harness-owned task branch; the worktree and
  branch metadata must match the harness-owned values (mismatched or missing
  metadata, or a merged-but-unrelated PR, is rejected).

Task success moves the task from `Tasking` to `Completed` and synchronizes `Updated`.

Work-object scope applies when:

- `bf.md.State` is `Implementing`;
- all tasks are `Completed`;
- all bf-level ACs are checked;
- latest work-object `verify-result.md` is `SUCCESS`, `Mode: Final Acceptance`, and matches the work-object scope;
- `bf.md` and task specs have not changed after that verify result.

Work-object success moves `bf.md` from `Implementing` to `Completed` and synchronizes `Updated`.

### `cleanup <bf-wo>/<task>`

Cleans one completed task's harness-owned Git worktree.

Applies when:

- scope is `<bf-wo>/<task>`;
- task `spec.md` state is `Completed`.

Behavior:

- Refuses work-object scope; cleanup is task-scoped.
- Refuses to run before task `State: Completed`.
- For `Requires-Worktree: false`, returns success with no cleanup action.
- For `Requires-Worktree: true`, requires managed Git mode and the
  primary-worktree `.bf` state home.
- Treats only branch `bf/<bf-wo>/<task-id>` and worktree
  `<primary-worktree>/.worktrees/works/<bf-wo>/<task-id>` as harness-owned.
- Skips metadata that does not exactly match those harness-owned values.
- Removes registered clean task worktrees with `git worktree remove`.
- Deletes local task branches with `git branch -d` only after the worktree is no
  longer checked out.
- Retains and reports dirty worktrees, unregistered path conflicts, checked-out
  branches, and unmerged branches instead of forcing deletion.
- Does not delete `.bf` work-object state. Use `discard` only when intentionally
  abandoning or removing local BF state.

Output includes one line per cleanup action, such as:

```text
Removed worktree: <absolute-worktree-path>
Deleted branch: bf/<bf-wo>/<task-id>
Retained branch: bf/<bf-wo>/<task-id> (<git reason>)
```
