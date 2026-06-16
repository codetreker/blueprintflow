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

pass
