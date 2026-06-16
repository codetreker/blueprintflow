import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { loadWo } from "./load-wo.mjs";
import { writeTaskExecutionMetadata, writeUpdated, formatTimestamp } from "./write-mutations.mjs";
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

export async function cmdAttachPr({ baseHome, woId, taskId, prUrl, installDir, now = new Date() }) {
  const parsedPr = parseGitHubPrUrl(prUrl);
  if (!parsedPr) return { ok: false, error: "attach-pr requires a GitHub PR URL" };

  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  const task = bundle.tasks.find(t => t.id === taskId);
  if (!task?.spec) return { ok: false, error: `task spec not found: ${taskId}` };
  if (task.spec.frontmatter.State !== "Tasking") {
    return { ok: false, error: "attach-pr requires a Tasking task" };
  }
  if (!task.spec.requiresWorktree) {
    return { ok: false, error: "attach-pr requires Requires-Worktree: true" };
  }
  const metadata = task.spec.executionMetadata || {};
  if (!metadata.branch || !metadata.worktree) {
    return { ok: false, error: "attach-pr requires task Branch and Worktree metadata" };
  }

  // Fail closed: pin the worktree/branch to the recomputed harness-owned values
  // rather than trusting the verbatim spec metadata. validateTaskWorktree rejects
  // a missing Branch/Worktree and any hand-edited value that is not harness-owned.
  const cwd = path.dirname(baseHome);
  const validated = validateTaskWorktree({ baseHome, cwd, woId, taskId, metadata });
  if (!validated.ok) return { ok: false, error: validated.error };
  const branch = validated.branch;
  const worktree = validated.worktree;

  const remote = runGit(worktree, ["remote", "get-url", "origin"]);
  if (!remote.ok) return { ok: false, error: "attach-pr requires an origin remote on the task worktree" };
  const remoteRepo = parseGitHubRemoteUrl(remote.stdout);
  if (!remoteRepo) return { ok: false, error: "attach-pr requires a GitHub origin remote" };
  if (remoteRepo.repoSlug !== parsedPr.repoSlug) {
    return {
      ok: false,
      error: `attach-pr requires a PR from the same repository (${remoteRepo.owner}/${remoteRepo.repo})`,
    };
  }

  // Assert the PR head branch equals the harness-owned branch unconditionally,
  // so a merged-but-unrelated PR cannot be attached.
  const lookup = readGitHubPr(parsedPr.url);
  if (!lookup.ok) return { ok: false, error: lookup.error };
  if (lookup.pr.headRefName !== branch) {
    return {
      ok: false,
      error: `attach-pr branch mismatch: expected ${branch}, found ${lookup.pr.headRefName || "<none>"}`,
    };
  }

  let text = fs.readFileSync(task.specPath, "utf8");
  text = writeTaskExecutionMetadata(text, { pullRequest: parsedPr.url });
  text = writeUpdated(text, formatTimestamp(now));
  fs.writeFileSync(task.specPath, text);
  return { ok: true, taskId, pullRequest: parsedPr.url };
}

export function formatAttachPr(r) {
  if (!r.ok) return `FAIL\n\n${r.error || "attach-pr failed"}\n`;
  return `SUCCESS\nPull-Request: ${r.pullRequest}\n`;
}
