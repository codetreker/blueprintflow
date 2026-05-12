# Preflight check

Before using the bf-phase-plan flow, walk this decision graph. If any check returns "yes", skip the heavyweight machinery.

```dot
digraph phase_plan_preflight {
    "Considering blueprintflow" [shape=doublecircle];
    "PR touches ≤1 file with no docs/blueprint reference?" [shape=diamond];
    "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" [shape=diamond];
    "Team collaborators <3?" [shape=diamond];
    "Project missing docs/blueprint/?" [shape=diamond];
    "Skip 4-piece, go straight to PR review" [shape=box];
    "Skip 4-piece (change-type axis)" [shape=box];
    "Skip 4-role dual review (single-person iteration)" [shape=box];
    "Redirect to bf-brainstorm to lock stance" [shape=box];
    "Run the full phase-plan + 4-piece flow" [shape=doublecircle];
    "Exit preflight (not applicable)" [shape=doublecircle];

    "Considering blueprintflow" -> "PR touches ≤1 file with no docs/blueprint reference?";
    "PR touches ≤1 file with no docs/blueprint reference?" -> "Skip 4-piece, go straight to PR review" [label="yes"];
    "PR touches ≤1 file with no docs/blueprint reference?" -> "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" [label="no"];
    "Skip 4-piece, go straight to PR review" -> "Exit preflight (not applicable)";
    "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" -> "Skip 4-piece (change-type axis)" [label="yes"];
    "PR type ∈ {typo/dep/lint/refactor/tooling/hotfix}?" -> "Team collaborators <3?" [label="no"];
    "Skip 4-piece (change-type axis)" -> "Exit preflight (not applicable)";
    "Team collaborators <3?" -> "Skip 4-role dual review (single-person iteration)" [label="yes"];
    "Team collaborators <3?" -> "Project missing docs/blueprint/?" [label="no"];
    "Skip 4-role dual review (single-person iteration)" -> "Exit preflight (not applicable)";
    "Project missing docs/blueprint/?" -> "Redirect to bf-brainstorm to lock stance" [label="yes"];
    "Project missing docs/blueprint/?" -> "Run the full phase-plan + 4-piece flow" [label="no"];
    "Redirect to bf-brainstorm to lock stance" -> "Exit preflight (not applicable)";
}
```

## Decision points

| # | Check | Skip if | Constraint |
|---|---|---|---|
| 1 | `git diff --name-only main \| wc -l` ≤ 1 and no `docs/blueprint` reference | Single-file fix, no blueprint citation | If the change cites §X.Y → can't skip, run 4-piece |
| 2 | PR type is typo / dep bump / lint / refactor / tooling / hotfix | Mechanical change | Breaking dep bump → fall back; hotfix must have retro PR within 7 days |
| 3 | `gh api repos/:o/:r/contributors \| jq length` < 3 | Solo / 2-person team | AI agent team (1 human + 6 agents) = full team, not solo |
| 4 | `docs/blueprint/` missing or only README | No blueprint yet | Redirect to `bf-brainstorm` + `bf-blueprint-write` first |

Walk the checks **in order** — each depends on the earlier ones.

## Anti-patterns

- ❌ Skipping preflight → heavyweight machinery on a project that doesn't need it
- ❌ Forcing phase-plan after preflight said "not applicable"
- ❌ Short-circuiting the 4 checks with "or" (they run in series)
- ❌ Permanent hotfix bypass without retro PR within 7 days
