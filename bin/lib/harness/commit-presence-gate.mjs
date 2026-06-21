import path from "node:path";
import { spawnSync } from "node:child_process";
import { parseGitHubPrUrl, parseGitHubRemoteUrl, readGitHubPr } from "./github-pr.mjs";
import { validateWoWorktree, expectedWoGit } from "./managed-git.mjs";
import { resolvePrimaryGitWorktree } from "../shared/state-home.mjs";

function runGit(cwd, args) {
  const r = spawnSync("git", args, { cwd, encoding: "utf8" });
  return {
    ok: r.status === 0,
    stdout: String(r.stdout || "").trim(),
    stderr: String(r.stderr || "").trim(),
  };
}

// Mode B (single-pr) task-done gate. Replaces the per-task merged-PR gate that
// does not exist in single-pr (there is no per-task PR; tasks are commits on the
// shared branch bf/<wo>). CONJUNCTIVE: every clause must hold or we FAIL CLOSED.
// We RECOMPUTE every fact from the harness-owned values + git/origin — we NEVER
// trust the verbatim spec metadata or any PR-body/spec text (mirrors the
// fail-closed recompute discipline in github-pr-gate.mjs:15-18).
//
// Clauses (§1.3 of the Mode B research report, with the 5.2 anti-revert
// resolution):
//   (1) recompute `BF-Task: <woId>/<taskId>` trailer (never read from spec);
//       find >=1 commit carrying it in mergeBase(origin/HEAD, bf/<wo>)..bf/<wo>.
//       Zero matching commits => FAIL.
//   (2) that commit is reachable on BOTH local bf/<wo> AND origin/bf/<wo>
//       (proves integrated + pushed). A local-only forged/amended commit fails
//       the origin ancestry check.
//   (3) the commit has a non-empty diff vs its parent (no empty placeholder).
//   (4) the WO PR (bf.md Pull-Request) is present, head == bf/<wo>, repo-slug
//       matches origin, and is OPEN / merged === false (a premature WO-PR merge
//       at task-done is itself a FAIL — the WO PR closes only at completeWorkObject).
//   (5) ANTI-REVERT (resolved 5.2 — net-diff-present via git's own revert
//       provenance): no commit in <task-commit>..origin/bf/<wo> reverts the task
//       commit (body contains `This reverts commit <full-sha>`). Fail-closed AND
//       stacking-compatible: a later legitimately-stacked task commit that merely
//       mentions "revert" in its subject does NOT trip it; only an actual revert
//       of THIS commit's exact SHA does. Checked for every matching trailer SHA.
//
// The trailer proves identity/integration/pushed — NOT correctness. Correctness
// stays with the unchanged Task Verification gates layered before this one.
export function checkTaskCommitPresenceGate(task, { baseHome, cwd, woId, taskId } = {}) {
  if (!task?.spec?.requiresWorktree) return { ok: true };

  // Managed Git pins state home to <primary>/.bf, so derive the primary worktree
  // from baseHome (cwd may be any caller directory / linked worktree).
  const resolvedCwd = baseHome ? path.dirname(baseHome) : (cwd || process.cwd());
  const metadata = task.spec.executionMetadata || {};

  // Recompute + validate the harness-owned shared worktree/branch. requireBoth
  // rejects a missing Branch/Worktree; the path/branch checks reject hand-edited
  // values; requireClean (inside validateWoWorktree) is the shared-worktree
  // contract. This pins `branch` to bf/<woId> — never trusting spec metadata.
  const validated = validateWoWorktree({ baseHome, cwd: resolvedCwd, woId, metadata });
  if (!validated.ok) return { ok: false, error: validated.error };
  const branch = validated.branch;
  const worktree = validated.worktree;

  const primaryWorktree = resolvePrimaryGitWorktree(resolvedCwd);
  if (!primaryWorktree) {
    return { ok: false, error: "single-pr commit-presence gate requires a Git worktree" };
  }
  // Recompute the expected shared branch independently of the validated value so
  // a future drift in validateWoWorktree cannot silently change what we gate on.
  const expected = expectedWoGit(primaryWorktree, woId);
  if (branch !== expected.branch) {
    return { ok: false, error: `single-pr commit-presence gate branch mismatch: expected ${expected.branch}, found ${branch}` };
  }
  const localBranch = expected.branch;
  const originBranch = `origin/${expected.branch}`;

  // Always operate from the primary worktree (origin refs + fetch live there).
  // The fetch is a best-effort FRESHNESS refresh of refs/remotes/origin/bf/<wo>.
  // We do NOT fail closed on a fetch error: the origin-ancestry proof below reads
  // the remote-tracking ref, and a stale tracking ref can only ever show FEWER
  // commits than origin truly has — never extra — so a fetch failure can at worst
  // yield a false FAIL (a just-pushed commit not yet mirrored), which is the SAFE
  // direction. It can never let an un-pushed commit pass. A genuinely missing
  // tracking ref is still rejected below (fail closed).
  runGit(primaryWorktree, ["fetch", "origin"]);

  // Both refs must resolve. A missing local branch means nothing was committed;
  // a missing origin branch means nothing was pushed. Either way: FAIL CLOSED.
  const localTip = runGit(primaryWorktree, ["rev-parse", "--verify", "--quiet", `refs/heads/${localBranch}`]);
  if (!localTip.ok || !localTip.stdout) {
    return { ok: false, error: `single-pr commit-presence gate: local branch ${localBranch} not found` };
  }
  const originTip = runGit(primaryWorktree, ["rev-parse", "--verify", "--quiet", `refs/remotes/${originBranch}`]);
  if (!originTip.ok || !originTip.stdout) {
    return { ok: false, error: `single-pr commit-presence gate: origin branch ${originBranch} not found (push the shared branch)` };
  }

  // (1) Recompute the trailer and find the task commits in
  //     mergeBase(origin/HEAD, bf/<wo>)..bf/<wo>. Never read the trailer from spec.
  const wantTrailer = `${woId}/${taskId}`;
  const originHead = runGit(primaryWorktree, ["symbolic-ref", "--quiet", "refs/remotes/origin/HEAD"]);
  if (!originHead.ok || !originHead.stdout) {
    return { ok: false, error: "single-pr commit-presence gate requires origin/HEAD" };
  }
  const mergeBase = runGit(primaryWorktree, ["merge-base", originHead.stdout, localBranch]);
  if (!mergeBase.ok || !mergeBase.stdout) {
    return { ok: false, error: "single-pr commit-presence gate cannot compute merge-base(origin/HEAD, bf/<wo>)" };
  }
  const range = `${mergeBase.stdout}..${localBranch}`;
  // %x1f (unit separator) joins SHA + its BF-Task trailer values so we can
  // associate each commit with its recomputed trailer without re-shelling.
  const log = runGit(primaryWorktree, [
    "log",
    range,
    "--format=%H%x1f%(trailers:key=BF-Task,valueonly,separator=%x1e)",
  ]);
  if (!log.ok) {
    return { ok: false, error: `single-pr commit-presence gate git log failed: ${log.stderr || log.stdout || "unknown error"}` };
  }
  const matchingShas = [];
  for (const line of log.stdout.split("\n")) {
    if (!line) continue;
    const sep = line.indexOf("\x1f");
    if (sep === -1) continue;
    const sha = line.slice(0, sep);
    const trailerBlob = line.slice(sep + 1);
    const values = trailerBlob.split("\x1e").map((v) => v.trim()).filter(Boolean);
    // Exact match only: `wo-1/task-a` must equal the recomputed wo/task pair, so
    // a mis-scoped trailer (wrong wo or wrong task) cannot satisfy this task.
    if (values.includes(wantTrailer)) matchingShas.push(sha);
  }
  if (matchingShas.length === 0) {
    return { ok: false, error: `single-pr commit-presence gate: no commit carrying trailer "BF-Task: ${wantTrailer}" in ${range}` };
  }

  for (const sha of matchingShas) {
    // (2) reachable on BOTH local and origin (integrated + pushed).
    const localAnc = runGit(primaryWorktree, ["merge-base", "--is-ancestor", sha, localBranch]);
    if (!localAnc.ok) {
      return { ok: false, error: `single-pr commit-presence gate: commit ${sha} is not an ancestor of ${localBranch}` };
    }
    const originAnc = runGit(primaryWorktree, ["merge-base", "--is-ancestor", sha, originBranch]);
    if (!originAnc.ok) {
      return { ok: false, error: `single-pr commit-presence gate: commit ${sha} is not pushed (not an ancestor of ${originBranch})` };
    }

    // (3) non-empty diff vs the commit's parent. A root commit (no parent) is
    //     compared against the empty tree; an --allow-empty placeholder FAILS.
    const parent = runGit(primaryWorktree, ["rev-parse", "--verify", "--quiet", `${sha}^`]);
    const diffArgs = parent.ok && parent.stdout
      ? ["diff", "--name-only", `${sha}^`, sha]
      : ["diff", "--name-only", "4b825dc642cb6eb9a060e54bf8d69288fbee4904", sha];
    const diff = runGit(primaryWorktree, diffArgs);
    if (!diff.ok) {
      return { ok: false, error: `single-pr commit-presence gate diff failed for ${sha}: ${diff.stderr || diff.stdout || "unknown error"}` };
    }
    if (diff.stdout === "") {
      return { ok: false, error: `single-pr commit-presence gate: commit ${sha} has an empty diff (placeholder commit)` };
    }

    // (5) ANTI-REVERT (resolved 5.2). No commit in <sha>..origin/bf/<wo> reverts
    //     THIS exact SHA. We use git's deterministic revert marker
    //     `This reverts commit <full-sha>` — stacking-compatible (a later
    //     legitimately-stacked commit merely mentioning "revert" in its subject
    //     does NOT match) and fail-closed (an honest `git revert` of this commit
    //     always emits the marker). Bounded full-sha match with a non-hex
    //     boundary prevents a prefix collision from masking the revert.
    const revertScan = runGit(primaryWorktree, [
      "log",
      `${sha}..${originBranch}`,
      "--format=%H%x1f%B%x1e",
    ]);
    if (!revertScan.ok) {
      return { ok: false, error: `single-pr commit-presence gate revert scan failed for ${sha}: ${revertScan.stderr || revertScan.stdout || "unknown error"}` };
    }
    const revertMarker = new RegExp(`This reverts commit ${sha}(?![0-9a-fA-F])`, "i");
    for (const record of revertScan.stdout.split("\x1e")) {
      const body = record.trim();
      if (!body) continue;
      if (revertMarker.test(body)) {
        return { ok: false, error: `single-pr commit-presence gate: task commit ${sha} was reverted on ${originBranch}` };
      }
    }
  }

  // (4) WO PR present, OPEN/unmerged, head == bf/<wo>, repo-slug matches origin.
  const remote = runGit(worktree, ["remote", "get-url", "origin"]);
  if (!remote.ok) return { ok: false, error: "single-pr commit-presence gate cannot read origin remote" };
  const remoteRepo = parseGitHubRemoteUrl(remote.stdout);
  // Non-GitHub origin: the WO-PR clause is not applicable, but clauses (1)-(3)+(5)
  // already passed, so the task-done proof holds. (Mirrors github-pr-gate.mjs:42.)
  if (!remoteRepo) return { ok: true };

  const woPrUrl = woPullRequestUrl(task);
  if (!woPrUrl) {
    return { ok: false, error: "single-pr commit-presence gate: bf.md is missing the WO-level Pull-Request" };
  }
  const parsedPr = parseGitHubPrUrl(woPrUrl);
  if (!parsedPr) return { ok: false, error: "single-pr commit-presence gate: WO Pull-Request must be a GitHub PR URL" };
  if (parsedPr.repoSlug !== remoteRepo.repoSlug) {
    return {
      ok: false,
      error: `single-pr commit-presence gate: WO Pull-Request must belong to ${remoteRepo.owner}/${remoteRepo.repo}`,
    };
  }
  const lookup = readGitHubPr(parsedPr.url);
  if (!lookup.ok) return { ok: false, error: lookup.error };
  if (lookup.pr.headRefName !== branch) {
    return {
      ok: false,
      error: `single-pr commit-presence gate: WO PR branch mismatch: expected ${branch}, found ${lookup.pr.headRefName || "<none>"}`,
    };
  }
  // Premature WO-PR merge at task-done is itself a FAIL: tasks complete while the
  // WO PR is still OPEN; the merge happens only at completeWorkObject (W7 / §2.1 #7).
  if (lookup.pr.merged === true) {
    return { ok: false, error: "single-pr commit-presence gate: WO PR is already merged before all tasks are done" };
  }

  return { ok: true };
}

// The WO-level Pull-Request lives in bf.md frontmatter (§1.4). The loaded task
// bundle does not carry bf, so callers thread it in via task.__bf (set by
// cmd-complete from the loaded bundle). Recompute-never-trust still holds: this
// is the harness's own loaded bf.md, not LLM-authored spec metadata, and the URL
// is re-validated against origin + the live PR below.
function woPullRequestUrl(task) {
  const bf = task?.__bf;
  const raw = bf?.frontmatter?.["Pull-Request"];
  if (raw == null) return null;
  if (Array.isArray(raw)) return null;
  const v = String(raw).trim();
  return v === "" ? null : v;
}
