# Preflight check

Before using the bf-phase-plan flow, walk this decision graph. If any check returns "yes", skip the heavyweight machinery.

```dot
digraph phase_plan_preflight {
    "Considering blueprintflow" [shape=doublecircle];
    "PR touches ≤1 file with no docs/blueprint reference?" [shape=diamond];
    "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" [shape=diamond];
    "Project missing docs/blueprint/?" [shape=diamond];
    "Skip Phase/Milestone planning; go straight to PR review" [shape=box];
    "Skip Phase/Milestone planning (change-type axis)" [shape=box];
    "Redirect to bf-brainstorm to lock stance" [shape=box];
    "Run Phase/Milestone planning" [shape=doublecircle];
    "Exit preflight (not applicable)" [shape=doublecircle];

    "Considering blueprintflow" -> "PR touches ≤1 file with no docs/blueprint reference?";
    "PR touches ≤1 file with no docs/blueprint reference?" -> "Skip Phase/Milestone planning; go straight to PR review" [label="yes"];
    "PR touches ≤1 file with no docs/blueprint reference?" -> "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" [label="no"];
    "Skip Phase/Milestone planning; go straight to PR review" -> "Exit preflight (not applicable)";
    "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" -> "Skip Phase/Milestone planning (change-type axis)" [label="yes"];
    "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" -> "Project missing docs/blueprint/?" [label="no"];
    "Skip Phase/Milestone planning (change-type axis)" -> "Exit preflight (not applicable)";
    "Project missing docs/blueprint/?" -> "Redirect to bf-brainstorm to lock stance" [label="yes"];
    "Project missing docs/blueprint/?" -> "Run Phase/Milestone planning" [label="no"];
    "Redirect to bf-brainstorm to lock stance" -> "Exit preflight (not applicable)";
}
```

## Decision points

After this preflight says Phase/Milestone planning applies, require recorded `bf-blueprint-iteration` Next lock integrity gate evidence in `docs/blueprint/_meta/<target-version>/next-lock-integrity.md`. Treat evidence as stale if selected anchors, README rows, detail anchors, blockers/open anchors, source issue/note trace, milestone paths, `phase-plan.md`, or `milestone.md` changed after the recorded gate result. If the gate is missing, stale, or failed, stop and return to `bf-blueprint-iteration` for fresh lock evidence before planning.

| # | Check | Skip if | Constraint |
|---|---|---|---|
| 1 | `git diff --name-only main \| wc -l` ≤ 1 and no `docs/blueprint` reference | Single-file fix, no blueprint citation | If the change cites §X.Y → route through `bf-workflow` |
| 2 | PR type is typo / dep bump / lint / refactor / tooling / hotfix | Mechanical change | Breaking dep bump → fall back; hotfix must have retro PR by the project-defined hotfix threshold |
| 3 | `docs/blueprint/` missing or only README | No blueprint yet | Redirect to `bf-brainstorm` + `bf-blueprint-write` first |

Walk the checks **in order** — each depends on the earlier ones.

## Anti-patterns

- ❌ Skipping preflight → heavyweight machinery on a project that doesn't need it
- ❌ Forcing phase-plan after preflight said "not applicable"
- ❌ Short-circuiting the checks with "or" (they run in series)
- ❌ Permanent hotfix bypass without retro PR by the project-defined hotfix threshold
- ❌ Using small human team size to skip required role or Security review
