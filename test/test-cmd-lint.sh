#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

setup_repo() {
  REPO=$(make_temp_home)
  mkdir -p "$REPO/roles" "$REPO/packs"
  cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
  cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
}

setup_base() {
  BASE=$(make_temp_home)
  mkdir -p "$BASE/projects/p"
}

# Happy path
setup_repo; setup_base
cp -R "$FIXTURES/clean-wo" "$BASE/projects/p/clean-wo"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', projectSlug: 'p', woId: 'clean-wo', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
rm -rf "$REPO" "$BASE"

# missing capability
setup_repo; setup_base
cp -R "$FIXTURES/missing-capability-wo" "$BASE/projects/p/wo-1"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', projectSlug: 'p', woId: 'wo-1', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "CAPABILITY_UNKNOWN" "missing capability flagged"
assert_match "$STDOUT" "bogus-cap" "specific cap name in error"
rm -rf "$REPO" "$BASE"

# State != Draft → BAD_STATE
setup_repo; setup_base
cp -R "$FIXTURES/clean-wo" "$BASE/projects/p/clean-wo"
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/projects/p/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', projectSlug: 'p', woId: 'clean-wo', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "BAD_STATE" "state check"
rm -rf "$REPO" "$BASE"

# Pack 不存在
setup_repo; setup_base
cp -R "$FIXTURES/clean-wo" "$BASE/projects/p/clean-wo"
sed -i.bak 's/^Pack: engineering/Pack: nonexistent/' "$BASE/projects/p/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', projectSlug: 'p', woId: 'clean-wo', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PACK_NOT_FOUND" "pack check"
rm -rf "$REPO" "$BASE"

pass
