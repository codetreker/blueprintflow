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
  copy_fixture clean-wo "$BASE/works/wo-1"
  sed -i.bak 's/^State: Draft/State: Implementing/' "$BASE/works/wo-1/bf.md"
  for t in task-a task-b; do
    sed -i.bak 's/^State: Draft/State: Completed/' "$BASE/works/wo-1/$t/spec.md"
    sed -i.bak 's/^Updated: .*/Updated: 2026-05-19 10:00/' "$BASE/works/wo-1/$t/spec.md"
  done
  rm -f "$BASE/works/wo-1"/*.bak "$BASE/works/wo-1"/*/*.bak
}

cleanup() { rm -rf "$REPO" "$BASE"; }

write_signed_review() {
  local dir="$1" role="$2" idx="$3" ac_ids="$4"
  mkdir -p "$dir"
  {
    echo "# Desc"; echo
    echo "## Results"; echo
    echo "### Blocker"; echo "### High"; echo "### Minor"; echo "### Nit"; echo
    echo "## Accepted Criteria"; echo
    for id in $ac_ids; do echo "- $id: signed by $role"; done
  } > "$dir/result_${role}_${idx}.md"
}

run_verify_c() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
      })));
    });
  ")
}

setup
ROUND_DIR="$BASE/works/wo-1/runs/reviews/round_1"
write_signed_review "$ROUND_DIR" tester 1 "AC-1"
touch -d "2026-05-19 10:00:30" "$ROUND_DIR/result_tester_1.md"
run_verify_c
assert_json_field "$STDOUT" .status "SUCCESS"
grep -qE "^- \[x\] AC-1\|" "$BASE/works/wo-1/bf.md" || fail "bf-level AC should flip for a final review created after task completion"
grep -q "^State: Implementing" "$BASE/works/wo-1/bf.md" || fail "bf.md should remain Implementing after final verify"
cleanup

pass
