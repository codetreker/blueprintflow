import path from "node:path";
import { buildPackRegistry } from "../shared/pack-registry.mjs";

export async function cmdListPacks({ cwd, extensionPacksDirs = [] }) {
  const reg = buildPackRegistry({ packsDir: path.join(cwd, "packs"), extensionPacksDirs });
  const packs = [...reg.packs.values()]
    .sort((a, b) => a.id.localeCompare(b.id))
    .map(p => ({ id: p.id, desc: p.desc, paths: p.paths || [] }));
  return { ok: true, packs, warnings: reg.warnings };
}

/**
 * Format the result of cmdListPacks as labeled key:value blocks (one block
 * per pack, separated by a blank line). Matches the style of `bf-harness
 * next` for consistency across the CLI.
 *
 * Empty: `(no packs installed)`.
 * Failure: `<error>` on stdout.
 * Warnings (if any) appended at the end as `# <warning>` lines.
 *
 * Example:
 *   Id: engineering
 *   Desc: Software engineering work …
 *   Path: /…/packs/engineering/pack.md
 *
 * Every field is on its own line with a stable label.
 */
export function formatListPacks(r) {
  if (!r.ok) return `${r.error || "list-packs failed"}\n`;
  const blocks = [];
  if (!r.packs || r.packs.length === 0) {
    blocks.push("(no packs installed)");
  } else {
    for (const p of r.packs) {
      const desc = p.desc && p.desc.length > 0 ? p.desc : "-";
      const paths = (p.paths || []).map(file => `Path: ${file}`);
      blocks.push([`Id: ${p.id}`, `Desc: ${desc}`, ...paths].join("\n"));
    }
  }
  const warnings = (r.warnings || []).map(w => `# ${w}`);
  const recordsStr = blocks.join("\n\n---\n\n");
  const warningsStr = warnings.length > 0 ? "\n\n" + warnings.join("\n") : "";
  return recordsStr + warningsStr + "\n";
}
