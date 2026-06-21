import { expectedTaskGit, expectedWoGit } from "./managed-git.mjs";

// Single source of truth for the Work Object integration mode (Mode A / Mode B).
// Mode A (default) = "per-task-pr": one PR + one branch/worktree per task.
// Mode B (opt-in)  = "single-pr":  one PR per WO, each task a commit on a shared
//                    branch `bf/<wo>` in one shared worktree.
//
// P0 is a PURE REFACTOR: "single-pr" is DEFINED here but NOT wired up — no caller
// passes it yet. Mode A behavior must stay byte-identical.

export const INTEGRATION_MODES = Object.freeze({
  PER_TASK_PR: "per-task-pr",
  SINGLE_PR: "single-pr",
});

const VALID_MODES = new Set(Object.values(INTEGRATION_MODES));

// Read the integration mode off bf.frontmatter. Absent => per-task-pr (Mode A).
// Fail-closed: any value not in the known set throws — never silently coerced.
export function woIntegrationMode(bf) {
  const raw = bf?.frontmatter?.Integration;
  if (raw == null || raw === "") return INTEGRATION_MODES.PER_TASK_PR;
  if (!VALID_MODES.has(raw)) {
    throw new Error(
      `invalid Integration value: ${JSON.stringify(raw)} (expected one of ${[...VALID_MODES].join(", ")})`,
    );
  }
  return raw;
}

export function isSinglePrMode(mode) {
  return mode === INTEGRATION_MODES.SINGLE_PR;
}

// Resolve the { branch, worktree } tuple for a task under a given mode.
// per-task-pr: per-task tuple (delegates to the legacy expectedTaskGit — Mode A).
// single-pr:   WO-scoped shared tuple (defined for P3; no P0 caller passes it).
// Fail-closed: any unknown mode throws.
export function resolveModeGit(mode, primaryWorktree, woId, taskId) {
  if (mode === INTEGRATION_MODES.PER_TASK_PR) {
    return expectedTaskGit(primaryWorktree, woId, taskId);
  }
  if (mode === INTEGRATION_MODES.SINGLE_PR) {
    return expectedWoGit(primaryWorktree, woId);
  }
  throw new Error(
    `unknown integration mode: ${JSON.stringify(mode)} (expected one of ${[...VALID_MODES].join(", ")})`,
  );
}
