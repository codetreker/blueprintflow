# Automation

Goal: execute one externally triggered automation run, record the result, and route any needed BF work through normal BF gates.

## Trigger

Use this flow only when the host invocation explicitly identifies an externally triggered automation run. The external trigger must provide the automation id or the automation state path. Run one bounded automation run, then stop.

Do not start this flow during ordinary `$bf` execution. Ordinary `$bf` execution remains user-driven and is not automatic background work.

## State

Use the resolved BF state home. In a Git project, this is the primary worktree `.bf`. The automation state convention is:

```text
.bf/automations/<automation-id>/definition.md
.bf/automations/<automation-id>/cursor.json
.bf/automations/<automation-id>/runs/<timestamp>/run.md
```

`definition.md` is the automation instruction contract. It must identify the source boundary, bounded run steps, cursor semantics, no-op condition, handoff rule, evidence expectations, and stop conditions.

`cursor.json` is the durable cursor for this automation. It must be valid JSON unless the definition explicitly says the first run may create it.

`runs/<timestamp>/run.md` is the run record for one invocation. Use a sortable, unique timestamp, preferably UTC.

## One Run

1. Confirm the trigger explicitly asks for one automation run. If it does not, stop.
2. Resolve the automation id and state directory.
3. Read `definition.md`. If it is missing or ambiguous about source boundary, cursor semantics, no-op condition, or handoff rule, write a blocked run record if a run directory can be created, then stop.
4. Read `cursor.json`. If it is missing, invalid, or incompatible with the definition and the definition does not define safe initialization or repair, write a blocked run record and stop.
5. Create `runs/<timestamp>/run.md` before source side effects. Record the trigger context, input cursor, start time, and planned bounded action.
6. Perform only the bounded source inspection or collection described by the definition. Do not poll, wait for future events, start a daemon, or broaden into a worker pool.
7. Decide the outcome: no-op, cursor update, ordinary BF work object handoff, or blocked.
8. Finish `run.md` with the result, evidence, output cursor decision, work-object id when one exists, blockers, and retained risks.
9. Update the cursor only after the run record explains why the update is safe. If the run is blocked or ambiguous, leave the cursor unchanged unless the definition gives a safe partial update rule.
10. Stop after this one run.

## No-Op

Use a no-op result when the observed source state contains no relevant change, the cursor already covers the source state, or the definition's handoff condition is not met.

A no-op still writes a run record. It may update the cursor only when the definition says the observed source position is safe to record without creating BF work.

## Work Handoff

When the run finds work that needs BF, create or resume an ordinary BF work object. The automation run may supply source context, evidence, and a proposed request, but the work object must go through normal BF gates: brainstorm, spec, accept, execution, task review, readiness verification, Final Acceptance, PR readiness, complete, cleanup, and Independent Verification.

Do not use automation to approve a spec, skip a review, satisfy Independent Verification, merge a PR, complete a work object, or clean up a task. Record the ordinary BF work object id in `run.md` and stop or continue only as normal BF execution explicitly allows.

## Run Record

`run.md` should include:

- automation id;
- trigger source and trigger time;
- input cursor summary;
- bounded action performed;
- source evidence inspected;
- result: `no-op`, `handoff`, or `blocked`;
- output cursor decision;
- ordinary BF work object id or status when there is a handoff;
- blockers and retained risks;
- stop time.

## V1 Boundary

Do not add a scheduler, daemon, polling loop, webhook server, worker pool, lease system, retry framework, source plugin framework, policy engine, or automation CLI.

Do not implement source-specific behavior such as GitHub issue triage or social media collection unless an accepted ordinary BF work object separately defines that feature.

Do not weaken normal BF gates, PR readiness, complete, cleanup, or Independent Verification.
