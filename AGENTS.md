# Repository Guidelines

## What BF Is

BF is an evidence-gated workflow runtime for LLM orchestrators. It turns a user
request into a locked Markdown contract, then drives implementation through
harness-owned state transitions and independent reviewer sign-off.

BF is not an application server. Runtime artifacts are instructions, templates,
roles, packs, and CLI tools that an orchestrating LLM reads and executes.

## Source Of Truth

| Area | Source |
|---|---|
| BF runtime | Root npm package: `SKILL.md`, `bin/`, `roles/`, `packs/`, `templates/`, `references/` |
| BF design | `docs/`, especially `docs/spec.md` |
| DDD draft work | `.tasks/` (gitignored) |
| Tests | `test/` + `npm test` |
| Legacy plugin | `plugins/blueprintflow/` (deprecated; edit only when explicitly requested) |

## Hard Rules

- Treat `docs/` as the durable, latest accepted design record.
- Put draft DDD notes, alternatives, and discussion artifacts in `.tasks/`.
- After DDD is accepted, update the relevant `docs/` files.
- Keep runtime artifacts self-contained. `SKILL.md`, `roles/`, `packs/`, `templates/`, and `references/` must not reference `docs/` or `.tasks/`.
- Use a worktree for implementation work.
- Never push directly to `main`.
- Never use admin merge. If a PR is blocked, resolve every blocking review,
  check, branch policy, or conversation issue and merge normally.
- Use the BF gate for PR readiness: the PR author records the BF work object
  id/status and validation evidence, or records why BF was not required;
  required GitHub reviews/checks pass; blocking conversations are resolved.
- When spawning subagents, use the same thinking/reasoning effort as the main
  agent. Do not lower effort unless the user explicitly requests it.
- Do not use legacy plugin content as BF source of truth unless the user explicitly asks.

## Required Flow

For behavior, architecture, parser, harness, CLI, install, package layout, or runtime-instruction changes:

1. Create or use a focused worktree.
2. Discuss the design.
3. Record draft design in `.tasks/`.
4. Get user approval.
5. Write the smallest failing test for one approved behavior.
6. Confirm the test fails for the expected reason.
7. Implement the smallest passing change.
8. Re-run the focused test.
9. Repeat red-green for remaining behavior.
10. Update `docs/` with the accepted final design.
11. Run full validation.
12. Commit, push, and open a PR when requested.

If implementation exposes a design gap, stop coding and return to DDD.

## TDD Gate

- No production code before a failing test.
- No broad implementation before a focused red test.
- No completion claim before `npm test` passes.
- No test rewrite to fit an implementation unless the approved design changed.

## Commands

```bash
npm install
npm test
git diff --check
.github/scripts/validate-bf-package-layout.sh
.github/scripts/validate-bf-version.sh origin/main
```

Focused test examples:

```bash
bash test/test-cmd-install.sh
bash test/test-cmd-list-pipelines.sh
```

When legacy plugin files are touched, also run:

```bash
.github/scripts/validate-plugin-layout.sh
.github/scripts/validate-skills.sh
.github/scripts/validate-release-version.sh origin/main
```

## Version Gates

- Release-facing BF changes require a semver bump in `package.json` and `package-lock.json`.
- Legacy plugin manifest versions matter only when legacy plugin files change.

## Style

- Prefer small, scoped changes.
- Use existing parsers, registries, and helpers before adding new mechanisms.
- Write runtime instructions as direct commands.
- Put durable rationale in `docs/`, not runtime files.
- Use ASCII punctuation unless editing existing Chinese prose.
- Use `apply_patch` for manual edits.

## Anti-Patterns

- "This is small enough to code directly." --> No. Record the design in `.tasks/`, get approval, then enter TDD.
- "I'll add tests after the implementation." --> No. Write the failing test first and confirm the expected failure.
- "The test is failing because the implementation is not done, so I can keep coding." --> Stop. Confirm the failure matches the approved behavior before writing production code.
- "The design gap is obvious; I'll decide in code." --> Stop. Return to DDD.
- "This draft should live in `docs/` so it is easy to find." --> No. Put drafts in `.tasks/`; update `docs/` only after acceptance.
- "The DDD is done, so the code is enough." --> No. Update the relevant `docs/` files with the final accepted design.
- "Runtime can link to `docs/` for more detail." --> No. Keep runtime artifacts self-contained; move required instructions into runtime files.
- "The old plugin already solved this." --> No. Treat `plugins/blueprintflow/` as deprecated unless the user asked for legacy plugin work.
- "A CI check can enforce this wording preference." --> No. Keep permanent CI to stable mechanical invariants only.
- "It is faster to rewrite the surrounding file." --> No. Make the smallest scoped edit that satisfies the approved task.
