#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE"
  cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"
}

seed_mode_a_success() {
  local wo="$1"
  local dir="$wo/runs/reviews/round_1"
  mkdir -p "$dir"
  cat > "$dir/verify-result.md" <<'EOF'
---
Result: SUCCESS
Mode: Spec Review
Scope: clean-wo
Round: 1
Timestamp: 2026-05-19 10:00
---
EOF
}

cleanup() { rm -rf "$REPO" "$BASE"; }

setup
seed_mode_a_success "$BASE/clean-wo"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
      now: new Date(2026, 4, 19, 12, 34),
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .transitioned.bf.from "Draft"
assert_json_field "$STDOUT" .transitioned.bf.to "Accepted"
assert_json_field "$STDOUT" .transitioned.tasks.task-a.from "Draft"
assert_json_field "$STDOUT" .transitioned.tasks.task-a.to "Ready"
grep -q "^State: Accepted" "$BASE/clean-wo/bf.md" || fail "bf.md state not flipped"
grep -q "^State: Ready" "$BASE/clean-wo/task-a/spec.md" || fail "task-a state not flipped"
grep -q "^State: Ready" "$BASE/clean-wo/task-b/spec.md" || fail "task-b state not flipped"
grep -q "^Updated: 2026-05-19 12:34" "$BASE/clean-wo/bf.md" || fail "bf.md Updated not set"
cleanup

setup
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "no Spec Review SUCCESS" "Spec Review gate"
grep -q "^State: Draft" "$BASE/clean-wo/bf.md" || fail "bf.md unexpectedly modified"
cleanup

setup
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "already accepted" "double accept rejected"
cleanup

setup
seed_mode_a_success "$BASE/clean-wo"
sed -i.bak 's/^Pack: engineering/Pack: nope/' "$BASE/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "lint failed" "lint gate"
grep -q "^State: Draft" "$BASE/clean-wo/bf.md" || fail "bf.md unexpectedly modified"
cleanup

# CLI-level text output (OUT-4 + OUT-3 audit): bf-harness accept emits SUCCESS
# on stdout line 1, with transition lines and an Updated: line. No trailing
# whitespace on any line.
setup
seed_mode_a_success "$BASE/clean-wo"
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh accept "clean-wo"
assert_eq "$RC" "0" "accept clean-wo exit 0"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "SUCCESS" "accept stdout line 1 is SUCCESS"
assert_match "$STDOUT" "bf.md: Draft -> Accepted" "bf transition line"
assert_match "$STDOUT" "task-a: Draft -> Ready" "task-a transition line"
assert_match "$STDOUT" "task-b: Draft -> Ready" "task-b transition line"
[ "$(printf "%s\n" "$STDOUT" | grep -c '^Updated: ')" = "1" ] || fail "expected exactly one Updated: line"
# No line ends in whitespace.
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in accept stdout"
unset BF_HOME BF_INSTALL_DIR
cleanup

# CLI-level failure path: leads with FAIL, body on stdout, exit 1.
setup
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh accept "clean-wo"
assert_eq "$RC" "1" "accept without Spec Review exit 1"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "FAIL" "accept stdout line 1 is FAIL"
assert_match "$STDOUT" "no Spec Review SUCCESS" "accept FAIL body has error"
# FAIL body shape: line 1 "FAIL", line 2 blank, line 3 top-level reason.
SECOND_LINE=$(printf "%s\n" "$STDOUT" | sed -n 2p)
assert_eq "$SECOND_LINE" "" "accept FAIL line 2 is blank (lint-style)"
unset BF_HOME BF_INSTALL_DIR
cleanup

# CLI-level FAIL with details: the lint-gate path produces `r.details` from
# validateWo errors. Round 2 dropped them; round 3 renders them with the
# same `<code> at <ref>` / indented-message shape as format-lint.
setup
seed_mode_a_success "$BASE/clean-wo"
sed -i.bak 's/^Pack: engineering/Pack: nope/' "$BASE/clean-wo/bf.md"
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh accept "clean-wo"
assert_eq "$RC" "1" "accept lint-gate exit 1"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "FAIL" "accept stdout line 1 is FAIL"
assert_match "$STDOUT" "lint failed" "accept FAIL top-level reason"
assert_match "$STDOUT" "PACK_NOT_FOUND" "accept FAIL details include error code"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in accept FAIL stdout"
unset BF_HOME BF_INSTALL_DIR
cleanup

# accept stale gate includes referenced local pipeline files
setup
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/clean-wo/task-a/spec.md"
write_local_pipeline "$BASE/clean-wo/pipelines/api-migration.yml" "api-migration"
seed_mode_a_success "$BASE/clean-wo"
sleep 1
echo "# changed after review" >> "$BASE/clean-wo/pipelines/api-migration.yml"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "CONTRACT_CHANGED_AFTER_REVIEW" "changed local pipeline is stale contract"
assert_match "$STDOUT" "pipelines/api-migration.yml" "changed local pipeline path reported"
cleanup

# deleted referenced local pipeline blocks accept
setup
sed -i.bak 's/^Pipeline: feature/Pipeline: api-migration/' "$BASE/clean-wo/task-a/spec.md"
write_local_pipeline "$BASE/clean-wo/pipelines/api-migration.yml" "api-migration"
seed_mode_a_success "$BASE/clean-wo"
rm "$BASE/clean-wo/pipelines/api-migration.yml"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PIPELINE_NOT_FOUND" "deleted local pipeline blocks accept via lint"
cleanup

pass
