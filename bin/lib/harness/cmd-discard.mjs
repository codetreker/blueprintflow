import fs from "node:fs";
import path from "node:path";
import { woDir } from "./wo-paths.mjs";

export async function cmdDiscard({ baseHome, woId }) {
  if (!woId || woId.includes("/") || woId.includes("..")) {
    return { ok: false, error: `invalid woId: ${woId}` };
  }
  const target = woDir(baseHome, woId);
  if (!target.startsWith(baseHome + path.sep)) {
    return { ok: false, error: "path escape detected" };
  }
  if (!fs.existsSync(target)) {
    return { ok: false, error: "bf-wo not found" };
  }
  fs.rmSync(target, { recursive: true, force: true });
  return { ok: true, removed: target };
}
