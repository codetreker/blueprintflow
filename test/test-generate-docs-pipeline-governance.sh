#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/generate-docs.yml"
STANDARD="$REPO_ROOT/references/project-design-document-standard.md"

[ -f "$FILE" ] || fail "missing generate-docs pipeline"
[ -f "$STANDARD" ] || fail "missing project design-document standard"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

assert_json_field "$PIPELINE_JSON" .id "generate-docs"
assert_match "$PIPELINE_JSON" "qualified project design documentation" "generate-docs pipeline description"

STAGES=$(node -e "
  const p = JSON.parse(process.argv[1]);
  process.stdout.write(p.stages.map((stage) => stage.id).join(','));
" "$PIPELINE_JSON")
assert_eq "$STAGES" "doc-root-discovery,system-inventory,documentation-plan,documentation-draft,documentation-consistency-review,validation,terminal-state-closure" "generate-docs stage order"

STAGE_CONTRACTS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const expected = {
    'doc-root-discovery': {
      capability: 'system-architecture',
      output: 'artifacts/doc-root-discovery.md',
      terms: ['confirmed project doc root', 'local project convention', 'discussion.md', 'project instructions', 'repository structure', 'multiple candidates', 'conflicting instructions', 'stop', 'handoff'],
    },
    'system-inventory': {
      capability: 'system-architecture',
      output: 'artifacts/system-inventory.md',
      terms: ['stable implementation anchors', 'system boundaries', 'module ownership', 'state authority', 'cross-module flows', 'validation boundaries', 'known gaps', 'not a code directory index', 'handoff'],
    },
    'documentation-plan': {
      capability: 'system-architecture',
      output: 'artifacts/documentation-plan.md',
      terms: ['references/project-design-document-standard.md', 'qualified project design docs', 'target docs', 'coverage gaps', 'design drift', 'stop', 'handoff'],
    },
    'documentation-draft': {
      capability: 'system-architecture',
      output: 'artifacts/documentation-draft.md',
      terms: ['references/project-design-document-standard.md', 'confirmed project doc root', 'local project convention', 'changed files', 'stable anchors', 'fixed documentation path', 'handoff'],
    },
    'documentation-consistency-review': {
      capability: 'design-review',
      output: 'artifacts/documentation-consistency-review.md',
      terms: ['references/project-design-document-standard.md', 'qualified design-doc standard', 'local project convention', 'design drift', 'blocker', 'high', 'signoff'],
    },
    'validation': {
      capability: 'software-implementation',
      output: 'artifacts/validation.md',
      terms: ['task spec', 'command output', 'project-owned', 'not-applicable evidence', 'skipped evidence', 'substitute validation', 'handoff'],
    },
    'terminal-state-closure': {
      capability: 'quality-assurance',
      output: 'artifacts/terminal-state-closure.md',
      terms: ['external artifacts', 'side effects', 'terminal state', 'handoff owner', 'stop condition', 'dangling', 'final acceptance'],
    },
  };
  const top = String(p.instruction || '').toLowerCase();
  const topTerms = ['doc-root discovery', 'system inventory', 'documentation planning', 'documentation drafting', 'consistency review', 'validation', 'terminal-state closure', 'target project', 'project design-document standard', 'design-doc-sync'];
  const failures = [];
  for (const term of topTerms) {
    if (!top.includes(term)) failures.push('top: missing term ' + term);
  }
  for (const [id, contract] of Object.entries(expected)) {
    const stage = p.stages.find((candidate) => candidate.id === id);
    if (!stage) {
      failures.push(id + ': missing stage');
      continue;
    }
    if (stage.capability !== contract.capability) failures.push(id + ': capability ' + (stage.capability || '<missing>'));
    if ((stage.output || '') !== contract.output) failures.push(id + ': output ' + (stage.output || '<none>'));
    const instruction = String(stage.instruction || '').toLowerCase();
    for (const term of contract.terms) {
      if (!instruction.includes(term)) failures.push(id + ': missing term ' + term);
    }
  }
  process.stdout.write(JSON.stringify({ ok: failures.length === 0, failures }));
" "$PIPELINE_JSON")
assert_json_field "$STAGE_CONTRACTS" .ok true

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
assert_match "$PIPELINES" '"id":"generate-docs"' "generate-docs pipeline should be discoverable"
assert_match "$PIPELINES" "qualified project design documentation" "generate-docs list description"

STANDARD_BODY=$(tr '[:upper:]' '[:lower:]' < "$STANDARD" | tr '\n\t' '  ' | tr -s ' ')
for term in \
  "qualified project design docs" \
  "purpose" \
  "recommended structures" \
  "required coverage" \
  "stable implementation anchors" \
  "local convention" \
  "review expectations" \
  "design drift" \
  "system boundaries" \
  "module ownership" \
  "state authority" \
  "cross-module flows" \
  "validation boundaries" \
  "known gaps" \
  "encyclopedia" \
  "code directory index"; do
  assert_match "$STANDARD_BODY" "$term" "project design-document standard should mention '$term'"
done

RUNTIME_TEXT=$(printf "%s\n%s\n" "$(cat "$FILE")" "$(cat "$STANDARD")")
assert_not_match "$RUNTIME_TEXT" "docs/spec" "runtime guidance must not depend on BF design docs"
assert_not_match "$RUNTIME_TEXT" "docs/current" "runtime guidance must not force BF's documentation layout"
assert_not_match "$RUNTIME_TEXT" "\`docs/\`" "runtime guidance must not force a docs/ root"

pass
