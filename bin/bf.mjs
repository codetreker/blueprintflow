#!/usr/bin/env node
// To add a subcommand: create `cmd-foo.mjs` (pure, returns `{ok, ...}`) and
// export a matching `formatFoo` from the same file (pure, takes the cmd
// result, returns the printable text). `install` / `uninstall` print
// conversationally via an injected `log` and intentionally have no formatter.
import path from "node:path";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { cmdListRoles, formatListRoles } from "./lib/bf/cmd-list-roles.mjs";
import { cmdListPacks, formatListPacks } from "./lib/bf/cmd-list-packs.mjs";
import { cmdListPipelines, formatListPipelines } from "./lib/bf/cmd-list-pipelines.mjs";
import { cmdInstall } from "./lib/bf/cmd-install.mjs";
import { cmdUninstall } from "./lib/bf/cmd-uninstall.mjs";
import { cmdUpdate } from "./lib/bf/cmd-update.mjs";
import { DISCOVERY_TARGETS, globalExtensionsDir, isDiscoveryTarget } from "./lib/shared/install-paths.mjs";
import { resolveDefaultStateHome } from "./lib/shared/state-home.mjs";

const TARGET_USAGE = DISCOVERY_TARGETS.join("|");
const USAGE = `Usage:
  bf list-roles [--pack <pack-id>]
  bf list-packs
  bf list-pipelines [--pack <pack-id>]
  bf install [--target ${TARGET_USAGE}]
  bf uninstall [--target ${TARGET_USAGE}]
  bf update                   Update global BF package to latest
  bf version                  Show installed BF version`;

function write(text) { process.stdout.write(text.endsWith("\n") ? text : text + "\n"); }
function fail(msg, code = 2) { process.stderr.write(msg + "\n"); process.exit(code); }

function resolveInstallDir() {
  if (process.env.BF_INSTALL_DIR) return process.env.BF_INSTALL_DIR;
  return path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
}

function parseTargetOption(rest) {
  let target = null;
  for (let i = 0; i < rest.length; i++) {
    const arg = rest[i];
    if (arg !== "--target") return { ok: false, error: `unknown option: ${arg}` };
    if (target !== null) return { ok: false, error: "--target may be specified only once" };
    const value = rest[++i];
    if (!value || value.startsWith("--")) return { ok: false, error: "--target requires a value" };
    if (!isDiscoveryTarget(value)) return { ok: false, error: `unknown target: ${value} (supported: ${TARGET_USAGE})` };
    target = value;
  }
  return { ok: true, target };
}

async function main() {
  const [, , subcmd, ...rest] = process.argv;

  if (!subcmd || subcmd === "--help" || subcmd === "-h") {
    process.stdout.write(USAGE + "\n");
    return;
  }

  const installDir = resolveInstallDir();
  const baseHome = resolveDefaultStateHome();
  // Extension dirs: global lives under ~/.bf/extensions. Project ext lives in
  // <baseHome>/extensions/. Project wins.
  const globalExt = globalExtensionsDir();
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
    const r = await cmdListRoles({ cwd: installDir, pack, extensionRolesDirs, extensionPacksDirs });
    write(formatListRoles(r));
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "list-packs") {
    const r = await cmdListPacks({ cwd: installDir, extensionPacksDirs });
    write(formatListPacks(r));
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "list-pipelines") {
    let pack = null;
    for (let i = 0; i < rest.length; i++) {
      if (rest[i] === "--pack" && rest[i + 1]) { pack = rest[++i]; }
    }
    const r = await cmdListPipelines({ cwd: installDir, pack, extensionPacksDirs });
    write(formatListPipelines(r));
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "install") {
    const parsed = parseTargetOption(rest);
    if (!parsed.ok) fail(`${parsed.error}\n${USAGE}`, 2);
    const r = await cmdInstall({ srcDir: installDir, target: parsed.target });
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "uninstall") {
    const parsed = parseTargetOption(rest);
    if (!parsed.ok) fail(`${parsed.error}\n${USAGE}`, 2);
    const r = await cmdUninstall({ target: parsed.target });
    process.exit(r.ok ? 0 : 1);
  }
  if (subcmd === "update") {
    if (rest.length > 0) fail(`unknown option: ${rest[0]}\n${USAGE}`, 2);
    const r = await cmdUpdate();
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
