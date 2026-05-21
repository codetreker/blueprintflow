#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

TMP=$(make_temp_home)
mkdir -p "$TMP/scope/runs/reviews/round_1" "$TMP/scope/runs/reviews/round_3"
touch "$TMP/scope/runs/reviews/round_1/result_tester_1.md"
touch "$TMP/scope/runs/reviews/round_1/result_tester_2.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/verify-round.mjs').then(m => {
    const r = m.findLatestRound('$TMP/scope');
    const round1 = '$TMP/scope/runs/reviews/round_1';
    const files = m.listResultFiles(round1);
    const findings = m.collectFindings([
      { role: 'tester', idx: 1, parsed: { severities: { blocker: ['boom'], high: [] } } },
      { role: 'qa', idx: 1, parsed: { severities: { blocker: [], high: ['eek'] } } },
    ]);
    process.stdout.write(JSON.stringify({ round: r, files: files.length, findings }));
  });
")
assert_json_field "$STDOUT" .round "3"
assert_json_field "$STDOUT" .files "2"
assert_match "$STDOUT" "[tester#1] boom" "blocker labeled"
assert_match "$STDOUT" "[qa#1] eek" "high labeled"

# empty / nonexistent
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/verify-round.mjs').then(m => {
    process.stdout.write(JSON.stringify({
      round: m.findLatestRound('/nonexistent/path'),
      files: m.listResultFiles('/nonexistent/path').length,
    }));
  });
")
assert_json_field "$STDOUT" .round "0"
assert_json_field "$STDOUT" .files "0"

rm -rf "$TMP"
pass
