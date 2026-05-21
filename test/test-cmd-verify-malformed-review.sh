#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

REPO=$(make_temp_home)
mkdir -p "$REPO/roles" "$REPO/packs"
cp -R "$FIXTURES/roles-core/." "$REPO/roles/"
cp -R "$FIXTURES/packs-engineering" "$REPO/packs/engineering"
BASE=$(make_temp_home)
mkdir -p "$BASE"
cp -R "$FIXTURES/clean-wo" "$BASE/wo-1"

# Create a result "file" that is actually a directory → fs.readFileSync throws EISDIR.
ROUND="$BASE/wo-1/runs/reviews/round_1"
mkdir -p "$ROUND/result_tester_1.md"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-verify.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdVerify({
      baseHome: '$BASE', woId: 'wo-1', repoRoot: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "malformed review result" "error message present"
# Must NOT have written a verify-result.md (early return)
[ ! -f "$ROUND/verify-result.md" ] || fail "verify-result.md should not be written on parse error"

rm -rf "$REPO" "$BASE"
pass
