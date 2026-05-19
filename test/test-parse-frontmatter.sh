#!/usr/bin/env bash
set -u
source "$(dirname "$0")/test-helpers.sh"

run_parser() {
  local input="$1"
  STDOUT=$(node --input-type=module -e "
    import('$REPO_ROOT/bin/lib/parse-frontmatter.mjs').then(m => {
      try {
        const r = m.parseFrontmatter(process.argv[1]);
        process.stdout.write(JSON.stringify(r));
      } catch (e) {
        process.stdout.write(JSON.stringify({ error: e.message }));
      }
    });
  " -- "$input")
}

# Case A: scalar + list
run_parser "$(printf -- '---\nId: foo\nCapabilities:\n  - cap-a\n  - cap-b\n---\n# Body\n')"
assert_json_field "$STDOUT" .frontmatter.Id "foo"
assert_json_field "$STDOUT" .frontmatter.Capabilities '["cap-a","cap-b"]'
assert_match "$STDOUT" "# Body" "body included"

# Case B: 没 frontmatter
run_parser "$(printf '# Just body\n')"
assert_json_field "$STDOUT" .frontmatter '{}'

# Case C: unterminated → error
run_parser "$(printf -- '---\nId: foo\n# missing closing\n')"
assert_match "$STDOUT" "unterminated frontmatter" "unterminated error"

# Case D: 非法行
run_parser "$(printf -- '---\nnot a kv line\n---\n')"
assert_match "$STDOUT" "invalid frontmatter line" "invalid line error"

pass
