# Security Review Checklist

> **Lazy reference**: only pulled when the Security role is doing a PR review. It does not live in the SKILL.md body — that keeps the main flow's context lean.
>
> Usage: before a Security review on a PR, read all 12 categories of this checklist; pick the relevant items based on the PR's change scope; all pass → LGTM, any red → NOT-LGTM, send back to author to fix.
>
> **Granularity stance**: this checklist lists only the **dimension + a one-line "what to check" + the anti-constraint**, **without binding to any specific language / framework / tool / path**. Each project specializes the concrete grep commands / lint rules / tool calls for its own stack; projects can land the concrete execution in their own repo at `references/security-checklist-<stack>.md`. This generic checklist anchors only the dimensions.

---

## 1. Authentication / Authorization

- **Auth check (user / admin / anonymous paths)**
  - Dimension: does the endpoint miss a login-state check; can anonymous call it directly
  - Anti-constraint: any endpoint that touches user data must go through an auth middleware
- **Capability gate (can the user do this operation)**
  - Dimension: logged in ≠ authorized; is there a fine-grained capability check
  - Anti-constraint: write actions must check permission, not just login state
- **Cross-org / tenant data isolation**
  - Dimension: a user passes someone else's org ID into a query — does the server filter by tenant
  - Anti-constraint: any endpoint that looks up by ID must scope by tenant / owner
- **Impersonate path (admin god-mode)**
  - Dimension: can an admin act as a regular user, and is it audited
  - Anti-constraint: any admin write action must go through audit log + must carry an "acting on behalf of whom" field
- **Cookie domain / SameSite / HttpOnly / Secure flag**
  - Dimension: is the cookie scoped to subdomain / cross-site protected / not readable by JS / restricted to HTTPS path
  - Anti-constraint: every session/auth cookie must have all 4 flags set; defaults are not allowed

## 2. Input validation

- **SQL injection**
  - Dimension: can user input flow directly into a SQL query string
  - Anti-constraint: any string-built SQL must be reviewed; must use parameterized queries
- **XSS (cross-site scripting)**
  - Dimension: is user input rendered as HTML without escaping
  - Anti-constraint: rendering user content must go through sanitization or escaping
- **Command injection**
  - Dimension: is user input concatenated into shell / exec commands
  - Anti-constraint: shell calls must use array-form arguments; no string concatenation
- **Path traversal**
  - Dimension: can a user-controlled file path escape the intended directory
  - Anti-constraint: user-controlled paths must be normalized + checked against an allowed-root prefix
- **SSRF (server-side request forgery)**
  - Dimension: server fetches a URL the user provides — can it reach internal / metadata endpoints
  - Anti-constraint: outbound requests must resolve + blacklist internal / loopback / metadata ranges
- **CSRF (cross-site request forgery)**
  - Dimension: is a state-changing action exposed via GET / missing a token / relying solely on SameSite
  - Anti-constraint: write actions must use a non-GET method + carry a CSRF token or strict SameSite
- **Deserialization**
  - Dimension: can a user-controlled structure trigger type confusion / prototype pollution
  - Anti-constraint: deserialization target must be a clearly defined type; no arbitrary structures

## 3. Sensitive data

- **Passwords / tokens / API keys never enter logs and never reach the client**
  - Dimension: is a secret being logged / returned to the client / written into an error response
  - Anti-constraint: secret fields are filtered at the serialization / logging layer
- **Error messages don't leak internal structure**
  - Dimension: in prod, are stack traces / DB errors / internal paths returned to the user
  - Anti-constraint: prod error responses use a generic message; internal detail goes only to server logs
- **PII handled with minimization**
  - Dimension: are unnecessary PII collected; is PII redacted in logs
  - Anti-constraint: returning PII must be a business necessity + PII in logs must be redacted
- **Encryption at rest**
  - Dimension: are passwords using a one-way slow hash; is sensitive data encrypted at rest
  - Anti-constraint: passwords cannot be stored in cleartext or with a fast hash; must use an industry-standard slow hash
- **TLS in transit**
  - Dimension: is data transmitted over an encrypted channel
  - Anti-constraint: production config must not contain non-encrypted endpoints

## 4. Sessions / credentials

- **Session invalidation paths**
  - Dimension: do logout / password change / suspicious login actually invalidate the old session
  - Anti-constraint: logout must really delete the session record + password change must invalidate all sessions
- **Token lifetime / refresh mechanism**
  - Dimension: is the access token too long-lived; does refresh have rotation
  - Anti-constraint: short-lived access token + refresh token has a rotation mechanism
- **Multi-device login policy**
  - Dimension: is unusual concurrent use detected; is there a device fingerprint
  - Anti-constraint: unusual concurrent logins have a notification or block path
- **Brute-force protection**
  - Dimension: does the login endpoint have rate limiting + failure lockout
  - Anti-constraint: login endpoint must have per-IP + per-account rate limiting

## 5. Rate limit / DoS

- **Rate limit on high-frequency endpoints**
  - Dimension: can a single user at high frequency overwhelm the service
  - Anti-constraint: every public endpoint must have rate limiting; quota for critical endpoints can be tightened explicitly
- **Limits on resource-heavy endpoints**
  - Dimension: do upload / search / export have size / row count / time bounds
  - Anti-constraint: large requests must be paginated + use an async queue or carry an explicit cap
- **Recursion / loop bounds**
  - Dimension: do decompression / parsing have depth / size bounds (defending against ZIP bomb / deep nesting)
  - Anti-constraint: parsers must have a depth cap + decompression must have an output size cap

## 6. Third-party dependencies

- **New dependencies audited**
  - Dimension: does a new dependency carry known CVEs
  - Anti-constraint: CI must run a dependency vulnerability scan; high severity must be fixed
- **Lockfile committed**
  - Dimension: are dependency versions pinned; is the install reproducible across environments
  - Anti-constraint: lockfile must be committed
- **Upgrade path covers CVE patches**
  - Dimension: does long-term lack of upgrade expose published vulnerabilities
  - Anti-constraint: there must be a periodic dependency-upgrade process

## 7. Configuration / deployment

- **Secrets not in git**
  - Dimension: have any .env / credentials / key files been committed into history
  - Anti-constraint: all secret files must be in ignore; secrets are injected via env
- **Default values panic-fast — anti silent prod**
  - Dimension: when a critical env var is missing, does it fall back to a default in prod
  - Anti-constraint: critical security envs missing → panic on startup; no silent fallback
- **Domains / endpoints not hardcoded**
  - Dimension: are prod / test / staging endpoints hardcoded in code
  - Anti-constraint: environment-dependent endpoints must come from env injection
- **Runtime not running as a privileged user**
  - Dimension: does the container / process run as root, magnifying a vuln into host privileges
  - Anti-constraint: containers / processes must run as a non-privileged user

## 8. Business logic security

- **IDOR (Insecure Direct Object Reference)**
  - Dimension: can a user pass someone else's resource_id and read their data
  - Anti-constraint: every get / update / delete by resource_id must check owner / tenant scope
- **Privilege escalation paths (regular user → admin)**
  - Dimension: can a profile-update-style endpoint be used to set role / admin / permission fields
  - Anti-constraint: user-mutable fields must use an explicit allowlist; arbitrary client-supplied fields are not accepted
- **Race conditions (concurrent update / counter)**
  - Dimension: do concurrent read-modify-writes have atomicity guarantees
  - Anti-constraint: critical counters / balances must use atomic operations or transactions + row locks
- **Transactional integrity for money / points operations**
  - Dimension: when a multi-step operation fails partway, can it roll back; can it double-spend
  - Anti-constraint: money-class operations must use transactions + idempotency key + state machine

---

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
