import { existsSync, rmSync, readdirSync, lstatSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { MANAGED_ENTRIES, skillsTargetDir } from "./cmd-install.mjs";

// Inside these managed entries, files the user added themselves are preserved on uninstall.
const PRESERVE_USER_FILES = new Set(["roles", "packs"]);

export async function cmdUninstall({ srcDir, home = homedir(), log = console.log }) {
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

  const preserved = {};
  for (const entry of MANAGED_ENTRIES) {
    const target = join(skillsDir, entry);
    if (!existsSync(target)) continue;

    if (PRESERVE_USER_FILES.has(entry)) {
      let managed;
      try {
        managed = readdirSync(join(srcDir, entry));
      } catch (err) {
        log(`  ⚠ Could not read source ${entry}/ (${err.message}); removing entire ${entry}/`);
        rmSync(target, { recursive: true });
        continue;
      }
      for (const name of managed) {
        const p = join(target, name);
        if (existsSync(p)) rmSync(p, { recursive: true });
      }
      try {
        const remaining = readdirSync(target);
        if (remaining.length === 0) {
          rmSync(target, { recursive: true });
        } else {
          preserved[entry] = remaining;
          log(`  Kept ${remaining.length} custom ${entry === "roles" ? "role(s)" : "pack(s)"} in ${target}`);
        }
      } catch (err) {
        log(`  ⚠ Could not clean ${entry}/: ${err.message}`);
      }
    } else if (lstatSync(target).isDirectory()) {
      rmSync(target, { recursive: true });
    } else {
      rmSync(target);
    }
  }

  // Remove dir only if now empty.
  try {
    const remaining = readdirSync(skillsDir);
    if (remaining.length === 0) rmSync(skillsDir, { recursive: true });
  } catch (err) {
    log(`  ⚠ Could not remove skill dir: ${err.message}`);
  }

  log(`✓ BF removed from ${skillsDir}`);
  return { ok: true, mode: "removed", path: skillsDir, preserved };
}
