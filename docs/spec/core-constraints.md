# Core Constraints

This page records BF's non-negotiable runtime constraints.

## Independent Verification

For each task, the subagent that implements the task must not be reused as the
subagent that reviews the task. The doer must not verify its own work.

This is a subagent-instance constraint, not a role constraint. The same role can
contribute both the doer and the reviewer as long as the instances are different.
The harness cannot see subagent identity because review filenames are role-level,
so the orchestrating LLM enforces this rule when it spawns subagents.

Harness responsibilities:

- `next` returns `Pipeline` and `Pipeline path`, so the LLM can follow pipeline stages.
- `start-review` and `verify` use AC capabilities to identify reviewer roles.
- `lint` verifies that each AC capability is declared by at least one role.

## State Machine

### bf.md

```text
Draft  ────►  Accepted  ────►  Implementing  ────►  Completed
  ▲             │
  └─ Spec Review iterates here (runs/reviews/round_N/)
```

| State | Meaning |
|---|---|
| `Draft` | Brainstorm and breakdown exist; spec review may be iterating in `runs/reviews/round_N/`. |
| `Accepted` | The user ran `bf-harness accept`; the contract is locked. |
| `Implementing` | At least one task entered `Tasking`; the first successful `next` moves the bf state here. |
| `Completed` | All tasks are completed and bf-level final acceptance verified. |

### task spec.md

```text
Draft  ────►  Ready  ────►  Tasking  ────►  Completed
                              ▲    │
                              └────┘
                          verify FAIL: stays Tasking
```

| State | Meaning |
|---|---|
| `Draft` | The task is drafted while `bf.md` is not yet accepted. |
| `Ready` | `bf.md` was accepted and the task is eligible for `next`. |
| `Tasking` | `next` claimed the task. Verify failures leave it here until fixed. |
| `Completed` | Task verification succeeded. |

### Transitions

| Transition | Trigger | Writer |
|---|---|---|
| bf.md `Draft` --> `Accepted` | `bf-harness accept <bf-wo>` | harness |
| bf.md `Accepted` --> `Implementing` | first `next` returns a task | harness |
| bf.md `Implementing` --> `Completed` | Final Acceptance verify succeeds after all tasks complete | harness |
| task `Draft` --> `Ready` | bf.md accepted | harness |
| task `Ready` --> `Tasking` | `next` claim | harness |
| task `Tasking` --> `Completed` | Task Verification succeeds | harness |

Cancel and abandon do not add states. `bf-harness discard <bf-wo>` deletes the
whole work object.

## discussion.md vs bf.md

| File | Role | Locking |
|---|---|---|
| `bf.md` | Contract: structured commitment driven by lint, accept, and the state machine. | Locked after accept; only harness narrow mutations are allowed. |
| `discussion.md` | Rationale archive: brainstorm and spec discussion, tradeoffs, rejected options, decisions. | Never locked; LLM may append throughout the work object. |

`bf.md` is derived from `discussion.md`. During spec, the LLM distills
discussion into the structured contract. They should not contradict each other.

Execution use:

- If `bf.md` or task `spec.md` is ambiguous, read `discussion.md`.
- If `discussion.md` has no answer, append clarification notes.
- If clarification changes locked scope, stop and ask the user.

Conflict handling:

- If `bf.md` contradicts `discussion.md`, treat it as a lock-time drift signal.
- Do not silently choose which file wins.
- Stop and ask the user whether to abandon and recreate the work object or accept the current `bf.md` contract.

## Allowed Mutations After Accept

After accept, the LLM must not edit `bf.md` or task `spec.md` content.

Harness-only mutation whitelist:

1. Flip AC lines from `[ ]` to `[x]`.
2. Sync the frontmatter `Updated:` timestamp when a mutation occurs.
3. Advance frontmatter `State:` according to the state machine.

Every other mutation is illegal, including adding lines, deleting lines, changing
fields, changing the task list, or changing boundaries.
