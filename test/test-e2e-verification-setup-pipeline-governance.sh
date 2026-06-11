#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/e2e-verification-setup.yml"
[ -f "$FILE" ] || fail "missing e2e-verification-setup pipeline"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

assert_json_field "$PIPELINE_JSON" .id "e2e-verification-setup"
assert_match "$PIPELINE_JSON" "reusable E2E verification" "setup pipeline description"

STAGES=$(node -e "
  const p = JSON.parse(process.argv[1]);
  process.stdout.write(p.stages.map((stage) => stage.id).join(','));
" "$PIPELINE_JSON")
assert_eq "$STAGES" "protocol-inventory,setup-proposal,user-confirmation,setup-implementation,local-lifecycle-validation,instruction-persistence,code-review,security-review,terminal-state-closure" "e2e setup stage order"

STAGE_CONTRACTS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const top = String(p.instruction || '').toLowerCase();
  const expected = {
    'protocol-inventory': {
      capability: 'system-architecture',
      output: 'artifacts/e2e-protocol-inventory.md',
      terms: ['project instructions', 'docs', 'package scripts', 'e2e configs', 'makefiles', 'docker compose', 'ci workflows', 'comparable local orchestration', 'existing', 'partial', 'missing', 'repository access', 'classified'],
    },
    'setup-proposal': {
      capability: 'system-architecture',
      output: 'artifacts/e2e-setup-proposal.md',
      terms: ['tool', 'startup', 'readiness', 'verification command', 'cleanup', 'env', 'credential', 'data', 'fixture', 'stable lifecycle entrypoint', 'proposal omits'],
    },
    'user-confirmation': {
      capability: 'system-architecture',
      output: 'artifacts/e2e-setup-confirmation.md',
      terms: ['user confirms', 'gate', 'stop before adding dependencies', 'scripts', 'orchestration', 'persistent project instructions', 'expanding setup scope'],
    },
    'setup-implementation': {
      capability: 'software-implementation',
      output: 'artifacts/e2e-setup-implementation.md',
      terms: ['confirmed setup', 'changed files', 'command evidence', 'unconfirmed dependencies', 'services', 'credentials', 'persistent instructions', 'scope beyond'],
    },
    'local-lifecycle-validation': {
      capability: 'software-implementation',
      output: 'artifacts/e2e-local-validation.md',
      terms: ['start', 'readiness', 'verification', 'cleanup', 'failure to clean up', 'not complete', 'processes', 'ports', 'temporary data', 'dangling'],
    },
    'instruction-persistence': {
      capability: 'system-architecture',
      output: 'artifacts/e2e-instruction-persistence.md',
      terms: ['governing project instruction file', 'agents.md', 'stable e2e entrypoint', 'prerequisites', 'future agent', 'ambiguous', 'confirmed'],
    },
    'code-review': {
      capability: 'quality-assurance',
      output: 'artifacts/code-review.md',
      terms: ['independent review', 'setup implementation', 'lifecycle evidence', 'instruction persistence', 'blocker', 'high', 'accepted criteria'],
    },
    'security-review': {
      capability: 'security-review',
      output: 'artifacts/security-review.md',
      terms: ['scripts', 'shell execution', 'secrets', 'ports', 'dependency exposure', 'logging', 'cleanup risk', 'blocker', 'high'],
    },
    'terminal-state-closure': {
      capability: 'quality-assurance',
      output: 'artifacts/terminal-state-closure.md',
      terms: ['processes', 'ports', 'temporary data', 'external artifacts', 'handoffs', 'dangling', 'terminal'],
    },
  };
  const failures = [];
  if (!top.includes('one stable command') && !top.includes('one stable script')) failures.push('top: missing stable lifecycle command preference');
  for (const term of ['start', 'ready', 'verification', 'clean up']) {
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

PIPELINES=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$REPO_ROOT', pack: 'engineering' })));
  });
")
assert_json_field "$PIPELINES" .ok true
assert_match "$PIPELINES" '"id":"e2e-verification-setup"' "e2e setup pipeline should be discoverable"
assert_match "$PIPELINES" "reusable E2E verification" "e2e setup list description"

pass
