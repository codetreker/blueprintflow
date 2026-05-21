import path from "node:path";

export function woDir(baseHome, woId) {
  return path.join(baseHome, woId);
}

export function taskDir(baseHome, woId, taskId) {
  return path.join(woDir(baseHome, woId), taskId);
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
