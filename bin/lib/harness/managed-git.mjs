import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { resolvePrimaryGitWorktree } from "../shared/state-home.mjs";

function runGit(cwd, args) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8" });
  return {
    ok: r.status === 0,
    stdout: String(r.stdout || "").trim(),
    stderr: String(r.stderr || "").trim(),
  };
}

function samePath(a, b) {
  return path.resolve(a) === path.resolve(b);
}

export function resolveManagedGit({ baseHome, cwd = process.cwd() }) {
  const primaryWorktree = resolvePrimaryGitWorktree(cwd);
  if (!primaryWorktree) {
    return { ok: false, error: "managed Git mode requires a Git worktree" };
  }
  const expectedStateHome = path.join(primaryWorktree, ".bf");
  if (!samePath(baseHome, expectedStateHome)) {
    return {
      ok: false,
      error: `managed Git mode requires state home ${expectedStateHome}`,
    };
  }
  return { ok: true, primaryWorktree };
}

export function prepareTaskWorktree({ baseHome, cwd = process.cwd(), woId, taskId }) {
  const managed = resolveManagedGit({ baseHome, cwd });
  if (!managed.ok) return managed;

  const { primaryWorktree } = managed;
  const origin = runGit(primaryWorktree, ["remote", "get-url", "origin"]);
  if (!origin.ok) return { ok: false, error: "managed Git setup requires origin remote" };

  const fetch = runGit(primaryWorktree, ["fetch", "origin"]);
  if (!fetch.ok) {
    return { ok: false, error: `fetch origin failed: ${fetch.stderr || fetch.stdout || "unknown error"}` };
  }

  const originHead = runGit(primaryWorktree, ["symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"]);
  if (!originHead.ok || !originHead.stdout) {
    return { ok: false, error: "managed Git setup requires origin/HEAD" };
  }

  const branch = `bf/${woId}/${taskId}`;
  const worktree = path.join(primaryWorktree, ".worktrees", woId, taskId);
  fs.mkdirSync(path.dirname(worktree), { recursive: true });
  const added = runGit(primaryWorktree, ["worktree", "add", "-b", branch, worktree, originHead.stdout]);
  if (!added.ok) {
    return { ok: false, error: `git worktree add failed: ${added.stderr || added.stdout || "unknown error"}` };
  }

  return { ok: true, branch, worktree };
}
