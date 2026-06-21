import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { loadWo } from "./load-wo.mjs";
import { resolveManagedGit, expectedTaskGit } from "./managed-git.mjs";
import { integrationError } from "./validate-wo.mjs";
import { woIntegrationMode, isSinglePrMode } from "./integration-mode.mjs";

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

function metadataMatchesHarnessTask(metadata, expected) {
  const branch = metadata?.branch || null;
  const worktree = metadata?.worktree || null;
  if (!branch && !worktree) {
    return { ok: false, reason: "missing Branch or Worktree metadata" };
  }
  if (branch !== expected.branch) {
    return { ok: false, reason: `Branch metadata is not harness-owned: ${branch || "<empty>"}` };
  }
  if (!worktree || !samePath(worktree, expected.worktree)) {
    return { ok: false, reason: `Worktree metadata is not harness-owned: ${worktree || "<empty>"}` };
  }
  return { ok: true };
}

function reasonText(r) {
  return (r.stderr || r.stdout || "unknown error").replace(/\s+/g, " ");
}

export async function cmdCleanup({ baseHome, woId, taskId, installDir, cwd = process.cwd() }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  // Fail closed on a post-accept Integration flip / invalid mode (accept-lock):
  // cmd-cleanup acts on the mode (whether to destroy per-task git) but is not on
  // validateWo's lint/accept path.
  const integLock = integrationError(bundle.bf);
  if (integLock) return { ok: false, error: `${integLock.code}: ${integLock.message}` };
  const singlePr = isSinglePrMode(woIntegrationMode(bundle.bf));

  const task = bundle.tasks.find((t) => t.id === taskId);
  if (!task || !task.spec) {
    return { ok: false, error: `task spec not found: ${taskId}` };
  }
  if (task.spec.frontmatter.State !== "Completed") {
    return { ok: false, error: "cleanup requires task State: Completed" };
  }
  if (!task.spec.requiresWorktree) {
    return {
      ok: true,
      removedWorktrees: [],
      deletedBranches: [],
      retainedWorktrees: [],
      retainedBranches: [],
      skipped: [],
    };
  }

  // single-pr (Mode B): per-task cleanup is a NO-OP. The shared worktree+branch
  // bf/<wo>+_shared are retained until WO completion (WO-scope cleanup is P4) —
  // removing them per task would destroy other tasks' in-flight commits on the
  // shared branch. We retain (not remove) and report it so the operator sees why.
  if (singlePr) {
    const managed = resolveManagedGit({ baseHome, cwd });
    if (!managed.ok) return managed;
    return {
      ok: true,
      removedWorktrees: [],
      deletedBranches: [],
      retainedWorktrees: [{
        taskId: task.id,
        worktree: task.spec.executionMetadata?.worktree || "",
        reason: "single-pr shared worktree retained until WO completion",
      }],
      retainedBranches: [{
        taskId: task.id,
        branch: task.spec.executionMetadata?.branch || "",
        reason: "single-pr shared branch retained until WO completion",
      }],
      skipped: [],
    };
  }

  const managed = resolveManagedGit({ baseHome, cwd });
  if (!managed.ok) return managed;
  const { primaryWorktree } = managed;

  const out = {
    ok: true,
    removedWorktrees: [],
    deletedBranches: [],
    retainedWorktrees: [],
    retainedBranches: [],
    skipped: [],
  };

  const expected = expectedTaskGit(primaryWorktree, woId, task.id);
  const metadataCheck = metadataMatchesHarnessTask(task.spec.executionMetadata, expected);
  if (!metadataCheck.ok) {
    out.skipped.push({ taskId: task.id, reason: metadataCheck.reason });
    return out;
  }

  const registered = registeredWorktree(primaryWorktree, expected.worktree);
  const pathExists = fs.existsSync(expected.worktree);
  if (pathExists || registered) {
    if (!registered) {
      out.retainedWorktrees.push({
        taskId: task.id,
        worktree: expected.worktree,
        reason: "path exists but is not a registered Git worktree",
      });
    } else if (registered.branch !== expected.branch) {
      out.retainedWorktrees.push({
        taskId: task.id,
        worktree: expected.worktree,
        reason: `registered branch is ${registered.branch || "detached HEAD"}`,
      });
    } else {
      const removed = runGit(primaryWorktree, ["worktree", "remove", expected.worktree]);
      if (removed.ok) {
        out.removedWorktrees.push({ taskId: task.id, worktree: expected.worktree });
      } else {
        out.retainedWorktrees.push({
          taskId: task.id,
          worktree: expected.worktree,
          reason: reasonText(removed),
        });
      }
    }
  }

  if (localBranchExists(primaryWorktree, expected.branch)) {
    const deleted = runGit(primaryWorktree, ["branch", "-d", expected.branch]);
    if (deleted.ok) {
      out.deletedBranches.push({ taskId: task.id, branch: expected.branch });
    } else {
      out.retainedBranches.push({
        taskId: task.id,
        branch: expected.branch,
        reason: reasonText(deleted),
      });
    }
  }

  return out;
}

export function formatCleanup(r) {
  if (!r.ok) return `${r.error || "cleanup failed"}\n`;
  const lines = [];
  for (const item of r.removedWorktrees || []) {
    lines.push(`Removed worktree: ${item.worktree}`);
  }
  for (const item of r.deletedBranches || []) {
    lines.push(`Deleted branch: ${item.branch}`);
  }
  for (const item of r.retainedWorktrees || []) {
    lines.push(`Retained worktree: ${item.worktree} (${item.reason})`);
  }
  for (const item of r.retainedBranches || []) {
    lines.push(`Retained branch: ${item.branch} (${item.reason})`);
  }
  for (const item of r.skipped || []) {
    lines.push(`Skipped task: ${item.taskId} (${item.reason})`);
  }
  if (lines.length === 0) lines.push("No harness-owned task worktrees to clean.");
  return lines.join("\n") + "\n";
}
