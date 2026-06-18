---
Id: <role-id>
Desc: <one sentence describing this role's identity>
Capabilities:
  - <capability-1>
  - <capability-2>
---

<!--
frontmatter field notes:

- Id: Unique identifier shown in `list-roles` output.
- Desc: One-sentence description that helps the LLM quickly decide when this role fits.
- Capabilities: The capabilities this role provides. Capabilities named by AC lines in `bf.md` and task `spec.md` are resolved against this list.
  BF Core has no centralized capability registry. Any capability string declared in any `roles/*.md` file is a valid capability.
  `bf-harness lint` scans capabilities referenced by each bf-wo and requires every one to be declared by a role, which catches typos.
-->

# {Role Name}

## Identity

This role's identity and perspective: how it approaches the work, what it cares
about, and what it does not care about.

## Contract Ambiguity

Include this section for any role that acts on a locked contract (most roles).
State that the role reads `discussion.md` only when accepted scope, boundary,
acceptance, evidence, or design intent is unclear while doing its assigned BF
work, and that it reports the ambiguity to the coordinator and stops before
inventing scope or changing the locked contract when `discussion.md` does not
answer it.

## Material User Decisions

Include this section for any role that can hit a material user-decision point in
delegated BF work. State that the role does not ask the user directly from
delegated BF work; instead it stops and returns decision-brief input to the
coordinator: the decision, relevant context and current evidence, realistic
options, tradeoffs or consequences, and a recommendation when evidence supports
one.

## Expertise

What this role can do, what kinds of problems it solves, and any specific
preferences or methods it applies.

## When to Include

When this role should be included. This can apply to brainstorm, spec, execute,
review, or any other stage.
