#!/usr/bin/env bash
set -e

# Deterministic patterns only — no LLM call
expect_transcribe() {
  local input="$1"
  local expected_verb="$2"
  OUT=$(node -e "
    import('./bin/lib/dispatcher/nl-parse.mjs').then(m => {
      const r = m.transcribeDeterministic(${input});
      console.log(JSON.stringify(r));
    });
  ")
  echo "$OUT" | grep -q "\"verb\":\"$expected_verb\"" || {
    echo "FAIL: '$input' did not transcribe to '$expected_verb' (got: $OUT)"
    exit 1
  }
}

expect_transcribe '["show","auth-v1"]'                    show
expect_transcribe '["tree"]'                              tree
expect_transcribe '["list","--state","doing"]'            list
# Mixed-case / unknown verb → null (LLM would handle)
OUT=$(node -e "
  import('./bin/lib/dispatcher/nl-parse.mjs').then(m => {
    const r = m.transcribeDeterministic(['帮我搞定','auth-v1']);
    console.log(JSON.stringify(r));
  });
")
echo "$OUT" | grep -q '"verb":null' || { echo "FAIL: non-deterministic input should return null"; exit 1; }

echo "PASS: deterministic NL transcription"
