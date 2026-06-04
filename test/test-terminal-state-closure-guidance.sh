#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

assert_file_contains_all() {
  local file="$1" label="$2"
  shift 2

  local body
  body=$(tr '[:upper:]' '[:lower:]' < "$REPO_ROOT/$file")

  for term in "$@"; do
    case "$body" in
      *"$term"*) ;;
      *) fail "$label should mention '$term'" ;;
    esac
  done
}

assert_file_contains_all \
  "roles/pipeline-designer.md" \
  "pipeline-designer role" \
  "external artifact" \
  "side effect" \
  "terminal state" \
  "closure" \
  "handoff" \
  "user-perspective"

assert_file_contains_all \
  "references/spec-authoring.md" \
  "spec authoring guidance" \
  "bf-wo local pipeline" \
  "terminal-state closure" \
  "pipeline-review" \
  "dangling"

assert_file_contains_all \
  "templates/pipeline.yml" \
  "pipeline template" \
  "external artifact" \
  "closure stage" \
  "handoff" \
  "user-perspective done state"

pass
