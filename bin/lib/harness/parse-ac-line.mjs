const AC_RE = /^- \[( |x)\] ([A-Za-z][\w-]*)\|([A-Za-z][\w-]*):\s*(.+)$/;

export function parseAcLine(line) {
  const m = line.match(AC_RE);
  if (!m) return null;
  const [, mark, id, capability, text] = m;
  return {
    id,
    capability,
    text: text.trim(),
    checked: mark === "x",
  };
}
