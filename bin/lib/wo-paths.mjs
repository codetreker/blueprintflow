import path from "node:path";

export function projectHome(baseHome, projectSlug) {
  return path.join(baseHome, "projects", projectSlug);
}

export function woDir(baseHome, projectSlug, woId) {
  return path.join(projectHome(baseHome, projectSlug), woId);
}

export function taskDir(baseHome, projectSlug, woId, taskId) {
  return path.join(woDir(baseHome, projectSlug, woId), taskId);
}

export function runsReviewsDir(scopeDir) {
  return path.join(scopeDir, "runs", "reviews");
}

export function roundDir(scopeDir, n) {
  return path.join(runsReviewsDir(scopeDir), `round_${n}`);
}

export function resultFile(roundDirPath, role, idx) {
  return path.join(roundDirPath, `result_${role}_${idx}.md`);
}

export function verifyResultFile(roundDirPath) {
  return path.join(roundDirPath, "verify-result.md");
}
