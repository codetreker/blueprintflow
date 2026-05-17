import { listWos } from "../dispatcher/wo-resolver.mjs";

export async function tree({ args, flags }) {
  const wos = await listWos();
  const showAll = !!flags.all;
  const filtered = showAll ? wos : wos.filter(w => w.current_state !== "done");
  // Sort by id (which is the path-like segment string) so children follow parents.
  filtered.sort((a, b) => a.id.localeCompare(b.id));
  if (filtered.length === 0) {
    console.log("(no work orders)");
    return;
  }
  for (const w of filtered) {
    const indent = "  ".repeat(w.depth);
    const cur = w.current_state ?? "?";
    const des = w.desired_state ?? "?";
    const sch = w.schema ?? "?";
    console.log(`${indent}${w.id}  [${sch}: ${cur} → ${des}]`);
  }
}
