import fs from "node:fs";
import path from "node:path";
import { parseBfMd } from "./parse-bf-md.mjs";
import { worksDir } from "./wo-paths.mjs";

// Reserved dir names under baseHome that are not bf-wos.
const RESERVED = new Set(["extensions", "works"]);

function readWoEntry({ name, woPath, warnings }) {
  if (!fs.statSync(woPath).isDirectory()) return null;
  const bfMd = path.join(woPath, "bf.md");
  if (!fs.existsSync(bfMd)) {
    warnings.push(`skip ${name}: no bf.md`);
    return null;
  }
  try {
    const parsed = parseBfMd(fs.readFileSync(bfMd, "utf8"));
    return {
      id: parsed.frontmatter.Id,
      desc: parsed.frontmatter.Desc,
      state: parsed.frontmatter.State,
      updated: parsed.frontmatter.Updated || null,
    };
  } catch (e) {
    warnings.push(`skip ${name}: ${e.message}`);
    return null;
  }
}

export async function cmdList({ baseHome }) {
  const warnings = [];
  if (!fs.existsSync(baseHome)) return { ok: true, woList: [], warnings };
  const woList = [];
  const seen = new Set();

  const works = worksDir(baseHome);
  if (fs.existsSync(works) && fs.statSync(works).isDirectory()) {
    for (const name of fs.readdirSync(works).sort()) {
      const entry = readWoEntry({ name: `works/${name}`, woPath: path.join(works, name), warnings });
      if (!entry) continue;
      woList.push(entry);
      seen.add(entry.id);
    }
  }

  for (const name of fs.readdirSync(baseHome).sort()) {
    if (RESERVED.has(name)) continue;
    const entry = readWoEntry({ name, woPath: path.join(baseHome, name), warnings });
    if (!entry || seen.has(entry.id)) continue;
    woList.push(entry);
    seen.add(entry.id);
  }
  return { ok: true, woList, warnings };
}

/**
 * Format the result of cmdList as labeled key:value blocks (one block per
 * bf-wo, separated by a blank line). Matches the style of `bf-harness next`
 * for consistency across the CLI.
 *
 * Empty: `(no bf-wos)`.
 * Failure: `<error>` on stdout.
 * Warnings (e.g. `skip <name>: no bf.md`) appended as `# <warning>` lines.
 *
 * Example:
 *   Id: wo-1
 *   State: Implementing
 *   Updated: 2026-05-25T14:32:10Z
 *   Desc: Add export pipeline
 *
 *   Id: wo-2
 *   State: Draft
 *   Updated: -
 *   Desc: …
 *
 * Every field is on its own line with a stable label; `grep '^State:'` returns
 * one line per bf-wo for quick filtering.
 */
export function formatList(r) {
  if (r && r.ok === false) return `${r.error || "list failed"}\n`;
  const woList = (r && r.woList) || [];
  const blocks = [];
  if (woList.length === 0) {
    blocks.push("(no bf-wos)");
  } else {
    for (const wo of woList) {
      const updated = wo.updated || "-";
      const desc = wo.desc && wo.desc.length > 0 ? wo.desc : "-";
      blocks.push(
        `Id: ${wo.id}\nState: ${wo.state}\nUpdated: ${updated}\nDesc: ${desc}`
      );
    }
  }
  const warnings = ((r && r.warnings) || []).map(w => `# ${w}`);
  const recordsStr = blocks.join("\n\n---\n\n");
  const warningsStr = warnings.length > 0 ? "\n\n" + warnings.join("\n") : "";
  return recordsStr + warningsStr + "\n";
}
