import path from "node:path";
import { buildPackRegistry } from "../shared/pack-registry.mjs";

export async function cmdListPacks({ cwd, extensionPacksDirs = [] }) {
  const reg = buildPackRegistry({ packsDir: path.join(cwd, "packs"), extensionPacksDirs });
  const packs = [...reg.packs.values()]
    .sort((a, b) => a.id.localeCompare(b.id))
    .map(p => ({ id: p.id, desc: p.desc, source: p.source }));
  return { ok: true, packs, warnings: reg.warnings };
}
