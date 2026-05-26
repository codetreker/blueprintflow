#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

VALID=$(make_temp_home)
mkdir -p "$VALID/packs/engineering/pipelines"
cat > "$VALID/package.json" <<'JSON'
{"files":["packs/"]}
JSON
cat > "$VALID/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF
cat > "$VALID/packs/engineering/pipelines/feature.yml" <<'EOF'
id: feature
desc: Feature pipeline
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$VALID" 2>&1)
RC=$?
assert_eq "$RC" "0" "valid BF package layout"
assert_match "$OUT" "BF package layout is valid" "valid layout message"
rm -rf "$VALID"

BAD_NAME=$(make_temp_home)
mkdir -p "$BAD_NAME/packs/engineering/pipelines"
cat > "$BAD_NAME/package.json" <<'JSON'
{"files":["packs/"]}
JSON
cat > "$BAD_NAME/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF
cat > "$BAD_NAME/packs/engineering/pipelines/Feature.yaml" <<'EOF'
id: Feature
desc: Bad pipeline filename
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$BAD_NAME" 2>&1)
RC=$?
[ "$RC" != "0" ] || fail "invalid pipeline filename should fail"
assert_match "$OUT" "invalid pipeline filename" "invalid filename message"
rm -rf "$BAD_NAME"

EMPTY_DIR=$(make_temp_home)
mkdir -p "$EMPTY_DIR/packs/engineering/pipelines"
cat > "$EMPTY_DIR/package.json" <<'JSON'
{"files":["packs/"]}
JSON
cat > "$EMPTY_DIR/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$EMPTY_DIR" 2>&1)
RC=$?
[ "$RC" != "0" ] || fail "empty pipelines directory should fail"
assert_match "$OUT" "pipelines directory is empty" "empty pipelines message"
rm -rf "$EMPTY_DIR"

pass
