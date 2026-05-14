# Background Job Verification

Use for cron, queues, workers, scheduled jobs, async processing, webhooks, and retries.

## Checks

- Trigger path: schedule/event/enqueue condition fires exactly when expected.
- Processing path: job consumes input, writes expected result, and records status.
- Retry/idempotency: duplicate delivery or retry does not corrupt state.
- Failure path: errors are visible, bounded, and recoverable.
- Concurrency: parallel jobs do not race on shared state.
- Observability: logs/metrics identify job, target, outcome, duration, and redacted error.

## Evidence

- Trigger command/event or test name.
- Job ID/correlation ID.
- Before/after state assertion.
- Retry or duplicate-delivery proof where relevant.
- Failure-path proof or explicit N/A.

## Anti-patterns

- Verifying only that a job was enqueued.
- Ignoring duplicate delivery.
- Treating logs as success without checking state.
- Leaving failure paths invisible to operators.
