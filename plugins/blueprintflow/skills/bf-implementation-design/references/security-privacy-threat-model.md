# Security / Privacy Threat Model

Use for sensitive code tasks before Security design LGTM.

## Required When

Task scope includes auth, privacy, credentials, dangerous commands, remote agents, admin paths, tenant/user data isolation, dependency execution, or project-defined sensitive areas.

## Design Section Template

Add this section to task `design.md`:

```markdown
## Security / Privacy Threat Model

Assets:
- <tokens, PII, tenant data, filesystem, command capability, admin action, etc.>

Trust boundaries:
- <browser/server/worker/agent/host/filesystem/network boundary>

Actors and capabilities:
- <normal user/admin/agent/operator/attacker>

Abuse cases:
- <what could go wrong>

Mitigations:
- <authz, validation, audit, sandbox/least privilege, redaction, rate limit, approval boundary>

Verification:
- <tests/checks/security review items>

Privacy decisions:
- Collection: <data collected or N/A>
- Purpose: <why needed>
- Retention/deletion: <policy or N/A>
- Disclosure/logging/export: <where data appears; redaction>
```

## Checks

- Security reviewer can trace every mitigation to a design choice or verification item.
- Privacy data has purpose, retention, deletion, and logging/export decisions.
- If a mitigation is deferred, it has a future task path or placeholder PR.
