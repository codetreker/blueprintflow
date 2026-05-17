import { discoverPacks } from "../dispatcher/pack-discovery.mjs";

export async function pack({ args, flags }) {
  const sub = args[0];
  const packs = await discoverPacks();
  if (!sub || sub === "list") {
    if (packs.length === 0) { console.log("(no packs discovered)"); return; }
    for (const p of packs) {
      console.log(`${p.id}\t${p.version}\t${p.manifest.description ?? ""}`);
    }
    return;
  }
  if (sub === "info") {
    const id = args[1];
    if (!id) { console.log(JSON.stringify({ error: "pack info requires <id>" })); process.exit(2); }
    const p = packs.find(x => x.id === id);
    if (!p) { console.log(JSON.stringify({ error: "pack not found", id })); process.exit(2); }
    console.log(JSON.stringify(p.manifest));
    return;
  }
  console.log(JSON.stringify({ error: `unknown pack sub-verb: ${sub}` }));
  process.exit(2);
}
