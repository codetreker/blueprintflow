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
- source.

### `list-pipelines`

Lists task pipelines available for the effective pack registry.

Output includes:

- pipeline id;
- description;
- path.

## `bf-harness`

`bf-harness` controls BF work-order state under `<project-root>/.bf/<bf-wo>`.

### `list`

Lists project work orders under `<project-root>/.bf/`.

Output includes:

- id;
- description;
- state;
- updated timestamp.

### `lint`

Validates a draft work order.

Checks:

- `bf.md` and task `spec.md` shape.
- Required fields.
- Task ids in `bf.md` task list.
- Task dependencies, including unknown ids and cycles.
- AC capability registry: every `{capability}` marker must be declared by at least one role.
- Task pipeline registry: each task has `Pipeline`; task frontmatter does not have `Capability`; the selected pipeline exists in the selected pack.
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

Claims the next eligible task.

Eligibility:

- task is `Ready` or already `Tasking`;
- dependencies are complete;
- dependency graph is valid.

Behavior:

- Marks the task `Tasking`.
- Moves bf.md from `Accepted` to `Implementing` on first returned task.
- Returns task directory, spec path, task description, `Pipeline`, `Pipeline path`, and pack id.

### `verify <bf-wo>` / `verify <bf-wo>/<task>`

Verifies review results. Scope and `bf.md.State` select one of three modes.

#### Spec Review

Applies when:

- scope is `<bf-wo>`;
- `bf.md.State` is `Draft`.

Behavior:

- Reads the latest `<bf-wo>/runs/reviews/round_N/`.
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

- Reads the latest `<bf-wo>/<task>/runs/reviews/round_N/`.
- Parses `## Results` and `## Accepted Criteria`.
- Any Blocker or High finding fails without mutation.
- For each task AC, finds roles that provide the AC capability.
- An AC is signed when at least one provider role review file accepts that AC id.
- Multiple provider roles do not all need to sign; the orchestrator chooses the relevant reviewer role before review.
- Signed ACs flip from `[ ]` to `[x]`.
- `Updated:` is synchronized.
- When all task ACs are checked, task state moves from `Tasking` to `Completed`.

#### Final Acceptance

Applies when:

- scope is `<bf-wo>`;
- `bf.md.State` is `Implementing`;
- every task is `Completed`.

Behavior:

- Reads the latest bf-level review round created after task completion.
- Applies task verification-style block and sign-off logic to bf.md ACs.
- On success, flips bf.md ACs to `[x]`.
- Moves bf.md from `Implementing` to `Completed`.
- Synchronizes `Updated:`.

BF-level final review does not currently enforce doer/reviewer identity across
all task doers. It is an integrative review; strict final-review IV can be added
later if needed.

#### Phase Mismatch

Any unsupported scope/state combination returns:

```text
phase mismatch: cannot verify <scope> when bf.md.State = <X>
```

#### Verify Output

`verify` has three output classes:

- Success: stdout `SUCCESS <absolute-file-path>`, exit 0.
- Verification failure: stdout `FAIL <absolute-file-path>`, exit 1.
- Setup error: stderr `bf-harness verify: <message>`, exit 1, stdout empty.

Success and verification failure write `verify-result.md` to the active review
round. Setup errors do not write a verify result. Reviewer/fixer subagents should
read the file path instead of receiving the full verify result in prompt context.

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
// State transitions caused by this verify run.
- task-3: Tasking --> Completed
- bf.md: Implementing --> Completed
```
