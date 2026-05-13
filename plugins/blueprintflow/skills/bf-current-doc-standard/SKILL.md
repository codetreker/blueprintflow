---
name: bf-current-doc-standard
description: "Part of the Blueprintflow methodology. Use when creating, updating, or reviewing docs/current architecture, module, UI, or current-sync PR documentation."
---

# Current Doc Standard

`docs/current` describes the **current implemented system**: boundaries, ownership, flows, state authority, trust, validation, gaps, and code anchors.

Not: blueprint, PR history, test log, endpoint/component catalog, or code walkthrough.

## Direct Invocation Guard

If `bf-workflow` is not active, STOP here. Load `bf-workflow` with the user's input; do nothing else in this skill until it routes back.

## Workflow Fit

| Invoked by | Use |
|---|---|
| `bf-milestone-fourpiece` | Dev creates/updates segment 1.4 current docs |
| `bf-git-workflow` | Teamlead checks current-doc sync before PR |
| `bf-pr-review-flow` | QA verifies presence; Architect verifies quality |

## Required Coverage

| Doc type | Must answer |
|---|---|
| Entry overview | System definition, outside boundary, reader paths |
| System context | Actors, external deps, owned vs external systems |
| Module overview | Role, boundary, collaborators, internal shape, invariants |
| Cross-module flow | Trigger, modules crossed, permission, state read/write, side effects |
| Data/state model | Authority; durable/runtime/local/cache/cursor/audit/migration state |
| Security boundary | Credentials, capabilities, privacy, audit, trust boundaries |
| UI structure reference | Surfaces, navigation, layout/interaction relationship, state transitions |
| Verification/release | Which gates protect which architecture boundaries |
| Known gaps | Current behavior, impact, do-not-assume, owner/next doc |

## Structure

- If `docs/current` does not exist, use [references/current-doc-template.md](references/current-doc-template.md).
- Start broad: diagram/equivalent, module boundary summary, reading map.
- Drill down by module/theme: flow, data, security, UI, verification.
- Put `Implementation Anchors` near the end.
- Make links clickable and contextual; say why to follow them.

## Update / Review Method

- Edit: read related docs/code; merge existing text unless a new section/subdoc fits better.
- Reread the whole affected doc; fix flow, rigor, duplicates, and sibling-doc conflicts.
- Review from changed code plus affected docs; do not review only the diff.

## Implementation Anchors

Stable anchors: directories/packages; schema/config/migration folders; key files/types/interfaces; durable protocols/manifests.

Avoid line links, exhaustive function/helper/endpoint catalogs, and PR references.

## Anti-Patterns

| Do not write | Replace with |
|---|---|
| Future roadmap / promised behavior | Current behavior + known gap |
| PR timeline / changelog story | Current system shape |
| Test run log / acceptance checklist | Validation boundary and protected risk |
| Endpoint or schema field catalog | State ownership, authority, lifecycle |
| Component / DOM / CSS selector inventory | UI surface map and interaction structure |
| File-by-file code tour | Module role, boundary, collaborators |
| Helper/function list | Stable implementation anchors |
| Vague TODOs | Current behavior, impact, do-not-assume |

## Review Checklist

- [ ] Current implementation only; future intent stays in `docs/blueprint`/`docs/tasks`.
- [ ] Boundaries, non-goals, flows, state authority, trust boundaries are explicit.
- [ ] Validation/release gates name the boundary they protect.
- [ ] Known gaps include current behavior, impact, and do-not-assume.
- [ ] Anchors are stable and limited.
- [ ] No endpoint catalog, component list, PR timeline, test record as architecture.
