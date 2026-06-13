# Project Design-Document Standard

## Purpose

Qualified project design docs are the target project's durable design authority. They explain how the system is shaped, where responsibility lives, how important flows work, which guarantees matter, and where accepted gaps remain. They help future implementers decide whether a change fits the system before reading every implementation detail.

Use this standard when a BF task creates, fills, restructures, or reviews project design documentation.

## Qualified Project Design Docs

A qualified project design doc:

- describes current or accepted system design, not temporary brainstorming;
- names the system boundary or feature boundary it governs;
- records ownership, state authority, cross-module flows, validation boundaries, known gaps, and stable implementation anchors;
- distinguishes accepted facts from inferred or unresolved evidence;
- follows the confirmed doc root and local convention for the target project.

## Recommended Structures

Choose the smallest structure that fits the target project:

- an entrypoint page with a reading map for larger systems;
- focused module or subsystem pages for boundaries that change independently;
- flow pages for cross-module behavior, state transitions, lifecycle, or release paths;
- gap or decision sections when uncertainty is accepted and must be visible.

Use local headings, naming, file placement, and linking conventions when they exist. If no convention exists, keep the structure simple and explain the chosen pattern in the documentation plan.

## Required Coverage

Qualified project design docs should cover the design facts future work needs:

- system boundaries and non-goals;
- module ownership and responsibility splits;
- state authority and mutation rules;
- cross-module flows and lifecycle transitions;
- validation boundaries, release boundaries, and evidence expectations;
- known gaps, do-not-assume notes, and deferred decisions;
- stable implementation anchors such as public entrypoints, command names, data stores, state files, schemas, or integration boundaries.

Coverage should be proportional. A small project can carry this in one concise page; a large project may need a reading map plus focused pages.

## Stable Implementation Anchors

Use anchors that are likely to remain useful across ordinary refactors:

- public commands, routes, package entrypoints, or documented extension points;
- parser, registry, state, storage, or orchestration boundaries;
- stable configuration files, templates, schemas, and generated artifact contracts;
- tests or validation commands that define accepted behavior.

Avoid anchoring design authority to incidental helper names, private call order, or directory listings unless those details are part of the accepted public contract.

## Local Convention Handling

The confirmed project doc root and local convention control where docs belong and how they are organized. Do not force a fixed documentation path, BF-specific layout, or a new hierarchy when the target project already has an accepted convention.

When multiple conventions appear, record the conflict and stop for coordinator clarification. When no convention exists, propose a minimal convention in the planning artifact before drafting.

## Anti-Patterns

Avoid:

- encyclopedia coverage that tries to document every file, class, or function;
- a code directory index presented as architecture;
- generated API listings without design authority;
- tutorial prose that hides ownership, state, flows, validation, or known gaps;
- stale design claims that contradict implementation evidence;
- silently choosing whether code or docs win when design drift appears;
- project-specific maintenance instructions that belong outside the target project's design authority.

## Review Expectations

A design-doc review checks whether the docs are usable as system design authority:

- required coverage is present or gaps are explicit;
- stable anchors are sufficient for future work;
- local convention and confirmed doc root are respected;
- claims are supported by source evidence or accepted design;
- anti-patterns are absent;
- design drift is recorded as a blocker instead of resolved silently.

Use Blocker or High findings for missing authority coverage, unsupported claims, hidden design drift, forced layout, or scope drift. Use Minor or Nit findings for clarity and polish that do not undermine design authority.
