import { readFile, readdir, stat } from "node:fs/promises";
import path from "node:path";
import os from "node:os";

export const WO_HOME = process.env.BF_WO_HOME ?? path.join(os.homedir(), ".bf", "wo");

export { parseFrontmatter };

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
    desired_state: fm.desired_state,
    frontmatter: fm,
  };
}

// Recursively walk WO_HOME and return all WOs (any dir containing wo.md).
// Each entry: { id, path, depth, schema, current_state, desired_state, pack }.
export async function listWos() {
  const out = [];
  async function walk(dir, relSegs) {
    let entries;
    try { entries = await readdir(dir, { withFileTypes: true }); }
    catch { return; }
    // If this dir itself contains a wo.md, record it.
    if (relSegs.length > 0) {
      try {
        await stat(path.join(dir, "wo.md"));
        const md = await readFile(path.join(dir, "wo.md"), "utf8");
        const fm = parseFrontmatter(md);
        out.push({
          id: relSegs.join("/"),
          path: dir,
          depth: relSegs.length - 1,
          schema: fm.schema,
          current_state: fm.current_state,
          desired_state: fm.desired_state,
          pack: fm.pack,
        });
      } catch {}
    }
    for (const e of entries) {
      if (!e.isDirectory()) continue;
      if (e.name === "runs" || e.name === "nodes") continue;
      await walk(path.join(dir, e.name), [...relSegs, e.name]);
    }
  }
  await walk(WO_HOME, []);
  return out;
}
