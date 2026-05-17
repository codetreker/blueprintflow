import { readFile, stat } from "node:fs/promises";
import path from "node:path";
import os from "node:os";

const WO_HOME = process.env.BF_WO_HOME ?? path.join(os.homedir(), ".bf", "wo");

function parseFrontmatter(md) {
  const m = md.match(/^---\n([\s\S]*?)\n---/);
  if (!m) return {};
  const out = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^(\w+):\s*(.+)$/);
    if (kv) out[kv[1]] = kv[2].trim();
  }
  return out;
}

export async function resolveWo(woId) {
  const segments = woId.split("/").filter(Boolean);
  if (segments.length === 0) return { exists: false, reason: "empty wo id" };

  let cur = WO_HOME;
  for (const seg of segments) {
    cur = path.join(cur, seg);
    try {
      await stat(path.join(cur, "wo.md"));
    } catch {
      return { exists: false, reason: `missing wo.md at ${cur}`, path: cur };
    }
  }
  const md = await readFile(path.join(cur, "wo.md"), "utf8");
  const fm = parseFrontmatter(md);
  return {
    exists: true,
    path: cur,
    schema: fm.schema,
    current_state: fm.current_state,
    pack: fm.pack,
  };
}
