// Format the result of cmdListRoles as line-oriented text.
// Success: one role per line — `<id> | [<cap1>, <cap2>, ...] | <source> | <file>`.
// Empty:   `(no roles installed)`.
// Failure: `<error>` on stdout.
// Warnings (if any) appended after rows as `# <warning>` lines.
//
// Column separator is ` | ` (space-pipe-space) so descriptions / file paths
// containing double spaces parse cleanly with `cut -d'|'`. Empty fields render
// as `-` so rows never end in trailing whitespace.

export function formatListRoles(r) {
  if (!r.ok) return `${r.error || "list-roles failed"}\n`;
  const lines = [];
  if (!r.roles || r.roles.length === 0) {
    lines.push("(no roles installed)");
  } else {
    for (const role of r.roles) {
      const caps = `[${(role.capabilities || []).join(", ")}]`;
      const source = role.source || "-";
      const file = role.file && role.file.length > 0 ? role.file : "-";
      lines.push(`${role.id} | ${caps} | ${source} | ${file}`);
    }
  }
  for (const w of r.warnings || []) lines.push(`# ${w}`);
  return lines.join("\n") + "\n";
}
