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

// Per-task git tuple (Mode A). Single source of truth for the per-task
// branch/worktree layout; resolveModeGit('per-task-pr', ...) reuses this so the
// two cannot drift. Exported for the mode resolver and cmd-cleanup re-use.
export function expectedTaskGit(primaryWorktree, woId, taskId) {
  return {
    branch: `bf/${woId}/${taskId}`,
    worktree: path.join(primaryWorktree, ".worktrees", "works", woId, taskId),
  };
}

// WO-scoped shared git tuple (Mode B / single-pr). DEFINED for P3 wiring;
// NO P0 caller resolves this yet. Marker is `_shared` (decided in §1.1).
export function expectedWoGit(primaryWorktree, woId) {
  return {
    branch: `bf/${woId}`,
    worktree: path.join(primaryWorktree, ".worktrees", "works", woId, "_shared"),
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

// requireClean (Mode B / 5.4a): when set, the existing shared worktree must have
// an EMPTY `git status --porcelain` before a new task may claim it. We FAIL CLOSED
// on a dirty tree rather than `git reset --hard`/`clean -fd` — those would destroy
// prior tasks' unpushed commits accumulated on the shared branch bf/<wo>, and
// uncommitted scratch the operator may still need. Mode A passes requireClean=false
// (its per-task worktrees are single-owner, so this stays byte-identical).
function validateExistingWorktree(primaryWorktree, expected, { requireClean = false } = {}) {
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
  if (requireClean) {
    const status = runGit(expected.worktree, ["status", "--porcelain", "--untracked-files=normal"]);
    if (!status.ok) {
      return { ok: false, error: `shared worktree status check failed: ${status.stderr || status.stdout || "unknown error"}` };
    }
    if (status.stdout !== "") {
      return {
        ok: false,
        error: `shared worktree is not clean on claim: ${expected.worktree} has uncommitted changes; commit or stash them before claiming the next task (the harness will NOT reset/clean — that would discard prior tasks' commits)`,
      };
    }
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

// --- Mode B (single-pr) shared WO worktree -----------------------------------
// One shared branch `bf/<wo>` + one shared worktree `_shared` per Work Object,
// created once off origin/HEAD on the first worktree-task claim and REUSED by
// every subsequent task's claim. Layout comes from expectedWoGit (single source
// of truth, shared with resolveModeGit('single-pr', ...)).
//
// Concurrency/data-loss contract (open question 5.4):
//  (a) clean-on-claim: reuse REQUIRES a clean working tree (validateExistingWorktree
//      requireClean=true). We never reset/clean — that would destroy prior tasks'
//      unpushed commits on the shared branch. Dirty => fail closed.
//  (b) crash-idempotent create: if the worktree already exists, we validate-and-
//      return (never re-create); a failed `git worktree add` whose path now exists
//      re-validates via the existing recovery path.
//  (c) first-claim lock: an O_EXCL `.bf-create.lock` at <wo>/.bf-create.lock makes
//      two concurrent first-claims mutually exclusive; the loser fails fast (no
//      retry) and the lock is released in `finally`.

const WO_CREATE_LOCK = ".bf-create.lock";

export function prepareWoWorktree({ baseHome, cwd = process.cwd(), woId, metadata = {} }) {
  const managed = resolveManagedGit({ baseHome, cwd });
  if (!managed.ok) return managed;

  const { primaryWorktree } = managed;
  const expected = expectedWoGit(primaryWorktree, woId);
  const metadataCheck = checkMetadata(metadata, expected);
  if (!metadataCheck.ok) return metadataCheck;

  // Fast path: an already-created shared worktree is reused without taking the
  // creation lock. Reuse enforces the clean-on-claim contract (5.4a). This must
  // run BEFORE the lock so a normal second-task claim never contends on it.
  if (fs.existsSync(expected.worktree)) {
    return validateExistingWorktree(primaryWorktree, expected, { requireClean: true });
  }

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

  // First-claim lock (5.4c). The lock lives in the WO dir (the parent of the
  // _shared worktree) so it survives even though _shared does not yet exist.
  const woDir = path.dirname(expected.worktree);
  fs.mkdirSync(woDir, { recursive: true });
  const lockPath = path.join(woDir, WO_CREATE_LOCK);
  let lockFd;
  try {
    lockFd = fs.openSync(lockPath, "ax");
  } catch (err) {
    if (err && err.code === "EEXIST") {
      return { ok: false, error: `WO shared worktree is being claimed by another process (lock: ${lockPath}). If no other claim is running, this is a stale lock — remove that file to recover.` };
    }
    return { ok: false, error: `failed to acquire WO create lock: ${err.message}` };
  }

  try {
    // Re-check under the lock: a racing claim that completed between our
    // existsSync above and acquiring the lock may have created it.
    if (fs.existsSync(expected.worktree)) {
      return validateExistingWorktree(primaryWorktree, expected, { requireClean: true });
    }
    if (localBranchExists(primaryWorktree, expected.branch)) {
      return {
        ok: false,
        error: `branch conflict: ${expected.branch} exists without expected worktree ${expected.worktree}`,
      };
    }

    const added = runGit(primaryWorktree, ["worktree", "add", "-b", expected.branch, expected.worktree, originHead.stdout]);
    if (!added.ok) {
      // Crash-idempotent recovery (5.4b): a half-initialized path from a prior
      // crash between mkdirSync and `worktree add` re-validates here.
      if (fs.existsSync(expected.worktree)) {
        const recovered = validateExistingWorktree(primaryWorktree, expected, { requireClean: true });
        if (recovered.ok) return recovered;
      }
      return { ok: false, error: `git worktree add failed: ${added.stderr || added.stdout || "unknown error"}` };
    }

    return { ok: true, branch: expected.branch, worktree: expected.worktree };
  } finally {
    try { fs.closeSync(lockFd); } catch { /* already closed */ }
    try { fs.unlinkSync(lockPath); } catch { /* already removed */ }
  }
}

export function validateWoWorktree({ baseHome, cwd = process.cwd(), woId, metadata = {} }) {
  const managed = resolveManagedGit({ baseHome, cwd });
  if (!managed.ok) return managed;
  const expected = expectedWoGit(managed.primaryWorktree, woId);
  const metadataCheck = checkMetadata(metadata, expected, { requireBoth: true });
  if (!metadataCheck.ok) return metadataCheck;
  return validateExistingWorktree(managed.primaryWorktree, expected, { requireClean: true });
}
