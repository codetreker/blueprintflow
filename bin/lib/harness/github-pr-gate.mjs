import path from "node:path";
import { spawnSync } from "node:child_process";
import { parseGitHubPrUrl, parseGitHubRemoteUrl, readGitHubPr } from "./github-pr.mjs";
import { validateTaskWorktree } from "./managed-git.mjs";

function runGit(cwd, args) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8" });
  return {
    ok: r.status === 0,
    stdout: String(r.stdout || "").trim(),
    stderr: String(r.stderr || "").trim(),
  };
}

// Fail closed: pin the worktree/branch to the recomputed harness-owned values
// (never trust the verbatim spec metadata), require Branch, and assert the merged
// PR head branch equals the harness-owned branch unconditionally.
//
// `task` is the loaded task bundle entry; `woId`/`taskId` identify the task so
// the expected harness-owned worktree (`<primary>/.worktrees/works/<woId>/<taskId>`)
// and branch (`bf/<woId>/<taskId>`) can be recomputed. `baseHome` is the state
// home (`<primary>/.bf`); `cwd` defaults to the primary worktree derived from it.
export function checkGitHubPrMergedGate(task, { baseHome, cwd, woId, taskId } = {}) {
  if (!task.spec.requiresWorktree) return { ok: true };
  // Managed Git mode pins the state home to `<primary-worktree>/.bf`, so the
  // primary worktree is derived from baseHome rather than the process cwd (which
  // may be a linked worktree or any caller directory).
  const resolvedCwd = baseHome ? path.dirname(baseHome) : (cwd || process.cwd());
  const metadata = task.spec.executionMetadata || {};

  // Recompute + validate the harness-owned worktree/branch. requireBoth rejects a
  // missing Branch or Worktree; the path/branch checks reject hand-edited values
  // that do not match the harness-owned task git.
  const validated = validateTaskWorktree({ baseHome, cwd: resolvedCwd, woId, taskId, metadata });
  if (!validated.ok) return { ok: false, error: validated.error };
  const branch = validated.branch;
  const worktree = validated.worktree;

  const remote = runGit(worktree, ["remote", "get-url", "origin"]);
  if (!remote.ok) return { ok: false, error: "worktree-required task GitHub gate cannot read origin remote" };
  const remoteRepo = parseGitHubRemoteUrl(remote.stdout);
  if (!remoteRepo) return { ok: true };
  if (!metadata.pullRequest) {
    return { ok: false, error: "GitHub worktree-required task is missing Pull-Request metadata" };
  }
  const parsedPr = parseGitHubPrUrl(metadata.pullRequest);
  if (!parsedPr) return { ok: false, error: "Pull-Request must be a GitHub PR URL" };
  if (parsedPr.repoSlug !== remoteRepo.repoSlug) {
    return {
      ok: false,
      error: `Pull-Request must belong to the same GitHub repository (${remoteRepo.owner}/${remoteRepo.repo})`,
    };
  }
  const lookup = readGitHubPr(parsedPr.url);
  if (!lookup.ok) return { ok: false, error: lookup.error };
  if (lookup.pr.headRefName !== branch) {
    return {
      ok: false,
      error: `GitHub PR branch mismatch: expected ${branch}, found ${lookup.pr.headRefName || "<none>"}`,
    };
  }
  if (lookup.pr.merged !== true) {
    return { ok: false, error: "GitHub PR is not merged" };
  }
  return { ok: true };
}
