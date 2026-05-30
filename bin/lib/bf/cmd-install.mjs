import { existsSync, mkdirSync, cpSync, rmSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { discoveryTargetDir, resolveDiscoveryTargets, SKILL_NAME } from "../shared/install-paths.mjs";

export { SKILL_NAME };
// Back-compat re-export — kept so cmd-uninstall and tests can keep their existing import.
export const skillsTargetDir = (home = homedir()) => discoveryTargetDir("claude", home);

// Files/dirs included in the host discovery snapshot.
// `bin/` and `package.json` are intentionally NOT here: with `npm install -g` they live
// inside the npm package dir and npm puts the commands on PATH.
export const SNAPSHOT_ENTRIES = [
  "SKILL.md",
  "roles",
  "packs",
  "templates",
  "references",
];

export async function cmdInstall({ srcDir, home = homedir(), target = null, log = console.log }) {
  const selectedTargets = resolveDiscoveryTargets({ target, home });
  const pkg = JSON.parse(readFileSync(join(srcDir, "package.json"), "utf8"));

  if (selectedTargets.length === 0) {
    log("No supported BF discovery target detected. Use --target claude or --target codex to install explicitly.");
    return { ok: true, mode: "noop", version: pkg.version, targets: [] };
  }

  const results = [];
  for (const t of selectedTargets) {
    const path = discoveryTargetDir(t, home);
    rmSync(path, { recursive: true, force: true });
    mkdirSync(path, { recursive: true });
    const copied = [];
    for (const entry of SNAPSHOT_ENTRIES) {
      const src = join(srcDir, entry);
      const dest = join(path, entry);
      if (!existsSync(src)) continue;
      cpSync(src, dest, { recursive: true });
      copied.push(entry);
    }
    log(`✓ BF v${pkg.version} installed to ${path} (${t})`);
    results.push({ target: t, status: "installed", path, copied });
  }
  log("  Custom roles/packs go in ~/.bf/extensions/ or <project>/.bf/extensions/.");
  return { ok: true, mode: "copied", version: pkg.version, targets: results };
}
