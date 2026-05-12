# Repository Guidelines

## Project Structure & Module Organization

Blueprintflow is a Markdown-first repository for Claude/OpenClaw/Codex skills, not an application runtime. Core skill packages live under `skills/bf-*/`; each package has a `SKILL.md` entrypoint and may include supporting material in `references/`. Project documentation lives in `README.md`, `docs/CHANGELOG.md`, and `docs/tasks/BOARD.md`. Plugin metadata is in `.claude-plugin/`, `.codex-plugin/`, and `.agents/plugins/`. Pull request process guidance is in `.github/pull_request_template.md`.

## Build, Test, and Development Commands

There is no package manager, build step, or automated test runner in this repo. Use lightweight validation commands before opening a PR:

```bash
rg --files skills docs .github .claude-plugin
```

Lists tracked content areas and catches unexpected file placement.

```bash
rg "TODO|FIXME|TBD" skills docs README.md
```

Finds unresolved placeholders before review.

```bash
git diff --check
```

Checks for whitespace errors in Markdown and JSON files.

## Coding Style & Naming Conventions

Write skill content in concise Markdown with clear headings, direct instructions, and executable examples. Keep skill directories named `skills/bf-<topic>/`, with the public entrypoint always named `SKILL.md`. Store longer role prompts, checklists, or execution notes in `references/*.md` rather than bloating the skill entrypoint. Keep JSON metadata formatted with two-space indentation. Prefer ASCII punctuation unless editing existing Chinese prose where full-width punctuation is already used.

## Testing Guidelines

Validation is review-driven. For any skill change, manually check that triggers, responsibilities, examples, and referenced files still match the README skill table. If a skill references `references/foo.md`, verify the file exists and the relative path is correct. For workflow changes, test by reading the modified skill from a fresh-agent perspective: the next action should be unambiguous and verifiable.

## Commit & Pull Request Guidelines

Git history uses short conventional prefixes such as `feat:`, `fix:`, `chore:`, and `skill:`; keep that style, for example `fix: clarify phase exit gate checklist`. PRs should include a summary, affected skills, and the review checklist from the template. The expected review lenses are Architect consistency, PM readability, Dev executability, QA verifiability, and Owner direction. Link issues when relevant and update `docs/CHANGELOG.md` or plugin version metadata for release-facing changes.

## Version Metadata

Release-facing version bumps must update both `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` to the same version. Treat the Claude manifest as the existing release source and the Codex manifest as the Codex packaging mirror; do not bump one without the other.

## Agent-Specific Instructions

Keep future edits focused and prefer updating the smallest relevant `SKILL.md` or `references/*.md` file. Avoid unrelated formatting churn.
