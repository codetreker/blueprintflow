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
