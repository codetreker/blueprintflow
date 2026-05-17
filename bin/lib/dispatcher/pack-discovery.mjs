import { readdir, readFile, stat } from "node:fs/promises";
import path from "node:path";

// v0.2 scope: scan repo-local packs/. Future: also scan sibling npm packages.
const REPO_PACKS_DIR = path.resolve(process.cwd(), "packs");

export async function discoverPacks() {
  let entries;
  try {
    entries = await readdir(REPO_PACKS_DIR, { withFileTypes: true });
  } catch (e) {
    return [];
  }
  const packs = [];
  for (const e of entries) {
    if (!e.isDirectory()) continue;
    const manifestPath = path.join(REPO_PACKS_DIR, e.name, "pack.json");
    try {
      const raw = await readFile(manifestPath, "utf8");
      const manifest = JSON.parse(raw);
      packs.push({
        id: manifest.id ?? e.name,
        version: manifest.version ?? "0.0.0",
        path: path.join(REPO_PACKS_DIR, e.name),
        manifest,
      });
    } catch (e) {
      // pack.json missing or invalid — skip
    }
  }
  return packs;
}
