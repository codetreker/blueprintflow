import path from "node:path";
import { spawnSync } from "node:child_process";
import { parseGitHubPrUrl, parseGitHubRemoteUrl, readGitHubPr } from "./github-pr.mjs";
import { validateTaskWorktree, validateWoWorktree } from "./managed-git.mjs";

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
//
// `branchMode` SELECTS what is recomputed/gated, WITHOUT forking the merged===true
// + headRefName + repo-slug verification logic below:
//   - "task" (DEFAULT, Mode A / per-task-pr): recompute bf/<woId>/<taskId> via
//     validateTaskWorktree; PR URL from the task spec's Pull-Request metadata.
//     Behavior is byte-identical to the pre-parameterization gate.
//   - "wo" (Mode B / single-pr, WO-final): recompute bf/<woId> via
//     validateWoWorktree; PR URL from bf.md frontmatter (`bf` arg). Same
//     merged===true assertion, hoisted to WO scope.
export function checkGitHubPrMergedGate(task, { baseHome, cwd, woId, taskId, branchMode = "task", bf } = {}) {
  if (!task.spec.requiresWorktree) return { ok: true };
  // Managed Git mode pins the state home to `<primary-worktree>/.bf`, so the
  // primary worktree is derived from baseHome rather than the process cwd (which
  // may be a linked worktree or any caller directory).
  const resolvedCwd = baseHome ? path.dirname(baseHome) : (cwd || process.cwd());
  const metadata = task.spec.executionMetadata || {};

  // Recompute + validate the harness-owned worktree/branch. requireBoth rejects a
  // missing Branch or Worktree; the path/branch checks reject hand-edited values
  // that do not match the harness-owned git. The branchMode selects per-task
  // (Mode A) vs WO-shared (Mode B) recomputation — the SAME validate-then-assert
  // discipline either way.
  const validated = branchMode === "wo"
    ? validateWoWorktree({ baseHome, cwd: resolvedCwd, woId, metadata })
    : validateTaskWorktree({ baseHome, cwd: resolvedCwd, woId, taskId, metadata });
  if (!validated.ok) return { ok: false, error: validated.error };
  const branch = validated.branch;
  const worktree = validated.worktree;

  // PR URL source diverges by mode but the URL is re-validated identically below.
  // Mode A reads the per-task spec metadata; Mode B reads the WO-level bf.md
  // frontmatter (harness-owned, re-asserted against origin + the live PR).
  const pullRequest = branchMode === "wo"
    ? woPullRequestFromBf(bf)
    : metadata.pullRequest;

  const remote = runGit(worktree, ["remote", "get-url", "origin"]);
  if (!remote.ok) return { ok: false, error: "worktree-required task GitHub gate cannot read origin remote" };
  const remoteRepo = parseGitHubRemoteUrl(remote.stdout);
  if (!remoteRepo) return { ok: true };
  if (!pullRequest) {
    return {
      ok: false,
      error: branchMode === "wo"
        ? "GitHub single-pr work object is missing the WO-level Pull-Request in bf.md"
        : "GitHub worktree-required task is missing Pull-Request metadata",
    };
  }
  const parsedPr = parseGitHubPrUrl(pullRequest);
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

// WO-level Pull-Request from bf.md frontmatter (Mode B / branchMode "wo"). This
// is the harness's own loaded bf.md, not LLM-authored task spec metadata, and the
// URL is re-validated against origin + the live PR by the caller above.
function woPullRequestFromBf(bf) {
  const raw = bf?.frontmatter?.["Pull-Request"];
  if (raw == null || Array.isArray(raw)) return null;
  const v = String(raw).trim();
  return v === "" ? null : v;
}
