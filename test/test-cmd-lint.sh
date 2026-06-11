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
  mkdir -p "$BASE"
}

# Happy path
setup_repo; setup_base
copy_fixture clean-wo "$BASE/works/clean-wo"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok true
rm -rf "$REPO" "$BASE"

# missing capability
setup_repo; setup_base
copy_fixture missing-capability-wo "$BASE/works/wo-1"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', woId: 'wo-1', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "CAPABILITY_UNKNOWN" "missing capability flagged"
assert_match "$STDOUT" "bogus-cap" "specific cap name in error"
rm -rf "$REPO" "$BASE"

# State != Draft → BAD_STATE
setup_repo; setup_base
copy_fixture clean-wo "$BASE/works/clean-wo"
sed -i.bak 's/^State: Draft/State: Accepted/' "$BASE/works/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "BAD_STATE" "state check"
rm -rf "$REPO" "$BASE"

# Pack 不存在
setup_repo; setup_base
copy_fixture clean-wo "$BASE/works/clean-wo"
sed -i.bak 's/^Pack: engineering/Pack: nonexistent/' "$BASE/works/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-lint.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdLint({
      baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO',
    })));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PACK_NOT_FOUND" "pack check"
rm -rf "$REPO" "$BASE"

# OUT-4: CLI text output — `bf-harness lint` leads stdout with SUCCESS or FAIL.
setup_repo; setup_base
copy_fixture clean-wo "$BASE/works/clean-wo"
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh lint "clean-wo"
assert_eq "$RC" "0" "lint clean-wo exit 0"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "SUCCESS" "lint stdout line 1 is SUCCESS"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in lint SUCCESS stdout"
rm -rf "$REPO" "$BASE"

setup_repo; setup_base
copy_fixture missing-capability-wo "$BASE/works/wo-1"
export BF_HOME="$BASE"
export BF_INSTALL_DIR="$REPO"
run_bfh lint "wo-1"
assert_eq "$RC" "1" "lint bad wo exit 1"
FIRST_LINE=$(printf "%s\n" "$STDOUT" | head -1)
assert_eq "$FIRST_LINE" "FAIL" "lint stdout line 1 is FAIL"
assert_match "$STDOUT" "CAPABILITY_UNKNOWN" "lint stdout contains error code"
printf "%s\n" "$STDOUT" | grep -E ' +$' >/dev/null && fail "trailing whitespace in lint FAIL stdout"
unset BF_HOME BF_INSTALL_DIR
rm -rf "$REPO" "$BASE"

pass
