#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/wo-paths.mjs').then(m => {
    const out = {
      project: m.projectHome('/tmp/bfh', 'my-proj'),
      wo: m.woDir('/tmp/bfh', 'my-proj', 'wo-1'),
      task: m.taskDir('/tmp/bfh', 'my-proj', 'wo-1', 'task-a'),
      runs: m.runsReviewsDir(m.woDir('/tmp/bfh', 'my-proj', 'wo-1')),
      round: m.roundDir(m.woDir('/tmp/bfh', 'my-proj', 'wo-1'), 3),
      result: m.resultFile(m.roundDir(m.woDir('/tmp/bfh','p','w'),1),'tester',2),
      verify: m.verifyResultFile(m.roundDir(m.woDir('/tmp/bfh','p','w'),1)),
    };
    process.stdout.write(JSON.stringify(out));
  });
")

assert_json_field "$STDOUT" .project "/tmp/bfh/projects/my-proj"
assert_json_field "$STDOUT" .wo "/tmp/bfh/projects/my-proj/wo-1"
assert_json_field "$STDOUT" .task "/tmp/bfh/projects/my-proj/wo-1/task-a"
assert_json_field "$STDOUT" .runs "/tmp/bfh/projects/my-proj/wo-1/runs/reviews"
assert_json_field "$STDOUT" .round "/tmp/bfh/projects/my-proj/wo-1/runs/reviews/round_3"
assert_json_field "$STDOUT" .result "/tmp/bfh/projects/p/w/runs/reviews/round_1/result_tester_2.md"
assert_json_field "$STDOUT" .verify "/tmp/bfh/projects/p/w/runs/reviews/round_1/verify-result.md"

pass
