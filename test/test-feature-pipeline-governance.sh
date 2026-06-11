#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/feature.yml"
[ -f "$FILE" ] || fail "missing feature pipeline"

body=$(tr '[:upper:]' '[:lower:]' < "$FILE" | tr '\n\t' '  ' | tr -s ' ')

for term in \
  "id: feature" \
  "design-first" \
  "architecture-design" \
  "implementation-design" \
  "evidence plan" \
  "design-doc-sync" \
  "validation" \
  "not-applicable evidence" \
  "independent review" \
  "security-review" \
  "security baseline" \
  "security-relevant change" \
  "do not clean bf-owned task worktrees" \
  "bf-harness cleanup after bf-harness complete succeeds" \
  "does not require red-first tdd"; do
  case "$body" in
    *"$term"*) ;;
    *) fail "feature pipeline should mention '$term'" ;;
  esac
done

assert_match "$body" "coordinator" "feature pipeline should name coordinator final gate"
assert_match "$body" "reruns final verify" "feature pipeline should require final verify rerun"
assert_match "$body" "merge" "feature pipeline should keep merge before completion boundary"
assert_match "$body" "complete" "feature pipeline should keep complete boundary"
assert_match "$body" "cleanup" "feature pipeline should keep cleanup boundary"
assert_not_match "$body" "coordinator decides whether this evidence is sufficient" "feature pipeline should not keep old coordinator closure sufficiency wording"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")
MISSING_OUTPUTS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const ids = ['architecture-review', 'design-review', 'code-review', 'security-review', 'terminal-state-closure'];
  const missing = ids.filter(id => {
    const stage = p.stages.find(s => s.id === id);
    return !stage || !String(stage.output || '').trim();
  });
  process.stdout.write(missing.join(','));
" "$PIPELINE_JSON")
assert_eq "$MISSING_OUTPUTS" "" "feature review/closure stages must have durable outputs"

SECURITY_STAGE_CHECKS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const code = p.stages.findIndex((stage) => stage.id === 'code-review');
  const security = p.stages.findIndex((stage) => stage.id === 'security-review');
  const closure = p.stages.findIndex((stage) => stage.id === 'terminal-state-closure');
  const stage = p.stages[security] || {};
  const instruction = String(stage.instruction || '').toLowerCase();
  process.stdout.write(JSON.stringify({
    ordered: code >= 0 && security > code && closure > security,
    capability: stage.capability || '',
    stopGuidance: instruction.includes('blocker') && instruction.includes('high'),
    naGuidance: instruction.includes('not-applicable evidence') && instruction.includes('security-relevant change'),
  }));
" "$PIPELINE_JSON")
assert_json_field "$SECURITY_STAGE_CHECKS" .ordered true
assert_json_field "$SECURITY_STAGE_CHECKS" .capability "security-review"
assert_json_field "$SECURITY_STAGE_CHECKS" .stopGuidance true
assert_json_field "$SECURITY_STAGE_CHECKS" .naGuidance true

E2E_STAGE_CHECKS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const validation = p.stages.findIndex((stage) => stage.id === 'validation');
  const e2e = p.stages.findIndex((stage) => stage.id === 'e2e-protocol-discovery');
  const code = p.stages.findIndex((stage) => stage.id === 'code-review');
  const security = p.stages.findIndex((stage) => stage.id === 'security-review');
  const closure = p.stages.findIndex((stage) => stage.id === 'terminal-state-closure');
  const stage = p.stages[e2e] || {};
  const instruction = String(stage.instruction || '').toLowerCase();
  const hasEvery = (terms) => terms.every((term) => instruction.includes(term));
  process.stdout.write(JSON.stringify({
    ordered: validation >= 0 && e2e > validation && code > e2e && security > e2e && closure > e2e,
    capability: stage.capability || '',
    output: stage.output || '',
    sourceInspection: hasEvery(['project instructions', 'docs', 'package scripts', 'e2e', 'makefile', 'docker compose', 'orchestration']),
    lifecycle: hasEvery(['start', 'readiness', 'verification', 'cleanup']),
    frontendEvidence: instruction.includes('playwright') && instruction.includes('equivalent'),
    missingProtocolRoute: hasEvery(['runtime-facing', 'stop', 'e2e-verification-setup', 'coordinator']),
    skipEvidence: instruction.includes('not-applicable') && instruction.includes('skipped evidence') && instruction.includes('substitute validation'),
  }));
" "$PIPELINE_JSON")
assert_json_field "$E2E_STAGE_CHECKS" .ordered true
assert_json_field "$E2E_STAGE_CHECKS" .capability "software-implementation"
assert_json_field "$E2E_STAGE_CHECKS" .output "artifacts/e2e-protocol-discovery.md"
assert_json_field "$E2E_STAGE_CHECKS" .sourceInspection true
assert_json_field "$E2E_STAGE_CHECKS" .lifecycle true
assert_json_field "$E2E_STAGE_CHECKS" .frontendEvidence true
assert_json_field "$E2E_STAGE_CHECKS" .missingProtocolRoute true
assert_json_field "$E2E_STAGE_CHECKS" .skipEvidence true

pass
