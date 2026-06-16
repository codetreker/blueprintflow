#!/usr/bin/env bash
# Regression for audit #1: the review-result parser must detect severity findings
# tolerantly (case-insensitive, singular/plural headings, any non-empty content
# line, findings directly under `## Results`, no `## Results` wrapper), and must
# fail CLOSED when a file carries Accepted Criteria but no recognizable Results
# section — refusing to honor that file's acceptedIds.
set -u
source "$(dirname "$0")/test-helpers.sh"

parse() {
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/harness/parse-review-result.mjs').then(m => {
      process.stdout.write(JSON.stringify(m.parseReviewResult(process.argv[1])));
    });
  " -- "$1")
}

# --- Variation A: plural heading '### Blockers' counts as a blocker finding ---
INPUT=$(cat <<'EOF'
# Desc

review round 1.

## Results

### Blockers

- src/api.mjs:23 missing password hash

### High

## Accepted Criteria

- AC-1: looks fine
EOF
)
parse "$INPUT"
assert_match "$STDOUT" "missing password hash" "plural '### Blockers' must yield a blocker finding"
assert_not_match "$STDOUT" '"blocker":[]' "plural '### Blockers' must not be empty"

# --- Variation B: lowercase '### blocker' counts ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### blocker

- lowercase blocker line

## Accepted Criteria

- AC-1: ok
EOF
)
parse "$INPUT"
assert_match "$STDOUT" "lowercase blocker line" "lowercase '### blocker' must yield a finding"

# --- Variation C: deeper '#### Blocker' heading counts ---
INPUT=$(cat <<'EOF'
# Desc

## Results

#### Blocker

- deeper-heading blocker line

## Accepted Criteria

- AC-1: ok
EOF
)
parse "$INPUT"
assert_match "$STDOUT" "deeper-heading blocker line" "'#### Blocker' must yield a finding"

# --- Variation D: prose (non-bullet) content under a severity heading counts ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### Blocker

This is a prose blocker without a bullet marker.

## Accepted Criteria

- AC-1: ok
EOF
)
parse "$INPUT"
assert_match "$STDOUT" "prose blocker" "non-bullet prose under a severity heading must count"

# --- Variation E: clean file (empty severity sections) stays clean ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### Blocker
### High
### Minor
### Nit

## Accepted Criteria

- AC-1: signed
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .severities.blocker '[]'
assert_json_field "$STDOUT" .severities.high '[]'
assert_json_field "$STDOUT" .acceptedIds '["AC-1"]'

# --- Variation F: Accepted Criteria present but NO recognizable Results section
#     -> fail CLOSED: parseError set AND acceptedIds NOT honored. ---
INPUT=$(cat <<'EOF'
# Desc

review with no results wrapper

## Accepted Criteria

- AC-1: signed despite missing Results
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError true "missing Results section must be a parse error"
assert_json_field "$STDOUT" .acceptedIds '[]' "unparseable Results must drop acceptedIds"

# --- Variation G: `## Results` EXISTS but holds only a NON-severity subheading
#     (`### Summary`) describing a real blocker -> fail CLOSED. The Results
#     section has no recognized severity subheading and no direct findings, so it
#     is unstructured: parseError set, acceptedIds dropped. ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### Summary

The implementation ships a hardcoded credential and must NOT be accepted.

## Accepted Criteria

- AC-1: signed despite the unstructured Results
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError true "Results with only a non-severity subheading must be a parse error"
assert_json_field "$STDOUT" .acceptedIds '[]' "unstructured Results must drop acceptedIds"

# --- Variation H: blocker described only in `# Desc`, with an EMPTY `## Results`
#     that has no severity subheading and no findings -> fail CLOSED. ---
INPUT=$(cat <<'EOF'
# Desc

Blocker: this change leaks a secret token in logs.

## Results

## Accepted Criteria

- AC-1: signed despite the empty unstructured Results
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError true "empty unstructured Results must be a parse error"
assert_json_field "$STDOUT" .acceptedIds '[]' "empty unstructured Results must drop acceptedIds"

# --- Variation I (backward-compat guard): a CLEAN canonical file with the four
#     EMPTY severity subheadings is recognized structure -> NOT a parse error,
#     acceptedIds honored. ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### Blocker
### High
### Minor
### Nit

## Accepted Criteria

- AC-1: clean signoff
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError false "empty recognized severity subheadings are recognized structure"
assert_json_field "$STDOUT" .acceptedIds '["AC-1"]' "clean canonical file must still honor acceptedIds"

pass
