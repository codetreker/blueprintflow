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

function expectedTaskGit(primaryWorktree, woId, taskId) {
  return {
    branch: `bf/${woId}/${taskId}`,
    worktree: path.join(primaryWorktree, ".worktrees", woId, taskId),
  };
}

function localBranchExists(primaryWorktree, branch) {
  return runGit(primaryWorktree, ["show-ref", "--verify", `refs/heads/${branch}`]).ok;
}

function registeredWorktree(primaryWorktree, worktree) {
  const listed = runGit(primaryWorktree, ["worktree", "list", "--porcelain"]);
  if (!listed.ok) return null;
  let current = null;
  for (const line of listed.stdout.split("\n")) {
    if (line.startsWith("worktree ")) {
      current = { path: line.replace(/^worktree\s+/, ""), branch: null };
      continue;
    }
    if (!current) continue;
    if (line.startsWith("branch ")) {
      current.branch = line.replace(/^branch\s+refs\/heads\//, "");
    }
    if (line === "") {
      if (samePath(current.path, worktree)) return current;
      current = null;
    }
  }
  if (current && samePath(current.path, worktree)) return current;
  return null;
}

function checkMetadata(metadata, expected, { requireBoth = false } = {}) {
  const branch = metadata?.branch || null;
  const worktree = metadata?.worktree || null;
  if (requireBoth && (!branch || !worktree)) {
    return { ok: false, error: "task execution metadata missing Branch or Worktree" };
  }
  if (branch && branch !== expected.branch) {
    return { ok: false, error: `task execution metadata branch conflict: expected ${expected.branch}, found ${branch}` };
  }
  if (worktree && !samePath(worktree, expected.worktree)) {
    return { ok: false, error: `task execution metadata worktree conflict: expected ${expected.worktree}, found ${worktree}` };
  }
  return { ok: true };
}

function validateExistingWorktree(primaryWorktree, expected) {
  if (!fs.existsSync(expected.worktree)) {
    return { ok: false, error: `worktree missing: ${expected.worktree}` };
  }
  const registered = registeredWorktree(primaryWorktree, expected.worktree);
  if (!registered) {
    const nestedCommon = runGit(expected.worktree, ["rev-parse", "--path-format=absolute", "--git-common-dir"]);
    if (nestedCommon.ok) {
      const primaryCommon = runGit(primaryWorktree, ["rev-parse", "--path-format=absolute", "--git-common-dir"]);
      if (!primaryCommon.ok || !samePath(primaryCommon.stdout, nestedCommon.stdout)) {
        return { ok: false, error: `worktree repository conflict: ${expected.worktree} belongs to a different repository` };
      }
    }
    return { ok: false, error: `worktree path conflict: ${expected.worktree} is not a registered Git worktree` };
  }
  if (registered.branch !== expected.branch) {
    return {
      ok: false,
      error: `checkout branch conflict: expected ${expected.branch}, found ${registered.branch || "detached HEAD"}`,
    };
  }
  const inside = runGit(expected.worktree, ["rev-parse", "--is-inside-work-tree"]);
  if (!inside.ok || inside.stdout !== "true") {
    return { ok: false, error: `worktree path conflict: ${expected.worktree} exists but is not a Git worktree` };
  }
  const primaryCommon = runGit(primaryWorktree, ["rev-parse", "--path-format=absolute", "--git-common-dir"]);
  const worktreeCommon = runGit(expected.worktree, ["rev-parse", "--path-format=absolute", "--git-common-dir"]);
  if (!primaryCommon.ok || !worktreeCommon.ok || !samePath(primaryCommon.stdout, worktreeCommon.stdout)) {
    return { ok: false, error: `worktree repository conflict: ${expected.worktree} belongs to a different repository` };
  }
  return { ok: true, branch: expected.branch, worktree: expected.worktree };
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

export function prepareTaskWorktree({ baseHome, cwd = process.cwd(), woId, taskId, metadata = {} }) {
  const managed = resolveManagedGit({ baseHome, cwd });
  if (!managed.ok) return managed;

  const { primaryWorktree } = managed;
  const expected = expectedTaskGit(primaryWorktree, woId, taskId);
  const metadataCheck = checkMetadata(metadata, expected);
  if (!metadataCheck.ok) return metadataCheck;

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

  if (fs.existsSync(expected.worktree)) {
    return validateExistingWorktree(primaryWorktree, expected);
  }
  if (localBranchExists(primaryWorktree, expected.branch)) {
    return {
      ok: false,
      error: `branch conflict: ${expected.branch} exists without expected worktree ${expected.worktree}`,
    };
  }

  fs.mkdirSync(path.dirname(expected.worktree), { recursive: true });
  const added = runGit(primaryWorktree, ["worktree", "add", "-b", expected.branch, expected.worktree, originHead.stdout]);
  if (!added.ok) {
    if (fs.existsSync(expected.worktree)) {
      const recovered = validateExistingWorktree(primaryWorktree, expected);
      if (recovered.ok) return recovered;
    }
    return { ok: false, error: `git worktree add failed: ${added.stderr || added.stdout || "unknown error"}` };
  }

  return { ok: true, branch: expected.branch, worktree: expected.worktree };
}

export function validateTaskWorktree({ baseHome, cwd = process.cwd(), woId, taskId, metadata = {} }) {
  const managed = resolveManagedGit({ baseHome, cwd });
  if (!managed.ok) return managed;
  const expected = expectedTaskGit(managed.primaryWorktree, woId, taskId);
  const metadataCheck = checkMetadata(metadata, expected, { requireBoth: true });
  if (!metadataCheck.ok) return metadataCheck;
  return validateExistingWorktree(managed.primaryWorktree, expected);
}
