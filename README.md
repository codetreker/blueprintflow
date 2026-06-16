# @codetreker/bf

**BF — evidence-gated work loop CLI for LLM orchestrators.**

BF turns a fuzzy user request into a locked contract (`bf.md` + per-task `spec.md`), then drives execution through a `next → do → review → verify` loop until every Acceptance Criterion is signed off by a reviewer actor that is **not the same actor instance** whose work is reviewed.

This package ships the BF core: the CLI (`bf`, `bf-harness`), the entry skill (`SKILL.md`), Core roles, the engineering pack, file templates, and phase references.

## Install

```bash
npm install -g @codetreker/bf
```

Requires Node.js ≥ 20. **Install globally** (`-g`) so the `bf` and `bf-harness` CLIs land on `$PATH` — that is the only supported install mode. Local installs (`--save-dev`) put the CLIs in `node_modules/.bin/` only and break shell invocations from delegated actor commands.

`npm install` also runs a `postinstall` step that copies a host discovery snapshot (`SKILL.md`, `roles/`, `packs/`, `templates/`, `references/`) for detected LLM hosts. Claude Code uses `~/.claude/skills/bf/`; Codex uses `$CODEX_HOME/skills/bf/`, defaulting to `~/.codex/skills/bf/`; Copilot uses `~/.copilot/skills/bf/`. The install output lists detected targets and whether each snapshot was installed, updated, refreshed, or updated from an unknown older copy. Re-run manually anytime with `bf install`.

`bf install` auto-detects supported targets. Use `--target` to install one explicitly:

```bash
bf install --target claude
bf install --target codex
bf install --target copilot
```

### Updating

Run `bf update` to upgrade the global BF npm package to the latest published
version:

```bash
bf update
```

The command runs `npm install -g @codetreker/bf@latest`. The updated package's
`postinstall` step then runs `bf install`, so Claude/Codex/Copilot discovery snapshots
are refreshed by the same install path instead of by a second manual refresh.

### Uninstalling

npm (≥ v7) does **not** run lifecycle scripts on `npm uninstall`, so removing the package does **not** clean up host discovery snapshots automatically. To remove them, run:

```bash
bf uninstall                              # before npm uninstall, while the CLI is still on $PATH
npm uninstall -g @codetreker/bf
```

`bf uninstall` auto-detects supported targets. Use `bf uninstall --target claude`, `bf uninstall --target codex`, or `bf uninstall --target copilot` for one target.

## Extending BF — `extensions/`

BF looks for additional roles and packs in host-neutral `extensions/` directories. Drop `.md` files in role dirs or full pack directories, and BF will pick them up automatically.

| Location | When to use |
|---|---|
| `~/.bf/extensions/roles/<name>.md` | A custom role you want available across every project |
| `~/.bf/extensions/packs/<id>/pack.md` | A custom pack available globally |
| `<primary-worktree>/.bf/extensions/roles/<name>.md` | A role only this project should see |
| `<primary-worktree>/.bf/extensions/packs/<id>/pack.md` | A pack only this project should see |

**Precedence (highest wins):** project extension → global extension → selected pack-private role → Core role. So a project-local `engineer.md` overrides anything else with that id.

Host discovery snapshots are generated copies. Do not put extensions under `~/.claude/skills/bf/`, `$CODEX_HOME/skills/bf/`, or `~/.copilot/skills/bf/`; BF does not read those locations.

`bf list-packs` shows each effective pack with every `pack.md` path in read order. `bf list-roles [--pack <id>]` and `bf list-pipelines [--pack <id>]` show the final effective role and pipeline registries.

## What you get

After install, two CLIs are on `$PATH`:

- `bf` — read-only metadata + install management: `bf list-packs`, `bf list-pipelines [--pack <id>]`, `bf list-roles [--pack <id>]`, `bf install`, `bf update`, `bf uninstall`, `bf version`
- `bf-harness` — work-object loop driver: `list`, `status`, `lint`, `start-review`, `accept`, `next`, `attach-pr`, `verify`, `complete`, `cleanup`, `discard`

Run either with `--help` for full usage.

## How it works (in 30 seconds)

```
brainstorm  →  spec  ──accept──▶  execute  ──verify──▶  complete  ──▶  Completed
                  ▲                    │
                  └──── lint / verify FAIL ───┘
```

1. **Brainstorm** — drive a discussion with the user, pick a pack, write `discussion.md`.
2. **Spec** — author `bf.md` + per-task `spec.md` in `Draft`, `lint`, run a Spec Review round, `verify`, then `accept`. Contract is locked.
3. **Execute** — `next` returns eligible task blocks in task-list order. Each returned task has completed prerequisites, and no returned task depends on another returned task. For `Requires-Worktree: true` tasks in managed Git mode, it also creates or validates each task branch/worktree and returns that metadata. A host-compatible task driver follows each returned task's pipeline instructions; a **different** reviewer actor grades the final task AC. GitHub worktree tasks can record a PR with `attach-pr`. After a task verifies, `complete` transitions it to `Completed` and, when it has a recorded PR, checks that the PR is merged before allowing completion. Once a task completes and, when it has a PR, that PR is merged, `cleanup` removes that task's harness-owned worktree and safely deletes its merged local task branch. Repeat. Before Final Acceptance, `status` reports the work-object state and task states so the coordinator does not inspect every task spec to decide readiness. Final Acceptance runs work-object `verify` then `complete`, which flips the bf.md AC and marks the work Completed.

## State layout

BF stores work-in-progress state under a state home:

- In a Git repository, BF uses the primary worktree `.bf` even when commands run from a linked worktree.
- Outside Git, BF uses `<cwd>/.bf`.
- For tests, set `BF_HOME` to an isolated directory. Do not use it as normal project configuration.
- New work objects live under `<state-home>/works/<bf-wo>/`.
- Legacy direct `<state-home>/<bf-wo>/` work objects remain readable; when both layouts contain the same id, `works/<bf-wo>` wins.
- Project extensions live under `<state-home>/extensions/`.

Add `.bf/` and `.worktrees/` to your `.gitignore` when using project-local BF state and task worktrees. BF leaves old worktree-local `.bf` state in place; it does not migrate, copy, archive, or clean it up.

```
<project-root>/
  .bf/
    extensions/
    works/
      <bf-wo>/
        bf.md
        discussion.md
        runs/reviews/round_N/
          result_<role>_<idx>.md
          verify-result.md
        <task-id>/
          spec.md
          runs/reviews/round_N/...
  .worktrees/
    works/
      <bf-wo>/
        <task-id>/
```

Each task spec declares `Requires-Worktree: true|false`. Worktree-required tasks
use harness-owned `Branch:`, `Worktree:`, and `Pull-Request:` fields; do not
edit those fields by hand. `bf-harness cleanup <bf-wo>/<task>` runs only after
that task reaches `State: Completed`; it removes only that task's harness-owned
worktree and uses safe local branch deletion, retaining anything Git cannot
delete safely.

## The Independent Verification rule

The harness cannot see actor identity (review filenames are role-level). IV is enforced **only by the coordinator** when dispatching reviewers:

- For any given task, the actor whose work is reviewed and any reviewer must be **different actor instances**.
- Same `role` on both sides is fine (e.g. an `engineer` task driver + a separate `engineer` reviewer).
- Same actor instance on both sides is a contract violation the harness will not catch.

## Where to read next

- `SKILL.md` — entry doc for the orchestrating LLM (high-level contract + IV red line).
- `references/brainstorm.md` — drive the discussion, pick a pack.
- `references/spec-authoring.md` — author specs, design any bf-wo local pipelines, lint, Spec Review, accept.
- `references/execution.md` — `next → do → review → verify` loop.
- `templates/` — frozen file shapes; copy these when authoring.
- `roles/`, `packs/` — Core roles and installed packs.

## License

MIT
