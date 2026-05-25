import fs from "node:fs";
import { taskDir } from "./wo-paths.mjs";
import { writeState, writeUpdated, formatTimestamp } from "./write-mutations.mjs";
import { loadWo } from "./load-wo.mjs";

export async function cmdNext({ baseHome, woId, installDir, now = new Date() }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.bf) return { ok: false, error: "load failed", details: bundle.errors };
  const bfState = bundle.bf.frontmatter.State;
  if (!["Accepted", "Implementing"].includes(bfState)) {
    return { ok: false, error: `wrong state: ${bfState}` };
  }
  if (bundle.tasks.some((t) => !t.spec)) {
    return { ok: false, error: "task spec missing", details: bundle.errors };
  }
  const stateOf = (id) => bundle.tasks.find((t) => t.id === id)?.spec.frontmatter.State;

  const eligible = bundle.tasks.filter((t) => {
    if (!["Ready", "Tasking"].includes(t.spec.frontmatter.State)) return false;
    return t.deps.every((d) => stateOf(d) === "Completed");
  });
  if (eligible.length === 0) return { ok: false, error: "no eligible task" };

  const chosen = eligible.find((t) => t.spec.frontmatter.State === "Ready") || eligible[0];
  const ts = formatTimestamp(now);

  if (chosen.spec.frontmatter.State === "Ready") {
    let text = fs.readFileSync(chosen.specPath, "utf8");
    text = writeState(text, "Tasking", { kind: "taskSpec" });
    text = writeUpdated(text, ts);
    fs.writeFileSync(chosen.specPath, text);

    if (bfState === "Accepted") {
      let bfText = fs.readFileSync(bundle.bfPath, "utf8");
      bfText = writeState(bfText, "Implementing", { kind: "bf" });
      bfText = writeUpdated(bfText, ts);
      fs.writeFileSync(bundle.bfPath, bfText);
    }
  }

  const cap = chosen.spec.frontmatter.Capability;
  const candidate_roles = (bundle.roleReg.byCapability.get(cap) || []).map((r) => r.id);

  return {
    ok: true,
    task: {
      taskId: chosen.id,
      taskDir: taskDir(baseHome, woId, chosen.id),
      specPath: chosen.specPath,
      desc: chosen.spec.frontmatter.Desc,
      capability_required: cap,
      candidate_roles,
      pack: bundle.bf.frontmatter.Pack,
    },
  };
}

/**
 * Format the result of cmdNext as labeled key:value lines.
 * Success:
 *   Task: <id>
 *   Capability: <capability>
 *   Candidate roles: <r1>, <r2>, ...     (or "(none)" if empty)
 *   Pack: <pack>
 *   Spec: <abs-spec-path>
 *   Dir: <abs-task-dir>
 * Failure:
 *   <error message>
 *
 * Required fields (`taskId`, `capability_required`, `pack`, `specPath`,
 * `taskDir`) must be present and non-empty on `ok: true` — a missing one
 * signals a cmd-layer bug, so this formatter throws rather than masking the
 * regression with a sentinel. Optional field `candidate_roles` may legitimately
 * be empty (no eligible roles), in which case the line renders as `(none)`
 * to preserve the no-trailing-whitespace invariant.
 */
const REQUIRED = ["taskId", "capability_required", "pack", "specPath", "taskDir"];

function requireField(t, name) {
  const v = t?.[name];
  if (v === undefined || v === null || v === "") {
    throw new Error(`formatNext: missing required task field '${name}' (cmd-next contract violation)`);
  }
  return v;
}

export function formatNext(r) {
  if (!r.ok) return `${r.error || "next failed"}\n`;
  const t = r.task || {};
  for (const name of REQUIRED) requireField(t, name);
  const rolesArr = t.candidate_roles || [];
  const roles = rolesArr.length === 0 ? "(none)" : rolesArr.join(", ");
  const lines = [
    `Task: ${t.taskId}`,
    `Capability: ${t.capability_required}`,
    `Candidate roles: ${roles}`,
    `Pack: ${t.pack}`,
    `Spec: ${t.specPath}`,
    `Dir: ${t.taskDir}`,
  ];
  return lines.join("\n") + "\n";
}
