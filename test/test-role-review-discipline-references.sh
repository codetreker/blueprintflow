#!/usr/bin/env bash
# Governance: every Core role that declares a review capability must carry a
# `## Review Discipline` section that references the canonical adversarial
# review reference (roles/references/review-discipline.md), so neither a new nor
# a renamed reviewer role can silently drift away from the discipline.
#
# The reviewer-role set is derived DYNAMICALLY from the role registry: a role is
# "reviewer-capable" if it declares any of the review capabilities below. This is
# NOT a hardcoded role list, so adding/renaming a reviewer role is also caught.
# It also asserts the four built-in AC-gating pipelines' code-review and
# security-review stages reference the canonical file, and that the reference and
# the role template are wired.
set -u
source "$(dirname "$0")/test-helpers.sh"

assert_file_contains() {
  local file="$1" needle="$2" msg="${3:-}"
  if ! grep -F "$needle" "$file" >/dev/null; then
    fail "$msg: $file does not contain '$needle'"
  fi
}

assert_file_not_contains() {
  local file="$1" needle="$2" msg="${3:-}"
  if grep -F "$needle" "$file" >/dev/null; then
    fail "$msg: $file unexpectedly contains '$needle'"
  fi
}

REF="$REPO_ROOT/roles/references/review-discipline.md"
[ -f "$REF" ] || fail "missing review-discipline reference: $REF"

# The reference must not register as a role and must be self-contained.
assert_file_not_contains "$REF" "Capabilities:" "review-discipline reference must not be a role"
assert_file_not_contains "$REF" "docs/" "review-discipline reference must be self-contained (no docs/ ref)"

# The reference must state the five stance elements.
assert_file_contains "$REF" "Refute" "reference covers refute-by-default"
assert_file_contains "$REF" "Record the refutation attempted" "reference covers record-refutation"
assert_file_contains "$REF" "Sign only what survives" "reference covers sign-only-survivors"
assert_file_contains "$REF" "Never sign an AC you cannot verify" "reference covers never-sign-unverifiable"
assert_file_contains "$REF" "missing evidence" "reference covers recording missing evidence"
assert_file_contains "$REF" "manufacturing findings" "reference covers calibrate-not-manufacture"

# Derive the reviewer-capable Core role set dynamically from the role registry.
# A role is reviewer-capable if it declares any of these review capabilities.
REVIEW_CAPS='["design-review","quality-assurance","security-review","pipeline-review","interaction-design"]'
ROLE_FILES=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/shared/role-registry.mjs').then((m) => {
    const reviewCaps = new Set($REVIEW_CAPS);
    const r = m.buildRoleRegistry({ coreRolesDir: '$REPO_ROOT/roles' });
    const files = [];
    for (const role of r.roles.values()) {
      if ((role.capabilities || []).some((c) => reviewCaps.has(c))) files.push(role.file);
    }
    files.sort();
    process.stdout.write(files.join('\n'));
  });
")
[ -n "$ROLE_FILES" ] || fail "no reviewer-capable Core roles detected from the role registry"

# Every reviewer-capable role must apply the canonical reference under a
# `## Review Discipline` section.
COUNT=0
while IFS= read -r role_file; do
  [ -n "$role_file" ] || continue
  assert_file_contains "$role_file" "## Review Discipline" "reviewer-capable role must carry Review Discipline section"
  assert_file_contains "$role_file" "roles/references/review-discipline.md" "reviewer-capable role must reference the canonical review-discipline file"
  COUNT=$((COUNT + 1))
done <<< "$ROLE_FILES"
[ "$COUNT" -ge 5 ] || fail "expected at least 5 reviewer-capable Core roles, found $COUNT"

# The role template must carry the placeholder section so new reviewer roles inherit it.
TEMPLATE="$REPO_ROOT/templates/role.md"
[ -f "$TEMPLATE" ] || fail "missing role template: $TEMPLATE"
assert_file_contains "$TEMPLATE" "## Review Discipline" "role template must carry Review Discipline placeholder"
assert_file_contains "$TEMPLATE" "roles/references/review-discipline.md" "role template must point to the canonical review-discipline file"

# The four built-in AC-gating pipelines' code-review and security-review stages
# must instruct adversarial review per the canonical reference.
PIPELINE_DIR="$REPO_ROOT/packs/engineering/pipelines"
PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import path from 'node:path';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const dir = '$PIPELINE_DIR';
  const named = ['feature.yml', 'feature-light.yml', 'bugfix.yml', 'e2e-verification-setup.yml'];
  const REF = 'roles/references/review-discipline.md';
  const missing = [];
  for (const f of named) {
    const p = parsePipeline(fs.readFileSync(path.join(dir, f), 'utf8'));
    for (const want of ['code-review', 'security-review']) {
      const stage = (p.stages || []).find((s) => s.id === want);
      if (!stage) { missing.push(f + ':' + want + ':absent'); continue; }
      if (!String(stage.instruction || '').includes(REF)) missing.push(f + ':' + want);
    }
  }
  process.stdout.write(JSON.stringify({ missing }));
")
MISSING=$(node -e "process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).missing))" "$PIPELINE_JSON")
assert_eq "$MISSING" "[]" "AC-gating pipeline review stages missing adversarial-review reference"

pass
