import fs from "node:fs";

export function writeVerifyResultMd({
  filePath, mode, scope, round, status, timestamp,
  issues = {}, perAc = null, flipped = [], stateChanges = [],
}) {
  const out = [];
  out.push("---");
  out.push(`Result: ${status}`);
  out.push(`Mode: ${mode}`);
  out.push(`Scope: ${scope}`);
  out.push(`Round: ${round}`);
  out.push(`Timestamp: ${timestamp}`);
  out.push("---", "");
  if (status === "FAIL") {
    out.push("## Issues", "");
    out.push("### Blocker");
    for (const item of issues.blocker || []) out.push(`- ${item}`);
    out.push("");
    out.push("### High");
    for (const item of issues.high || []) out.push(`- ${item}`);
    out.push("");
  }
  if (perAc) {
    out.push("## AC Sign-off");
    for (const ac of perAc) {
      if (ac.status === "signed") {
        out.push(`- ${ac.id}: signed (by ${ac.reviewers.join(", ")})`);
      } else {
        const got = ac.providers.length > 0 ? `; providers=${ac.providers.join(", ")}` : "";
        out.push(`- ${ac.id}: missing${got}`);
      }
    }
    out.push("");
  }
  if (flipped.length > 0) {
    out.push("## Flipped");
    for (const id of flipped) out.push(`- ${id}`);
    out.push("");
  }
  if (stateChanges.length > 0) {
    out.push("## State Changes");
    for (const c of stateChanges) out.push(`- ${c}`);
    out.push("");
  }
  fs.writeFileSync(filePath, out.join("\n"));
}
