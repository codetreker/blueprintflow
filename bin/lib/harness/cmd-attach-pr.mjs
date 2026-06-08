import fs from "node:fs";
import { spawnSync } from "node:child_process";
import { loadWo } from "./load-wo.mjs";
import { writeTaskExecutionMetadata, writeUpdated, formatTimestamp } from "./write-mutations.mjs";
import { parseGitHubPrUrl, parseGitHubRemoteUrl, readGitHubPr } from "./github-pr.mjs";

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

  const remote = runGit(metadata.worktree, ["remote", "get-url", "origin"]);
  if (!remote.ok) return { ok: false, error: "attach-pr requires an origin remote on the task worktree" };
  const remoteRepo = parseGitHubRemoteUrl(remote.stdout);
  if (!remoteRepo) return { ok: false, error: "attach-pr requires a GitHub origin remote" };
  if (remoteRepo.repoSlug !== parsedPr.repoSlug) {
    return {
      ok: false,
      error: `attach-pr requires a PR from the same repository (${remoteRepo.owner}/${remoteRepo.repo})`,
    };
  }

  const lookup = readGitHubPr(parsedPr.url);
  if (lookup.ok && lookup.pr.headRefName && lookup.pr.headRefName !== metadata.branch) {
    return {
      ok: false,
      error: `attach-pr branch mismatch: expected ${metadata.branch}, found ${lookup.pr.headRefName}`,
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
