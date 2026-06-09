import path from "node:path";
import { spawnSync } from "node:child_process";

function runGit(cwd, args) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8" });
  if (r.status !== 0) return null;
  return String(r.stdout || "").trim() || null;
}

export function resolvePrimaryGitWorktree(cwd = process.cwd()) {
  if (runGit(cwd, ["rev-parse", "--is-inside-work-tree"]) !== "true") {
    return null;
  }
  const commonDir = runGit(cwd, ["rev-parse", "--path-format=absolute", "--git-common-dir"]);
  if (commonDir && path.basename(commonDir) === ".git") {
    return path.dirname(commonDir);
  }
  const top = runGit(cwd, ["rev-parse", "--show-toplevel"]);
  return top ? path.resolve(cwd, top) : null;
}

export function resolveDefaultStateHome({ cwd = process.cwd(), env = process.env } = {}) {
  if (env.BF_HOME) return env.BF_HOME;
  const primary = resolvePrimaryGitWorktree(cwd);
  return path.join(primary || cwd, ".bf");
}
