# @codetreker/bf

**BF — evidence-gated work loop CLI for LLM orchestrators.**

BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by a reviewer subagent that is **not the same subagent instance** that did the work.

This package ships the BF v1 core: the CLI (`bf`, `bf-harness`), the entry skill (`SKILL.md`), Core roles, the engineering pack, file templates, and phase references.

## Install

```bash
npm install -g @codetreker/bf
# or as a project dev dep
npm install --save-dev @codetreker/bf
```

Requires Node.js ≥ 20.

`npm install` also runs a `postinstall` step that copies the skill files (`SKILL.md`, `roles/`, `packs/`, `templates/`, `references/`, `bin/`) into `~/.claude/skills/bf/` so Claude Code can discover the `/bf` skill. Re-run manually anytime with `bf install`.

### Uninstalling

npm (≥ v7) does **not** run lifecycle scripts on `npm uninstall`, so removing the package does **not** clean up `~/.claude/skills/bf/` automatically. To remove the skill files, run:

```bash
bf uninstall                              # before npm uninstall, while the CLI is still on $PATH
npm uninstall -g @codetreker/bf           # or --save-dev for project installs
```

`bf uninstall` preserves any roles or packs you added yourself; only the files BF originally installed are removed.

## What you get

After install, two CLIs are on `$PATH`:

- `bf` — read-only metadata + install management: `bf list-packs`, `bf list-roles [--pack <id>]`, `bf install`, `bf uninstall`, `bf version`
- `bf-harness` — state-mutating loop driver: `lint`, `start-review`, `accept`, `next`, `verify`, `discard`, `list`

Run either with `--help` for full usage.

## How it works (in 30 seconds)

```
brainstorm  →  spec  ──accept──▶  execute  ──verify──▶  Completed
                  ▲                    │
                  └──── lint / verify FAIL ───┘
```

1. **Brainstorm** — drive a discussion with the user, pick a pack, write `discussion.md`.
2. **Spec** — author `bf.md` + per-task `spec.md` in `Draft`, `lint`, run a spec review round, `verify` (Mode A), then `accept`. Contract is locked.
3. **Execute** — `next` claims one ready task; a doer subagent does it; a **different** reviewer subagent grades it; `verify` (Mode B) flips its AC on SUCCESS. Repeat. A final `verify` (Mode C) flips the bf.md AC and marks the work Completed.

## State layout

BF stores all work-in-progress state at `<cwd>/.bf/<bf-wo>/`. Add `.bf/` to your `.gitignore`. Override the location with the `BF_HOME` env var (mostly useful for tests).

```
<project-root>/
  .bf/
    <bf-wo>/
      bf.md
      discussion.md
      runs/reviews/round_N/
        result_<role>_<idx>.md
        verify-result.md
      <task-id>/
        spec.md
        runs/reviews/round_N/...
```

## The Independent Verification rule

The harness cannot see subagent identity (review filenames are role-level). IV is enforced **only by the orchestrator** when spawning subagents:

- For any given task, the doer and any reviewer must be **different subagent instances**.
- Same `role` on both sides is fine (e.g. `engineer` doer + a separate `engineer` reviewer).
- Same subagent instance on both sides is a contract violation the harness will not catch.

## Where to read next

- `SKILL.md` — entry doc for the orchestrating LLM (high-level contract + IV red line).
- `references/phase-1-brainstorm.md` — drive the discussion, pick a pack.
- `references/phase-2-spec.md` — author specs, lint, Mode A review, accept.
- `references/phase-3-execute.md` — `next → do → review → verify` loop.
- `templates/` — frozen file shapes; copy these when authoring.
- `roles/`, `packs/` — Core roles and installed packs.

## License

MIT
