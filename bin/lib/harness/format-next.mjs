// Format the result of cmdNext as labeled key:value lines.
// Success:
//   Task: <id>
//   Capability: <capability>
//   Candidate roles: <r1>, <r2>, ...     (or "(none)" if empty)
//   Pack: <pack>
//   Spec: <abs-spec-path>
//   Dir: <abs-task-dir>
// Failure:
//   <error message>
//
// Required fields (`taskId`, `capability_required`, `pack`, `specPath`,
// `taskDir`) must be present and non-empty on `ok: true` — a missing one
// signals a cmd-layer bug, so this formatter throws rather than masking the
// regression with a sentinel. Optional field `candidate_roles` may legitimately
// be empty (no eligible roles), in which case the line renders as `(none)`
// to preserve the no-trailing-whitespace invariant.

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
