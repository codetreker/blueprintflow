import { listWos } from "../dispatcher/wo-resolver.mjs";

export async function list({ args, flags }) {
  let wos = await listWos();
  if (flags.pack) wos = wos.filter(w => w.pack === flags.pack);
  if (flags.state) wos = wos.filter(w => w.current_state === flags.state);
  if (flags.schema) wos = wos.filter(w => w.schema === flags.schema);
  wos.sort((a, b) => a.id.localeCompare(b.id));
  if (wos.length === 0) {
    console.log("(no matching work orders)");
    return;
  }
  for (const w of wos) {
    console.log(`${w.id}\t${w.schema ?? "?"}\t${w.current_state ?? "?"} → ${w.desired_state ?? "?"}\t${w.pack ?? ""}`);
  }
}
