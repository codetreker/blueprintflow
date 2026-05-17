# API Verification

Use for backend endpoints, RPC handlers, service contracts, authz paths, and integrations.

## Checks

- Contract: request shape, response shape, status codes, error shape, and backward compatibility match `design.md`.
- Authorization: allowed user succeeds; forbidden user fails; cross-tenant/cross-owner access fails.
- Validation: missing, malformed, oversized, and boundary inputs fail safely.
- Side effects: writes, emitted events, cache changes, and audit logs match acceptance.
- Idempotency/retry: repeated request behavior is defined for mutation or job-triggering endpoints.
- Observability: expected logs/metrics exist without leaking secrets or PII.

## Evidence

- Command or test name used.
- Fixture identity: user/tenant/resource IDs with secrets redacted.
- Expected vs actual status/body.
- Data side-effect proof or explicit N/A.
- Authz negative case proof for protected endpoints.

## Anti-patterns

- Verifying only `200 OK`.
- Testing as admin only.
- Omitting negative authz or validation cases.
- Accepting a response snapshot without checking side effects.
