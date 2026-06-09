#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

for file in brainstorm spec-authoring execution; do
  [ -f "$REPO_ROOT/references/$file.md" ] || fail "missing references/$file.md"
done

FIRST=$(sed -n '1p' "$REPO_ROOT/references/brainstorm.md")
assert_eq "$FIRST" "# Brainstorm" "brainstorm H1"
FIRST=$(sed -n '1p' "$REPO_ROOT/references/spec-authoring.md")
assert_eq "$FIRST" "# Spec Authoring" "spec-authoring H1"
FIRST=$(sed -n '1p' "$REPO_ROOT/references/execution.md")
assert_eq "$FIRST" "# Execution" "execution H1"

SPEC_AUTHORING_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/spec-authoring.md")
assert_match "$SPEC_AUTHORING_BODY" "scope contract" "spec authoring defines task specs as scope contracts"
assert_match "$SPEC_AUTHORING_BODY" "not implementation design" "spec authoring separates specs from implementation design"
assert_match "$SPEC_AUTHORING_BODY" "contract gaps" "spec review blocks contract gaps"
assert_match "$SPEC_AUTHORING_BODY" "execution design" "spec authoring leaves details to execution design"
assert_match "$SPEC_AUTHORING_BODY" "accepted user-facing contract" "spec authoring preserves accepted-detail exception"
assert_match "$SPEC_AUTHORING_BODY" "discussion.md contains source material" "spec authoring requires discussion source coverage before bf.md"
assert_match "$SPEC_AUTHORING_BODY" "stop before task breakdown" "spec authoring blocks premature task breakdown"
assert_match "$SPEC_AUTHORING_BODY" "must not cite or quote discussion.md" "spec authoring keeps bf.md concise without redundant citations"
assert_match "$SPEC_AUTHORING_BODY" "spawn exactly three reviewer subagents" "spec authoring fixes Spec Review reviewer count"
assert_match "$SPEC_AUTHORING_BODY" "same spec review round must be a distinct subagent instance" "spec authoring requires same-round reviewer independence"
assert_match "$SPEC_AUTHORING_BODY" "three independent reviewer subagents with the \`pipeline-review\` capability" "spec authoring fixes local pipeline review count"

BRAINSTORM_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/brainstorm.md")
assert_match "$BRAINSTORM_BODY" "source coverage" "brainstorm defines source coverage"
assert_match "$BRAINSTORM_BODY" "requirement, acceptance, out-of-scope boundary" "brainstorm readiness covers core contract answers"
assert_match "$BRAINSTORM_BODY" "assistant-led proposal" "brainstorm supports assistant-led proposal entries"
assert_match "$BRAINSTORM_BODY" "confirmed or accepted proposal" "brainstorm restricts bf.md source material to accepted discussion"
assert_match "$BRAINSTORM_BODY" "every bf.md section" "brainstorm requires every bf.md section to be supportable"

RUNTIME_WORKFLOW_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/runtime-layout-and-workflow.md")
assert_match "$RUNTIME_WORKFLOW_BODY" "spawn exactly three reviewer subagents" "workflow docs fix Spec Review reviewer count"
assert_match "$RUNTIME_WORKFLOW_BODY" "same spec review round must be a distinct subagent instance" "workflow docs require same-round reviewer independence"
assert_match "$RUNTIME_WORKFLOW_BODY" "host runtime" "workflow docs define host runtime"
assert_match "$RUNTIME_WORKFLOW_BODY" "task driver" "workflow docs define task driver"
assert_match "$RUNTIME_WORKFLOW_BODY" "claude code \`teammate\`" "workflow docs map Claude Code teammate"
assert_match "$RUNTIME_WORKFLOW_BODY" "codex subagent" "workflow docs map Codex subagent"
assert_match "$RUNTIME_WORKFLOW_BODY" "coordinator runs \`start-review\`" "workflow docs keep start-review coordinator-owned"
assert_match "$RUNTIME_WORKFLOW_BODY" "coordinator runs \`verify\`" "workflow docs keep verify coordinator-owned"

SPEC_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec.md")
assert_match "$SPEC_BODY" "task driver executes pipeline" "top-level spec diagram uses task driver"
assert_match "$SPEC_BODY" "coordinator-owned task verification" "top-level spec diagram keeps acceptance coordinator-owned"
assert_match "$SPEC_BODY" "discussion.md source coverage" "top-level spec documents discussion source coverage"

EXECUTION_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/execution.md")
assert_match "$EXECUTION_BODY" "host-runtime strategy" "execution requires host-runtime strategy"
assert_match "$EXECUTION_BODY" "review-ready handoff" "execution requires task-driver handoff"
assert_match "$EXECUTION_BODY" "coordinator dispatches bf acceptance reviewers" "execution keeps BF acceptance reviewer dispatch coordinator-owned"
assert_match "$EXECUTION_BODY" "acceptance-readiness terminal-state closure" "execution separates terminal-state closure from code review"
assert_match "$EXECUTION_BODY" "read discussion.md first" "execution recovers unclear intent from discussion"
assert_match "$EXECUTION_BODY" "scope, boundary, acceptance, or design intent" "execution stops for clarification on contract-affecting ambiguity"

CORE_CONSTRAINTS_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/core-constraints.md")
assert_match "$CORE_CONSTRAINTS_BODY" "coordinator" "core constraints define coordinator"
assert_match "$CORE_CONSTRAINTS_BODY" "leaf worker" "core constraints define leaf worker"
assert_match "$CORE_CONSTRAINTS_BODY" "instruction-level constraints" "core constraints document instruction-level runtime enforcement"
assert_match "$CORE_CONSTRAINTS_BODY" "discussion.md is durable source material" "core constraints document discussion as durable source material"
assert_match "$CORE_CONSTRAINTS_BODY" "bf.md does not need direct citations" "core constraints avoid redundant bf.md citations"

ARCHITECTURE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/architecture.md")
assert_match "$ARCHITECTURE_BODY" "repository maintenance is governed by \`agents.md\`" "architecture keeps repository maintenance authority in AGENTS.md"
assert_match "$ARCHITECTURE_BODY" "not a repo-maintenance skill or pack" "architecture does not introduce a repo-maintenance replacement"

PACKS_PIPELINES_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/packs-and-pipelines.md")
assert_match "$PACKS_PIPELINES_BODY" "three independent reviewer subagents with the" "pipeline docs fix local pipeline review count"
assert_match "$PACKS_PIPELINES_BODY" "\`pipeline-review\` capability" "pipeline docs name pipeline-review as capability"
assert_match "$PACKS_PIPELINES_BODY" "pipeline review" "pipeline docs distinguish pipeline review"
assert_match "$PACKS_PIPELINES_BODY" "bf acceptance" "pipeline docs distinguish BF acceptance"

ENGINEERING_PACK_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/packs/engineering/pack.md")
assert_match "$ENGINEERING_PACK_BODY" "small enough that one host-compatible task driver can finish it" "engineering breakdown avoids engineer subagent task ownership"
assert_not_match "$ENGINEERING_PACK_BODY" "pick doers" "engineering pack avoids stale doer vocabulary"

if rg -n "phase-1|phase-2|phase-3" \
  "$REPO_ROOT/README.md" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs" "$REPO_ROOT/references" \
  >/tmp/bf-semantic-refs.$$; then
  cat /tmp/bf-semantic-refs.$$ >&2
  rm -f /tmp/bf-semantic-refs.$$
  fail "active runtime/docs still reference old phase filenames"
fi
rm -f /tmp/bf-semantic-refs.$$

if rg -n "spawn 1-3 reviewer subagents|spawn 1–3 reviewer subagents|one to three subagents|capped at ten|cap total at 10" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs" "$REPO_ROOT/references" \
  >/tmp/bf-semantic-stale-reviewers.$$; then
  cat /tmp/bf-semantic-stale-reviewers.$$ >&2
  rm -f /tmp/bf-semantic-stale-reviewers.$$
  fail "active runtime/docs still reference stale Spec Review reviewer-count guidance"
fi
rm -f /tmp/bf-semantic-stale-reviewers.$$

if rg -n "\b[Dd]oer\b|\b[Dd]oers\b|task doer|pick doers" \
  "$REPO_ROOT/README.md" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs" "$REPO_ROOT/references" \
  "$REPO_ROOT/packs/engineering" "$REPO_ROOT/roles" "$REPO_ROOT/templates" \
  >/tmp/bf-semantic-stale-doer.$$; then
  cat /tmp/bf-semantic-stale-doer.$$ >&2
  rm -f /tmp/bf-semantic-stale-doer.$$
  fail "active runtime/docs still use stale doer vocabulary"
fi
rm -f /tmp/bf-semantic-stale-doer.$$

if rg -n "subagent|subagents|Subagent|Subagents" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs/spec" "$REPO_ROOT/docs/architecture.md" \
  "$REPO_ROOT/references" "$REPO_ROOT/packs/engineering" "$REPO_ROOT/roles" "$REPO_ROOT/templates" \
  | grep -v -E "Codex subagent|reviewer subagents|subagent instance|subagent-instance|subagent only as runtime guidance|reviewer-subagent" \
  >/tmp/bf-semantic-stale-subagent.$$; then
  cat /tmp/bf-semantic-stale-subagent.$$ >&2
  rm -f /tmp/bf-semantic-stale-subagent.$$
  fail "active runtime/docs still use stale generic subagent vocabulary"
fi
rm -f /tmp/bf-semantic-stale-subagent.$$

if [ -e "$REPO_ROOT/.agents/skills/repo-update" ] || [ -e "$REPO_ROOT/.claude/skills/repo-update" ]; then
  fail "repo-local repo-update skill entry points must be removed"
fi

if rg -n "repo-update|repo update|repo maintenance entry|repository update workflow|\\.agents/skills/repo-update|\\.claude/skills/repo-update" \
  "$REPO_ROOT/README.md" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/docs/spec.md" \
  "$REPO_ROOT/docs/architecture.md" "$REPO_ROOT/references" "$REPO_ROOT/packs" \
  "$REPO_ROOT/roles" "$REPO_ROOT/templates" "$REPO_ROOT/.agents" "$REPO_ROOT/.claude" \
  >/tmp/bf-semantic-stale-repo-update.$$; then
  cat /tmp/bf-semantic-stale-repo-update.$$ >&2
  rm -f /tmp/bf-semantic-stale-repo-update.$$
  fail "active runtime/docs still advertise repo-update as repository workflow driver"
fi
rm -f /tmp/bf-semantic-stale-repo-update.$$

PKG_VERSION=$(node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')).version)" "$REPO_ROOT/package.json")
LOCK_VERSION=$(node -e "const p=JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')); process.stdout.write(p.version + ' ' + p.packages[''].version)" "$REPO_ROOT/package-lock.json")
assert_eq "$PKG_VERSION" "0.7.2" "package.json version should be bumped"
assert_eq "$LOCK_VERSION" "0.7.2 0.7.2" "package-lock root versions should be bumped"

pass
