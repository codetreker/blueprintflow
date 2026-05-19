import path from "node:path";
import { buildPackRegistry } from "./pack-registry.mjs";

export async function cmdListPacks({ cwd }) {
  const reg = buildPackRegistry({ packsDir: path.join(cwd, "packs") });
  const packs = [...reg.packs.values()]
    .sort((a, b) => a.id.localeCompare(b.id))
    .map(p => ({ id: p.id, desc: p.desc }));
  return { ok: true, packs, warnings: reg.warnings };
}
