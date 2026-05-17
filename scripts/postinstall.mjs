#!/usr/bin/env node

// Postinstall: copy the bf skill content into ~/.claude/skills/bf/
// so Claude Code can discover and invoke it.
//
// Mirrors OPC's pattern but does the copy inline (no bin/bf install
// dependency — Stage 4 will replace this with a fuller installer when
// the bf dispatcher lands).

import { cpSync, mkdirSync, existsSync, readFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { homedir } from "os";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PKG_ROOT = join(__dirname, "..");
const PKG = JSON.parse(readFileSync(join(PKG_ROOT, "package.json"), "utf8"));

// What to copy into ~/.claude/skills/bf/. Mirror of package.json `files`
// excluding scripts/ (postinstall itself isn't useful inside the skill copy).
const SKILL_CONTENT = [
  "SKILL.md",
  "bin",
  "roles",
  "references",
  "pipeline",
  "packs",
  "test",
  "UPSTREAM.md",
  "README.md",
];

const targetDir = join(homedir(), ".claude", "skills", "bf");

try {
  mkdirSync(targetDir, { recursive: true });

  for (const entry of SKILL_CONTENT) {
    const src = join(PKG_ROOT, entry);
    if (!existsSync(src)) continue; // tolerate optional pieces
    const dst = join(targetDir, entry);
    cpSync(src, dst, { recursive: true });
  }

  console.log(`✓ @codetreker/bf v${PKG.version} installed to ${targetDir}`);
  console.log(`  Run 'bf-harness --help' for the runtime CLI.`);
  console.log(`  In Claude Code, the 'bf' skill is now discoverable.`);
} catch (err) {
  console.warn(`⚠ Postinstall failed to copy skill content.`);
  console.warn(`  Error: ${err.message}`);
  console.warn(`  Manual fallback: cp -r ${PKG_ROOT} ${targetDir}`);
  // Don't exit non-zero — the npm binary is still usable from PATH.
}
