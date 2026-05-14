# Teamlead Notebook

Teamlead keeps a local coordination notebook for each real project. The notebook is durable across sessions and worktrees, but it is not a product-doc source of truth.

## Location

Use:

```bash
repo_root=$(git rev-parse --path-format=absolute --git-common-dir)
repo_root=${repo_root%/.git}
repo_dir=${repo_root#/}
mkdir -p "$HOME/.blueprint/$repo_dir"
$EDITOR "$HOME/.blueprint/$repo_dir/teamlead.md"
```

`<repo-dir>` mirrors the canonical local repo directory under `~/.blueprint/`: strip the leading `/` from the absolute repo root path and use the remaining path as nested directories. Example: `/workspace/blueprintflow` stores the notebook at `~/.blueprint/workspace/blueprintflow/teamlead.md`. Use the Git common directory so linked worktrees share the main project notebook instead of creating one notebook per temporary worktree path.

## Rules

- Do not read or update the notebook before a concrete objective or explicit ongoing-coordination request exists.
- Cron skills still honor their Direct Invocation Guard: if `using-plueprint` has not routed back with an active objective, stop before reading the notebook.
- At objective start, read `~/.blueprint/<repo-dir>/teamlead.md` before routing or dispatching work.
- If the notebook does not exist, create it from the Minimal Template below before proceeding.
- After every Teamlead dispatch, blocker decision, retraction, PR gate decision, merge, or pause/stop request, update the notebook in the same turn.
- Before each fast-cron, slow-cron, issue-triage, or role-reminder tick, read the notebook and reconcile it with live PR/issue/task state.
- Store coordination state only: role lanes, open blockers, active PRs/issues, recent decisions, retractions, and next checks.
- Do not store secrets, credentials, long logs, raw issue bodies, or large evidence dumps. Link to PRs, issues, commits, worktrees, or docs instead.
- Treat GitHub issues, PR bodies, `docs/tasks`, blueprints, and `docs/current` as the source of truth. The notebook is a Teamlead memory aid; if it conflicts with a source of truth, fix the notebook.

## Minimal Template

```markdown
# <project> Teamlead Notebook

Updated: YYYY-MM-DD HH:MM UTC

## Active Objective
- <milestone / issue / PR / Phase / audit objective>

## Role Lanes
| Role | Status | Current task | Blocker | Next check |
|---|---|---|---|---|
| Architect | idle / active / blocked / waiting | ... | ... | ... |
| PM | idle / active / blocked / waiting | ... | ... | ... |
| Dev | idle / active / blocked / waiting | ... | ... | ... |
| QA | idle / active / blocked / waiting | ... | ... | ... |
| Security | idle / active / blocked / waiting | ... | ... | ... |
| Designer | idle / active / blocked / waiting / N/A | ... | ... | ... |

## Open Blockers
- <blocker> -> owner, evidence link, next action

## PR / Issue Queue
- <PR/issue> -> state, missing acceptance/test-plan items, owner

## Decisions And Retractions
- YYYY-MM-DD HH:MM UTC: <decision/retraction> -> affected roles notified

## Next Teamlead Checks
- <time/cadence>: <what to verify>
```

Keep the file short enough to scan. Archive stale detail into dated sections only when it still explains current routing or blockers.
