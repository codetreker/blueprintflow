# CLI / Operator Verification

Use for command-line tools, admin/operator commands, automation entrypoints, and terminal-first workflows.

## Checks

- Help text and usage match the accepted behavior.
- Success path returns correct exit code, output, and side effects.
- Failure paths return non-zero exit, actionable error text, and no partial unsafe state.
- Dry-run/confirm/force flags behave as specified.
- Dangerous commands require explicit confirmation, scoped target, or documented operator boundary.
- Logs redact secrets and PII.

## Evidence

- Command line with secrets redacted.
- Exit code.
- Relevant stdout/stderr excerpt.
- Side-effect proof or explicit N/A.
- Failure case proof for destructive or privileged commands.

## Anti-patterns

- Verifying only help output.
- Running destructive commands without dry-run or isolated fixture.
- Ignoring exit codes.
- Treating operator convenience as permission safety.
