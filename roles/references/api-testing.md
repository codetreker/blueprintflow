# API Testing Reference

Use this reference when a tester reviews API behavior. It guides judgment and evidence expectations for the reviewed API scope; it does not require every item here to block every task.

## Focus Areas

- API contract shape: verify routes, methods, request fields, response fields, status codes, content types, pagination, idempotency, and backward compatibility expectations that apply to the task.
- auth and authorization: check authentication requirements, role or ownership checks, tenant boundaries, token/session handling, and denied-access behavior.
- input validation: exercise required fields, type and range constraints, malformed payloads, unknown fields, boundary values, and safe rejection of invalid input.
- behavior and state: confirm side effects, persistence, ordering, retries, concurrency assumptions, cache invalidation, and read-after-write behavior.
- error semantics: verify error status codes, stable error shapes, safe messages, retryability, and distinction between client, auth, not-found, conflict, and server failures.
- integration boundaries: inspect external service calls, database boundaries, event publication, queues, timeouts, retries, and fallback behavior that are in scope.
- evidence quality: prefer focused unit, integration, contract, or CLI/API-call evidence that shows accepted behavior and meaningful failure paths.
