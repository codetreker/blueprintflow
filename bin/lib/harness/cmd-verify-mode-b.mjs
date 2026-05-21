import fs from "node:fs";
import { collectFindings } from "./verify-round.mjs";
import { computeAcSignoff } from "./compute-ac-signoff.mjs";
import { flipCheckbox } from "./write-checkbox.mjs";
import { writeState } from "./write-state.mjs";
import { writeUpdated, formatTimestamp } from "./write-updated.mjs";
import { parseTaskSpec } from "./parse-task-spec.mjs";

// Mode B: Task Verification. OR semantics — ≥1 provider signed each AC → signed.
export async function verifyModeB({ bundle, parsedResults, taskId }) {
  const issues = collectFindings(parsedResults);
  if (issues.blocker.length > 0 || issues.high.length > 0) {
    return { status: "FAIL", issues };
  }
  const task = bundle.tasks.find(t => t.id === taskId);
  if (!task || !task.spec) {
    return { status: "FAIL", issues: { blocker: [`task spec not found: ${taskId}`], high: [] } };
  }
  const signoff = computeAcSignoff({
    acList: task.spec.acceptanceCriteria,
    reviewResults: parsedResults,
    roleReg: bundle.roleReg,
  });
  if (signoff.missing.length > 0) {
    return { status: "FAIL", issues: { blocker: [], high: [] }, perAc: signoff.perAc };
  }

  // Apply mutations: flip newly signed AC checkboxes, refresh Updated, maybe state change.
  let specText = fs.readFileSync(task.specPath, "utf8");
  for (const id of signoff.flipped) specText = flipCheckbox(specText, id);
  specText = writeUpdated(specText, formatTimestamp());
  const stateChanges = [];
  const refreshed = parseTaskSpec(specText);
  const allChecked = refreshed.acceptanceCriteria.every(a => a.checked);
  if (allChecked && task.spec.frontmatter.State === "Tasking") {
    specText = writeState(specText, "Completed", { kind: "taskSpec" });
    stateChanges.push(`${taskId}: Tasking -> Completed`);
  }
  fs.writeFileSync(task.specPath, specText);

  return {
    status: "SUCCESS",
    perAc: signoff.perAc,
    flipped: signoff.flipped,
    stateChanges,
  };
}
