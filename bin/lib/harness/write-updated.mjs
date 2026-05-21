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
