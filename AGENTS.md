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
| Tests | `test/` + `npm test` |
| Legacy plugin | `plugins/blueprintflow/` (deprecated; edit only when explicitly requested) |

## Hard Rules

- Treat `docs/` as the durable, latest accepted design record.
- After DDD is accepted, update the relevant `docs/` files.
- Keep runtime artifacts self-contained. `SKILL.md`, `roles/`, `packs/`, `templates/`, and `references/` must not reference `docs/`.
- Use a worktree for implementation work.
- Never push directly to `main`.
- Never use admin merge. If a PR is blocked, resolve every blocking review,
  check, branch policy, or conversation issue and merge normally.
- Use the BF gate for PR readiness: the PR author records the BF work object
  id/status and validation evidence, or records why BF was not required;
  required GitHub reviews/checks pass; blocking conversations are resolved.
- Run dependency install and test validation that can invoke BF with isolated
  `HOME`, `CODEX_HOME`, and `BF_HOME`; use
  `.github/scripts/with-isolated-bf-env.sh` for repository validation.
- When spawning subagents, use the same thinking/reasoning effort as the main
  agent. Do not lower effort unless the user explicitly requests it.
- Do not use legacy plugin content as BF source of truth unless the user explicitly asks.

## Required Flow

For behavior, architecture, parser, harness, CLI, install, package layout, or runtime-instruction changes:

1. Create or use a focused worktree.
2. Discuss the design.
3. Record the design discussion in BF work-object artifacts.
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
bash .github/scripts/with-isolated-bf-env.sh npm install
bash .github/scripts/with-isolated-bf-env.sh npm test
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
- Do not insert line breaks in prompt or runtime-instruction prose merely because a line exceeds a target length such as 80 characters. Preserve semantic line breaks, table rows, code blocks, quoted text, and line breaks required by a file format.
- Use `apply_patch` for manual edits.

## Writing Skill Prompts

A skill prompt is executed by an actor that has only that text, not your reasoning. Write so the actor, reading only this, acts correctly.

- Teach HOW, not WHY. Every sentence must change what the actor does. Cut anything that only explains.
- Keep a `why` only when it lets the actor generalize to a case you did not list, or stops the actor rationalizing away a fail-closed rule. One clause, not a paragraph.
- Sink design rationale, history, and justification into `docs/` or code comments, never the actor's instruction path.
- State the sequence and the owner, not just the end state. Name who does what, in what order, and what must hold before each gate. Passive voice hides the owner.
- Give the exact form: the command, flag, field, or trailer syntax. An instruction the actor cannot run verbatim is a latent failure.
- Carry the condition on any instruction that is only true in one mode or context. A rule stated unconditionally that is wrong in another mode is a contradiction bug.
- Surface the discriminator the actor needs inline. Do not make it infer state from a place you never told it to read.
- Give the recovery path: name the failure the actor will hit and how to recover. An unannounced fail-closed gate reads as a bug.
- Default uncertainty to stop and escalate, not guess. Encode stop conditions.
- Show, do not point: present the content the actor must act on inline; a file or path pointer may supplement but never replace it.
- One source of truth: do not restate a rule across surfaces where the copies can drift.
- Test by role immersion before shipping: read the prompt AS the actor that executes it, with only what it is given, and ask "would I act correctly, stall, or err?". Prefer independent reviewers each in a distinct actor seat; ground every fix in the actual mechanism, because reviewers propose wrong fixes too.

The cut test for every sentence: does it change what the actor does? An imperative instruction keeps. A `why` that changes a judgment in an unlisted case keeps. Pure background is cut, or sunk to `docs/`.

## Anti-Patterns

- "This is small enough to code directly." --> No. Record the design, get approval, then enter TDD.
- "I'll add tests after the implementation." --> No. Write the failing test first and confirm the expected failure.
- "The test is failing because the implementation is not done, so I can keep coding." --> Stop. Confirm the failure matches the approved behavior before writing production code.
- "The design gap is obvious; I'll decide in code." --> Stop. Return to DDD.
- "This draft should live in `docs/` so it is easy to find." --> No. Update `docs/` only after the design is accepted.
- "The DDD is done, so the code is enough." --> No. Update the relevant `docs/` files with the final accepted design.
- "Runtime can link to `docs/` for more detail." --> No. Keep runtime artifacts self-contained; move required instructions into runtime files.
- "The old plugin already solved this." --> No. Treat `plugins/blueprintflow/` as deprecated unless the user asked for legacy plugin work.
- "A CI check can enforce this wording preference." --> No. Keep permanent CI to stable mechanical invariants only.
- "It is faster to rewrite the surrounding file." --> No. Make the smallest scoped edit that satisfies the approved task.
