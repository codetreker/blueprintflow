# test/test-helpers.sh — sourced by every test-*.sh
# 提供：assert_eq / assert_match / assert_not_match / assert_json_field / make_temp_home /
#       copy_fixture / run_bf / run_bfh / pass / fail
# 约定：失败 → echo 并 exit 1；成功 → 静默；最后调 pass 输出 "PASS"

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BF="$REPO_ROOT/bin/bf.mjs"
BFH="$REPO_ROOT/bin/bf-harness.mjs"
FIXTURES="$REPO_ROOT/test/fixtures"

fail() { echo "FAIL: $*" >&2; exit 1; }

pass() { echo "PASS"; exit 0; }

assert_eq() {
  local got="$1" expected="$2" msg="${3:-}"
  if [ "$got" != "$expected" ]; then
    fail "$msg: expected '$expected', got '$got'"
  fi
}

assert_match() {
  local haystack="$1" needle="$2" msg="${3:-}"
  case "$haystack" in
    *"$needle"*) ;;
    *) fail "$msg: '$haystack' does not contain '$needle'" ;;
  esac
}

assert_not_match() {
  local haystack="$1" needle="$2" msg="${3:-}"
  case "$haystack" in
    *"$needle"*) fail "$msg: '$haystack' unexpectedly contains '$needle'" ;;
  esac
}

# assert_json_field <json-string> <dot-path> <expected-value>
# 例：assert_json_field "$out" .ok true
assert_json_field() {
  local json="$1" path="$2" expected="$3"
  local got
  got=$(node -e "
    const j = JSON.parse(process.argv[1]);
    const p = process.argv[2].replace(/^\\./, '').split('.');
    let v = j;
    for (const k of p) { v = v?.[k]; }
    process.stdout.write(typeof v === 'string' ? v : JSON.stringify(v));
  " "$json" "$path")
  assert_eq "$got" "$expected" "json field $path"
}

make_temp_home() {
  mktemp -d -t bf-test-XXXXXX
}

# copy_fixture <fixture-name> <dest-dir>
copy_fixture() {
  local name="$1" dest="$2"
  if [ ! -d "$FIXTURES/$name" ]; then
    fail "fixture not found: $name"
  fi
  mkdir -p "$dest"
  cp -R "$FIXTURES/$name/." "$dest/"
}

write_local_pipeline() {
  local file="$1" id="$2"
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<EOF
id: $id
desc: Local pipeline $id
instruction: |
  Follow this local pipeline for the task.
stages:
  - id: implementation
    capability: software-implementation
    instruction: |
      Implement the task and produce the required evidence.
EOF
}

# run_bf <args...> → 把 stdout 打到全局变量 STDOUT，stderr 打到 STDERR，exit code 打到 RC
run_bf() {
  STDOUT=$(node "$BF" "$@" 2>/tmp/bf-test-stderr.$$) ; RC=$?
  STDERR=$(cat /tmp/bf-test-stderr.$$ 2>/dev/null || true)
  rm -f /tmp/bf-test-stderr.$$
}

run_bfh() {
  STDOUT=$(node "$BFH" "$@" 2>/tmp/bfh-test-stderr.$$) ; RC=$?
  STDERR=$(cat /tmp/bfh-test-stderr.$$ 2>/dev/null || true)
  rm -f /tmp/bfh-test-stderr.$$
}
