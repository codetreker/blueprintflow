import { existsSync, rmSync } from "node:fs";
import { homedir } from "node:os";
import { discoveryTargetDir, resolveDiscoveryTargets } from "../shared/install-paths.mjs";

export async function cmdUninstall({ home = homedir(), target = null, log = console.log } = {}) {
  const selectedTargets = resolveDiscoveryTargets({ target, home });
  if (selectedTargets.length === 0) {
    log("No supported BF discovery target detected. Use --target claude or --target codex to uninstall explicitly.");
    return { ok: true, mode: "noop", targets: [] };
  }

  const results = [];
  for (const t of selectedTargets) {
    const path = discoveryTargetDir(t, home);
    if (!existsSync(path)) {
      log(`Nothing to remove — ${path} does not exist (${t}).`);
      results.push({ target: t, status: "missing", path });
      continue;
    }
    rmSync(path, { recursive: true, force: true });
    log(`✓ BF removed from ${path} (${t})`);
    results.push({ target: t, status: "removed", path });
  }
  return { ok: true, mode: "removed", targets: results };
}
