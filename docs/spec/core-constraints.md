# Core Constraints

This page records BF's non-negotiable runtime constraints.

## Host Runtime Actors

The host runtime is the orchestration environment that runs BF, such as Claude
Code, Codex, or a future LLM host. It is distinct from the BF npm runtime and
from the target project's application runtime.

BF core uses generic actor names:

- **coordinator**: the main session. It owns BF state machine commands,
  `next`, `start-review`, `verify`, Final Acceptance, reviewer dispatch for BF
  acceptance, and actor lifecycle accounting.
- **task driver**: an actor assigned one concrete task. It follows the task
  pipeline and produces artifacts, evidence, pipeline review outputs, closure
  evidence, and a review-ready handoff.
- **leaf worker**: a bounded helper for one stage or artifact, used only when
  the current host runtime supports that delegation from the current actor.
- **reviewer**: an independent actor that writes review results.

Host-specific names map onto these actors without becoming BF core concepts.
For example, Claude Code `teammate` and Codex subagent can be task drivers when
the coordinator records a compatible host-runtime strategy.

Using `$bf` or `/bf` is explicit authorization for the coordinator to dispatch
host-compatible actor instances required by BF workflow execution, including
task drivers, allowed leaf workers, and reviewers. This authorization is scoped
to BF work and remains bounded by the recorded host-runtime strategy,
Independent Verification, lifecycle or closure accounting, and user confirmation
gates.

Actor identity, nested-delegation support, and closure state are
instruction-level constraints. The harness does not observe them, so the
coordinator enforces them when selecting task drivers, dispatching reviewers,
and accounting for actor lifecycle.
For execute-stage tasks, the coordinator assigns every claimed task and
verification fix to a host-compatible task driver instead of doing leaf work in
the main session. In Codex, that actor is a Codex subagent. The harness
does not track task-driver identity or mechanically enforce this delegation
rule.

## Independent Verification

For each task, the actor whose work is reviewed must not be reused as the
reviewer for that work. A task driver or leaf worker must not verify its own
work.

This is an actor-instance constraint, not a role constraint. The same role can
contribute both the work and the review as long as the instances are different.
The harness cannot see actor identity because review filenames are role-level,
so the coordinator enforces this rule when it dispatches reviewers.

Harness responsibilities:

- `next` returns `Pipeline` and `Pipeline path`, so the LLM can follow pipeline stages.
- `start-review` and `verify` use AC capabilities to identify reviewer roles.
- `lint` verifies that each AC capability is declared by at least one role.

## Provider-Role Signoff

The harness records review files by role id, not by actor identity. For Task
Verification and Final Acceptance, an AC is signed when at least one provider role
for that AC's capability has a review file that accepts the AC id and the round
has no Blocker or High finding.

Multiple roles may provide the same capability. The coordinator selects the
provider role or roles before review according to the accepted design and host
runtime strategy; the harness does not require every provider role to sign.
Instruction-level rules may require multiple independent reviewer actor
instances for a round, but actor-instance independence is enforced by the
coordinator rather than the harness.

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

Cancel, abandon, and cleanup do not add states. `bf-harness cleanup
<bf-wo>/<task>` is a task lifecycle command that removes only that task's
harness-owned worktree and safely deletes the merged local task branch. It must
not run before Task Verification sets the task `State: Completed`.
`bf-harness discard <bf-wo>` deletes the whole work object.

## discussion.md vs bf.md

| File | Role | Locking |
|---|---|---|
| `bf.md` | Contract: structured commitment driven by lint, accept, and the state machine. | Locked after accept; only harness narrow mutations are allowed. |
| `discussion.md` | Rationale archive: brainstorm and spec discussion, tradeoffs, rejected options, decisions. | Never locked; LLM may append throughout the work object. |

`bf.md` is derived from `discussion.md`. During spec, the LLM distills
discussion into the structured contract. They should not contradict each other.
discussion.md is durable source material for `bf.md`: each contract section
must be supportable from recorded discussion, including accepted assistant-led
proposals. bf.md does not need direct citations to `discussion.md`; redundant
quotes or links make the contract noisy.

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
4. Write harness-owned task execution metadata: `Branch:`, `Worktree:`, and
   `Pull-Request:`.

Every other mutation is illegal, including adding lines, deleting lines, changing
non-whitelisted fields, changing the task list, or changing boundaries.
