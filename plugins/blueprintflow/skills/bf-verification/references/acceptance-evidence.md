# Acceptance Evidence

Use this schema in task `acceptance.md` or `progress.md` when QA verifies behavior.

## Required Block

```markdown
## Acceptance Evidence

| Check | Evidence | Result |
|---|---|---|
| <acceptance item / spec segment> | <command/test/screenshot/log/PR anchor> | PASS / HOLD / BLOCK |

Verifier: <role/name>
Date: YYYY-MM-DD
Scope: <UI/API/data/CLI/background/security/current-doc>
Fixtures: <fixture/user/tenant/resource, secrets redacted, or N/A>
Out-of-scope findings: <issue links or N/A>
Decision: LGTM / HOLD / BLOCK
```

## Evidence Rules

- Every acceptance item maps to at least one evidence row.
- Evidence must be reproducible: command/test name, screenshot path, PR anchor, log excerpt, or manual walkthrough notes.
- Redact secrets, tokens, raw PII, and private tenant data.
- Use `N/A - <reason>` only when the acceptance item genuinely does not apply.
- `LGTM` requires all required rows `PASS` and no unresolved `HOLD` or `BLOCK`.

## Where To Put It

- Before PR open: task `progress.md`.
- QA-authored acceptance detail: task `acceptance.md`.
- Milestone/wave closure: `milestone.md` closure summary may link to task evidence instead of duplicating it.
