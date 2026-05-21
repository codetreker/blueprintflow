import fs from "node:fs";
import path from "node:path";
import { parsePack } from "./parse-pack.mjs";

function loadPacksFrom(packsDir, source, packs, warnings) {
  if (!packsDir || !fs.existsSync(packsDir)) return;
  for (const name of fs.readdirSync(packsDir)) {
    const dir = path.join(packsDir, name);
    if (!fs.statSync(dir).isDirectory()) continue;
    const packMd = path.join(dir, "pack.md");
    if (!fs.existsSync(packMd)) {
      warnings.push(`skip pack ${name} (${source}): pack.md missing`);
      continue;
    }
    try {
      const parsed = parsePack(fs.readFileSync(packMd, "utf8"));
      if (parsed.id !== name) {
        warnings.push(`skip pack ${name} (${source}): Id "${parsed.id}" != directory name`);
        continue;
      }
      const rolesDir = path.join(dir, "roles");
      packs.set(name, {
        id: parsed.id,
        desc: parsed.desc,
        sections: parsed.sections,
        dir,
        rolesDir: fs.existsSync(rolesDir) ? rolesDir : null,
        source,
      });
    } catch (e) {
      warnings.push(`skip pack ${name} (${source}): ${e.message}`);
    }
  }
}

// Precedence (later wins): packsDir < extensionPacksDirs[0] < extensionPacksDirs[1] < ...
// Callers should pass extensionPacksDirs ordered global-first, project-last.
export function buildPackRegistry({ packsDir, extensionPacksDirs = [] }) {
  const packs = new Map();
  const warnings = [];
  loadPacksFrom(packsDir, "core", packs, warnings);
  for (const dir of extensionPacksDirs) loadPacksFrom(dir, "extension", packs, warnings);
  return { packs, warnings };
}
