const VALID = new Set(["Draft", "Accepted", "Implementing", "Completed", "Ready", "Tasking"]);

export function writeState(text, newState) {
  if (!VALID.has(newState)) throw new Error(`invalid state: ${newState}`);
  const lines = text.split("\n");
  if (lines[0] !== "---") throw new Error("no frontmatter");
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") { end = i; break; }
  }
  if (end === -1) throw new Error("unterminated frontmatter");
  let hit = false;
  for (let i = 1; i < end; i++) {
    if (/^State\s*:/.test(lines[i])) {
      lines[i] = `State: ${newState}`;
      hit = true;
      break;
    }
  }
  if (!hit) throw new Error("State field missing in frontmatter");
  return lines.join("\n");
}
