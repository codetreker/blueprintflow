# Data Verification

Use for schema migrations, data model changes, backfills, imports/exports, reporting, and data integrity tasks.

## Checks

- Migration applies from a realistic pre-change state and rolls forward without manual edits.
- New constraints/indexes match the design and do not break existing valid rows.
- Backfill is resumable or explicitly one-shot with rollback/recovery notes.
- Read path and write path both see the new shape correctly.
- Counts reconcile: before/after row counts, affected rows, skipped rows, and error rows.
- Sensitive data is minimized, redacted in logs, and not exported unexpectedly.

## Evidence

- Migration/test command.
- Fixture or dataset description.
- Before/after counts.
- Spot-check queries or assertions.
- Rollback/recovery note or explicit N/A.

## Anti-patterns

- Applying migration only on an empty database.
- Reporting "migration passed" without data assertions.
- Ignoring skipped/error rows.
- Logging raw PII during import/export/backfill.
