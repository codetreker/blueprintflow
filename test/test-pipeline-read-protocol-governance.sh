#!/usr/bin/env bash
# Governance: every role-dispatching engineering pipeline must carry the
# role-instruction read-protocol clause in its top-level instruction:
#   "...require the actor to read its own role instruction before the stage
#    instruction. Do not inline role instruction content; stop when the actor
#    cannot read the role file."
# (See feature.yml / templates/pipeline.yml / roles/pipeline-designer.md.)
#
# The pipeline set is derived DYNAMICALLY from the pack directory (glob
# packs/engineering/pipelines/*.yml), NOT a hardcoded list, so a future pipeline
# shipped without the clause is also caught. A pipeline is "role-dispatching" if
# any stage declares a capability (which makes the harness dispatch a role-bound
# actor for that stage).
set -u
source "$(dirname "$0")/test-helpers.sh"

PIPELINE_DIR="$REPO_ROOT/packs/engineering/pipelines"
[ -d "$PIPELINE_DIR" ] || fail "missing engineering pipeline dir: $PIPELINE_DIR"

shopt -s nullglob
PIPELINES=( "$PIPELINE_DIR"/*.yml )
shopt -u nullglob
[ "${#PIPELINES[@]}" -gt 0 ] || fail "no engineering pipelines found under $PIPELINE_DIR"

# Classify + clause-check every pipeline via the real parser. Emit JSON:
#   { roleDispatching: [...], missingClause: [...] }
RESULT=$(node --input-type=module -e "
  import fs from 'node:fs';
  import path from 'node:path';
  import { parsePipeline } from '$REPO_ROOT/bin/lib/shared/parse-pipeline.mjs';
  const dir = '$PIPELINE_DIR';
  const files = fs.readdirSync(dir).filter((f) => f.endsWith('.yml')).sort();
  const CLAUSE = 'require the actor to read its own role instruction before the stage instruction';
  const CLAUSE2 = 'stop when the actor cannot read the role file';
  const roleDispatching = [];
  const missingClause = [];
  for (const f of files) {
    const p = parsePipeline(fs.readFileSync(path.join(dir, f), 'utf8'));
    const stages = Array.isArray(p.stages) ? p.stages : [];
    const dispatches = stages.some((s) => String(s.capability || '').trim().length > 0);
    if (!dispatches) continue;
    roleDispatching.push(f);
    const instr = String(p.instruction || '');
    if (!instr.includes(CLAUSE) || !instr.includes(CLAUSE2)) missingClause.push(f);
  }
  process.stdout.write(JSON.stringify({ roleDispatching, missingClause }));
")

MISSING=$(node -e "process.stdout.write(JSON.stringify(JSON.parse(process.argv[1]).missingClause))" "$RESULT")
COUNT=$(node -e "process.stdout.write(String(JSON.parse(process.argv[1]).roleDispatching.length))" "$RESULT")

[ "$COUNT" -gt 0 ] || fail "no role-dispatching engineering pipelines detected (every one has capability stages): $RESULT"
assert_eq "$MISSING" "[]" "role-dispatching engineering pipelines missing the read-protocol clause"

pass
