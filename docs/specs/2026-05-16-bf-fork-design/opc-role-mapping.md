# OPC Role Mapping

Companion to [../2026-05-16-bf-fork-design.md](../2026-05-16-bf-fork-design.md).

Decision policy for each of OPC's 16 roles. Three buckets:

- **Adopt to BF Core (`roles/`)** — generic enough for any Pack
- **Adopt to product-engineering Pack (`packs/product-engineering/roles/`)** — specific to product engineering
- **Skip** — too OPC-specific or redundant with BF's own role definitions

## Decision rule

**Ask one question: would this role still make sense in a different Pack (research / incident / content / ...)?**

- Yes for all → **Core role**
- No, only in product engineering → **Pack role**
- Industry-specific framing that no real Pack would adopt as-is → **Skip**

A second cross-check: does the role correspond to a BF axiom in [layering-principles.md](./layering-principles.md) §0? If yes, it's almost certainly a Core role (because axioms are domain-general by definition). For the full reasoning behind the layering choice, see [layering-principles.md](./layering-principles.md) §4.

## OPC roles inventory

From `/workspace/opc/roles/`:

```
a11y, active-user, architect, backend, churned-user, compliance,
dd-engineer, designer, devil-advocate, devops, engineer, frontend,
investor, mobile, new-user, pm, planner, security, skeptic-owner,
tester, user-simulator
```

(21 listed; OPC's README says 16 — minor inventory mismatch, treat the file list as source of truth.)

## Mapping table

| Role | Decision | Rationale |
|---|---|---|
| **planner** | **Adopt to BF Core** | Decomposition is a domain-general capability. Any Pack can need it. |
| **architect** | **Adopt to BF Core** | System-shape judgment is general. Polish: remove software-specific phrasing where possible. |
| **devil-advocate** | **Adopt to BF Core** | Adversarial review is domain-general. Auto-included when consensus is high — keep this rule. |
| **skeptic-owner** | **Adopt to BF Core** | Mandatory reviewer pattern is general; keep `mandatory: true` semantics. |
| **tester** | **Adopt to BF Core** | "Independent verifier" is BF axiom 5 (see [layering-principles.md](./layering-principles.md) §0). Generic name kept. |
| **security** | **Adopt to BF Core** | Security review applies beyond product engineering (research data handling, compliance, ops). |
| **a11y** | **Adopt to BF Core** | Accessibility review applies wherever there's a human interface, including non-engineering content. |
| **compliance** | **Adopt to BF Core** | Legal/regulatory review applies to many Packs (research consents, content licensing, ops). |
| **user-simulator** | **Adopt to BF Core** | Persona-driven simulation is general (research participants, content audiences, incident-affected users). |
| **engineer** | **Adopt to product-engineering Pack** | Specifically software engineering. |
| **frontend** | **Adopt to product-engineering Pack** | Software-specific. |
| **backend** | **Adopt to product-engineering Pack** | Software-specific. |
| **devops** | **Adopt to product-engineering Pack** | Software-specific. |
| **mobile** | **Adopt to product-engineering Pack** | Software-specific. |
| **dd-engineer** | **Adopt to product-engineering Pack** | OPC-coined: "due diligence engineer". Useful in product-eng review. |
| **designer** | **Adopt to product-engineering Pack** | UI/UX design — software-product specific. |
| **pm** | **Adopt to product-engineering Pack** | OPC's PM has product-management flavor; reuse for product-eng. Research / incident Packs will write their own variant. |
| **new-user** | **Adopt to product-engineering Pack** | User-lens roles fit product-engineering directly. Could later generalize as `audience-new` in a Core pattern, but v1 doesn't need that. |
| **active-user** | **Adopt to product-engineering Pack** | Same as new-user. |
| **churned-user** | **Adopt to product-engineering Pack** | Same. |
| **investor** | **Skip** | OPC-specific framing. Not in BF's path. If needed later, a `business` Pack can add it. |

## Polish strategy

For roles adopted to BF Core, apply these tightening passes:

1. **De-software** the language — `frontend` keeps its software flavor (because it stays in product-eng Pack); but `architect` should be re-phrased to apply to any system-shape decision, not just code.
2. **Keep `tags:` front matter** — OPC's stage tags (`review`, `build`, `execute`, etc.) align with BF Core's node types. No change needed.
3. **Keep `When to Include`** section — already domain-aware.
4. **Add `provides_capability:` front matter** — new BF field. Maps to Work Object `capability_required`. E.g. tester provides `["independent-verification", "test-design"]`.
5. **Add `pack_scope:` front matter** — `core` (any Pack) vs `<pack-id>` (specific). Lets BF Core's selection logic filter cleanly.

## Comparison with current BF team roles

`bf-team-roles` skill in `plugins/blueprintflow/skills/bf-team-roles/` defines:

| BF role | Maps to OPC role(s) |
|---|---|
| PM | `pm` |
| Architect | `architect` |
| Dev | `engineer` / `frontend` / `backend` |
| QA | `tester` |
| Teamlead | — (no OPC equivalent; BF-specific orchestration role) |
| (security review) | `security`, `compliance`, `a11y` |
| (devil's advocate) | `devil-advocate` |

**Decision**: keep BF's high-level role names (PM, Architect, Dev, QA, Teamlead) as **product-engineering Pack roles**, sourced from OPC's role files with polishing. Teamlead is BF-original — written from scratch, no OPC vendor.

## Open

- Should we de-emoji OPC role files? OPC uses 🔴🟡🔵 conventions matched by `synthesize`; if so, keep emojis. (Lean: keep — they're mechanical, not decorative.)
- Some OPC roles have anti-patterns sections heavy on software examples. Worth a per-role polish pass before Stage 5 demo.
