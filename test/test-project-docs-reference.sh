#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"
require_cmd rg  # fail closed if ripgrep is absent — the .tasks guard below would otherwise pass vacuously

PROJECT_DOCS="$REPO_ROOT/references/project-docs.md"

[ -f "$PROJECT_DOCS" ] || fail "missing references/project-docs.md"

grep -q "^# Project Docs$" "$PROJECT_DOCS" || fail "project docs reference must have stable H1"
grep -q "Doc Root Discovery" "$PROJECT_DOCS" || fail "project docs reference must define doc-root discovery"
grep -q "reuse that root" "$PROJECT_DOCS" || fail "project docs reference must reuse recorded confirmed roots"
grep -q "governing project instruction file" "$PROJECT_DOCS" || fail "project docs reference must require confirmed-root persistence prompt"
grep -q "Record the answer in" "$PROJECT_DOCS" || fail "project docs reference must record persistence answer"
grep -q "accepted contract" "$PROJECT_DOCS" || fail "project docs reference must route persistence through BF contract"
grep -q "out-of-band command" "$PROJECT_DOCS" || fail "project docs reference must allow explicit user-command persistence"
grep -q "single source of truth" "$PROJECT_DOCS" || fail "project docs reference must define design-doc authority"
grep -q "design drift" "$PROJECT_DOCS" || fail "project docs reference must define drift handling"
grep -q "Return To Design" "$PROJECT_DOCS" || fail "project docs reference must define return-to-design behavior"
grep -q "Do not edit locked" "$PROJECT_DOCS" || fail "project docs reference must forbid direct locked contract edits"

for file in SKILL.md references/brainstorm.md references/spec-authoring.md references/execution.md; do
  grep -q "project-docs.md" "$REPO_ROOT/$file" || fail "$file must reference project-docs.md"
done

if rg -n "\.tasks" "$REPO_ROOT/SKILL.md" "$REPO_ROOT/references" "$REPO_ROOT/roles" "$REPO_ROOT/packs" "$REPO_ROOT/templates" >/tmp/bf-project-docs-runtime.$$; then
  cat /tmp/bf-project-docs-runtime.$$ >&2
  rm -f /tmp/bf-project-docs-runtime.$$
  fail "runtime artifacts must not define .tasks as a BF runtime directory"
fi
rm -f /tmp/bf-project-docs-runtime.$$

pass
