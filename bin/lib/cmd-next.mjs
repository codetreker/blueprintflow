import fs from "node:fs";
import { taskDir } from "./wo-paths.mjs";
import { writeState } from "./write-state.mjs";
import { writeUpdated, formatTimestamp } from "./write-updated.mjs";
import { loadWo } from "./load-wo.mjs";

export async function cmdNext({ baseHome, projectSlug, woId, repoRoot, now = new Date() }) {
  const bundle = await loadWo({ baseHome, projectSlug, woId, repoRoot });
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
      taskDir: taskDir(baseHome, projectSlug, woId, chosen.id),
      specPath: chosen.specPath,
      desc: chosen.spec.frontmatter.Desc,
      capability_required: cap,
      candidate_roles,
      pack: bundle.bf.frontmatter.Pack,
    },
  };
}
