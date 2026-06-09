#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/wo-paths.mjs').then(m => {
    const out = {
      wo: m.woDir('/tmp/bfh', 'wo-1'),
      task: m.taskDir('/tmp/bfh', 'wo-1', 'task-a'),
      runs: m.runsReviewsDir(m.woDir('/tmp/bfh', 'wo-1')),
      round: m.roundDir(m.woDir('/tmp/bfh', 'wo-1'), 3),
      result: m.resultFile(m.roundDir(m.woDir('/tmp/bfh','w'),1),'tester',2),
      verify: m.verifyResultFile(m.roundDir(m.woDir('/tmp/bfh','w'),1)),
    };
    process.stdout.write(JSON.stringify(out));
  });
")

assert_json_field "$STDOUT" .wo "/tmp/bfh/works/wo-1"
assert_json_field "$STDOUT" .task "/tmp/bfh/works/wo-1/task-a"
assert_json_field "$STDOUT" .runs "/tmp/bfh/works/wo-1/runs/reviews"
assert_json_field "$STDOUT" .round "/tmp/bfh/works/wo-1/runs/reviews/round_3"
assert_json_field "$STDOUT" .result "/tmp/bfh/works/w/runs/reviews/round_1/result_tester_2.md"
assert_json_field "$STDOUT" .verify "/tmp/bfh/works/w/runs/reviews/round_1/verify-result.md"

pass
