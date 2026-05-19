#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/state-machine.mjs').then(m => {
    process.stdout.write(JSON.stringify({
      bfHappy:    m.canTransition('bf', 'Draft', 'Accepted'),
      bfSkip:     m.canTransition('bf', 'Draft', 'Implementing'),
      bfBack:     m.canTransition('bf', 'Accepted', 'Draft'),
      taskHappy:  m.canTransition('taskSpec', 'Ready', 'Tasking'),
      taskRetry:  m.canTransition('taskSpec', 'Tasking', 'Tasking'),
      unknownK:   m.canTransition('blah', 'Draft', 'Accepted'),
    }));
  });
")
assert_json_field "$STDOUT" .bfHappy true
assert_json_field "$STDOUT" .bfSkip false
assert_json_field "$STDOUT" .bfBack false
assert_json_field "$STDOUT" .taskHappy true
assert_json_field "$STDOUT" .taskRetry false
assert_json_field "$STDOUT" .unknownK false

pass
