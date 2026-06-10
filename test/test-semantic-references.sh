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

SKILL_TEXT=$(cat "$REPO_ROOT/SKILL.md")
SKILL_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/SKILL.md")
README_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/README.md")
assert_match "$README_BODY" "bf-harness cleanup" "README should list cleanup command"
assert_match "$README_BODY" "when it has a pr" "README should place cleanup after task verification and optional PR merge"
assert_match "$README_BODY" "bf-harness cleanup <bf-wo>/<task>" "README should document task-scoped cleanup target"
assert_match "$README_BODY" "safe local branch deletion" "README should document safe cleanup semantics"
assert_match "$SKILL_TEXT" '$bf' "skill description should cover dollar-prefixed BF trigger"
assert_match "$SKILL_TEXT" "/bf" "skill description should keep slash-prefixed BF trigger"
assert_match "$SKILL_BODY" "entry protocol" "root skill should define entry protocol"
assert_match "$SKILL_BODY" "when not to use" "root skill should define when not to use BF"
assert_match "$SKILL_BODY" "read-only" "root skill should route read-only/advisory requests"
assert_match "$SKILL_BODY" "bootstrap" "root skill should route new work bootstrap"
assert_match "$SKILL_BODY" "resume" "root skill should route existing work resume"
assert_match "$SKILL_BODY" "feedback" "root skill should route feedback flow"
assert_match "$SKILL_BODY" "explicit authorization" "root skill should treat BF trigger as actor authorization"
assert_match "$SKILL_BODY" "host-compatible actor" "root skill should scope actor authorization to host-compatible BF actors"

SPEC_AUTHORING_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/spec-authoring.md")
assert_match "$SPEC_AUTHORING_BODY" "scope contract" "spec authoring defines task specs as scope contracts"
assert_match "$SPEC_AUTHORING_BODY" "not implementation design" "spec authoring separates specs from implementation design"
assert_match "$SPEC_AUTHORING_BODY" "contract gaps" "spec review blocks contract gaps"
assert_match "$SPEC_AUTHORING_BODY" "execution design" "spec authoring leaves details to execution design"
assert_match "$SPEC_AUTHORING_BODY" "accepted user-facing contract" "spec authoring preserves accepted-detail exception"
assert_match "$SPEC_AUTHORING_BODY" "discussion.md contains source material" "spec authoring requires discussion source coverage before bf.md"
assert_match "$SPEC_AUTHORING_BODY" "stop before task breakdown" "spec authoring blocks premature task breakdown"
assert_match "$SPEC_AUTHORING_BODY" "must not cite or quote discussion.md" "spec authoring keeps bf.md concise without redundant citations"
assert_match "$SPEC_AUTHORING_BODY" "three independent reviewer actor instances" "spec authoring fixes Spec Review reviewer count"
assert_match "$SPEC_AUTHORING_BODY" "same spec review round must be a distinct actor instance" "spec authoring requires same-round reviewer independence"
assert_match "$SPEC_AUTHORING_BODY" "three independent reviewer actor instances with the \`pipeline-review\` capability" "spec authoring fixes local pipeline review count"
assert_match "$SPEC_AUTHORING_BODY" "select one provider role" "spec authoring records provider-role selection"

BRAINSTORM_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/brainstorm.md")
assert_match "$BRAINSTORM_BODY" "source coverage" "brainstorm defines source coverage"
assert_match "$BRAINSTORM_BODY" "requirement, acceptance, out-of-scope boundary" "brainstorm readiness covers core contract answers"
assert_match "$BRAINSTORM_BODY" "assistant-led proposal" "brainstorm supports assistant-led proposal entries"
assert_match "$BRAINSTORM_BODY" "confirmed or accepted proposal" "brainstorm restricts bf.md source material to accepted discussion"
assert_match "$BRAINSTORM_BODY" "every bf.md section" "brainstorm requires every bf.md section to be supportable"
assert_match "$BRAINSTORM_BODY" "bootstrap" "brainstorm defines work-object bootstrap"
assert_match "$BRAINSTORM_BODY" "choose a bf-wo id" "brainstorm bootstrap chooses bf-wo id"
assert_match "$BRAINSTORM_BODY" "copy \`templates/discussion.md\`" "brainstorm bootstrap copies discussion template"

RUNTIME_WORKFLOW_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/runtime-layout-and-workflow.md")
assert_match "$RUNTIME_WORKFLOW_BODY" "three independent reviewer actor instances" "workflow docs fix Spec Review reviewer count"
assert_match "$RUNTIME_WORKFLOW_BODY" "same spec review round must be a distinct actor instance" "workflow docs require same-round reviewer independence"
assert_match "$RUNTIME_WORKFLOW_BODY" "host runtime" "workflow docs define host runtime"
assert_match "$RUNTIME_WORKFLOW_BODY" "task driver" "workflow docs define task driver"
assert_match "$RUNTIME_WORKFLOW_BODY" "claude code \`teammate\`" "workflow docs map Claude Code teammate"
assert_match "$RUNTIME_WORKFLOW_BODY" "codex subagent" "workflow docs map Codex subagent"
assert_match "$RUNTIME_WORKFLOW_BODY" "coordinator runs \`start-review\`" "workflow docs keep start-review coordinator-owned"
assert_match "$RUNTIME_WORKFLOW_BODY" "coordinator runs \`verify\`" "workflow docs keep verify coordinator-owned"
assert_match "$RUNTIME_WORKFLOW_BODY" "bf-harness cleanup <bf-wo>/<task>" "workflow docs place cleanup at task scope"
assert_match "$RUNTIME_WORKFLOW_BODY" "after any task pr is" "workflow docs place cleanup after optional task PR merge"
assert_match "$RUNTIME_WORKFLOW_BODY" "task-level closure does not clean bf-owned task" "workflow docs keep pipeline closure from cleaning task worktrees"

SPEC_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec.md")
assert_match "$SPEC_BODY" "task driver executes pipeline" "top-level spec diagram uses task driver"
assert_match "$SPEC_BODY" "coordinator-owned task verification" "top-level spec diagram keeps acceptance coordinator-owned"
assert_match "$SPEC_BODY" "discussion.md source coverage" "top-level spec documents discussion source coverage"
assert_match "$SPEC_BODY" "task cleanup" "top-level spec includes task cleanup"
assert_match "$SPEC_BODY" "\`verify\`, \`cleanup\`, \`discard\`" "top-level spec lists cleanup harness command"
EXECUTION_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/execution.md")
assert_match "$EXECUTION_BODY" "phase gate" "execution has directive phase gate"
assert_match "$EXECUTION_BODY" "select the task" "execution lets the harness select work"
assert_match "$EXECUTION_BODY" "do not inspect all task specs" "execution forbids task selection by spec inspection"
assert_match "$EXECUTION_BODY" "read a task spec only after \`next\` returns that task" "execution delays task spec reads until after next"
assert_match "$EXECUTION_BODY" "discussion.md" "execution uses discussion only for ambiguity recovery"
assert_not_match "$EXECUTION_BODY" "read discussion.md first" "execution must not read discussion at entry"
assert_match "$EXECUTION_BODY" "scope, boundary, acceptance, or design intent" "execution stops for clarification on contract-affecting ambiguity"
assert_match "$EXECUTION_BODY" "explicit authorization" "execution records BF trigger as actor authorization"
assert_match "$EXECUTION_BODY" "bf-harness cleanup <bf-wo>/<task>" "execution runs task-scoped cleanup"
assert_match "$EXECUTION_BODY" "any task pr is merged" "execution runs cleanup after optional task PR merge"
assert_match "$EXECUTION_BODY" "do not defer task worktree cleanup to final" "execution forbids final-acceptance cleanup deferral"
assert_match "$EXECUTION_BODY" "bf-harness status <bf-wo>" "execution checks status before Final Acceptance"
assert_match "$EXECUTION_BODY" "status says all tasks are completed" "execution uses status fact for Final Acceptance readiness"
assert_not_match "$EXECUTION_BODY" "tasking=0" "execution should not encode task state counters in prompt"
assert_not_match "$EXECUTION_BODY" "ready=0" "execution should not encode task state counters in prompt"
assert_not_match "$EXECUTION_BODY" "draft=0" "execution should not encode task state counters in prompt"
assert_match "$EXECUTION_BODY" "unmerged branch" "execution documents retained cleanup items"

CORE_CONSTRAINTS_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/core-constraints.md")
assert_match "$CORE_CONSTRAINTS_BODY" "coordinator" "core constraints define coordinator"
assert_match "$CORE_CONSTRAINTS_BODY" "leaf worker" "core constraints define leaf worker"
assert_match "$CORE_CONSTRAINTS_BODY" "instruction-level constraints" "core constraints document instruction-level runtime enforcement"
assert_match "$CORE_CONSTRAINTS_BODY" "discussion.md is durable source material" "core constraints document discussion as durable source material"
assert_match "$CORE_CONSTRAINTS_BODY" "bf.md does not need direct citations" "core constraints avoid redundant bf.md citations"
assert_match "$CORE_CONSTRAINTS_BODY" "at least one provider role" "core constraints document provider-role signoff"
assert_match "$CORE_CONSTRAINTS_BODY" "explicit authorization" "core constraints document BF actor authorization"
assert_match "$CORE_CONSTRAINTS_BODY" "task lifecycle command" "core constraints document task cleanup lifecycle"

REVIEW_TEMPLATE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/templates/review-result.md")
assert_match "$REVIEW_TEMPLATE_BODY" "at least one provider-role review file" "review template matches provider-role signoff semantics"
assert_not_match "$REVIEW_TEMPLATE_BODY" "all required reviewer" "review template must not imply all provider roles must sign"

ARCHITECTURE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/architecture.md")
assert_match "$ARCHITECTURE_BODY" "repository maintenance is governed by \`agents.md\`" "architecture keeps repository maintenance authority in AGENTS.md"
assert_match "$ARCHITECTURE_BODY" "not a repo-maintenance skill or pack" "architecture does not introduce a repo-maintenance replacement"

PACKS_PIPELINES_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/packs-and-pipelines.md")
assert_match "$PACKS_PIPELINES_BODY" "three independent reviewer actor instances with the" "pipeline docs fix local pipeline review count"
assert_match "$PACKS_PIPELINES_BODY" "\`pipeline-review\` capability" "pipeline docs name pipeline-review as capability"
assert_match "$PACKS_PIPELINES_BODY" "pipeline review" "pipeline docs distinguish pipeline review"
assert_match "$PACKS_PIPELINES_BODY" "bf acceptance" "pipeline docs distinguish BF acceptance"
assert_match "$PACKS_PIPELINES_BODY" "not task-local side effects" "pipeline docs keep worktree cleanup outside task closure"
assert_match "$PACKS_PIPELINES_BODY" "bf-harness cleanup <bf-wo>/<task>" "pipeline docs assign task-scoped cleanup to coordinator"
assert_match "$PACKS_PIPELINES_BODY" "the task has a pr" "pipeline docs place cleanup after task verification and optional PR merge"

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

if rg -n "spawn 1-3 reviewer subagents|spawn 1–3 reviewer subagents|one to three subagents|capped at ten|cap total at 10|reviewer subagents|subagent instance|subagent-instance" \
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
  | grep -v -E "Codex subagent|Codex, that actor is a Codex subagent|Codex subagent can be" \
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
  >/tmp/bf-semantic-stale-repo-update.$$ 2>/dev/null; then
  cat /tmp/bf-semantic-stale-repo-update.$$ >&2
  rm -f /tmp/bf-semantic-stale-repo-update.$$
  fail "active runtime/docs still advertise repo-update as repository workflow driver"
fi
rm -f /tmp/bf-semantic-stale-repo-update.$$

PKG_VERSION=$(node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')).version)" "$REPO_ROOT/package.json")
LOCK_VERSION=$(node -e "const p=JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')); process.stdout.write(p.version + ' ' + p.packages[''].version)" "$REPO_ROOT/package-lock.json")
assert_eq "$PKG_VERSION" "0.7.5" "package.json version should be bumped"
assert_eq "$LOCK_VERSION" "0.7.5 0.7.5" "package-lock root versions should be bumped"

pass
