import { existsSync, rmSync, readdirSync, lstatSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { MANAGED_ENTRIES, skillsTargetDir } from "./cmd-install.mjs";

export async function cmdUninstall({ home = homedir(), log = console.log } = {}) {
  const skillsDir = skillsTargetDir(home);

  if (!existsSync(skillsDir)) {
    log(`Nothing to remove — ${skillsDir} does not exist.`);
    return { ok: true, mode: "noop" };
  }

  // Symlink mode: remove just the link.
  if (lstatSync(skillsDir).isSymbolicLink()) {
    rmSync(skillsDir);
    log(`✓ BF symlink removed: ${skillsDir}`);
    return { ok: true, mode: "symlink-removed", path: skillsDir };
  }

  // Remove every managed entry. Anything else (notably extensions/) is the user's
  // and is left untouched.
  for (const entry of MANAGED_ENTRIES) {
    const target = join(skillsDir, entry);
    if (existsSync(target)) rmSync(target, { recursive: true, force: true });
  }

  // Remove skillsDir only if nothing else remains.
  let kept = [];
  try {
    kept = readdirSync(skillsDir);
    if (kept.length === 0) {
      rmSync(skillsDir, { recursive: true });
    } else {
      log(`  Kept ${kept.length} user entry/entries in ${skillsDir} (${kept.slice(0, 3).join(", ")}${kept.length > 3 ? ", ..." : ""})`);
    }
  } catch (err) {
    log(`  ⚠ Could not inspect ${skillsDir}: ${err.message}`);
  }

  log(`✓ BF removed from ${skillsDir}`);
  return { ok: true, mode: "removed", path: skillsDir, kept };
}
