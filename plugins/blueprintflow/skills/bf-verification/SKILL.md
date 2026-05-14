---
name: bf-verification
description: "Part of the Blueprintflow methodology. Use when QA verifies task acceptance evidence for UI, API, data, CLI, background job, or release-regression scope before LGTM."
---

# Verification

QA verifies that accepted behavior is real, evidenced, and usable where users or operators touch it. Code correctness is necessary, not sufficient.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Trigger

Use before QA LGTM, task acceptance, milestone/wave closure, or Phase exit when any changed behavior must be verified.

## Select References

Load only the needed reference files:

| Scope | Reference |
|---|---|
| UI, frontend, desktop/mobile/web/extension, CLI UI | [references/ui-e2e.md](references/ui-e2e.md) |
| API, backend endpoint, contract, authz path | [references/api.md](references/api.md) |
| Database, migration, data integrity, backfill | [references/data.md](references/data.md) |
| CLI command, automation, operator workflow | [references/cli.md](references/cli.md) |
| Cron, queue, worker, async/background job | [references/background.md](references/background.md) |
| Evidence format for `acceptance.md` or `progress.md` | [references/acceptance-evidence.md](references/acceptance-evidence.md) |

For multi-surface tasks, run every relevant reference. UI tasks must include `ui-e2e.md`; backend-only tasks skip UI verification.

## Output

Record verification evidence in the task `acceptance.md` or `progress.md` using [references/acceptance-evidence.md](references/acceptance-evidence.md).

Decision values:
- `LGTM`: required evidence is present and reproducible.
- `HOLD`: evidence is incomplete or unclear; owner can fix without scope change.
- `BLOCK`: behavior fails, violates acceptance, or exposes drift/security risk.

## Checks

- Evidence maps to `task.md`, `spec.md`, and `acceptance.md`.
- Verification uses real behavior, not only code inspection.
- Out-of-scope findings become issues; they do not silently expand the task.
- UI scope includes usability and design review, not only acceptance clicks.

## Anti-patterns

- LGTM from green CI alone.
- Screenshot, curl, or log output without interpretation.
- Verifying only the happy path when acceptance names edge cases.
- Letting out-of-scope findings block without filing a follow-up issue.

## How to invoke

```
follow skill bf-verification
```
