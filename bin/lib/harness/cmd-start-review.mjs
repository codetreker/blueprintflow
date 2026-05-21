import fs from "node:fs";
import { woDir, taskDir, runsReviewsDir, roundDir } from "./wo-paths.mjs";

export async function cmdStartReview({ baseHome, woId, taskId = null }) {
  const scope = taskId
    ? taskDir(baseHome, woId, taskId)
    : woDir(baseHome, woId);
  if (!fs.existsSync(scope)) {
    return { ok: false, error: `scope not found: ${scope}` };
  }
  const reviewsDir = runsReviewsDir(scope);
  fs.mkdirSync(reviewsDir, { recursive: true });
  let maxN = 0;
  for (const name of fs.readdirSync(reviewsDir)) {
    const m = name.match(/^round_(\d+)$/);
    if (m) maxN = Math.max(maxN, Number(m[1]));
  }
  const nextN = maxN + 1;
  const dir = roundDir(scope, nextN);
  fs.mkdirSync(dir, { recursive: true });
  return { ok: true, round: nextN, dir };
}
