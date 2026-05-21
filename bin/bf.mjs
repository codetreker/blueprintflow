#!/usr/bin/env node
import path from "node:path";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cmdListRoles } from "./lib/bf/cmd-list-roles.mjs";
import { cmdListPacks } from "./lib/bf/cmd-list-packs.mjs";
import { cmdInstall } from "./lib/bf/cmd-install.mjs";
import { cmdUninstall } from "./lib/bf/cmd-uninstall.mjs";

const USAGE = `Usage:
  bf list-roles [--pack <pack-id>]
  bf list-packs
  bf install                  Copy skill files to ~/.claude/skills/bf/
  bf uninstall                Remove skill files (preserves custom roles/packs)
  bf version                  Show installed BF version`;

function out(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }
function fail(msg, code = 2) { process.stderr.write(msg + "\n"); process.exit(code); }

function resolveRepoRoot() {
  if (process.env.BF_REPO_ROOT) return process.env.BF_REPO_ROOT;
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
}

async function main() {
  const [, , subcmd, ...rest] = process.argv;

  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }

  const repoRoot = resolveRepoRoot();

  if (subcmd === "list-roles") {
    let pack = null;
    for (let i = 0; i < rest.length; i++) {
      if (rest[i] === "--pack" && rest[i + 1]) { pack = rest[++i]; }
    }
    const r = await cmdListRoles({ cwd: repoRoot, pack });
    out(r);
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "list-packs") {
    const r = await cmdListPacks({ cwd: repoRoot });
    out(r);
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "install") {
    const r = await cmdInstall({ srcDir: repoRoot });
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "uninstall") {
    const r = await cmdUninstall({ srcDir: repoRoot });
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "version" || subcmd === "-v" || subcmd === "--version") {
    const pkg = JSON.parse(readFileSync(path.join(repoRoot, "package.json"), "utf8"));
    process.stdout.write(pkg.version + "\n");
    return;
  }
  fail(`unknown subcommand: ${subcmd}\n${USAGE}`, 2);
}

main().catch((e) => fail(String(e?.stack || e), 1));
