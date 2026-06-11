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

EXECUTION_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/execution.md")
assert_match "$EXECUTION_BODY" "phase gate" "execution has directive phase gate"
assert_match "$EXECUTION_BODY" "select eligible task blocks" "execution lets the harness select work batches"
assert_match "$EXECUTION_BODY" "do not inspect all task specs" "execution forbids task selection by spec inspection"
assert_match "$EXECUTION_BODY" "do not read task specs or pipelines locally" "execution keeps task spec reads out of coordinator"
assert_match "$EXECUTION_BODY" "at task entry, a task driver first reads \`roles/task-driver.md\`" "execution makes task driver read its role first"
assert_match "$EXECUTION_BODY" "spec and pipeline for its returned" "execution scopes task driver entry reads to returned task"
assert_match "$EXECUTION_BODY" "discussion.md" "execution uses discussion only for ambiguity recovery"
assert_not_match "$EXECUTION_BODY" "tell the task driver to read \`discussion.md\` only when" "execution should not duplicate role ambiguity handling in handoff"
assert_not_match "$EXECUTION_BODY" "read discussion.md first" "execution must not read discussion at entry"
assert_match "$EXECUTION_BODY" "scope, boundary, acceptance, or design intent" "execution stops for clarification on contract-affecting ambiguity"
assert_match "$EXECUTION_BODY" "explicit authorization" "execution records BF trigger as actor authorization"
assert_match "$EXECUTION_BODY" "bf-harness cleanup <bf-wo>/<task>" "execution runs task-scoped cleanup"
assert_match "$EXECUTION_BODY" "any task pr is merged" "execution runs cleanup after optional task PR merge"
assert_match "$EXECUTION_BODY" "do not defer task worktree cleanup to final" "execution forbids final-acceptance cleanup deferral"
assert_match "$EXECUTION_BODY" "task blocks" "execution treats next output as task blocks"
assert_match "$EXECUTION_BODY" "each returned task gets one task driver" "execution dispatches one task driver per returned task"
assert_match "$EXECUTION_BODY" "## task driver prompt template" "execution provides a task driver prompt template"
assert_match "$EXECUTION_BODY" "use this template when starting or resuming a task driver" "execution scopes the task driver prompt template"
assert_match "$EXECUTION_BODY" "first, read your role instruction: \`roles/task-driver.md\`" "task driver prompt starts by reading task-driver role"
assert_match "$EXECUTION_BODY" "you are task-driver, working on" "task driver prompt identifies the task driver target"
assert_match "$EXECUTION_BODY" "paste the complete task block returned by \`bf-harness next\`" "task driver prompt passes through next output"
assert_match "$EXECUTION_BODY" "read this task's \`spec.md\` and selected pipeline" "task driver prompt requires own task spec and pipeline"
assert_match "$EXECUTION_BODY" "report changed files, evidence artifacts" "task driver prompt requires completion handoff evidence"
assert_match "$EXECUTION_BODY" "## role-bound worker prompt template" "execution provides a role-bound worker prompt template"
assert_match "$EXECUTION_BODY" "use this template when the coordinator or a task driver starts" "worker prompt template is shared by coordinator and task driver"
assert_match "$EXECUTION_BODY" "first, read your role instruction: \`roles/<role-id>.md\`" "worker prompt starts by reading own role"
assert_match "$EXECUTION_BODY" "do not read, summarize, or inline the role instruction" "parent actors do not proxy child role prompts"
assert_match "$EXECUTION_BODY" "until the task driver completes" "execution waits for task driver completion"
assert_match "$EXECUTION_BODY" "terminate it lightly" "execution avoids killing task drivers prematurely"
assert_match "$EXECUTION_BODY" "prefer dispatching fixes to the original" "execution prefers original task driver for verify fixes"
assert_match "$EXECUTION_BODY" "if \`next\` returns no eligible task, enter final acceptance" "execution enters Final Acceptance when next is empty"
assert_match "$EXECUTION_BODY" "start final acceptance by running \`bf-harness status <bf-wo>\`" "Final Acceptance starts with status"
assert_match "$EXECUTION_BODY" "status says all tasks are completed" "execution uses status fact for Final Acceptance readiness"
assert_not_match "$EXECUTION_BODY" "if \`next\` returns no eligible task, run \`bf-harness status <bf-wo>\`" "task loop should not status-gate before Final Acceptance"
assert_not_match "$EXECUTION_BODY" "no task block has been returned by" "execution should not stop before status when next is empty"
assert_not_match "$EXECUTION_BODY" "tasking=0" "execution should not encode task state counters in prompt"
assert_not_match "$EXECUTION_BODY" "ready=0" "execution should not encode task state counters in prompt"
assert_not_match "$EXECUTION_BODY" "draft=0" "execution should not encode task state counters in prompt"
assert_match "$EXECUTION_BODY" "unmerged branch" "execution documents retained cleanup items"

REVIEW_TEMPLATE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/templates/review-result.md")
assert_match "$REVIEW_TEMPLATE_BODY" "at least one provider-role review file" "review template matches provider-role signoff semantics"
assert_not_match "$REVIEW_TEMPLATE_BODY" "all required reviewer" "review template must not imply all provider roles must sign"

ENGINEERING_PACK_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/packs/engineering/pack.md")
assert_match "$ENGINEERING_PACK_BODY" "small enough that one host-compatible task driver can finish it" "engineering breakdown avoids engineer subagent task ownership"
assert_not_match "$ENGINEERING_PACK_BODY" "pick doers" "engineering pack avoids stale doer vocabulary"

for role in engineer architect tester pipeline-designer task-driver; do
  ROLE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/roles/$role.md")
  case "$role" in
    engineer)
      assert_match "$ROLE_BODY" "you are the engineer" "engineer role starts with direct identity framing"
      ;;
    architect)
      assert_match "$ROLE_BODY" "you are the architect" "architect role starts with direct identity framing"
      ;;
    tester)
      assert_match "$ROLE_BODY" "you are the tester" "tester role starts with direct identity framing"
      ;;
    pipeline-designer)
      assert_match "$ROLE_BODY" "you are the pipeline designer" "pipeline-designer role starts with direct identity framing"
      ;;
    task-driver)
      assert_match "$ROLE_BODY" "you are the task driver" "task-driver role starts with direct identity framing"
      assert_match "$ROLE_BODY" "capabilities:" "task-driver role has capabilities frontmatter"
      assert_match "$ROLE_BODY" "task-driving" "task-driver role declares task-driving capability"
      assert_match "$ROLE_BODY" "start every role-bound worker prompt with" "task-driver role starts workers with role-read instruction"
      ;;
  esac
  assert_match "$ROLE_BODY" "read \`discussion.md\` only when" "$role role handles discussion ambiguity recovery"
  assert_match "$ROLE_BODY" "report the ambiguity to the coordinator" "$role role returns unresolved ambiguity to coordinator"
done

if rg -n "phase-1|phase-2|phase-3" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/references" \
  >/tmp/bf-semantic-refs.$$; then
  cat /tmp/bf-semantic-refs.$$ >&2
  rm -f /tmp/bf-semantic-refs.$$
  fail "active runtime/docs still reference old phase filenames"
fi
rm -f /tmp/bf-semantic-refs.$$

if rg -n "spawn 1-3 reviewer subagents|spawn 1–3 reviewer subagents|one to three subagents|capped at ten|cap total at 10|reviewer subagents|subagent instance|subagent-instance" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/references" \
  >/tmp/bf-semantic-stale-reviewers.$$; then
  cat /tmp/bf-semantic-stale-reviewers.$$ >&2
  rm -f /tmp/bf-semantic-stale-reviewers.$$
  fail "active runtime/docs still reference stale Spec Review reviewer-count guidance"
fi
rm -f /tmp/bf-semantic-stale-reviewers.$$

if rg -n "\b[Dd]oer\b|\b[Dd]oers\b|task doer|pick doers" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/references" \
  "$REPO_ROOT/packs/engineering" "$REPO_ROOT/roles" "$REPO_ROOT/templates" \
  >/tmp/bf-semantic-stale-doer.$$; then
  cat /tmp/bf-semantic-stale-doer.$$ >&2
  rm -f /tmp/bf-semantic-stale-doer.$$
  fail "active runtime/docs still use stale doer vocabulary"
fi
rm -f /tmp/bf-semantic-stale-doer.$$

if rg -n "subagent|subagents|Subagent|Subagents" \
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/references" "$REPO_ROOT/packs/engineering" \
  "$REPO_ROOT/roles" "$REPO_ROOT/templates" \
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
  "$REPO_ROOT/SKILL.md" "$REPO_ROOT/references" "$REPO_ROOT/packs" "$REPO_ROOT/roles" \
  "$REPO_ROOT/templates" "$REPO_ROOT/.agents" "$REPO_ROOT/.claude" \
  >/tmp/bf-semantic-stale-repo-update.$$ 2>/dev/null; then
  cat /tmp/bf-semantic-stale-repo-update.$$ >&2
  rm -f /tmp/bf-semantic-stale-repo-update.$$
  fail "active runtime/docs still advertise repo-update as repository workflow driver"
fi
rm -f /tmp/bf-semantic-stale-repo-update.$$

PKG_VERSION=$(node -e "process.stdout.write(JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')).version)" "$REPO_ROOT/package.json")
LOCK_VERSION=$(node -e "const p=JSON.parse(require('fs').readFileSync(process.argv[1], 'utf8')); process.stdout.write(p.version + ' ' + p.packages[''].version)" "$REPO_ROOT/package-lock.json")
assert_eq "$PKG_VERSION" "0.7.6" "package.json version should be bumped"
assert_eq "$LOCK_VERSION" "0.7.6 0.7.6" "package-lock root versions should be bumped"

pass
