export function parseFrontmatter(text) {
  const lines = text.split("\n");
  if (lines[0] !== "---") {
    return { frontmatter: {}, body: text };
  }
  let end = -1;
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") { end = i; break; }
  }
  if (end === -1) {
    throw new Error("unterminated frontmatter: missing closing ---");
  }
  const fm = {};
  let currentKey = null;
  for (let i = 1; i < end; i++) {
    const line = lines[i];
    if (line === "" || /^\s*#/.test(line)) continue;
    const listMatch = line.match(/^\s+-\s+(.+)$/);
    if (listMatch && currentKey) {
      if (!Array.isArray(fm[currentKey])) fm[currentKey] = [];
      fm[currentKey].push(listMatch[1].trim());
      continue;
    }
    const kvMatch = line.match(/^([A-Za-z][\w-]*)\s*:\s*(.*)$/);
    if (!kvMatch) {
      throw new Error(`invalid frontmatter line: ${JSON.stringify(line)}`);
    }
    const [, key, value] = kvMatch;
    currentKey = key;
    if (value === "") {
      fm[key] = [];
    } else {
      fm[key] = value.trim();
    }
  }
  const body = lines.slice(end + 1).join("\n");
  return { frontmatter: fm, body };
}
