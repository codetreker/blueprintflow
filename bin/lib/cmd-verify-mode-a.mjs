import { collectFindings } from "./verify-round.mjs";

// Spec Review: 任一 reviewer 报 Blocker/High → FAIL；全 clean → SUCCESS。不动 state / checkbox。
export async function verifyModeA({ parsedResults }) {
  const issues = collectFindings(parsedResults);
  const status = (issues.blocker.length === 0 && issues.high.length === 0) ? "SUCCESS" : "FAIL";
  return { status, issues };
}
