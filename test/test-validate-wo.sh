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
}
cleanup() { rm -rf "$REPO" "$BASE"; }

run_validate() {
  STDOUT=$(node --input-type=module -e "
    Promise.all([
      import('$REPO_ROOT/bin/lib/harness/load-wo.mjs'),
      import('$REPO_ROOT/bin/lib/harness/validate-wo.mjs'),
    ]).then(async ([l, v]) => {
      const bundle = await l.loadWo({ baseHome: '$BASE', woId: process.argv[1], repoRoot: '$REPO' });
      process.stdout.write(JSON.stringify(v.validateWo(bundle)));
    });
  " "$1")
}

setup; cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"
run_validate clean-wo
assert_json_field "$STDOUT" .ok true
cleanup

setup; cp -R "$FIXTURES/missing-capability-wo" "$BASE/missing-cap-wo"
run_validate missing-cap-wo
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "CAPABILITY_UNKNOWN" "missing cap"
cleanup

# dep cycle: 把 task-a 改成依赖 task-b（task-b 已经依赖 task-a）
setup; cp -R "$FIXTURES/clean-wo" "$BASE/cycle-wo"
sed -i.bak 's/^- task-a$/- task-a: task-b/' "$BASE/cycle-wo/bf.md"
run_validate cycle-wo
assert_match "$STDOUT" "DEP_CYCLE" "cycle detected"
cleanup

pass
