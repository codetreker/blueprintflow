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
Mode: A
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
      baseHome: '$BASE', woId: 'clean-wo', repoRoot: '$REPO',
      now: new Date(2026, 4, 19, 12, 34),
    })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .transitioned.bf "Draft->Accepted"
grep -q "^State: Accepted" "$BASE/clean-wo/bf.md" || fail "bf.md state not flipped"
grep -q "^State: Ready" "$BASE/clean-wo/task-a/spec.md" || fail "task-a state not flipped"
grep -q "^State: Ready" "$BASE/clean-wo/task-b/spec.md" || fail "task-b state not flipped"
grep -q "^Updated: 2026-05-19 12:34" "$BASE/clean-wo/bf.md" || fail "bf.md Updated not set"
cleanup

setup
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "no Mode A SUCCESS" "Mode A gate"
grep -q "^State: Draft" "$BASE/clean-wo/bf.md" || fail "bf.md unexpectedly modified"
cleanup

setup
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdAccept({
      baseHome: '$BASE', woId: 'clean-wo', repoRoot: '$REPO',
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
      baseHome: '$BASE', woId: 'clean-wo', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "lint failed" "lint gate"
grep -q "^State: Draft" "$BASE/clean-wo/bf.md" || fail "bf.md unexpectedly modified"
cleanup

pass
