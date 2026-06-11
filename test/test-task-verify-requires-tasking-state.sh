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
  sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/wo-1/bf.md"
  sed -i.bak 's/^State: Draft/State: Ready/' "$BASE/works/wo-1/task-a/spec.md" "$BASE/works/wo-1/task-b/spec.md"
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

run_verify_b() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
      process.stdout.write(JSON.stringify(await m.cmdVerify({
        baseHome: '$BASE', woId: 'wo-1', taskId: 'task-a', installDir: '$REPO',
      })));
    });
  ")
}

setup
write_signed_review "$BASE/works/wo-1/task-a/runs/reviews/round_1" tester 1 "AC-1"
run_verify_b
assert_json_field "$STDOUT" .ok false
grep -qE "^- \[ \] AC-1\|" "$BASE/works/wo-1/task-a/spec.md" || fail "Ready task AC should not flip before next claims it"
grep -q "^State: Ready" "$BASE/works/wo-1/task-a/spec.md" || fail "Ready task should stay Ready before next claims it"
cleanup

pass
