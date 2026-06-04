#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file() {
  [[ -f "$ROOT/$1" ]] || fail "$1 missing"
}

assert_contains() {
  local file=$1
  local pattern=$2
  grep -qE "$pattern" "$ROOT/$file" || fail "$file missing pattern: $pattern"
}

assert_not_contains() {
  local file=$1
  local pattern=$2
  ! grep -qE "$pattern" "$ROOT/$file" || fail "$file should not contain pattern: $pattern"
}

assert_file references/feedback.md
assert_contains SKILL.md "references/feedback\\.md"
assert_contains SKILL.md "BF GitHub issue feedback"

assert_contains references/feedback.md "explicitly asks"
assert_contains references/feedback.md "codetreker/blueprintflow"
assert_contains references/feedback.md "https://github\\.com/codetreker/blueprintflow/issues"
assert_contains references/feedback.md "reuse an existing issue"
assert_contains references/feedback.md "personal preference"
assert_contains references/feedback.md "reproducible"
assert_contains references/feedback.md "outside BF's scope"
assert_contains references/feedback.md "fully covers"
assert_contains references/feedback.md "secrets|tokens|sensitive"
assert_contains references/feedback.md "search query"
assert_contains references/feedback.md "GitHub issue search is unavailable"
assert_contains references/feedback.md "duplicate search unavailable"
assert_contains references/feedback.md "duplicate search results"
assert_contains references/feedback.md "filing decision"
assert_contains references/feedback.md "redacted draft"
assert_contains references/feedback.md "target action"
assert_contains references/feedback.md "final user confirmation"
assert_not_contains references/feedback.md "[Rr]eaction"

mapfile -t templates < <(find "$ROOT/.github/ISSUE_TEMPLATE" -maxdepth 1 -type f | sort)
[[ ${#templates[@]} -eq 1 ]] || fail "expected exactly one GitHub issue template, found ${#templates[@]}"
[[ ${templates[0]} == "$ROOT/.github/ISSUE_TEMPLATE/feedback.yml" ]] || fail "expected unified feedback.yml template"

assert_contains .github/ISSUE_TEMPLATE/feedback.yml "name: Feedback"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Feedback type"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Impact"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Context"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Duplicate search result"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Filing rationale"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Redaction confirmation"
assert_contains .github/ISSUE_TEMPLATE/feedback.yml "Expected outcome"

assert_file docs/spec/feedback.md
assert_contains docs/spec.md "spec/feedback\\.md"
assert_not_contains docs/spec/feedback.md "[Rr]eaction"

pkg_version=$(jq -r '.version' "$ROOT/package.json")
lock_top_version=$(jq -r '.version' "$ROOT/package-lock.json")
lock_version=$(jq -r '.packages[""].version' "$ROOT/package-lock.json")
[[ "$pkg_version" == "$lock_top_version" ]] || fail "package and package-lock top-level versions differ: $pkg_version vs $lock_top_version"
[[ "$pkg_version" == "$lock_version" ]] || fail "package and package-lock root package versions differ: $pkg_version vs $lock_version"

if git -C "$ROOT" rev-parse --verify -q "origin/main^{commit}" >/dev/null; then
  merge_base=$(git -C "$ROOT" merge-base HEAD origin/main)
  release_changed=false
  while IFS= read -r path; do
    case "$path" in
      bin/*|scripts/*|SKILL.md|roles/*|packs/*|templates/*|references/*|package.json)
        release_changed=true
        ;;
    esac
  done < <(git -C "$ROOT" diff --name-only "$merge_base"...HEAD)

  version_output=$("$ROOT/.github/scripts/validate-bf-version.sh" origin/main 2>&1) || fail "$version_output"
  if [[ "$release_changed" == true ]]; then
    echo "$version_output" | grep -q "version bump valid" || fail "expected version gate to confirm a release version bump"
  fi
fi

echo "PASS"
