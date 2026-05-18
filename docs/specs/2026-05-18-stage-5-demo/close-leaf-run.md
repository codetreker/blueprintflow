# Stage 5.3 — close-leaf-task real-agent run

> Second half of the Stage 5 end-to-end demo. Drove `task` WO
> `add-bf-version-verb-...` from `current_state: doing` →
> `done` using the SKILL.md orchestrator + real subagents at
> implement/code-review/verify/gate. The `implement` node
> produced **real code that landed in the repo** at commit
> `a202ef8` ("feat(bf): bf version verb prints package.json
> version") — the demo's "this actually does something" anchor.

## Bridge from 5.2

5.2 finalized with `current_state: shaped`. v0.2's `pack.json.routing`
has no `task,shaped` rule for leaf tasks (Stage 4 known gap). Manual
flip per the plan:

```bash
sed -i 's/current_state: shaped/current_state: doing/' \
  ~/.bf/wo/add-bf-version-verb-that-prints-package-json-version/wo.md
```

(Stage 6.1 candidate fix: add `task,shaped → close-leaf-task` routing
so leaf tasks skip the breakdown step.)

## Walk-through

### Node: `implement` (build)

| Aspect | Value |
|---|---|
| Roles dispatched | `engineer` |
| Subagent model | sonnet |
| Artifacts produced | `eval-engineer.md` + **4 real code files** |
| Verdict | PASS |
| Seal | `{sealed: true}` |
| Transition | `implement → code-review` |
| Code commit | **`a202ef8`** "feat(bf): bf version verb prints package.json version" |

Engineer implemented the verb to spec — read existing patterns
(`bin/lib/verbs/help.mjs`, `arg-parser.mjs`), added 1 new verb file,
edited 2 existing files (KNOWN_VERBS, VERB_DOCS), wrote 1 test.
Boundary respected: no new deps, no shell-out, no flags. Test suite
grew 134 → 135. Engineer committed the code on its own SHA before
sealing — orchestrator's eval references that SHA.

### Node: `code-review` (review)

| Aspect | Value |
|---|---|
| Roles dispatched | `tester`, `skeptic-owner` (mandatory) |
| Subagent model | sonnet × 2 |
| Artifacts produced | `eval-tester.md`, `eval-skeptic-owner.md` |
| Verdicts | PASS, PASS |
| Seal | `{sealed: true}` |
| Transition | `code-review → verify` |

Tester verified all 8 acceptance criteria by running actual commands
(not by reasoning about the code). Skeptic-owner adversarially
checked the diff: nothing missing, nothing extra, commit message
honest, test catches real regression. Both PASS — no ITERATE round
needed.

### Node: `verify` (execute)

| Aspect | Value |
|---|---|
| Roles dispatched | `tester` (independent verifier per BF axiom 5) |
| Artifacts produced | `eval-tester.md`, `cli-output.log` |
| Verdict | PASS |
| Seal | `{sealed: true}` |
| Transition | `verify → gate` |

Ran the full test suite — 135/0. Adversarial probe: invoked `bf
version` from a different cwd (`/tmp/`), still works (verb resolves
package.json relative to module location, not cwd). No regression
in any other suite. Independent verification ≠ code-review's role:
verify confirms the build runs in the wild; code-review confirms
the diff matches intent.

### Node: `gate` (gate)

| Aspect | Value |
|---|---|
| Roles dispatched | `planner` (carry-forward Stage 6 finding — gates shouldn't dispatch) |
| Artifact produced | `eval-planner.md` (hand-synthesized) |
| Verdict | PASS |
| Finalize | `{done: true, current_state: "done"}` |

Synthesized verdict from upstream: implement PASS / code-review
PASS+PASS / verify PASS → gate PASS. WO state transitions to
`done`. `bf execute` next call: `{done: true, current_state: done}`
— terminal.

## Findings (Stage 6 input — added to 5.2's list)

5. **Routing gap `task,shaped → ?`** — Stage 4 v0.2 known issue
   surfaced as a real friction point for leaf tasks. Fix: add a
   routing rule `task,shaped → close-leaf-task` (skip breakdown
   for leaf tasks); OR introduce a "is-leaf" hint in wo.md so the
   dispatcher can distinguish. Recommendation: routing rule. Files
   to touch: `packs/product-engineering/pack.json`.

6. **Demo task pollutes the demo-runner's repo.** The `implement`
   subagent committed `a202ef8` directly into the demo's worktree
   (`worktree-bf-fork-spec`). That's both the WO output AND the
   demo trace's "evidence the demo worked", which is convenient but
   blurs the line between "code produced by BF" and "code produced
   by the BF developer working on BF". For a future cleaner demo,
   the implement subagent should target a separate scratch repo
   (or a dedicated demo branch).

7. **Gate node redundancy (re-confirmed).** Same as 5.2 finding #3.
   Bumping to Important severity because every flow has at least
   one gate; this is "wasted" agent invocation in every run.

8. **No criteria-toggling.** Same as 5.2 finding #4. The WO's
   `Acceptance criteria` checklist still reads `- [ ]` even after
   `current_state: done`. The state machine IS the truth (WO is
   done iff state is done); the checklist is a static record of
   what "done" was defined as.

## Test result

Final: `135 files passed, 0 files failed` — 134 carried in from
Stage 5.1 + 1 from the new `test-version.sh` shipped by `implement`.
