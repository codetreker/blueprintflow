# Remote Agent / Dangerous Commands Review

Use with the Security checklist when a PR touches remote agents, host automation, shell commands, job runners, approval flows, or filesystem/network capability delegation.

## Checks

- Identity: the acting user, agent, and target host are authenticated and auditable.
- Authorization: remote action checks capability at execution time, not only at request creation.
- Approval boundary: user approval happens in the initiating product flow when required; do not require later SSH-only approval unless the product explicitly chose that UX.
- Command construction: shell calls use array-form arguments or equivalent; no string-concatenated untrusted input.
- Scope: filesystem paths, environment variables, network targets, and working directory are constrained.
- Secrets: credentials are not echoed, logged, serialized to clients, or passed to untrusted tools.
- Replay/idempotency: duplicate configure/run messages do not repeat unsafe side effects.
- Revocation: revoked host/agent/user cannot continue queued or future actions.
- Observability: logs identify actor, host, command class, result, and redacted failure reason.
- Failure mode: partial failure leaves a recoverable state and clear operator action.

## Evidence

- Authz path or test.
- Command construction proof.
- Revocation/duplicate-run proof where relevant.
- Log redaction proof.
- Operator/user-facing approval path proof.

## Anti-patterns

- Deferring web-triggered approval to later SSH interaction.
- Treating host install as permanent blanket consent.
- Running as privileged user without a documented boundary.
- Logging full command lines that include secrets or PII.
