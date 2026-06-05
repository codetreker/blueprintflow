#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

FILE="$REPO_ROOT/packs/engineering/pipelines/feature.yml"
[ -f "$FILE" ] || fail "missing feature pipeline"

body=$(tr '[:upper:]' '[:lower:]' < "$FILE")

for term in \
  "id: feature" \
  "design-first" \
  "architecture-design" \
  "implementation-design" \
  "evidence plan" \
  "design-doc-sync" \
  "validation" \
  "not-applicable evidence" \
  "independent review" \
  "does not require red-first tdd"; do
  case "$body" in
    *"$term"*) ;;
    *) fail "feature pipeline should mention '$term'" ;;
  esac
done

pass
