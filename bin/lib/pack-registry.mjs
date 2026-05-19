import fs from "node:fs";
import path from "node:path";
import { parsePack } from "./parse-pack.mjs";

export function buildPackRegistry({ packsDir }) {
  const packs = new Map();
  const warnings = [];
  if (!packsDir || !fs.existsSync(packsDir)) {
    return { packs, warnings };
  }
  for (const name of fs.readdirSync(packsDir)) {
    const dir = path.join(packsDir, name);
    if (!fs.statSync(dir).isDirectory()) continue;
    const packMd = path.join(dir, "pack.md");
    if (!fs.existsSync(packMd)) {
      warnings.push(`skip pack ${name}: pack.md missing`);
      continue;
    }
    try {
      const parsed = parsePack(fs.readFileSync(packMd, "utf8"));
      if (parsed.id !== name) {
        warnings.push(`skip pack ${name}: Id "${parsed.id}" != directory name`);
        continue;
      }
      const rolesDir = path.join(dir, "roles");
      packs.set(name, {
        id: parsed.id,
        desc: parsed.desc,
        sections: parsed.sections,
        dir,
        rolesDir: fs.existsSync(rolesDir) ? rolesDir : null,
      });
    } catch (e) {
      warnings.push(`skip pack ${name}: ${e.message}`);
    }
  }
  return { packs, warnings };
}
