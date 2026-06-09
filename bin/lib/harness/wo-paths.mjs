import path from "node:path";
import fs from "node:fs";

export function worksDir(baseHome) {
  return path.join(baseHome, "works");
}

export function newWoDir(baseHome, woId) {
  return path.join(worksDir(baseHome), woId);
}

export function legacyWoDir(baseHome, woId) {
  return path.join(baseHome, woId);
}

function hasBfMd(dir) {
  return fs.existsSync(path.join(dir, "bf.md"));
}

export function woDir(baseHome, woId) {
  const next = newWoDir(baseHome, woId);
  if (hasBfMd(next)) return next;
  const legacy = legacyWoDir(baseHome, woId);
  if (hasBfMd(legacy)) return legacy;
  return next;
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
