#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

run_case() {
  STDOUT=$(node --input-type=module -e "$1")
}

# Case A
run_case "
  import('$REPO_ROOT/bin/lib/compute-ac-signoff.mjs').then(m => {
    const roleReg = { byCapability: new Map([['backend-impl-review', [{id:'tester'}]]]) };
    const r = m.computeAcSignoff({
      acList: [{ id: 'AC-1', capability: 'backend-impl-review', checked: false }],
      reviewResults: [{ role: 'tester', idx: 1, parsed: { acceptedIds: ['AC-1'] } }],
      roleReg,
    });
    process.stdout.write(JSON.stringify(r));
  });
"
assert_json_field "$STDOUT" .perAc.0.status "signed"
assert_json_field "$STDOUT" .flipped '["AC-1"]'

# Case B
run_case "
  import('$REPO_ROOT/bin/lib/compute-ac-signoff.mjs').then(m => {
    const roleReg = { byCapability: new Map([['backend-impl-review', [{id:'tester'},{id:'qa-engineer'}]]]) };
    const r = m.computeAcSignoff({
      acList: [{ id: 'AC-1', capability: 'backend-impl-review', checked: false }],
      reviewResults: [{ role: 'tester', idx: 1, parsed: { acceptedIds: ['AC-1'] } }],
      roleReg,
    });
    process.stdout.write(JSON.stringify(r));
  });
"
assert_json_field "$STDOUT" .perAc.0.status "signed"
assert_json_field "$STDOUT" .perAc.0.reviewers '["tester"]'
assert_json_field "$STDOUT" .missing '[]'

# Case C
run_case "
  import('$REPO_ROOT/bin/lib/compute-ac-signoff.mjs').then(m => {
    const roleReg = { byCapability: new Map([['backend-impl-review', [{id:'tester'},{id:'qa-engineer'}]]]) };
    const r = m.computeAcSignoff({
      acList: [{ id: 'AC-1', capability: 'backend-impl-review', checked: false }],
      reviewResults: [{ role: 'tester', idx: 1, parsed: { acceptedIds: [] } }],
      roleReg,
    });
    process.stdout.write(JSON.stringify(r));
  });
"
assert_json_field "$STDOUT" .perAc.0.status "missing"
assert_match "$STDOUT" "no provider signed" "missing message"

# Case D
run_case "
  import('$REPO_ROOT/bin/lib/compute-ac-signoff.mjs').then(m => {
    const roleReg = { byCapability: new Map() };
    const r = m.computeAcSignoff({
      acList: [{ id: 'AC-1', capability: 'nobody-has-this', checked: false }],
      reviewResults: [],
      roleReg,
    });
    process.stdout.write(JSON.stringify(r));
  });
"
assert_match "$STDOUT" "no role provides" "missing provider message"

# Case E
run_case "
  import('$REPO_ROOT/bin/lib/compute-ac-signoff.mjs').then(m => {
    const roleReg = { byCapability: new Map([['backend-impl-review', [{id:'tester'}]]]) };
    const r = m.computeAcSignoff({
      acList: [{ id: 'AC-1', capability: 'backend-impl-review', checked: true }],
      reviewResults: [{ role: 'tester', idx: 1, parsed: { acceptedIds: ['AC-1'] } }],
      roleReg,
    });
    process.stdout.write(JSON.stringify(r));
  });
"
assert_json_field "$STDOUT" .perAc.0.status "signed"
assert_json_field "$STDOUT" .flipped '[]'

pass
