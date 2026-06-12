# Automation Runs

Automation runs are BF's v1 convention for externally triggered bounded work. An outside trigger wakes an LLM orchestration environment, the LLM performs one bounded automation run, records what happened, updates an automation cursor when appropriate, and exits or hands engineering work to an ordinary BF work object.

## Model

An automation run starts from an external trigger. The trigger can come from cron, a CI job, a host scheduler, a webhook adapter, or a manual host command outside BF. BF v1 does not own that trigger. BF defines what the LLM does after the trigger starts one run.

Each run is bounded. The LLM reads the automation definition and cursor, performs only the work described for this one invocation, writes a run record, and stops. The LLM must not remain alive as a daemon, poll for more work, spawn a worker pool, or wait for future events.

The cursor records durable source progress for one automation. Cursor shape is automation-specific JSON, but the definition must explain how to interpret it, when to advance it, and when to leave it unchanged. The cursor is state, not policy approval.

The run record is the audit trail for one invocation. It records the trigger context, input cursor, actions taken, output cursor decision, result, handoff target when one exists, and retained risks or blockers.

## State Convention

Automation state lives under the resolved BF state home:

```text
.bf/
  automations/
    <automation-id>/
      definition.md
      cursor.json
      runs/
        <timestamp>/
          run.md
```

`.bf/automations/<automation-id>/definition.md` is the automation's durable instruction contract. It names the automation purpose, source boundary, trigger expectations, bounded run steps, cursor semantics, no-op condition, handoff rule, validation or evidence expectations, and stop conditions.

`.bf/automations/<automation-id>/cursor.json` is the current durable cursor. It must be valid JSON. The automation definition owns its schema.

`.bf/automations/<automation-id>/runs/<timestamp>/run.md` is the run record for one invocation. The timestamp should be sortable and unique for the automation, preferably UTC.

## Run Outcomes

A run can finish with a no-op result. Use no-op when the external source has no relevant change, the cursor already covers the observed source state, or the definition's conditions for creating or resuming BF work are not met. The run record still exists for a no-op.

A run can update the cursor. Update the cursor only after the run has inspected the relevant source state and recorded the result. If the run is blocked, unsafe, ambiguous, or unable to prove the source position, leave the cursor unchanged unless the definition explicitly defines a safe partial cursor.

A run can hand work to an ordinary BF work object. When engineering work is needed, automation does not become a private execution path. The LLM creates or resumes `.bf/works/<bf-wo>` through the normal BF brainstorm, spec, accept, execution, review, verify, complete, cleanup, PR readiness, and Independent Verification gates. Automation may record the work-object id in the run record, but it does not approve, merge, complete, or clean up that work outside the normal BF lifecycle.

## V1 Non-Goals

BF v1 automation runs do not add a scheduler, daemon, polling loop, webhook server, worker pool, lease system, retry framework, source plugin framework, policy engine, or automation CLI.

BF v1 does not implement GitHub issue triage, social media collection, source-specific ingestion, automatic approval, automatic merge, or automatic completion.

BF v1 does not change `bf-harness` work-object lifecycle commands, task state transitions, task worktree behavior, review identity rules, completion semantics, cleanup semantics, or PR gates.

## Gate Boundary

Automation runs are trigger and state conventions around BF, not a bypass around BF. Any discovered engineering change remains ordinary BF work. Spec Review, task review, readiness verification, Final Acceptance, PR readiness, completion, cleanup, and Independent Verification still apply.

The LLM must stop and record a blocker when the automation definition is ambiguous, the cursor is invalid, a source action exceeds the bounded run, or the next step would require a user decision that the automation definition has not already authorized.
