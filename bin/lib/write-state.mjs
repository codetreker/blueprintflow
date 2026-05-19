import { assertTransition } from "./state-machine.mjs";

const ALL_STATES = new Set(["Draft", "Accepted", "Implementing", "Completed", "Ready", "Tasking"]);

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
