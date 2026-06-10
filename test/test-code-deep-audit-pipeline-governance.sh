#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/code-deep-audit.yml"
[ -f "$FILE" ] || fail "missing code-deep-audit pipeline"

body=$(tr '[:upper:]' '[:lower:]' < "$FILE" | tr '\n\t' '  ' | tr -s ' ')

for term in \
  "id: code-deep-audit" \
  "review-only" \
  "deep codebase audit" \
  "dimensions 1-9 and 11" \
  "repository-inventory" \
  "repository-specific-plan" \
  "inventory-derived" \
  "command-evidence" \
  "command safety" \
  "skipped-command evidence" \
  "security baseline" \
  "findings triage" \
  "terminal-state closure" \
  "blocker" \
  "high" \
  "medium" \
  "low"; do
  case "$body" in
    *"$term"*) ;;
    *) fail "code-deep-audit pipeline should mention '$term'" ;;
  esac
done

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")
assert_json_field "$PIPELINE_JSON" .id "code-deep-audit"

STAGE_CHECKS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const required = [
    'repository-inventory',
    'repository-specific-plan',
    'command-evidence',
    'codebase-architecture-audit',
    'correctness-audit',
    'test-quality-audit',
    'security-baseline',
    'maintainability-audit',
    'developer-experience-audit',
    'release-package-governance-audit',
    'runtime-reliability-audit',
    'documentation-consistency-audit',
    'repository-specific-checks',
    'findings-triage',
    'terminal-state-closure',
  ];
  const missing = required.filter((id) => !p.stages.some((stage) => stage.id === id));
  const missingOutput = [
    'repository-inventory',
    'repository-specific-plan',
    'command-evidence',
    'audit-findings',
    'terminal-state-closure',
  ].filter((id) => {
    const stage = p.stages.find((candidate) => candidate.id === id);
    return !stage || !String(stage.output || '').trim();
  });
  const auditReview = p.stages.some((stage) => stage.id === 'audit-review');
  const security = p.stages.find((stage) => stage.id === 'security-baseline');
  process.stdout.write(JSON.stringify({
    missing,
    missingOutput,
    auditReview,
    securityCapability: security?.capability || '',
  }));
" "$PIPELINE_JSON")
assert_json_field "$STAGE_CHECKS" .missing '[]'
assert_json_field "$STAGE_CHECKS" .missingOutput '[]'
assert_json_field "$STAGE_CHECKS" .auditReview false
assert_json_field "$STAGE_CHECKS" .securityCapability "security-review"

CAPABILITY_CHECKS=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  import { buildRoleRegistry } from '$REPO_ROOT/bin/lib/shared/role-registry.mjs';
  const pipeline = parsePipeline(fs.readFileSync('$FILE', 'utf8'));
  const roles = buildRoleRegistry({ coreRolesDir: '$REPO_ROOT/roles' });
  const missing = pipeline.stages
    .map((stage) => stage.capability)
    .filter((capability, index, all) => all.indexOf(capability) === index)
    .filter((capability) => !(roles.byCapability.get(capability) || []).length)
    .sort();
  process.stdout.write(JSON.stringify({ missing }));
")
assert_json_field "$CAPABILITY_CHECKS" .missing '[]'

PIPELINES=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$REPO_ROOT', pack: 'engineering' })));
  });
")
assert_json_field "$PIPELINES" .ok true
assert_match "$PIPELINES" '"id":"code-deep-audit"' "code-deep-audit pipeline should be discoverable"
assert_match "$PIPELINES" '"id":"feature"' "feature pipeline should remain discoverable"
assert_match "$PIPELINES" '"id":"bugfix"' "bugfix pipeline should remain discoverable"

pass
