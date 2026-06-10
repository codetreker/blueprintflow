import { loadWo } from "./load-wo.mjs";

const TASK_STATES = ["Draft", "Ready", "Tasking", "Completed"];

export async function cmdStatus({ baseHome, woId, installDir }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
  if (!bundle.ok) return { ok: false, error: "load failed", details: bundle.errors };

  const counts = Object.fromEntries(TASK_STATES.map((state) => [state, 0]));
  const tasks = bundle.tasks.map((task) => {
    const state = task.spec.frontmatter.State;
    if (Object.hasOwn(counts, state)) counts[state] += 1;
    return { taskId: task.id, state };
  });

  return {
    ok: true,
    woId,
    state: bundle.bf.frontmatter.State,
    counts,
    tasks,
  };
}

export function formatStatus(r) {
  if (!r.ok) return `${r.error || "status failed"}\n`;
  const lines = [
    `BF: ${r.woId}`,
    `State: ${r.state}`,
    `Tasks: total=${r.tasks.length} Draft=${r.counts.Draft} Ready=${r.counts.Ready} Tasking=${r.counts.Tasking} Completed=${r.counts.Completed}`,
  ];
  for (const task of r.tasks) {
    lines.push(`Task: ${task.taskId} State: ${task.state}`);
  }
  return lines.join("\n") + "\n";
}
