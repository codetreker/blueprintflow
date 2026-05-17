import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import os from "node:os";
import { discoverPacks } from "../dispatcher/pack-discovery.mjs";

const WO_HOME = process.env.BF_WO_HOME ?? path.join(os.homedir(), ".bf", "wo");

export async function create({ args, flags }) {
  const description = args[0];
  if (!description) {
    console.log(JSON.stringify({ error: "create requires a description: bf create \"<text>\"" }));
    process.exit(2);
  }
  const id = flags.id ?? description.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 60);
  const schema = flags.schema ?? "task";
  const packs = await discoverPacks();
  let packId = flags.pack;
  if (!packId) {
    if (packs.length === 1) packId = packs[0].id;
    else {
      console.log(JSON.stringify({ error: `multiple Packs installed (${packs.map(p=>p.id).join(", ")}); pass --pack <id>` }));
      process.exit(2);
    }
  }
  const woPath = path.join(WO_HOME, id);
  await mkdir(woPath, { recursive: true });
  const wo = `---
schema: ${schema}
current_state: new
desired_state: done
pack: ${packId}
---

# ${description}

## Objective

${description}

## Boundary

(to be shaped in brainstorm)

## Acceptance criteria

(to be shaped in brainstorm)
`;
  await writeFile(path.join(woPath, "wo.md"), wo);
  console.log(JSON.stringify({ created: true, id, path: woPath, schema, pack: packId, current_state: "new" }));
}
