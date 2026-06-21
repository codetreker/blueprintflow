#!/usr/bin/env bash
# Mode B P0 resolver unit test (pure functions, no git side effects).
# Pins: woIntegrationMode default + fail-closed; resolveModeGit('per-task-pr')
# returns the SAME tuple as the legacy expectedTaskGit (Mode A byte-identical).
set -u
source "$(dirname "$0")/test-helpers.sh"

# --- woIntegrationMode -------------------------------------------------------

# absent Integration => per-task-pr (Mode A default)
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs').then(m => {
    process.stdout.write(m.woIntegrationMode({ frontmatter: {} }));
  });
")
assert_eq "$OUT" "per-task-pr" "absent Integration defaults to per-task-pr"

# explicit per-task-pr accepted
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs').then(m => {
    process.stdout.write(m.woIntegrationMode({ frontmatter: { Integration: 'per-task-pr' } }));
  });
")
assert_eq "$OUT" "per-task-pr" "explicit per-task-pr accepted"

# explicit single-pr accepted
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs').then(m => {
    process.stdout.write(m.woIntegrationMode({ frontmatter: { Integration: 'single-pr' } }));
  });
")
assert_eq "$OUT" "single-pr" "explicit single-pr accepted"

# invalid value throws (fail-closed)
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs').then(m => {
    try { m.woIntegrationMode({ frontmatter: { Integration: 'merge-train' } }); process.stdout.write('NO_THROW'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
")
assert_match "$OUT" "ERR:" "invalid Integration value throws"
assert_match "$OUT" "merge-train" "error names the offending value"

# --- resolveModeGit ----------------------------------------------------------

# per-task-pr tuple == legacy expectedTaskGit (byte-identical strings)
OUT=$(node --input-type=module -e "
  Promise.all([
    import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs'),
    import('$REPO_ROOT/bin/lib/harness/managed-git.mjs'),
  ]).then(([mode, git]) => {
    const resolver = mode.resolveModeGit('per-task-pr', '/primary', 'wo-1', 'task-a');
    const legacy = git.expectedTaskGit('/primary', 'wo-1', 'task-a');
    process.stdout.write(JSON.stringify({
      resolver,
      legacy,
      match: resolver.branch === legacy.branch && resolver.worktree === legacy.worktree,
    }));
  });
")
assert_json_field "$OUT" .resolver.branch "bf/wo-1/task-a"
assert_json_field "$OUT" .resolver.worktree "/primary/.worktrees/works/wo-1/task-a"
assert_json_field "$OUT" .legacy.branch "bf/wo-1/task-a"
assert_json_field "$OUT" .legacy.worktree "/primary/.worktrees/works/wo-1/task-a"
assert_json_field "$OUT" .match "true"

# single-pr tuple is WO-scoped with the _shared marker (defined, not yet wired)
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs').then(m => {
    process.stdout.write(JSON.stringify(m.resolveModeGit('single-pr', '/primary', 'wo-1', 'task-a')));
  });
")
assert_json_field "$OUT" .branch "bf/wo-1"
assert_json_field "$OUT" .worktree "/primary/.worktrees/works/wo-1/_shared"

# unknown mode throws (fail-closed)
OUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/integration-mode.mjs').then(m => {
    try { m.resolveModeGit('bogus', '/primary', 'wo-1', 'task-a'); process.stdout.write('NO_THROW'); }
    catch (e) { process.stdout.write('ERR:' + e.message); }
  });
")
assert_match "$OUT" "ERR:" "unknown mode throws"

pass
