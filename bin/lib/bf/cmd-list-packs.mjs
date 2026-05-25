import path from "node:path";
import { buildPackRegistry } from "../shared/pack-registry.mjs";

export async function cmdListPacks({ cwd, extensionPacksDirs = [] }) {
  const reg = buildPackRegistry({ packsDir: path.join(cwd, "packs"), extensionPacksDirs });
  const packs = [...reg.packs.values()]
    .sort((a, b) => a.id.localeCompare(b.id))
    .map(p => ({ id: p.id, desc: p.desc, source: p.source }));
  return { ok: true, packs, warnings: reg.warnings };
}

/**
 * Format the result of cmdListPacks as line-oriented text.
 * Success: one pack per line — `<id> | <desc> | <source>`.
 * Empty:   `(no packs installed)`.
 * Failure: `<error>` on stdout.
 * Warnings (if any) appended after rows as `# <warning>` lines.
 *
 * Column separator is ` | ` (space-pipe-space) so descriptions containing
 * double spaces parse cleanly with `cut -d'|'`. Empty desc renders as `-` so
 * the row never ends in trailing whitespace.
 */
export function formatListPacks(r) {
  if (!r.ok) return `${r.error || "list-packs failed"}\n`;
  const lines = [];
  if (!r.packs || r.packs.length === 0) {
    lines.push("(no packs installed)");
  } else {
    for (const p of r.packs) {
      const desc = p.desc && p.desc.length > 0 ? p.desc : "-";
      const source = p.source || "-";
      lines.push(`${p.id} | ${desc} | ${source}`);
    }
  }
  for (const w of r.warnings || []) lines.push(`# ${w}`);
  return lines.join("\n") + "\n";
}
