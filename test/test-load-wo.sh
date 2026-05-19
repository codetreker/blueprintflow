#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
  BASE=$(make_temp_home)
  mkdir -p "$BASE/projects/p"
  cp -R "$FIXTURES/clean-wo" "$BASE/projects/p/clean-wo"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

# Happy: 全解析
setup
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', projectSlug: 'p', woId: 'clean-wo', repoRoot: '$REPO' });
    process.stdout.write(JSON.stringify({
      ok: r.ok,
      bfId: r.bf.frontmatter.Id,
      taskIds: r.tasks.map(t=>t.id),
      hasSpecs: r.tasks.every(t => !!t.spec),
      packIds: [...r.packReg.packs.keys()],
      roleIds: [...r.roleReg.roles.keys()].sort(),
    }));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .bfId "clean-wo"
assert_json_field "$STDOUT" .taskIds '["task-a","task-b"]'
assert_json_field "$STDOUT" .hasSpecs true
assert_match "$STDOUT" "engineering" "pack registered"
cleanup

# Task spec 缺失
setup
rm "$BASE/projects/p/clean-wo/task-b/spec.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', projectSlug: 'p', woId: 'clean-wo', repoRoot: '$REPO' });
    process.stdout.write(JSON.stringify(r.errors));
  });
")
assert_match "$STDOUT" "TASK_MISSING" "task missing surfaced"
cleanup

# bf.md 坏掉
setup
echo "not a real bf.md" > "$BASE/projects/p/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', projectSlug: 'p', woId: 'clean-wo', repoRoot: '$REPO' });
    process.stdout.write(JSON.stringify({ ok: r.ok, errors: r.errors }));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PARSE_BF" "bf parse error"
cleanup

pass
