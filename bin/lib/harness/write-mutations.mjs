// Mutation-whitelist primitives: every in-place edit to bf.md / spec.md goes
// through one of these helpers (flipCheckbox, writeState, writeUpdated). The
// formatTimestamp helper produces the canonical "YYYY-MM-DD HH:MM" string used
// by writeUpdated and the verify result writer.
import { assertTransition } from "./state-machine.mjs";

const ALL_STATES = new Set(["Draft", "Accepted", "Implementing", "Completed", "Ready", "Tasking"]);

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
