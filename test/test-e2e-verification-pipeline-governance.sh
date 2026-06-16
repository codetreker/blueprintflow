#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/e2e-verification.yml"
[ -f "$FILE" ] || fail "missing e2e-verification pipeline"

PIPELINE_JSON=$(node --input-type=module -e "
  import fs from 'node:fs';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const text = fs.readFileSync('$FILE', 'utf8');
  process.stdout.write(JSON.stringify(parsePipeline(text)));
")

assert_json_field "$PIPELINE_JSON" .id "e2e-verification"
assert_match "$PIPELINE_JSON" "report-only verification report" "e2e-verification description"

# --- Eight stage ids and exact order ---
STAGES=$(node -e "
  const p = JSON.parse(process.argv[1]);
  process.stdout.write(p.stages.map((stage) => stage.id).join(','));
" "$PIPELINE_JSON")
assert_eq "$STAGES" "protocol-confirmation,verification-plan,environment-setup,verification-run,finding-adversarial-verification,environment-teardown,verification-report,terminal-state-closure" "e2e-verification stage order"

# --- Single owner: tester (quality-assurance) throughout all 8 stages ---
OWNERS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const nonQa = p.stages.filter((s) => s.capability !== 'quality-assurance').map((s) => s.id);
  process.stdout.write(nonQa.join(',') || 'all-quality-assurance');
" "$PIPELINE_JSON")
assert_eq "$OWNERS" "all-quality-assurance" "every stage owned by quality-assurance"

# --- Report-only: NO internal code-review or security-review stage ---
HAS_REVIEW_STAGE=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const banned = p.stages.filter((s) => s.id === 'code-review' || s.id === 'security-review').map((s) => s.id);
  process.stdout.write(banned.join(',') || 'none');
" "$PIPELINE_JSON")
assert_eq "$HAS_REVIEW_STAGE" "none" "report-only pipeline must not have internal code-review or security-review stage"

# --- Runtime artifact must be self-contained: no docs/ reference ---
assert_not_match "$PIPELINE_JSON" "docs/" "pipeline YAML must not reference docs/"

# --- Top-level instruction report-only + selectable-scope + IV markers ---
TOP_CONTRACT=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const top = String(p.instruction || '').toLowerCase();
  const required = [
    'report-only',
    'does not fix',
    'does not change product code',
    'eight stages',
    'playwright or the project',
    'screenshots',
    'traces',
    'video',
    'console and network logs',
    'selectable',
    'full e2e suite',
    'feature, journey, tag, or path',
    'coverage boundary',
    'protocol is missing',
    'e2e-verification-setup',
    'assertion pass or fail does not stop',
    'multiple independent verifier',
    'no internal code-review stage',
    'no internal security-review stage',
  ];
  const failures = required.filter((term) => !top.includes(term));
  process.stdout.write(JSON.stringify({ ok: failures.length === 0, failures }));
" "$PIPELINE_JSON")
assert_json_field "$TOP_CONTRACT" .ok true

# --- Per-stage contract: capability, output, and required terms ---
STAGE_CONTRACTS=$(node -e "
  const p = JSON.parse(process.argv[1]);
  const expected = {
    'protocol-confirmation': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-protocol-confirmation.md',
      terms: ['runnable e2e protocol', 'entrypoint', 'readiness', 'verification command', 'cleanup path', 'present, partial, or missing', 'does not build the protocol', 'stop and route to the e2e-verification-setup pipeline'],
    },
    'verification-plan': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-verification-plan.md',
      terms: ['chosen verification scope', 'full e2e suite', 'named subset by feature, journey, tag, or path', 'exact chosen scope', 'user journeys', 'critical ui paths', 'playwright or the project', 'screenshots', 'traces', 'video', 'console and network logs', 'decision brief', 'do not guess the scope'],
    },
    'environment-setup': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-environment-setup.md',
      terms: ['ready state', 'readiness', 'readiness evidence', 'environment-teardown', 'cannot reach the ready state'],
    },
    'verification-run': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-verification-run.md',
      terms: ['planned scope', 'subset-selection mechanism', 'playwright or the project', 'screenshots', 'traces', 'video', 'console and network logs', 'assertion pass or fail does not stop the pipeline', 'candidate finding with severity', 'command safety', 'skipped-command evidence'],
    },
    'finding-adversarial-verification': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-finding-verification.md',
      terms: ['adversarially verify', 'still-ready environment', 'flaky', 'multiple independent adversarial verifier actor instances', 'distinct instance', 'refute', 'reproduces', 'majority of verifiers cannot refute', 'confirmed-real', 'unconfirmed or flaky', 'recorded separately', 'hand that need back to the coordinator'],
    },
    'environment-teardown': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-environment-teardown.md',
      terms: ['stop processes', 'free ports', 'temporary data', 'cleanup evidence', 'dangling', 'distinct from the terminal-state-closure audit', 'cleanup fails'],
    },
    'verification-report': {
      capability: 'quality-assurance',
      output: 'artifacts/e2e-verification-report.md',
      terms: ['coverage boundary explicitly', 'what was verified', 'deliberately not covered', 'per-scenario', 'screenshots', 'traces', 'confirmed-real problems', 'unconfirmed or flaky observations', 'severity', 'routed out to a separate feature or bugfix task', 'not fixed here'],
    },
    'terminal-state-closure': {
      capability: 'quality-assurance',
      output: 'artifacts/terminal-state-closure.md',
      terms: ['audit of user-perspective side effects', 'not a second teardown', 'external artifact', 'staging', 'cloud resources', 'test accounts', 'seeded shared data', 'ci artifacts', 'terminal state', 'handoff owner', 'explicit stop condition', 'backstop', 'final acceptance'],
    },
  };
  const failures = [];
  for (const [id, contract] of Object.entries(expected)) {
    const stage = p.stages.find((candidate) => candidate.id === id);
    if (!stage) { failures.push(id + ': missing stage'); continue; }
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

# --- Both environment-teardown and terminal-state-closure present ---
assert_match "$STAGES" "environment-teardown" "environment-teardown stage present"
assert_match "$STAGES" "terminal-state-closure" "terminal-state-closure stage present"

# --- Discoverable via the in-repo pipeline registry ---
PIPELINES=$(node --input-type=module -e "
  import('$REPO_ROOT/bin/lib/bf/cmd-list-pipelines.mjs').then(async (m) => {
    process.stdout.write(JSON.stringify(await m.cmdListPipelines({ cwd: '$REPO_ROOT', pack: 'engineering' })));
  });
")
assert_json_field "$PIPELINES" .ok true
assert_match "$PIPELINES" '"id":"e2e-verification"' "e2e-verification pipeline should be discoverable"
assert_match "$PIPELINES" "report-only verification report" "e2e-verification list description"

pass
