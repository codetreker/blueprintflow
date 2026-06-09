#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

make_wo() {
  local dest="$1" id="$2" desc="$3"
  mkdir -p "$dest"
  cp -R "$FIXTURES/clean-wo/." "$dest/"
  node -e "
    const fs=require('fs');
    const p=process.argv[1];
    const id=process.argv[2];
    const desc=process.argv[3];
    let s=fs.readFileSync(p,'utf8');
    s=s.replace(/^Id: .*\$/m, 'Id: ' + id);
    s=s.replace(/^Desc: .*\$/m, 'Desc: ' + desc);
    fs.writeFileSync(p, s);
  " "$dest/bf.md" "$id" "$desc"
}

assert_list_has_once() {
  local output="$1" id="$2" msg="$3"
  local count
  count=$(printf "%s\n" "$output" | grep -cE "^Id: ${id}$" || true)
  assert_eq "$count" "1" "$msg"
}

# Module-level namespace behavior: new work objects live under works/, legacy
# direct work objects remain readable, duplicate ids prefer works/, and reserved
# directories are not treated as work objects.
BASE=$(make_temp_home)
mkdir -p "$BASE/works" "$BASE/extensions"
make_wo "$BASE/works/clean-wo" "clean-wo" "works clean"
make_wo "$BASE/legacy-wo" "legacy-wo" "legacy direct"
make_wo "$BASE/works/dupe-wo" "dupe-wo" "works wins"
make_wo "$BASE/dupe-wo" "dupe-wo" "legacy loses"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO_ROOT' });
    process.stdout.write(JSON.stringify({
      ok: r.ok,
      woPath: r.woPath,
      desc: r.bf?.frontmatter?.Desc,
    }));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .woPath "$BASE/works/clean-wo"
assert_json_field "$STDOUT" .desc "works clean"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'legacy-wo', installDir: '$REPO_ROOT' });
    process.stdout.write(JSON.stringify({
      ok: r.ok,
      woPath: r.woPath,
      desc: r.bf?.frontmatter?.Desc,
    }));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .woPath "$BASE/legacy-wo"
assert_json_field "$STDOUT" .desc "legacy direct"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'dupe-wo', installDir: '$REPO_ROOT' });
    process.stdout.write(JSON.stringify({
      ok: r.ok,
      woPath: r.woPath,
      desc: r.bf?.frontmatter?.Desc,
    }));
  });
")
assert_json_field "$STDOUT" .ok true
assert_json_field "$STDOUT" .woPath "$BASE/works/dupe-wo"
assert_json_field "$STDOUT" .desc "works wins"

STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/cmd-list.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdList({ baseHome: '$BASE' })));
  });
")
assert_json_field "$STDOUT" .ok true
assert_match "$STDOUT" "clean-wo" "works object listed"
assert_match "$STDOUT" "legacy-wo" "legacy direct object listed"
DUPE_COUNT=$(node -e "
  const j=JSON.parse(process.argv[1]);
  process.stdout.write(String(j.woList.filter(w => w.id === 'dupe-wo').length));
" "$STDOUT")
assert_eq "$DUPE_COUNT" "1" "duplicate id appears once"
DUPE_DESC=$(node -e "
  const j=JSON.parse(process.argv[1]);
  process.stdout.write(j.woList.find(w => w.id === 'dupe-wo')?.desc || '');
" "$STDOUT")
assert_eq "$DUPE_DESC" "works wins" "works namespace wins duplicate id"
assert_not_match "$STDOUT" "skip works" "works namespace is reserved"
assert_not_match "$STDOUT" "skip extensions" "extensions namespace is reserved"
rm -rf "$BASE"

# CLI default from a linked worktree uses the primary worktree .bf, not the
# disposable linked worktree .bf.
PRIMARY=$(make_temp_home)
LINKED=$(make_temp_home)
rm -rf "$LINKED"
git -C "$PRIMARY" init -b main >/dev/null 2>&1 || fail "git init failed"
git -C "$PRIMARY" config user.email "bf-test@example.com"
git -C "$PRIMARY" config user.name "BF Test"
printf "root\n" > "$PRIMARY/README.md"
git -C "$PRIMARY" add README.md >/dev/null 2>&1
git -C "$PRIMARY" commit -m init >/dev/null 2>&1 || fail "git commit failed"
git -C "$PRIMARY" worktree add "$LINKED" -b feature >/dev/null 2>&1 || fail "git worktree add failed"
mkdir -p "$PRIMARY/.bf/works" "$PRIMARY/.bf/extensions/packs/project-pack"
make_wo "$PRIMARY/.bf/works/primary-wo" "primary-wo" "primary state"
write_pack_md "$PRIMARY/.bf/extensions/packs/project-pack/pack.md" "project-pack" "project pack"

STDOUT=$(cd "$LINKED" && env -u BF_HOME node "$BFH" list)
assert_list_has_once "$STDOUT" "primary-wo" "linked worktree list reads primary .bf/works"
assert_not_match "$STDOUT" "skip works" "linked worktree list does not warn on works"

STDOUT=$(cd "$LINKED" && env -u BF_HOME node "$BFH" start-review primary-wo)
assert_match "$STDOUT" "$PRIMARY/.bf/works/primary-wo/runs/reviews/round_1" "linked worktree mutating command writes primary .bf/works"
[ -d "$PRIMARY/.bf/works/primary-wo/runs/reviews/round_1" ] || fail "review round missing under primary .bf/works"
[ ! -e "$LINKED/.bf" ] || fail "linked worktree .bf should not be created by mutating command"

HOME_DIR=$(make_temp_home)
STDOUT=$(cd "$LINKED" && env -u BF_HOME HOME="$HOME_DIR" node "$BF" list-packs)
assert_match "$STDOUT" "Id: project-pack" "bf metadata commands read primary .bf/extensions"
rm -rf "$HOME_DIR"

# Explicit BF_HOME still wins over Git primary detection.
OVERRIDE=$(make_temp_home)
mkdir -p "$OVERRIDE/works" "$OVERRIDE/extensions/packs/override-pack"
make_wo "$OVERRIDE/works/override-wo" "override-wo" "override state"
write_pack_md "$OVERRIDE/extensions/packs/override-pack/pack.md" "override-pack" "override pack"
STDOUT=$(cd "$LINKED" && BF_HOME="$OVERRIDE" node "$BFH" list)
assert_list_has_once "$STDOUT" "override-wo" "explicit BF_HOME list wins"
assert_not_match "$STDOUT" "primary-wo" "explicit BF_HOME hides primary state"
HOME_DIR=$(make_temp_home)
STDOUT=$(cd "$LINKED" && BF_HOME="$OVERRIDE" HOME="$HOME_DIR" node "$BF" list-packs)
assert_match "$STDOUT" "Id: override-pack" "explicit BF_HOME extensions win"
assert_not_match "$STDOUT" "Id: project-pack" "explicit BF_HOME hides primary extensions"
rm -rf "$HOME_DIR" "$OVERRIDE"

git -C "$PRIMARY" worktree remove "$LINKED" --force >/dev/null 2>&1 || true
rm -rf "$PRIMARY" "$LINKED"

# Non-Git fallback remains <cwd>/.bf with works/ beneath it.
NON_GIT=$(make_temp_home)
mkdir -p "$NON_GIT/.bf/works"
make_wo "$NON_GIT/.bf/works/non-git-wo" "non-git-wo" "non git state"
STDOUT=$(cd "$NON_GIT" && env -u BF_HOME node "$BFH" list)
assert_list_has_once "$STDOUT" "non-git-wo" "non-Git cwd fallback uses .bf/works"
rm -rf "$NON_GIT"

pass
