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
assert_match "$SKILL_BODY" "pending phase confirmation" "root skill should route affirmative answers to pending BF phase confirmations"
assert_match "$SKILL_BODY" "immediately run the next legal bf action and continue to that phase" "root skill should advance after phase approval"
assert_match "$SKILL_BODY" "do not ask for another phase command" "root skill should not ask for duplicate phase commands after approval"
assert_match "$SKILL_BODY" "explicit authorization" "root skill should treat BF trigger as actor authorization"
assert_match "$SKILL_BODY" "host-compatible actor" "root skill should scope actor authorization to host-compatible BF actors"
assert_match "$SKILL_BODY" "codex uses subagent actors for task drivers, leaf workers, and reviewers" "root skill should map Codex BF actors to subagents"
assert_match "$SKILL_BODY" "claude code uses \`teammate\` for task drivers" "root skill should map Claude Code task drivers to teammates"
assert_match "$SKILL_BODY" "claude code uses subagents for leaf workers and reviewers" "root skill should map Claude Code non-driver actors to subagents"
assert_not_match "$SKILL_BODY" "in claude code, this includes \`teammate\` actors" "root skill must not imply every Claude Code BF actor is a teammate"
assert_match "$SKILL_BODY" "read \`references/brainstorm.md\` first" "root skill should route new work through brainstorm before bootstrap details"
assert_match "$SKILL_BODY" "brainstorm owns pack selection, bootstrap, and the first accepted discussion entry" "root skill should keep new-work bootstrap inside brainstorm"
assert_match "$SKILL_BODY" "bf-harness complete" "root skill should include complete as terminal state command"
assert_match "$SKILL_BODY" "acceptance-ready" "root skill should describe task driver acceptance-ready handoff"
assert_match "$SKILL_BODY" "merge" "root skill should assign coordinator merge responsibility"
assert_match "$SKILL_BODY" "cleanup" "root skill should assign coordinator cleanup responsibility"
assert_not_match "$SKILL_BODY" "review-ready handoff" "root skill should not keep old task-driver handoff wording"
assert_match "$SKILL_BODY" "security" "root skill should name the Core security role"
assert_match "$SKILL_BODY" "code-deep-audit" "root skill should mention the built-in deep audit pipeline"
assert_match "$SKILL_BODY" "decision brief" "root skill should require decision briefs at material user decision gates"
assert_match "$SKILL_BODY" "material user decision gates" "root skill should name material user decision gates"
assert_match "$SKILL_BODY" "name the decision" "root skill should define decision-brief decision content"
assert_match "$SKILL_BODY" "relevant context and current evidence" "root skill should define decision-brief context and evidence content"
assert_match "$SKILL_BODY" "realistic options" "root skill should define decision-brief options content"
assert_match "$SKILL_BODY" "tradeoffs or consequences" "root skill should define decision-brief tradeoff content"
assert_match "$SKILL_BODY" "recommendation when evidence supports one" "root skill should define supported recommendation content"
assert_match "$SKILL_BODY" "simple factual clarifications" "root skill should preserve lightweight factual clarification prompts"
assert_match "$SKILL_BODY" "status updates" "root skill should preserve lightweight status prompts"
assert_match "$SKILL_BODY" "obvious yes/no confirmations" "root skill should preserve lightweight yes/no prompts"

SPEC_AUTHORING_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/spec-authoring.md")
assert_match "$SPEC_AUTHORING_BODY" "scope contract" "spec authoring defines task specs as scope contracts"
assert_match "$SPEC_AUTHORING_BODY" "not implementation design" "spec authoring separates specs from implementation design"
assert_match "$SPEC_AUTHORING_BODY" "contract gaps" "spec review blocks contract gaps"
assert_match "$SPEC_AUTHORING_BODY" "execution design" "spec authoring leaves details to execution design"
assert_match "$SPEC_AUTHORING_BODY" "accepted user-facing contract" "spec authoring preserves accepted-detail exception"
assert_match "$SPEC_AUTHORING_BODY" "phase gate" "spec authoring has directive phase gate"
assert_match "$SPEC_AUTHORING_BODY" "report discussion source coverage" "spec authoring reports coverage before drafting"
assert_match "$SPEC_AUTHORING_BODY" "do not write \`bf.md\` or task specs" "spec authoring blocks drafting before coverage"
assert_match "$SPEC_AUTHORING_BODY" "discussion.md contains source material" "spec authoring requires discussion source coverage before bf.md"
assert_match "$SPEC_AUTHORING_BODY" "stop before task breakdown" "spec authoring blocks premature task breakdown"
assert_match "$SPEC_AUTHORING_BODY" "must not cite or quote discussion.md" "spec authoring keeps bf.md concise without redundant citations"
assert_match "$SPEC_AUTHORING_BODY" "three independent reviewer actor instances" "spec authoring fixes Spec Review reviewer count"
assert_match "$SPEC_AUTHORING_BODY" "same spec review round must be a distinct actor instance" "spec authoring requires same-round reviewer independence"
assert_match "$SPEC_AUTHORING_BODY" "three independent reviewer actor instances with the \`pipeline-review\` capability" "spec authoring fixes local pipeline review count"
assert_match "$SPEC_AUTHORING_BODY" "select one provider role" "spec authoring records provider-role selection"

BRAINSTORM_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/brainstorm.md")
assert_match "$BRAINSTORM_BODY" "phase gate" "brainstorm has directive phase gate"
assert_match "$BRAINSTORM_BODY" "hard gates" "brainstorm has hard gates"
assert_match "$BRAINSTORM_BODY" "brainstorm loop" "brainstorm has an explicit loop"
assert_match "$BRAINSTORM_BODY" "source coverage checklist" "brainstorm has explicit coverage checklist"
assert_match "$BRAINSTORM_BODY" "source coverage" "brainstorm defines source coverage"
assert_match "$BRAINSTORM_BODY" "requirement, acceptance, out-of-scope boundary" "brainstorm readiness covers core contract answers"
assert_match "$BRAINSTORM_BODY" "assistant-led proposal" "brainstorm supports assistant-led proposal entries"
assert_match "$BRAINSTORM_BODY" "confirmed or accepted proposal" "brainstorm restricts bf.md source material to accepted discussion"
assert_match "$BRAINSTORM_BODY" "every bf.md section" "brainstorm requires every bf.md section to be supportable"
assert_match "$BRAINSTORM_BODY" "bootstrap" "brainstorm defines work-object bootstrap"
assert_match "$BRAINSTORM_BODY" "choose a bf-wo id" "brainstorm bootstrap chooses bf-wo id"
assert_match "$BRAINSTORM_BODY" "copy \`templates/discussion.md\`" "brainstorm bootstrap copies discussion template"
assert_match "$BRAINSTORM_BODY" "do not author \`bf.md\`" "brainstorm forbids bf.md authoring"
assert_match "$BRAINSTORM_BODY" "do not create task specs" "brainstorm forbids task spec creation"
assert_match "$BRAINSTORM_BODY" "do not start task breakdown" "brainstorm blocks premature task breakdown"
assert_match "$BRAINSTORM_BODY" "user explicitly agrees to enter spec authoring" "brainstorm requires explicit transition approval"
assert_match "$BRAINSTORM_BODY" "one unresolved coverage gap" "brainstorm loop focuses one coverage gap at a time"
assert_match "$BRAINSTORM_BODY" "decision brief" "brainstorm applies decision briefs to material user decision gates"

EXECUTION_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/execution.md")
EXECUTION_HARD_GATES=$(awk '/^## Hard Gates/{flag=1;next}/^## /{flag=0}flag' "$REPO_ROOT/references/execution.md" | tr '[:upper:]' '[:lower:]')
EXECUTION_TASK_LOOP=$(awk '/^## Task Loop/{flag=1;next}/^## /{flag=0}flag' "$REPO_ROOT/references/execution.md" | tr '[:upper:]' '[:lower:]')
EXECUTION_TASK_DRIVER_TEMPLATE=$(awk '/^## Task Driver Prompt Template/{flag=1;next}/^## /{flag=0}flag' "$REPO_ROOT/references/execution.md" | tr '[:upper:]' '[:lower:]')
EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS=$(awk '/^instructions:/{flag=1;next}/^boundaries:/{flag=0}flag' <<< "$EXECUTION_TASK_DRIVER_TEMPLATE")
EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES=$(awk '/^boundaries:/{flag=1;next}/^```/{flag=0}flag' <<< "$EXECUTION_TASK_DRIVER_TEMPLATE")
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
assert_match "$EXECUTION_BODY" "bf-harness complete <bf-wo>/<task>" "execution completes each task before cleanup"
assert_match "$EXECUTION_BODY" "bf-harness complete <bf-wo>" "execution completes final acceptance through harness"
assert_match "$EXECUTION_BODY" "any task pr is merged" "execution runs cleanup after optional task PR merge"
assert_match "$EXECUTION_BODY" "do not defer task worktree cleanup to final" "execution forbids final-acceptance cleanup deferral"
assert_not_match "$EXECUTION_HARD_GATES" "a task driver may run task review and readiness verification" "execution hard gates should not contain task-driver capability notes"
assert_not_match "$EXECUTION_HARD_GATES" "reruns task \`verify\` after task-driver handoff" "execution hard gates should not duplicate task loop verify steps"
assert_not_match "$EXECUTION_HARD_GATES" "merges task prs, runs task \`complete\`, runs task-scoped \`cleanup\`" "execution hard gates should not duplicate task loop closure steps"
assert_match "$EXECUTION_HARD_GATES" "task-driver proxy mode" "execution hard gates allow explicit task-driver proxy mode"
assert_match "$EXECUTION_HARD_GATES" "missing subagent tool" "execution hard gates scope task-driver proxy mode to missing subagent capability"
assert_match "$EXECUTION_BODY" "task blocks" "execution treats next output as task blocks"
assert_match "$EXECUTION_BODY" "task driver" "execution delegates returned task blocks to task drivers"
assert_match "$EXECUTION_TASK_LOOP" "if \`next\` returns task blocks" "task loop branches on returned task blocks"
assert_match "$EXECUTION_TASK_LOOP" "assign one task driver" "task loop assigns task drivers"
assert_match "$EXECUTION_TASK_LOOP" "each returned task" "task loop scopes assignment to returned tasks"
assert_match "$EXECUTION_TASK_LOOP" "missing subagent tool" "task loop handles task-driver missing subagent tool reports"
assert_match "$EXECUTION_TASK_LOOP" "task-driver proxy mode" "task loop enters task-driver proxy mode when delegation is unavailable"
assert_match "$EXECUTION_TASK_LOOP" "serially" "task loop serializes work in task-driver proxy mode"
assert_match "$EXECUTION_TASK_LOOP" "other returned task blocks" "task loop defers sibling task blocks during coordinator proxy"
assert_not_match "$EXECUTION_TASK_LOOP" "if \`next\` returns task blocks, do not read task specs or pipelines locally" "task loop should not keep an empty no-op branch before assignment"
assert_match "$EXECUTION_TASK_LOOP" "on fail" "task loop handles verify failures"
assert_match "$EXECUTION_TASK_LOOP" "verify result" "task loop reads verify failure results"
assert_match "$EXECUTION_TASK_LOOP" "original task driver" "task loop returns verify failures to the original task driver"
assert_match "$EXECUTION_TASK_LOOP" "when available" "task loop tolerates missing original task driver"
assert_match "$EXECUTION_TASK_LOOP" "wait for completion" "task loop waits for task-driver completion before retry"
assert_match "$EXECUTION_TASK_LOOP" "before rerunning verify" "task loop verifies only after the next handoff"
assert_not_match "$EXECUTION_TASK_LOOP" "require a fresh review round with fresh independent reviewers after fixes" "task loop should not instruct invisible task-driver internals"
assert_match "$EXECUTION_BODY" "## task driver prompt template" "execution provides a task driver prompt template"
assert_match "$EXECUTION_BODY" "use this template when starting or resuming a task driver" "execution scopes the task driver prompt template"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE" "first, read your role instruction: \`roles/task-driver.md\`" "task driver prompt starts by reading task-driver role"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE" "you are task-driver, working on" "task driver prompt identifies the task driver target"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE" "paste the complete task block returned by \`bf-harness next\`" "task driver prompt passes through next output"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS" "follow \`roles/task-driver.md\`" "task driver prompt delegates detailed instructions to the role"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS" "task execution" "task driver prompt delegates task execution to the role"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS" "review" "task driver prompt delegates review to the role"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS" "readiness verification" "task driver prompt delegates readiness verification to the role"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS" "handoff" "task driver prompt delegates handoff to the role"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_INSTRUCTIONS" "report changed files, evidence artifacts" "task driver prompt requires completion handoff evidence"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE" "boundaries:" "task driver prompt separates prohibited actions from instructions"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES" "do not work outside the returned task" "task driver prompt keeps scope boundary under Boundaries"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES" "do not merge prs" "task driver prompt keeps PR merge boundary under Boundaries"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES" "run \`bf-harness complete\`" "task driver prompt keeps complete boundary under Boundaries"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES" "run cleanup" "task driver prompt keeps cleanup boundary under Boundaries"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES" "perform final acceptance" "task driver prompt keeps Final Acceptance boundary under Boundaries"
assert_match "$EXECUTION_TASK_DRIVER_TEMPLATE_BOUNDARIES" "do not edit locked \`bf.md\` or task \`spec.md\` fields" "task driver prompt keeps locked-field boundary under Boundaries"
assert_not_match "$EXECUTION_TASK_DRIVER_TEMPLATE" "run or coordinate task review" "task driver prompt should not duplicate task-driver role execution details"
assert_not_match "$EXECUTION_TASK_DRIVER_TEMPLATE" "if fixes are required after review or verify" "task driver prompt should not duplicate task-driver role retry details"
assert_not_match "$EXECUTION_BODY" "## role-bound worker prompt template" "execution should not carry task-driver worker prompt template"
assert_not_match "$EXECUTION_BODY" "use this template when the coordinator or a task driver starts" "execution should not define shared worker template"
assert_match "$EXECUTION_BODY" "do not read, summarize, or inline the role instruction" "parent actors do not proxy child role prompts"
assert_match "$EXECUTION_BODY" "until each task driver reports completion" "execution waits for task driver completion"
assert_match "$EXECUTION_BODY" "terminate it lightly" "execution avoids killing task drivers prematurely"
assert_match "$EXECUTION_BODY" "prefer the original task driver" "execution prefers original task driver for verify fixes"
assert_match "$EXECUTION_BODY" "fresh independent reviewers" "execution requires fresh reviewers after fixes"
assert_match "$EXECUTION_BODY" "if \`next\` returns no eligible task, enter final acceptance" "execution enters Final Acceptance when next is empty"
assert_match "$EXECUTION_BODY" "start final acceptance by running \`bf-harness status <bf-wo>\`" "Final Acceptance starts with status"
assert_match "$EXECUTION_BODY" "status says all tasks are completed" "execution uses status fact for Final Acceptance readiness"
assert_match "$EXECUTION_BODY" "coordinator-owned action" "Final Acceptance retry permits coordinator-owned fixes"
assert_match "$EXECUTION_BODY" "fresh review round" "Final Acceptance retry requires a fresh review round"
assert_match "$EXECUTION_BODY" "fresh independent reviewers" "Final Acceptance retry requires fresh independent reviewers"
assert_match "$EXECUTION_BODY" "verify again" "Final Acceptance retry reruns verification"
assert_not_match "$EXECUTION_BODY" "if \`next\` returns no eligible task, run \`bf-harness status <bf-wo>\`" "task loop should not status-gate before Final Acceptance"
assert_not_match "$EXECUTION_BODY" "the coordinator runs \`start-review\`, dispatches bf acceptance reviewers, and runs \`verify\`" "execution should not keep old coordinator-only task review wording"
assert_not_match "$EXECUTION_BODY" "no task block has been returned by" "execution should not stop before status when next is empty"
assert_not_match "$EXECUTION_BODY" "tasking=0" "execution should not encode task state counters in prompt"
assert_not_match "$EXECUTION_BODY" "ready=0" "execution should not encode task state counters in prompt"
assert_not_match "$EXECUTION_BODY" "draft=0" "execution should not encode task state counters in prompt"
assert_match "$EXECUTION_BODY" "unmerged branch" "execution documents retained cleanup items"
assert_match "$EXECUTION_BODY" "decision brief" "execution applies decision briefs to material user decision gates"
assert_match "$EXECUTION_BODY" "decision-brief input to the coordinator" "execution routes delegated actor decision briefs through coordinator"

PROJECT_DOCS_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/project-docs.md")
assert_match "$PROJECT_DOCS_BODY" "decision brief" "project-docs applies decision briefs to material design-doc decisions"

FEEDBACK_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/references/feedback.md")
assert_match "$FEEDBACK_BODY" "decision brief" "feedback applies decision briefs before material filing decisions"

REVIEW_TEMPLATE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/templates/review-result.md")
assert_match "$REVIEW_TEMPLATE_BODY" "at least one provider-role review file" "review template matches provider-role signoff semantics"
assert_not_match "$REVIEW_TEMPLATE_BODY" "all required reviewer" "review template must not imply all provider roles must sign"

CORE_CONSTRAINTS_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/core-constraints.md")
assert_match "$CORE_CONSTRAINTS_BODY" "core security role owns" "core constraints record security role ownership"
assert_match "$CORE_CONSTRAINTS_BODY" "security-review" "core constraints record security-review capability"

ARCHITECTURE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/architecture.md")
assert_match "$ARCHITECTURE_BODY" "repository maintenance is governed by \`agents.md\`" "architecture keeps repository maintenance authority in AGENTS.md"
assert_match "$ARCHITECTURE_BODY" "not a repo-maintenance skill or pack" "architecture does not introduce a repo-maintenance replacement"
assert_match "$ARCHITECTURE_BODY" "security-review" "architecture records security-review capability authority"

PACKS_PIPELINES_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/docs/spec/packs-and-pipelines.md")
assert_match "$PACKS_PIPELINES_BODY" "three independent reviewer actor instances with the" "pipeline docs fix local pipeline review count"
assert_match "$PACKS_PIPELINES_BODY" "\`pipeline-review\` capability" "pipeline docs name pipeline-review as capability"
assert_match "$PACKS_PIPELINES_BODY" "pipeline review" "pipeline docs distinguish pipeline review"
assert_match "$PACKS_PIPELINES_BODY" "bf acceptance" "pipeline docs distinguish BF acceptance"
assert_match "$PACKS_PIPELINES_BODY" "not task-local side effects" "pipeline docs keep worktree cleanup outside task closure"
assert_match "$PACKS_PIPELINES_BODY" "bf-harness cleanup <bf-wo>" "pipeline docs assign cleanup to coordinator after Final Acceptance"
assert_match "$PACKS_PIPELINES_BODY" "\`code-deep-audit\`" "pipeline docs record built-in code-deep-audit pipeline"
assert_match "$PACKS_PIPELINES_BODY" "review-only deep codebase audit" "pipeline docs record audit boundary"
assert_match "$PACKS_PIPELINES_BODY" "command safety" "pipeline docs record command safety guidance"
assert_match "$PACKS_PIPELINES_BODY" "severity" "pipeline docs record finding severity guidance"
assert_match "$PACKS_PIPELINES_BODY" "security role" "pipeline docs record security role ownership"

ENGINEERING_PACK_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/packs/engineering/pack.md")
assert_match "$ENGINEERING_PACK_BODY" "small enough that one host-compatible task driver can finish it" "engineering breakdown avoids engineer subagent task ownership"
assert_not_match "$ENGINEERING_PACK_BODY" "pick doers" "engineering pack avoids stale doer vocabulary"

TASK_DRIVER_OPERATING_RULES=$(awk '/^## Operating Rules/{flag=1;next}/^## /{flag=0}flag' "$REPO_ROOT/roles/task-driver.md" | tr '[:upper:]' '[:lower:]')
assert_match "$TASK_DRIVER_OPERATING_RULES" "immediately check" "task-driver startup checks runtime capability immediately"
assert_match "$TASK_DRIVER_OPERATING_RULES" "subagent tool" "task-driver startup checks for subagent tool availability"
assert_match "$TASK_DRIVER_OPERATING_RULES" "missing subagent tool" "task-driver reports missing subagent tool distinctly"
assert_match "$TASK_DRIVER_OPERATING_RULES" "coordinator proxy" "task-driver hands task-driver work to coordinator proxy when subagent tool is missing"
assert_match "$TASK_DRIVER_OPERATING_RULES" "before reading the task spec" "task-driver performs subagent capability check before task work"

TASK_DRIVER_REVIEW_RULE=$(awk '
  /^- Run or coordinate task review and readiness verification/ { flag=1 }
  /^- Start every role-bound worker prompt/ { flag=0 }
  flag { print }
' "$REPO_ROOT/roles/task-driver.md" | tr '[:upper:]' '[:lower:]')
assert_match "$TASK_DRIVER_REVIEW_RULE" "fresh independent reviewers" "task-driver retry requires fresh independent reviewers"
assert_not_match "$TASK_DRIVER_REVIEW_RULE" "fresh independent reviewers when possible" "task-driver retry must not make fresh reviewers optional"
assert_not_match "$TASK_DRIVER_REVIEW_RULE" "when possible before retrying readiness verification" "task-driver retry must not use permissive readiness-verification wording"
assert_match "$TASK_DRIVER_REVIEW_RULE" "host runtime cannot provide reviewers or readiness verification" "task-driver handles unsupported review/readiness capability"
assert_match "$TASK_DRIVER_REVIEW_RULE" "stop" "task-driver unsupported review/readiness capability stops"
assert_match "$TASK_DRIVER_REVIEW_RULE" "report" "task-driver unsupported review/readiness capability reports"
assert_match "$TASK_DRIVER_REVIEW_RULE" "coordinator" "task-driver unsupported review/readiness capability hands off to coordinator"
assert_match "$TASK_DRIVER_REVIEW_RULE" "do not retry verification" "task-driver missing review/readiness gate blocks verification retry"
assert_match "$TASK_DRIVER_REVIEW_RULE" "claim readiness" "task-driver missing review/readiness gate blocks readiness claim"
assert_match "$TASK_DRIVER_REVIEW_RULE" "missing gate" "task-driver missing review/readiness gate must be resolved before proceeding"

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
      assert_match "$ROLE_BODY" "## role-bound worker prompt template" "task-driver role owns worker prompt template"
      assert_match "$ROLE_BODY" "first, read your role instruction: \`roles/<role-id>.md\`" "task-driver worker prompt starts by reading own role"
      assert_match "$ROLE_BODY" "you are <role-id>, working on" "task-driver worker prompt identifies the role and stage target"
      ;;
  esac
  assert_match "$ROLE_BODY" "read \`discussion.md\` only when" "$role role handles discussion ambiguity recovery"
  assert_match "$ROLE_BODY" "report the ambiguity to the coordinator" "$role role returns unresolved ambiguity to coordinator"
done

for role in architect engineer pipeline-designer security task-driver tester; do
  ROLE_BODY=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/roles/$role.md")
  assert_match "$ROLE_BODY" "decision-brief input to the coordinator" "$role role routes material user decisions through the coordinator"
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
  | grep -v -E "Codex subagent|Codex, that actor is a Codex subagent|Codex subagent can be|Codex uses subagent actors for task drivers, leaf workers, and reviewers|Claude Code uses subagents for leaf workers and reviewers|subagent tool" \
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

pass
