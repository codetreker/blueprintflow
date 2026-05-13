# Security Review Checklist

> **Lazy reference**: only pulled when the Security role is doing a PR review. It does not live in the SKILL.md body — that keeps the main flow's context lean.
>
> Usage: before a Security review on a PR, read all 12 categories of this checklist; pick the relevant items based on the PR's change scope; all pass → LGTM, any red → NOT-LGTM, send back to author to fix.
>
> **Granularity stance**: this checklist lists only the **dimension + a one-line "what to check" + the anti-constraint**, **without binding to any specific language / framework / tool / path**. Each project specializes the concrete grep commands / lint rules / tool calls for its own stack; projects can land the concrete execution in their own repo at `references/security-checklist-<stack>.md`. This generic checklist anchors only the dimensions.

---

## Sections

| Section | Use |
|---|---|
| 1-3 | Auth, validation, sensitive data |
| 4-6 | Privacy, filesystem/network, dependency/supply chain |
| 7-9 | Browser/UI, concurrency, logging/observability |
| 10-12 | Migration/config, test/security gates, review output |

## 1. Authentication / Authorization

| Check | Anti-constraint |
|---|---|
| Auth check (user / admin / anonymous paths) | any endpoint that touches user data must go through an auth middleware |
| Capability gate (can the user do this operation) | write actions must check permission, not just login state |
| Cross-org / tenant data isolation | any endpoint that looks up by ID must scope by tenant / owner |
| Impersonate path (admin god-mode) | any admin write action must go through audit log + must carry an "acting on behalf of whom" field |
| Cookie domain / SameSite / HttpOnly / Secure flag | every session/auth cookie must have all 4 flags set; defaults are not allowed |

## 2. Input validation

| Check | Anti-constraint |
|---|---|
| SQL injection | any string-built SQL must be reviewed; must use parameterized queries |
| XSS (cross-site scripting) | rendering user content must go through sanitization or escaping |
| Command injection | shell calls must use array-form arguments; no string concatenation |
| Path traversal | user-controlled paths must be normalized + checked against an allowed-root prefix |
| SSRF (server-side request forgery) | outbound requests must resolve + blacklist internal / loopback / metadata ranges |
| CSRF (cross-site request forgery) | write actions must use a non-GET method + carry a CSRF token or strict SameSite |
| Deserialization | deserialization target must be a clearly defined type; no arbitrary structures |

## 3. Sensitive data

| Check | Anti-constraint |
|---|---|
| Passwords / tokens / API keys never enter logs and never reach the client | secret fields are filtered at the serialization / logging layer |
| Error messages don't leak internal structure | prod error responses use a generic message; internal detail goes only to server logs |
| PII handled with minimization | returning PII must be a business necessity + PII in logs must be redacted |
| Encryption at rest | passwords cannot be stored in cleartext or with a fast hash; must use an industry-standard slow hash |
| TLS in transit | production config must not contain non-encrypted endpoints |

## 4. Sessions / credentials

| Check | Anti-constraint |
|---|---|
| Session invalidation paths | logout must really delete the session record + password change must invalidate all sessions |
| Token lifetime / refresh mechanism | short-lived access token + refresh token has a rotation mechanism |
| Multi-device login policy | unusual concurrent logins have a notification or block path |
| Brute-force protection | login endpoint must have per-IP + per-account rate limiting |

## 5. Rate limit / DoS

| Check | Anti-constraint |
|---|---|
| Rate limit on high-frequency endpoints | every public endpoint must have rate limiting; quota for critical endpoints can be tightened explicitly |
| Limits on resource-heavy endpoints | large requests must be paginated + use an async queue or carry an explicit cap |
| Recursion / loop bounds | parsers must have a depth cap + decompression must have an output size cap |

## 6. Third-party dependencies

| Check | Anti-constraint |
|---|---|
| New dependencies audited | CI must run a dependency vulnerability scan; high severity must be fixed |
| Lockfile committed | lockfile must be committed |
| Upgrade path covers CVE patches | there must be a periodic dependency-upgrade process |

## 7. Configuration / deployment

| Check | Anti-constraint |
|---|---|
| Secrets not in git | all secret files must be in ignore; secrets are injected via env |
| Default values panic-fast — anti silent prod | critical security envs missing → panic on startup; no silent fallback |
| Domains / endpoints not hardcoded | environment-dependent endpoints must come from env injection |
| Runtime not running as a privileged user | containers / processes must run as a non-privileged user |

## 8. Business logic security

| Check | Anti-constraint |
|---|---|
| IDOR (Insecure Direct Object Reference) | every get / update / delete by resource_id must check owner / tenant scope |
| Privilege escalation paths (regular user → admin) | user-mutable fields must use an explicit allowlist; arbitrary client-supplied fields are not accepted |
| Race conditions (concurrent update / counter) | critical counters / balances must use atomic operations or transactions + row locks |
| Transactional integrity for money / points operations | money-class operations must use transactions + idempotency key + state machine |

## Usage (Security review flow)

1. PR opens + Security review notified
2. Look at the PR's change scope (handler / frontend / deployment config / dependencies, etc.)
3. Map the change scope to the relevant items across the 12 categories
4. Walk them one by one + write the LGTM comment (or NOT-LGTM and send back to author)
5. The LGTM comment must cite specific checklist items (e.g. "§1 auth ✅, §2 SQL injection ✅, §8 IDOR prevented")

## Project-specific specialization

This checklist anchors only **dimensions**. Each project should add its own `<repo>/references/security-checklist-<stack>.md` with:

- Specific grep commands
- Specific framework / tool calls (dependency audit / lint rules / static scan)
- Project-specific paths / module boundaries

The generic checklist (this file) is stack-agnostic; project-specific checklists extend it as needed.

## Anti-patterns

- ❌ Reviewing on intuition without reading the checklist (the 12 categories are meaningful; missing one = missing a risk surface)
- ❌ LGTM without citing checklist items (no traceability afterwards; drift can't be caught)
- ❌ Copying the checklist into the SKILL.md body (breaks lazy-reference mode, pollutes context)
- ❌ Hardcoding language / framework / tool / path into the generic checklist (project stacks vary widely; not portable)
- ❌ Listing only the "what" without the "why / anti-constraint" (anti "checklist that doesn't tell you why")
