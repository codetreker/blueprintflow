// Mutation-whitelist primitives: every in-place edit to bf.md / spec.md goes
// through one of these helpers (flipCheckbox, writeState, writeUpdated, and
// task execution metadata writers). The formatTimestamp helper produces the
// canonical "YYYY-MM-DD HH:MM" string used by writeUpdated and the verify
// result writer.
import { assertTransition } from "./state-machine.mjs";
import { parseTaskSpec } from "./parse-task-spec.mjs";

const ALL_STATES = new Set(["Draft", "Accepted", "Implementing", "Completed", "Ready", "Tasking"]);
const TASK_METADATA_KEYS = new Map([
  ["branch", "Branch"],
  ["worktree", "Worktree"],
  ["pullRequest", "Pull-Request"],
]);

export function flipCheckbox(text, acId) {
  const lines = text.split("\n");
  const idRe = new RegExp(`^- \\[( |x)\\] ${acId.replace(/[-/\\^$*+?.()|[\]{}]/g, "\\$&")}\\|`);
  let hit = false;
  const out = lines.map(line => {
    const m = line.match(idRe);
    if (!m) return line;
    hit = true;
    if (m[1] === "x") return line;
    return line.replace("- [ ]", "- [x]");
  });
  if (!hit) throw new Error(`AC id not found: ${acId}`);
  return out.join("\n");
}

export function writeState(text, newState, { kind, allowSame = true } = {}) {
  if (!ALL_STATES.has(newState)) throw new Error(`invalid state: ${newState}`);
  if (!kind) throw new Error("writeState requires { kind: 'bf' | 'taskSpec' }");
  const lines = text.split("\n");
  if (lines[0] !== "---") throw new Error("no frontmatter");
  let end = -1;
  for (let i = 1; i < lines.length; i++) if (lines[i] === "---") { end = i; break; }
  if (end === -1) throw new Error("unterminated frontmatter");
  let oldState = null;
  let stateLineIdx = -1;
  for (let i = 1; i < end; i++) {
    const m = lines[i].match(/^State\s*:\s*(.+)$/);
    if (m) { oldState = m[1].trim(); stateLineIdx = i; break; }
  }
  if (stateLineIdx === -1) throw new Error("State field missing in frontmatter");
  if (oldState === newState) {
    if (allowSame) return text;
    throw new Error(`already in state ${newState}`);
  }
  assertTransition(kind, oldState, newState);
  lines[stateLineIdx] = `State: ${newState}`;
  return lines.join("\n");
}

export function formatTimestamp(date = new Date()) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

export function writeUpdated(text, timestamp) {
  const lines = text.split("\n");
  if (lines[0] !== "---") throw new Error("no frontmatter");
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") { end = i; break; }
  }
  if (end === -1) throw new Error("unterminated frontmatter");
  for (let i = 1; i < end; i++) {
    if (/^Updated\s*:/.test(lines[i])) {
      lines[i] = `Updated: ${timestamp}`;
      return lines.join("\n");
    }
  }
  lines.splice(end, 0, `Updated: ${timestamp}`);
  return lines.join("\n");
}

// Mode B accept-lock anchor (5.5). At accept the harness stamps the effective
// integration mode into a `Mode-Lock:` bf.md frontmatter field. validate-wo then
// rejects (INTEGRATION_LOCKED) any post-accept Integration value that diverges
// from this anchor. Like writeState/writeUpdated this is a whitelisted mutation:
// the LLM never writes Mode-Lock; only the harness does, atomically with accept.
export function writeModeLock(text, mode) {
  if (typeof mode !== "string" || mode === "") {
    throw new Error("writeModeLock requires a non-empty mode string");
  }
  const lines = text.split("\n");
  if (lines[0] !== "---") throw new Error("no frontmatter");
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") { end = i; break; }
  }
  if (end === -1) throw new Error("unterminated frontmatter");
  for (let i = 1; i < end; i++) {
    if (/^Mode-Lock\s*:/.test(lines[i])) {
      lines[i] = `Mode-Lock: ${mode}`;
      return lines.join("\n");
    }
  }
  lines.splice(end, 0, `Mode-Lock: ${mode}`);
  return lines.join("\n");
}

export function writeTaskExecutionMetadata(text, metadata = {}) {
  const lines = text.split("\n");
  if (lines[0] !== "---") throw new Error("no frontmatter");
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") { end = i; break; }
  }
  if (end === -1) throw new Error("unterminated frontmatter");
  for (let i = 1; i < end; i++) {
    if (/^Id\s*:/.test(lines[i])) throw new Error("writeTaskExecutionMetadata requires a task spec");
  }
  try {
    parseTaskSpec(text);
  } catch (err) {
    throw new Error(`writeTaskExecutionMetadata requires a task spec: ${err.message}`);
  }

  for (const [inputKey, fmKey] of TASK_METADATA_KEYS.entries()) {
    if (!(inputKey in metadata)) continue;
    const value = metadata[inputKey] == null ? "" : String(metadata[inputKey]);
    let found = false;
    for (let i = 1; i < end; i++) {
      if (new RegExp(`^${fmKey}\\s*:`).test(lines[i])) {
        lines[i] = value ? `${fmKey}: ${value}` : `${fmKey}:`;
        found = true;
        break;
      }
    }
    if (!found) {
      lines.splice(end, 0, value ? `${fmKey}: ${value}` : `${fmKey}:`);
      end++;
    }
  }
  return lines.join("\n");
}

// WO-level Pull-Request writer for Mode B (single-pr). The shared WO PR URL lives
// in bf.md frontmatter (§1.4) — written ONCE, idempotent on the same URL, and
// FAIL-CLOSED on an attempt to overwrite a different non-empty URL (so an attach
// cannot silently re-point the WO PR). Like the other writers this is a
// whitelisted mutation; the LLM never writes Pull-Request, only the harness does.
export function writeWoPullRequest(text, url) {
  if (typeof url !== "string" || url.trim() === "") {
    throw new Error("writeWoPullRequest requires a non-empty URL");
  }
  const value = url.trim();
  const lines = text.split("\n");
  if (lines[0] !== "---") throw new Error("no frontmatter");
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") { end = i; break; }
  }
  if (end === -1) throw new Error("unterminated frontmatter");
  for (let i = 1; i < end; i++) {
    const m = lines[i].match(/^Pull-Request\s*:\s*(.*)$/);
    if (m) {
      const existing = m[1].trim();
      if (existing !== "" && existing !== value) {
        throw new Error(`Pull-Request already set to a different URL: ${existing}`);
      }
      lines[i] = `Pull-Request: ${value}`;
      return lines.join("\n");
    }
  }
  lines.splice(end, 0, `Pull-Request: ${value}`);
  return lines.join("\n");
}
