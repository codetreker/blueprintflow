import fs from "node:fs";
import path from "node:path";
import { parsePack } from "./parse-pack.mjs";

function loadPacksFrom(packsDir, source, packs, warnings) {
  if (!packsDir || !fs.existsSync(packsDir)) return;
  for (const name of fs.readdirSync(packsDir)) {
    const dir = path.join(packsDir, name);
    let isDir = false;
    try {
      // statSync follows symlinks; a dangling symlink or an entry removed
      // between readdir and stat throws ENOENT. Skip-with-warning instead of
      // letting one bad/racy entry abort the whole registry build.
      isDir = fs.statSync(dir).isDirectory();
    } catch (e) {
      warnings.push(`skip pack ${name} (${source}): ${e.message}`);
      continue;
    }
    if (!isDir) continue;
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
      const pipelinesDir = path.join(dir, "pipelines");
      const layer = {
        id: parsed.id,
        desc: parsed.desc,
        sections: parsed.sections,
        dir,
        packMd,
        rolesDir: fs.existsSync(rolesDir) ? rolesDir : null,
        pipelinesDir: fs.existsSync(pipelinesDir) ? pipelinesDir : null,
        source,
      };
      const existing = packs.get(name);
      if (!existing) {
        packs.set(name, {
          id: parsed.id,
          desc: parsed.desc,
          sections: parsed.sections,
          dir,
          rolesDir: layer.rolesDir,
          source,
          layers: [layer],
          paths: [packMd],
          rolesDirs: layer.rolesDir ? [layer.rolesDir] : [],
          pipelinesDirs: layer.pipelinesDir ? [layer.pipelinesDir] : [],
        });
      } else {
        existing.desc = parsed.desc;
        existing.sections = parsed.sections;
        existing.dir = dir;
        existing.rolesDir = layer.rolesDir;
        existing.source = source;
        existing.layers.push(layer);
        existing.paths.push(packMd);
        if (layer.rolesDir) existing.rolesDirs.push(layer.rolesDir);
        if (layer.pipelinesDir) existing.pipelinesDirs.push(layer.pipelinesDir);
      }
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
