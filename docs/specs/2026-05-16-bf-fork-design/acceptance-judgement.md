# Acceptance Judgement — How BF Decides "Done"

Companion to [../2026-05-16-bf-fork-design.md](../2026-05-16-bf-fork-design.md).

How BF decides a Work Object has reached `desired_state` — i.e. how `acceptance_criteria` are judged satisfied. This document sets the record straight: there is no single "verify acceptance" step. Judgement is distributed across **criteria-lint, review nodes, execute / verify nodes, and gate synthesis**, inherited from OPC.

---

## 1. Principle

**Criteria are an evaluation baseline, not a mechanical checklist.**

A `verify` node does not loop through `acceptance_criteria` and tick each one. It produces *evidence* (test runs, screenshots, PR status). The judgement happens in the review nodes that read the criteria and the evidence together, with the gate making the final routing decision based on severity counts.

This is OPC's approach. BF inherits it, code and all.

---

## 2. The four mechanisms

| # | Mechanism | When | Mechanical or LLM? | Source |
|---|---|---|---|---|
| 1 | **criteria-lint** | Before WO can be created / first executed | Mechanical | OPC `bin/lib/criteria-lint.mjs` |
| 2 | **review-node evaluation** | Inside execution flow, after build / execute nodes | LLM (role agents) | OPC `pipeline/role-evaluator-prompt.md` |
| 3 | **execute-node evidence** | Inside execution flow, when artifact types are required | Mechanical (validation) + LLM (production) | OPC `pipeline/executor-protocol.md` |
| 4 | **gate synthesize** | After review / execute nodes; before transition | Mechanical | OPC `bin/lib/ux-verdict.mjs` |
| (loop only) | **scope coverage** | At loop termination | Mechanical (keyword matching) | OPC `bin/lib/loop-tick.mjs` |

### 2.1 criteria-lint (predict gate)

Before a WO can run any execution flow, its `acceptance_criteria` pass a mechanical lint:

- 3 to 7 items
- Each item is **observable / testable** (rejects "code is clean", accepts "tests/auth/* pass")
- Each item contains a verb ("user can ...", "system returns ...", "file X exists at Y")
- No hedging language (rejects "mostly", "approximately", "should generally")
- No nested compound criteria (one statement per item)

If lint fails, `bf-run create` / first `bf-run execute` refuses to proceed. User must fix the criteria.

Why this matters: it eliminates the worst failure mode — criteria so vague they can't be judged.

### 2.2 review-node evaluation

When a review node runs (e.g. `code-review`, `acceptance`), each dispatched role agent receives:

- The Work Object's `acceptance_criteria` (full text)
- The current evidence (artifacts from upstream execute / build nodes)
- The agent's own role identity and expertise

The agent writes `eval-<role>.md`. Findings are marked with severity emoji:

| Emoji | Meaning |
|---|---|
| 🔴 | Critical — a criterion is clearly unsatisfied, or a blocking issue is discovered |
| 🟡 | Warning — partially satisfied, or a non-blocking issue |
| 🔵 | Suggestion — would improve but doesn't block |
| LGTM | Implicit approval — no issues |

Crucially: **the agent judges criteria using the evidence**. It doesn't have to run tests itself; it reads test-result artifacts from execute nodes. It doesn't have to view screenshots in a browser; it reads the screenshot files captured by execute nodes.

Review nodes require ≥2 independent role agents (review independence axiom). The harness mechanically rejects copy-pasted evals.

### 2.3 execute-node evidence

Execute nodes (e.g. `test-execute`, `verify`) directly interact with the world:

- Run test commands; capture output as `test-result` artifact
- Take screenshots via Playwright; save as `screenshot` artifact
- Invoke `gh pr view` / `gh pr checks`; save output as `cli-output` artifact
- Hit deployed services; save response as `cli-output` artifact

Validation rule: execute nodes must produce **at least one evidence artifact** (type `test-result`, `screenshot`, or `cli-output`). The harness rejects handshakes without it.

But the harness does not judge whether the evidence proves the criterion. **That judgement happens in the next review node.**

### 2.4 gate synthesize

A gate node reads all `eval-*.md` from the upstream review/execute node and computes a verdict by counting emojis:

```
any 🔴 → FAIL
any 🟡 → ITERATE
all 🔵 / LGTM → PASS
```

Plus compound rules:
- ≥3 layers of unresolved findings across iterations → forced FAIL (prevents endless ITERATE)
- Any explicit BLOCKED in an eval → BLOCKED

The verdict drives flow transition (`bf-harness transition`).

No LLM gets to decide if a finding is "important enough to fail" — that judgement is made when the agent picks the emoji severity.

### 2.5 scope coverage (loop mode only)

When a WO is being executed in OPC-style loop mode (a single execute call internally runs many sub-flows for child WOs), the loop's terminator checks: for each item in `acceptance_criteria`, was it referenced by at least one completed unit (via keyword overlap or explicit reference)?

Uncovered criteria = hard error, loop cannot terminate.

This catches the failure mode where decomposition skipped part of the original scope.

---

## 3. Putting it together: how an `accepted_task` happens

Consider a product-engineering task with:

```jsonc
"acceptance_criteria": [
  "user can log in with email/password (manual browser test, screenshot evidence)",
  "session persists across refresh",
  "logout clears session",
  "tests/auth/* all pass",
  "PR opened, CI green"
]
```

Execution trace through `task-execute` flow:

1. **build (implement)** — implementer agent writes code, opens PR. Handshake = "code committed, PR opened".
2. **code-review (review)** — frontend, security, etc. role agents read criteria + diff + (if available) test output. Each writes `eval-<role>.md` marking findings with emoji. **Multiple criteria are evaluated together here; an agent might write 🔴 for "session does not persist" if they spot a logic bug.**
3. **verify / test-execute (execute)** — node runs `npm test`, captures result. Runs Playwright for the screenshot evidence. Calls `gh pr checks` for CI status. Produces evidence artifacts. Handshake = "evidence collected".
4. **acceptance-review (review)** — pm / designer / user-simulator agents read criteria + ALL evidence (review findings, test results, screenshots, PR status). Each writes `eval-<role>.md`. **This is where each criterion is implicitly judged against the consolidated evidence.**
5. **gate (gate)** — synthesize counts emojis across reviews. PASS → flow exits, WO `current_state = accepted_task`.

Notice:
- No step "checks criterion 1, then criterion 2, then criterion 3"
- Criteria are repeatedly fed to review roles as the evaluation baseline
- Mechanical parts: criteria-lint, evidence-type validation, emoji counting, transition routing
- LLM parts: role agents reading criteria + evidence and forming judgements

---

## 4. Why this design (vs a "verify-acceptance" node)

A naive design might have a single node that loops over criteria:

```
for criterion in acceptance_criteria:
  if can_mechanically_check(criterion):
    run_check()
  else:
    ask_llm_to_judge()
  record pass/fail
```

OPC explicitly does not do this. Reasons:

1. **Mechanical checking of free-text criteria is brittle.** "User can log in" — what's the test? Hardcode keywords? You end up either over-permissive or false-failing.
2. **LLM-judging in isolation has no expertise context.** A single "acceptance-judge" agent doesn't bring domain perspective. Multi-role review forces *distinct angles*: frontend judges UX, security judges credential handling, tester judges coverage.
3. **Severity is the routing signal, not boolean satisfaction.** A criterion partially-met (🟡) means *iterate*, not *fail*. Boolean checklists collapse this.
4. **Independence is a hard requirement.** A single verifier can't be independent of itself. ≥2 distinct review agents per check, plus mechanical content-distinctness check, gives real review independence.

---

## 5. BF inherits, does not invent

Everything in §2 already runs in OPC code. BF's job:

1. **Vendor the code** (Stage 1) — `bin/lib/criteria-lint.mjs`, `bin/lib/ux-verdict.mjs`, validation paths in `bin/lib/flow-core.mjs`.
2. **Write the BF-flavored doc** (this document, plus Pack protocols) — so BF users understand the model without reading OPC.
3. **Don't add a "verify-acceptance" mega-node** — earlier drafts of this spec suggested one; that was a mistake, corrected here.

---

## 6. Recursive acceptance (parent / child WOs)

Because Work Objects are recursive (a WO's directory may contain child WO directories — see [core-contracts.md](./core-contracts.md) §5 WO Home), acceptance judgement must compose across the tree.

### Two-level model

A parent WO's `done` state has two acceptance components:

1. **All children at `done`** — mechanical prerequisite enforced by the parent's `close` flow before it can run
2. **Cross-child acceptance criteria** — the parent's own `acceptance_criteria`, judged by the parent's `close` flow using the four mechanisms in §2

Component 1 is mechanical: the close flow starts by scanning child directories and refusing to proceed unless every child's `runtime.current_state == done`. No LLM involved.

Component 2 is the parent's *integrative* criteria — things that span children:

| Type | Example |
|---|---|
| End-to-end behavior | "complete auth flow works from sign-in to logout, screenshot captured" |
| Cross-cutting quality | "no regression in `tests/*` outside auth" |
| Integration check | "after all sub-PRs merged, main branch builds and CI green" |
| Release packaging | "CHANGELOG updated, version bump committed" |

These are written in the parent's `wo.md` `## Acceptance criteria` section, judged by the close flow's review nodes (same mechanism as §2.2-§2.4).

### Child criteria vs parent criteria — who owns what

Breakdown flow's job is to **distribute the parent's criteria** appropriately:

- A criterion that a single child can satisfy → move it to that child's `wo.md`
- A criterion that spans multiple children → keep in parent (verified at close)
- A criterion that's integrative (end-to-end, performance, packaging) → keep in parent

Pack provides shaping protocols guiding this distribution. The mechanical signal that the distribution is sane: after breakdown, the parent should have **fewer or smaller** criteria than before. If the parent's criteria are unchanged after breakdown, the children probably aren't covering the work.

### Why this composes cleanly

Each level uses the same four mechanisms (§2):
- Children's criteria → lint, review, evidence, gate (per child)
- Parent's criteria → lint, review, evidence, gate (at close)
- "All children done" is a mechanical precondition, not an LLM judgement

No special "recursive judge" mode is needed. The recursion is in the **WO tree**, not in the judgement logic.

### What happens when a child fails

If a child's gate FAILs and recovery is impossible, child stays in non-`done` state. Parent's close flow cannot run (prerequisite 1 unsatisfied). Parent stays at `broken_down` or `children_done` (whichever it last was).

User intervention options:
- Manually `discard` the child and `breakdown` again (parent state may need reset)
- Edit the child's `wo.md` to mark its `desired_state` short of the original, accepting partial completion
- Edit the parent's `wo.md` to remove dependency on that child

These are normal `wo.md` edits, not new verbs or new Core mechanisms.

---

## 7. Open

- Should BF expose a separate `verify` verb that runs only the verify-style nodes against an existing WO (for re-checking after manual changes)? OPC's `pre-release` flow template is roughly this; lean: yes, keep it as a Core verb, the flow lookup happens via Pack-declared flows
- How to surface verdict reasoning to humans without polluting WO Home with low-signal noise — render eval summaries on `bf-run show`? (Stage 5 demo task)
- Multi-criterion partial-failure UX: when 4 of 5 criteria pass and 1 🔴, the verdict is FAIL. Should the next iteration's review be scoped to just the failing criterion, or full re-review? (lean: full, but show "previously-passed" criteria with cached LGTM)
- Parent close after child re-breakdown: when a child's tree was re-built mid-execution, does parent re-evaluate its own criteria, or trust the child's new gate? (lean: re-evaluate the parent's cross-child criteria, trust each child's own gate)
