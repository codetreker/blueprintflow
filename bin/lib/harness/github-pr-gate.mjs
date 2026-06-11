import { spawnSync } from "node:child_process";
import { parseGitHubPrUrl, parseGitHubRemoteUrl, readGitHubPr } from "./github-pr.mjs";

function runGit(cwd, args) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8" });
  return {
    ok: r.status === 0,
    stdout: String(r.stdout || "").trim(),
    stderr: String(r.stderr || "").trim(),
  };
}

export function checkGitHubPrMergedGate(task) {
  if (!task.spec.requiresWorktree) return { ok: true };
  const metadata = task.spec.executionMetadata || {};
  if (!metadata.worktree) return { ok: false, error: "worktree-required task is missing Worktree metadata" };
  const remote = runGit(metadata.worktree, ["remote", "get-url", "origin"]);
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
  if (lookup.pr.headRefName && metadata.branch && lookup.pr.headRefName !== metadata.branch) {
    return {
      ok: false,
      error: `GitHub PR branch mismatch: expected ${metadata.branch}, found ${lookup.pr.headRefName}`,
    };
  }
  if (lookup.pr.merged !== true) {
    return { ok: false, error: "GitHub PR is not merged" };
  }
  return { ok: true };
}
