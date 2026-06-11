#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$REPO_ROOT/packs/engineering/pipelines/feature.yml', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

STAGE_COUNT=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(String(p.stages.length));" "$PIPELINE_JSON")
[ "$STAGE_COUNT" -ge 2 ] || fail "feature pipeline should have at least two stages"

LAST_INDEX=$((STAGE_COUNT - 1))
PREV_INDEX=$((STAGE_COUNT - 2))
CODE_PREV_INDEX=$((STAGE_COUNT - 3))

LAST_ID=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(p.stages[$LAST_INDEX]?.id || '');" "$PIPELINE_JSON")
LAST_CAPABILITY=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(p.stages[$LAST_INDEX]?.capability || '');" "$PIPELINE_JSON")
PREV_ID=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(p.stages[$PREV_INDEX]?.id || '');" "$PIPELINE_JSON")
CODE_PREV_ID=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(p.stages[$CODE_PREV_INDEX]?.id || '');" "$PIPELINE_JSON")
LAST_INSTRUCTION=$(node -e "const p = JSON.parse(process.argv[1]); process.stdout.write(String(p.stages[$LAST_INDEX]?.instruction || '').toLowerCase());" "$PIPELINE_JSON")

assert_eq "$CODE_PREV_ID" "code-review" "code-review should remain before security review and terminal-state closure"
assert_eq "$PREV_ID" "security-review" "security-review should be immediately before terminal-state closure"
assert_eq "$LAST_ID" "terminal-state-closure" "feature pipeline final stage"
assert_eq "$LAST_CAPABILITY" "quality-assurance" "terminal-state closure capability"

for term in \
  "external artifact" \
  "side effect" \
  "terminal state" \
  "handoff" \
  "stop" \
  "dangling" \
  "user-perspective"; do
  assert_match "$LAST_INSTRUCTION" "$term" "terminal-state closure instruction"
done

pass
