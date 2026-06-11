---
Id: <pack-id>
Desc: <one sentence describing what kind of work this pack is for>
---

<!--
frontmatter field notes:

- Id: Must match the `packs/<pack-id>/` directory name.
- Desc: Shown in `list-packs` output. The LLM uses it during brainstorm to decide whether to select this pack.
-->

## When to Use

Use one to three sentences to describe what kind of work fits this pack. The LLM
reads this section during brainstorm after receiving the user request and uses
it to decide which pack to select. This section is required.

## Domain Vocabulary

Key terms and concepts for this domain. This section is optional, but it helps
the LLM use the right language when talking with the user.

## Brainstorm Guidance

Questions to ask during brainstorm, what shape the blueprint should take, and
what counts as a good blueprint. This section can also name common anti-patterns
the LLM should avoid.

## Breakdown Guidance

What a task should look like in this domain: expected granularity, boundary
rules, typical deliverables, common dependency patterns, and similar guidance.

## Execute Guidance

General guidance for executing a task in this domain: common patterns,
anti-patterns, and what typical evidence should look like. The task driver reads
this section before executing the task.
