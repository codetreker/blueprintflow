#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

TMP=$(make_temp_home)

# SUCCESS Mode A: 不应有 Issues section
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-verify-result.mjs').then(m => {
    m.writeVerifyResultMd({
      filePath: '$TMP/a.md', mode: 'A', scope: 'wo-1', round: 1, status: 'SUCCESS',
      timestamp: '2026-05-19 12:34',
    });
  });
"
grep -q "^Result: SUCCESS" "$TMP/a.md" || fail "Result SUCCESS"
grep -q "^Mode: A" "$TMP/a.md" || fail "Mode A"
if grep -q "## Issues" "$TMP/a.md"; then fail "SUCCESS should NOT have Issues section"; fi

# FAIL Mode A: 有 Issues, Blocker 段填了
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-verify-result.mjs').then(m => {
    m.writeVerifyResultMd({
      filePath: '$TMP/b.md', mode: 'A', scope: 'wo-1', round: 2, status: 'FAIL',
      timestamp: '2026-05-19 12:34',
      issues: { blocker: ['[tester#1] src.mjs:10 bad'], high: [] },
    });
  });
"
grep -q "## Issues" "$TMP/b.md" || fail "FAIL should have Issues"
grep -q "src.mjs:10 bad" "$TMP/b.md" || fail "blocker propagated"

# Mode B SUCCESS with signOff + flipped + state change
node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/write-verify-result.mjs').then(m => {
    m.writeVerifyResultMd({
      filePath: '$TMP/c.md', mode: 'B', scope: 'wo-1/task-a', round: 1, status: 'SUCCESS',
      timestamp: '2026-05-19 12:34',
      perAc: [{ id: 'AC-1', status: 'signed', reviewers: ['tester'], providers: ['tester'] }],
      flipped: ['AC-1'],
      stateChanges: ['task-a: Tasking -> Completed'],
    });
  });
"
grep -q "## AC Sign-off" "$TMP/c.md" || fail "Mode B sign-off"
grep -q "AC-1: signed" "$TMP/c.md" || fail "sign-off content"
grep -q "## Flipped" "$TMP/c.md" || fail "Flipped section"
grep -q "## State Changes" "$TMP/c.md" || fail "State Changes section"
if grep -q "## Issues" "$TMP/c.md"; then fail "SUCCESS should NOT have Issues section"; fi

rm -rf "$TMP"
pass
