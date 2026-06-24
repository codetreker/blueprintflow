#!/usr/bin/env bash
# Mode B: cmd-next formatNext emits the `Integration:` mode on every task block,
# so a task driver knows the integration mode from the block alone without
# reading bf.md frontmatter (closes the "driver can't tell it's single-pr" gap).
set -u
source "$(dirname "$0")/test-helpers.sh"

run_format() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-next.mjs').then((m) => {
      const block = m.formatNext({ ok: true, tasks: [{
        taskId: 't', pipeline: 'feature', pipelinePath: '/p', pack: 'engineering',
        specPath: '/s', taskDir: '/d', integration: process.argv[1],
      }] });
      process.stdout.write(block);
    });
  " "$1")
}

run_format single-pr
assert_match "$STDOUT" "Integration: single-pr" "formatNext emits the single-pr Integration line"

run_format per-task-pr
assert_match "$STDOUT" "Integration: per-task-pr" "formatNext emits the per-task-pr Integration line"

pass
