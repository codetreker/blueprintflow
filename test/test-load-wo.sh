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
  cp -R "$FIXTURES/clean-wo" "$BASE/clean-wo"
}
cleanup() { rm -rf "$REPO" "$BASE"; }

# Happy: 全解析
setup
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO' });
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
rm "$BASE/clean-wo/task-b/spec.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO' });
    process.stdout.write(JSON.stringify(r.errors));
  });
")
assert_match "$STDOUT" "TASK_MISSING" "task missing surfaced"
cleanup

# bf.md 坏掉
setup
echo "not a real bf.md" > "$BASE/clean-wo/bf.md"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO' });
    process.stdout.write(JSON.stringify({ ok: r.ok, errors: r.errors }));
  });
")
assert_json_field "$STDOUT" .ok false
assert_match "$STDOUT" "PARSE_BF" "bf parse error"
cleanup

# Global extensions live under $HOME/.bf/extensions, not host discovery dirs.
setup
HOME_DIR=$(make_temp_home)
mkdir -p "$HOME_DIR/.bf/extensions/packs/engineering/roles"
cat > "$HOME_DIR/.bf/extensions/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Global extension engineering pack
---

## When to Use

Global extension engineering pack.
EOF
cat > "$HOME_DIR/.bf/extensions/packs/engineering/roles/pack-reviewer.md" <<'EOF'
---
Id: pack-reviewer
Desc: Pack-private reviewer from global extension pack
Capabilities:
  - pack-review
---

# Pack Reviewer
EOF
mkdir -p "$HOME_DIR/.bf/extensions/roles"
cat > "$HOME_DIR/.bf/extensions/roles/global-reviewer.md" <<'EOF'
---
Id: global-reviewer
Desc: Global extension reviewer
Capabilities:
  - global-review
---

# Global Reviewer
EOF
mkdir -p "$HOME_DIR/.claude/skills/bf/extensions/roles"
cat > "$HOME_DIR/.claude/skills/bf/extensions/roles/ignored-reviewer.md" <<'EOF'
---
Id: ignored-reviewer
Desc: Host discovery extension should be ignored
Capabilities:
  - ignored-review
---

# Ignored Reviewer
EOF
export HOME="$HOME_DIR"
STDOUT=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/harness/load-wo.mjs').then(async (m) => {
    const r = await m.loadWo({ baseHome: '$BASE', woId: 'clean-wo', installDir: '$REPO' });
    process.stdout.write(JSON.stringify({
      packDesc: r.packReg.packs.get('engineering')?.desc,
      roleIds: [...r.roleReg.roles.keys()].sort(),
    }));
  });
")
assert_json_field "$STDOUT" .packDesc "Global extension engineering pack"
assert_match "$STDOUT" "global-reviewer" "global extension role should be registered"
assert_match "$STDOUT" "pack-reviewer" "global extension pack private role should be registered"
assert_not_match "$STDOUT" "ignored-reviewer" "host discovery extensions must not be read"
unset HOME
rm -rf "$HOME_DIR"
cleanup

pass
