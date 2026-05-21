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
