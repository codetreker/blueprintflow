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
  copy_fixture clean-wo "$BASE/works/clean-wo"
}

cleanup() { rm -rf "$REPO" "$BASE"; }

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
  touch -d "2026-05-19 10:00" "$dir/verify-result.md"
}

run_accept() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-accept.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdAccept({
        baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
      })));
    });
  ")
}

setup
seed_mode_a_success "$BASE/works/clean-wo"
sed -i.bak '/^- \[ \] AC-1|quality-assurance:/a - [ ] AC-2|quality-assurance: Added after the successful spec review' "$BASE/works/clean-wo/task-a/spec.md"
rm -f "$BASE/works/clean-wo/task-a/spec.md.bak"
touch -d "2026-05-19 11:00" "$BASE/works/clean-wo/task-a/spec.md"
run_accept
assert_json_field "$STDOUT" .ok false
grep -q "^State: Draft" "$BASE/works/clean-wo/bf.md" || fail "bf.md should remain Draft when contract changed after spec review"
grep -q "^State: Draft" "$BASE/works/clean-wo/task-a/spec.md" || fail "task-a should remain Draft when contract changed after spec review"
cleanup

pass
