# @codetreker/bf

**BF — evidence-gated work loop CLI for LLM orchestrators.**

BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by a reviewer subagent that is **not the same subagent instance** that did the work.

This package ships the BF core: the CLI (`bf`, `bf-harness`), the entry skill (`SKILL.md`), Core roles, the engineering pack, file templates, and phase references.

## Install

```bash
npm install -g @codetreker/bf
```

Requires Node.js ≥ 20. **Install globally** (`-g`) so the `bf` and `bf-harness` CLIs land on `$PATH` — that is the only supported install mode. Local installs (`--save-dev`) put the CLIs in `node_modules/.bin/` only and break shell invocations from subagent commands.

`npm install` also runs a `postinstall` step that copies a host discovery snapshot (`SKILL.md`, `roles/`, `packs/`, `templates/`, `references/`) for detected LLM hosts. Claude Code uses `~/.claude/skills/bf/`; Codex uses `$CODEX_HOME/skills/bf/`, defaulting to `~/.codex/skills/bf/`. The install output lists detected targets and whether each snapshot was installed, updated, refreshed, or updated from an unknown older copy. Re-run manually anytime with `bf install`.

`bf install` auto-detects supported targets. Use `--target` to install one explicitly:

```bash
bf install --target claude
bf install --target codex
```

### Updating

Run `bf update` to upgrade the global BF npm package to the latest published
version:

```bash
bf update
```

The command runs `npm install -g @codetreker/bf@latest`. The updated package's
`postinstall` step then runs `bf install`, so Claude/Codex discovery snapshots
are refreshed by the same install path instead of by a second manual refresh.

### Uninstalling

npm (≥ v7) does **not** run lifecycle scripts on `npm uninstall`, so removing the package does **not** clean up host discovery snapshots automatically. To remove them, run:

```bash
bf uninstall                              # before npm uninstall, while the CLI is still on $PATH
npm uninstall -g @codetreker/bf
```

`bf uninstall` auto-detects supported targets. Use `bf uninstall --target claude` or `bf uninstall --target codex` for one target.

## Extending BF — `extensions/`

BF looks for additional roles and packs in host-neutral `extensions/` directories. Drop `.md` files in role dirs or full pack directories, and BF will pick them up automatically.

| Location | When to use |
|---|---|
| `~/.bf/extensions/roles/<name>.md` | A custom role you want available across every project |
| `~/.bf/extensions/packs/<id>/pack.md` | A custom pack available globally |
| `<project-root>/.bf/extensions/roles/<name>.md` | A role only this project should see |
| `<project-root>/.bf/extensions/packs/<id>/pack.md` | A pack only this project should see |

**Precedence (highest wins):** project extension → global extension → selected pack-private role → Core role. So a project-local `engineer.md` overrides anything else with that id.

Host discovery snapshots are generated copies. Do not put extensions under `~/.claude/skills/bf/` or `$CODEX_HOME/skills/bf/`; BF does not read those locations.

`bf list-packs` shows each effective pack with every `pack.md` path in read order. `bf list-roles [--pack <id>]` and `bf list-pipelines [--pack <id>]` show the final effective role and pipeline registries.

## What you get

After install, two CLIs are on `$PATH`:

- `bf` — read-only metadata + install management: `bf list-packs`, `bf list-pipelines [--pack <id>]`, `bf list-roles [--pack <id>]`, `bf install`, `bf update`, `bf uninstall`, `bf version`
- `bf-harness` — state-mutating loop driver: `lint`, `start-review`, `accept`, `next`, `verify`, `discard`, `list`

Run either with `--help` for full usage.

## How it works (in 30 seconds)

```
brainstorm  →  spec  ──accept──▶  execute  ──verify──▶  Completed
                  ▲                    │
                  └──── lint / verify FAIL ───┘
```

1. **Brainstorm** — drive a discussion with the user, pick a pack, write `discussion.md`.
2. **Spec** — author `bf.md` + per-task `spec.md` in `Draft`, `lint`, run a Spec Review round, `verify`, then `accept`. Contract is locked.
3. **Execute** — `next` claims one ready task and returns its pipeline; subagents follow the pipeline instructions; a **different** reviewer subagent grades the final task AC; Task Verification flips its AC on SUCCESS. Repeat. Final Acceptance flips the bf.md AC and marks the work Completed.

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
- `references/brainstorm.md` — drive the discussion, pick a pack.
- `references/spec-authoring.md` — author specs, design any bf-wo local pipelines, lint, Spec Review, accept.
- `references/execution.md` — `next → do → review → verify` loop.
- `templates/` — frozen file shapes; copy these when authoring.
- `roles/`, `packs/` — Core roles and installed packs.

## License

MIT
