#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/feature-light.yml"
[ -f "$FILE" ] || fail "missing feature-light pipeline"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

assert_json_field "$PIPELINE_JSON" .id "feature-light"
assert_match "$PIPELINE_JSON" "small, clear, low-risk feature tasks" "feature-light description"

STAGES=$(node -e "
  const p = JSON.parse(process.argv[1]);
  process.stdout.write(p.stages.map((stage) => stage.id).join(','));
" "$PIPELINE_JSON")
assert_eq "$STAGES" "scope-plan,implementation,validation,code-review,security-review,terminal-state-closure" "feature-light stage order"

STAGE_CONTRACTS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const expected = {
    'scope-plan': {
      capability: 'system-architecture',
      output: 'artifacts/scope-plan.md',
      terms: ['task fit', 'intended change scope', 'validation approach', 'escalation triggers', 'full feature pipeline', 'before implementation'],
    },
    implementation: {
      capability: 'software-implementation',
      output: '',
      terms: ['implement only', 'scope-plan', 'required evidence', 'stop', 'full feature pipeline'],
    },
    validation: {
      capability: 'software-implementation',
      output: 'artifacts/validation.md',
      terms: ['run task-appropriate validation', 'record the command output', 'full validation', 'stop'],
    },
    'code-review': {
      capability: 'quality-assurance',
      output: 'artifacts/code-review.md',
      terms: ['independent', 'diff', 'evidence', 'acceptance criteria', 'blocker', 'high', 'sign off'],
    },
    'security-review': {
      capability: 'security-review',
      output: 'artifacts/security-review.md',
      terms: ['security baseline', 'authentication', 'authorization', 'secrets', 'dependency', 'release integrity', 'not-applicable evidence', 'blocker', 'high'],
    },
    'terminal-state-closure': {
      capability: 'quality-assurance',
      output: 'artifacts/terminal-state-closure.md',
      terms: ['external artifact', 'side effect', 'terminal state', 'handoff owner', 'explicit stop condition', 'user-perspective completion'],
    },
  };
  const failures = [];
  for (const [id, contract] of Object.entries(expected)) {
    const stage = p.stages.find((candidate) => candidate.id === id);
    if (!stage) {
      failures.push(id + ': missing stage');
      continue;
    }
    if (stage.capability !== contract.capability) {
      failures.push(id + ': capability ' + (stage.capability || '<missing>'));
    }
    if ((stage.output || '') !== contract.output) {
      failures.push(id + ': output ' + (stage.output || '<none>'));
    }
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
assert_match "$PIPELINES" '"id":"feature-light"' "feature-light pipeline should be discoverable"
assert_match "$PIPELINES" "small, clear, low-risk feature tasks" "feature-light list description"

pass
