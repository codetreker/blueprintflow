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

# --- Variation J (round-2 bypass): the four EMPTY canonical severity headings
#     PLUS a sibling non-severity `### Summary` carrying a real blocker. The
#     existential check passes (an empty `### Blocker` exists) and never scans the
#     Summary. UNIVERSAL rule: any non-severity content under `## Results` is a
#     parse error -> acceptedIds dropped. ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### Blocker
### High
### Minor
### Nit

### Summary

The change writes the password to the log in cleartext. Blocking.

## Accepted Criteria

- AC-1: signed despite the sibling Summary blocker
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError true "sibling non-severity subheading under Results must be a parse error"
assert_json_field "$STDOUT" .acceptedIds '[]' "sibling non-severity subheading must drop acceptedIds"

# --- Variation K: a recognized severity heading WITH a real finding AND a sibling
#     non-severity `### Notes` subheading carrying content -> still fail closed
#     (universal: the unrecognized sibling alone makes it a parse error). ---
INPUT=$(cat <<'EOF'
# Desc

## Results

### Blocker

- src/auth.mjs:5 missing authz check

### Notes

Extra reviewer commentary that the parser must not silently accept.

## Accepted Criteria

- AC-1: signed
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError true "non-severity sibling alongside a real finding must still fail closed"
assert_json_field "$STDOUT" .acceptedIds '[]' "non-severity sibling must drop acceptedIds even with a real finding"

# --- Variation L: substantive prose directly under `## Results` outside any
#     severity heading (with empty severity subheadings after) -> parse error. ---
INPUT=$(cat <<'EOF'
# Desc

## Results

Overall this looks fine to me, shipping it.

### Blocker
### High
### Minor
### Nit

## Accepted Criteria

- AC-1: signed despite the direct prose
EOF
)
parse "$INPUT"
assert_json_field "$STDOUT" .parseError true "substantive prose directly under Results must be a parse error"
assert_json_field "$STDOUT" .acceptedIds '[]' "direct prose under Results must drop acceptedIds"

pass
