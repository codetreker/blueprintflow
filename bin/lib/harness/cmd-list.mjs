import fs from "node:fs";
import path from "node:path";
import { parseBfMd } from "./parse-bf-md.mjs";

// Reserved dir names under baseHome that are not bf-wos.
const RESERVED = new Set(["extensions"]);

export async function cmdList({ baseHome }) {
  const warnings = [];
  if (!fs.existsSync(baseHome)) return { ok: true, woList: [], warnings };
  const woList = [];
  for (const name of fs.readdirSync(baseHome).sort()) {
    if (RESERVED.has(name)) continue;
    const woPath = path.join(baseHome, name);
    if (!fs.statSync(woPath).isDirectory()) continue;
    const bfMd = path.join(woPath, "bf.md");
    if (!fs.existsSync(bfMd)) {
      warnings.push(`skip ${name}: no bf.md`);
      continue;
    }
    try {
      const parsed = parseBfMd(fs.readFileSync(bfMd, "utf8"));
      woList.push({
        id: parsed.frontmatter.Id,
        desc: parsed.frontmatter.Desc,
        state: parsed.frontmatter.State,
        updated: parsed.frontmatter.Updated || null,
      });
    } catch (e) {
      warnings.push(`skip ${name}: ${e.message}`);
    }
  }
  return { ok: true, woList, warnings };
}

/**
 * Format the result of cmdList as line-oriented text.
 * Success: one bf-wo per line — `<id> | <state> | <updated> | <desc>`.
 * Empty:   `(no bf-wos)`.
 * Warnings appended as `# <warning>` lines (e.g. `# skip wo-marker: no bf.md`).
 * Failure: `<error>` on stdout.
 *
 * Column separator is ` | ` (space-pipe-space) so a description containing
 * double spaces does not collide with the delimiter. Empty `desc` and missing
 * `updated` render as `-` so the row never ends in trailing whitespace
 * (Quality Constraint: no trailing whitespace). The `r.ok === false` guard
 * stays for defensive consistency with the other formatters.
 */
export function formatList(r) {
  if (r && r.ok === false) return `${r.error || "list failed"}\n`;
  const lines = [];
  const woList = (r && r.woList) || [];
  if (woList.length === 0) {
    lines.push("(no bf-wos)");
  } else {
    for (const wo of woList) {
      const updated = wo.updated || "-";
      const desc = wo.desc && wo.desc.length > 0 ? wo.desc : "-";
      lines.push(`${wo.id} | ${wo.state} | ${updated} | ${desc}`);
    }
  }
  for (const w of (r && r.warnings) || []) lines.push(`# ${w}`);
  return lines.join("\n") + "\n";
}
