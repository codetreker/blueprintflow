#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

VALID=$(make_temp_home)
mkdir -p "$VALID/packs/engineering/pipelines"
mkdir -p "$VALID/bin" "$VALID/scripts" "$VALID/roles" "$VALID/templates" "$VALID/references"
cat > "$VALID/package.json" <<'JSON'
{"files":["bin/","scripts/","SKILL.md","roles/","packs/","templates/","references/"]}
JSON
touch "$VALID/SKILL.md"
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
mkdir -p "$BAD_NAME/bin" "$BAD_NAME/scripts" "$BAD_NAME/roles" "$BAD_NAME/templates" "$BAD_NAME/references"
cat > "$BAD_NAME/package.json" <<'JSON'
{"files":["bin/","scripts/","SKILL.md","roles/","packs/","templates/","references/"]}
JSON
touch "$BAD_NAME/SKILL.md"
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
mkdir -p "$EMPTY_DIR/bin" "$EMPTY_DIR/scripts" "$EMPTY_DIR/roles" "$EMPTY_DIR/templates" "$EMPTY_DIR/references"
cat > "$EMPTY_DIR/package.json" <<'JSON'
{"files":["bin/","scripts/","SKILL.md","roles/","packs/","templates/","references/"]}
JSON
touch "$EMPTY_DIR/SKILL.md"
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

MISSING_RUNTIME=$(make_temp_home)
mkdir -p "$MISSING_RUNTIME/packs/engineering/pipelines"
cat > "$MISSING_RUNTIME/package.json" <<'JSON'
{"files":["packs/"]}
JSON
cat > "$MISSING_RUNTIME/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF
cat > "$MISSING_RUNTIME/packs/engineering/pipelines/feature.yml" <<'EOF'
id: feature
desc: Feature pipeline
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$MISSING_RUNTIME" 2>&1)
RC=$?
[ "$RC" != "0" ] || fail "missing runtime files surface should fail"
assert_match "$OUT" "files must include" "missing runtime files message"
rm -rf "$MISSING_RUNTIME"

DOCS_INCLUDED=$(make_temp_home)
mkdir -p "$DOCS_INCLUDED/bin" "$DOCS_INCLUDED/scripts" "$DOCS_INCLUDED/roles" "$DOCS_INCLUDED/templates" "$DOCS_INCLUDED/references"
mkdir -p "$DOCS_INCLUDED/packs/engineering/pipelines" "$DOCS_INCLUDED/docs"
touch "$DOCS_INCLUDED/SKILL.md"
cat > "$DOCS_INCLUDED/package.json" <<'JSON'
{"files":["bin/","scripts/","SKILL.md","roles/","packs/","templates/","references/","docs/"]}
JSON
cat > "$DOCS_INCLUDED/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF
cat > "$DOCS_INCLUDED/packs/engineering/pipelines/feature.yml" <<'EOF'
id: feature
desc: Feature pipeline
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$DOCS_INCLUDED" 2>&1)
RC=$?
[ "$RC" != "0" ] || fail "docs in package files should fail"
assert_match "$OUT" "must not include docs/" "docs exclusion message"
rm -rf "$DOCS_INCLUDED"

DOCS_FILE_INCLUDED=$(make_temp_home)
mkdir -p "$DOCS_FILE_INCLUDED/bin" "$DOCS_FILE_INCLUDED/scripts" "$DOCS_FILE_INCLUDED/roles" "$DOCS_FILE_INCLUDED/templates" "$DOCS_FILE_INCLUDED/references"
mkdir -p "$DOCS_FILE_INCLUDED/packs/engineering/pipelines" "$DOCS_FILE_INCLUDED/docs"
touch "$DOCS_FILE_INCLUDED/SKILL.md" "$DOCS_FILE_INCLUDED/docs/spec.md"
cat > "$DOCS_FILE_INCLUDED/package.json" <<'JSON'
{"files":["bin/","scripts/","SKILL.md","roles/","packs/","templates/","references/","docs/spec.md"]}
JSON
cat > "$DOCS_FILE_INCLUDED/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF
cat > "$DOCS_FILE_INCLUDED/packs/engineering/pipelines/feature.yml" <<'EOF'
id: feature
desc: Feature pipeline
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$DOCS_FILE_INCLUDED" 2>&1)
RC=$?
[ "$RC" != "0" ] || fail "docs file in package files should fail"
assert_match "$OUT" "must not include docs/" "docs file exclusion message"
rm -rf "$DOCS_FILE_INCLUDED"

DOT_DOCS_FILE_INCLUDED=$(make_temp_home)
mkdir -p "$DOT_DOCS_FILE_INCLUDED/bin" "$DOT_DOCS_FILE_INCLUDED/scripts" "$DOT_DOCS_FILE_INCLUDED/roles" "$DOT_DOCS_FILE_INCLUDED/templates" "$DOT_DOCS_FILE_INCLUDED/references"
mkdir -p "$DOT_DOCS_FILE_INCLUDED/packs/engineering/pipelines" "$DOT_DOCS_FILE_INCLUDED/docs"
touch "$DOT_DOCS_FILE_INCLUDED/SKILL.md" "$DOT_DOCS_FILE_INCLUDED/docs/spec.md"
cat > "$DOT_DOCS_FILE_INCLUDED/package.json" <<'JSON'
{"files":["bin/","scripts/","SKILL.md","roles/","packs/","templates/","references/","./docs/spec.md"]}
JSON
cat > "$DOT_DOCS_FILE_INCLUDED/packs/engineering/pack.md" <<'EOF'
---
Id: engineering
Desc: Engineering
---

## When to Use

Engineering work.
EOF
cat > "$DOT_DOCS_FILE_INCLUDED/packs/engineering/pipelines/feature.yml" <<'EOF'
id: feature
desc: Feature pipeline
EOF

OUT=$("$REPO_ROOT/.github/scripts/validate-bf-package-layout.sh" "$DOT_DOCS_FILE_INCLUDED" 2>&1)
RC=$?
[ "$RC" != "0" ] || fail "./docs file in package files should fail"
assert_match "$OUT" "must not include docs/" "./docs file exclusion message"
rm -rf "$DOT_DOCS_FILE_INCLUDED"

pass
