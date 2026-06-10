#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

contains_all() {
  local body="$1" label="$2"
  shift 2
  local normalized
  normalized=$(printf "%s" "$body" | tr '\n\t' '  ' | tr -s ' ')
  for term in "$@"; do
    case "$normalized" in
      *"$term"*) ;;
      *) fail "$label should mention '$term'" ;;
    esac
  done
}

ROLE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/roles/pipeline-designer.md")
contains_all "$ROLE_BODY" "pipeline-designer role" \
  "single stage owner" \
  "one capability" \
  "multi-perspective review" \
  "stage instruction" \
  "stable mechanical gate" \
  "role instruction file" \
  "read that file before"

TEMPLATE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/templates/pipeline.yml")
contains_all "$TEMPLATE_BODY" "pipeline template" \
  "review perspectives" \
  "implementation perspective" \
  "architecture perspective" \
  "qa perspective" \
  "role-bound actor" \
  "role instruction path" \
  "read that role instruction before"

TEMPLATE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$REPO_ROOT/templates/pipeline.yml', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

TEMPLATE_REVIEW=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const stage = p.stages.find(s => s.id === '<review-stage-id>');
  process.stdout.write(JSON.stringify(stage || null));
" "$TEMPLATE_JSON")

[ "$TEMPLATE_REVIEW" != "null" ] || fail "pipeline template should include review stage"

TEMPLATE_REVIEW_CAP=$(node -e "const s = JSON.parse(process.argv[1]); process.stdout.write(Array.isArray(s.capability) ? 'array' : String(s.capability || ''));" "$TEMPLATE_REVIEW")
assert_eq "$TEMPLATE_REVIEW_CAP" "<review-capability>" "pipeline template review capability should remain scalar"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$REPO_ROOT/packs/engineering/pipelines/feature.yml', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

CODE_REVIEW=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const stage = p.stages.find(s => s.id === 'code-review');
  process.stdout.write(JSON.stringify(stage || null));
" "$PIPELINE_JSON")

[ "$CODE_REVIEW" != "null" ] || fail "feature pipeline should include code-review stage"

CODE_REVIEW_CAP=$(node -e "const s = JSON.parse(process.argv[1]); process.stdout.write(Array.isArray(s.capability) ? 'array' : String(s.capability || ''));" "$CODE_REVIEW")
CODE_REVIEW_INSTRUCTION=$(node -e "const s = JSON.parse(process.argv[1]); process.stdout.write(String(s.instruction || '').toLowerCase());" "$CODE_REVIEW")
FEATURE_INSTRUCTION=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(String(p.instruction || '').toLowerCase());" "$PIPELINE_JSON")

assert_eq "$CODE_REVIEW_CAP" "quality-assurance" "code-review capability should remain scalar"
contains_all "$FEATURE_INSTRUCTION" "feature pipeline instruction" \
  "role-bound actor" \
  "role instruction path" \
  "read that role instruction before"
contains_all "$CODE_REVIEW_INSTRUCTION" "code-review instruction" \
  "multi-perspective review" \
  "implementation perspective" \
  "architecture perspective" \
  "qa perspective"

pass
