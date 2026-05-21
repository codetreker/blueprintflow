import { existsSync, mkdirSync, cpSync, readFileSync, lstatSync, realpathSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

export const SKILL_NAME = "bf";

// Files/dirs managed by `bf install` — anything else under the install dir is left alone.
export const MANAGED_ENTRIES = [
  "SKILL.md",
  "roles",
  "packs",
  "templates",
  "references",
  "bin",
  "package.json",
];

export function skillsTargetDir(home = homedir()) {
  return join(home, ".claude", "skills", SKILL_NAME);
}

export async function cmdInstall({ srcDir, home = homedir(), log = console.log }) {
  const skillsDir = skillsTargetDir(home);
  const pkg = JSON.parse(readFileSync(join(srcDir, "package.json"), "utf8"));

  // Dev mode: if skillsDir is already a symlink to srcDir, leave it alone.
  if (existsSync(skillsDir) && lstatSync(skillsDir).isSymbolicLink()) {
    const linkTarget = realpathSync(skillsDir);
    const src = realpathSync(srcDir);
    if (linkTarget === src) {
      log(`✓ BF v${pkg.version} already linked at ${skillsDir}`);
      return { ok: true, mode: "linked", path: skillsDir, version: pkg.version };
    }
  }

  mkdirSync(skillsDir, { recursive: true });
  const copied = [];
  for (const entry of MANAGED_ENTRIES) {
    const src = join(srcDir, entry);
    if (!existsSync(src)) continue;
    cpSync(src, join(skillsDir, entry), { recursive: true, force: true });
    copied.push(entry);
  }
  log(`✓ BF v${pkg.version} installed to ${skillsDir}`);
  log(`  Use /bf in Claude Code to get started.`);
  return { ok: true, mode: "copied", path: skillsDir, version: pkg.version, copied };
}
