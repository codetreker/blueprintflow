#!/usr/bin/env node
import path from "node:path";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cmdListRoles } from "./lib/bf/cmd-list-roles.mjs";
import { cmdListPacks } from "./lib/bf/cmd-list-packs.mjs";
import { cmdInstall } from "./lib/bf/cmd-install.mjs";
import { cmdUninstall } from "./lib/bf/cmd-uninstall.mjs";
import { skillsDir } from "./lib/shared/install-paths.mjs";

const USAGE = `Usage:
  bf list-roles [--pack <pack-id>]
  bf list-packs
  bf install                  Copy skill files to ~/.claude/skills/bf/
  bf uninstall                Remove skill files (preserves custom roles/packs)
  bf version                  Show installed BF version`;

function out(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function fail(msg, code = 2) { process.stderr.write(msg + "\n"); process.exit(code); }

function resolveInstallDir() {
  if (process.env.BF_INSTALL_DIR) return process.env.BF_INSTALL_DIR;
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
}

async function main() {
  const [, , subcmd, ...rest] = process.argv;

  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }

  const installDir = resolveInstallDir();
  const baseHome = process.env.BF_HOME || path.join(process.cwd(), ".bf");
  // Extension dirs: global lives under the user-facing skills dir (~/.claude/skills/bf/),
  // NOT under installDir (which for `npm install -g` is the npm package dir).
  // Project ext lives in <baseHome>/extensions/. Project wins.
  const globalExt = path.join(skillsDir(), "extensions");
  const extensionRolesDirs = [
    path.join(globalExt, "roles"),
    path.join(baseHome, "extensions", "roles"),
  ];
  const extensionPacksDirs = [
    path.join(globalExt, "packs"),
    path.join(baseHome, "extensions", "packs"),
  ];

  if (subcmd === "list-roles") {
    let pack = null;
    for (let i = 0; i < rest.length; i++) {
      if (rest[i] === "--pack" && rest[i + 1]) { pack = rest[++i]; }
    }
    const r = await cmdListRoles({ cwd: installDir, pack, extensionRolesDirs });
    out(r);
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "list-packs") {
    const r = await cmdListPacks({ cwd: installDir, extensionPacksDirs });
    out(r);
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "install") {
    const r = await cmdInstall({ srcDir: installDir });
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "uninstall") {
    const r = await cmdUninstall();
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "version" || subcmd === "-v" || subcmd === "--version") {
    const pkg = JSON.parse(readFileSync(path.join(installDir, "package.json"), "utf8"));
    process.stdout.write(pkg.version + "\n");
    return;
  }
  fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
}

main().catch((e) => fail(String(e?.stack || e), 1));
