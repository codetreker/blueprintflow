#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

ROOT=$(make_temp_home)
mkdir -p "$ROOT/packs"
cp -R "$FIXTURES/packs-engineering" "$ROOT/packs/engineering"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-packs.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPacks({ cwd: '$ROOT' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .packs.0.id "engineering"
assert_json_field "$STDOUT" .packs.0.desc "软件工程类工作"

# 没 packs/ 目录
EMPTY=$(make_temp_home)
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-packs.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPacks({ cwd: '$EMPTY' })));
  });
")
assert_json_field "$STDOUT" .packs '[]'

rm -rf "$ROOT" "$EMPTY"
pass
