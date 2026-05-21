import { existsSync, mkdirSync, cpSync, rmSync, readFileSync, lstatSync, realpathSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { skillsDir, SKILL_NAME } from "../shared/install-paths.mjs";

export { SKILL_NAME };
// Back-compat re-export — kept so cmd-uninstall and tests can keep their existing import.
export const skillsTargetDir = skillsDir;

// Files/dirs installed and managed by `bf install`. Anything else under the install dir
// (notably `extensions/`) is left alone — that is the user's space.
// `bin/` and `package.json` are intentionally NOT here: with `npm install -g` they live
// inside the npm package dir, are on $PATH via npm-created symlinks, and never get read
// from ~/.claude/skills/bf/.
export const MANAGED_ENTRIES = [
  "SKILL.md",
  "roles",
  "packs",
  "templates",
  "references",
];

export async function cmdInstall({ srcDir, home = homedir(), log = console.log }) {
  const target = skillsDir(home);
  const pkg = JSON.parse(readFileSync(join(srcDir, "package.json"), "utf8"));

  // Dev mode: if target is already a symlink to srcDir, leave it alone.
  if (existsSync(target) && lstatSync(target).isSymbolicLink()) {
    const linkTarget = realpathSync(target);
    const src = realpathSync(srcDir);
    if (linkTarget === src) {
      log(`✓ BF v${pkg.version} already linked at ${target}`);
      return { ok: true, mode: "linked", path: target, version: pkg.version };
    }
  }

  mkdirSync(target, { recursive: true });
  const copied = [];
  for (const entry of MANAGED_ENTRIES) {
    const src = join(srcDir, entry);
    const dest = join(target, entry);
    // Nuke + replace: removes orphans from prior versions without a stale-files list.
    if (existsSync(dest)) rmSync(dest, { recursive: true, force: true });
    if (!existsSync(src)) continue;
    cpSync(src, dest, { recursive: true });
    copied.push(entry);
  }
  log(`✓ BF v${pkg.version} installed to ${target}`);
  log(`  Use /bf in Claude Code to get started.`);
  log(`  Custom roles/packs go in ${join(target, "extensions")}/ — never touched by install/uninstall.`);
  return { ok: true, mode: "copied", path: target, version: pkg.version, copied };
}
