import { existsSync, mkdirSync, cpSync, rmSync, readFileSync, writeFileSync } from "node:fs";
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

const METADATA_FILE = ".bf-install.json";

function readPreviousVersion(path) {
  const file = join(path, METADATA_FILE);
  if (!existsSync(file)) return null;
  try {
    const parsed = JSON.parse(readFileSync(file, "utf8"));
    return typeof parsed.version === "string" && parsed.version.length > 0 ? parsed.version : null;
  } catch {
    return null;
  }
}

function installStatus({ existed, previousVersion, version }) {
  if (!existed) return "installed";
  if (!previousVersion) return "updated-from-unknown";
  if (previousVersion === version) return "refreshed";
  return "updated";
}

function formatTargetResult(result) {
  if (result.status === "installed") {
    return `${result.target}: installed ${result.version} (${result.path})`;
  }
  if (result.status === "refreshed") {
    return `${result.target}: refreshed ${result.version} (${result.path})`;
  }
  if (result.status === "updated") {
    return `${result.target}: updated ${result.previousVersion} -> ${result.version} (${result.path})`;
  }
  return `${result.target}: updated from unknown -> ${result.version} (${result.path})`;
}

function writeMetadata(path, { pkg, target, installedAt }) {
  writeFileSync(join(path, METADATA_FILE), `${JSON.stringify({
    schema: 1,
    package: pkg.name,
    version: pkg.version,
    target,
    installedAt,
  }, null, 2)}\n`);
}

export async function cmdInstall({ srcDir, home = homedir(), target = null, log = console.log }) {
  const selectedTargets = resolveDiscoveryTargets({ target, home });
  const pkg = JSON.parse(readFileSync(join(srcDir, "package.json"), "utf8"));

  log(`BF v${pkg.version} install`);
  if (target) {
    log(`Target: ${target}`);
  } else {
    log(`Detected: ${selectedTargets.length > 0 ? selectedTargets.join(", ") : "none"}`);
  }

  if (selectedTargets.length === 0) {
    log("No supported discovery target found.");
    log("Use: bf install --target claude");
    log("Or:  bf install --target codex");
    log("Or:  bf install --target copilot");
    return { ok: true, mode: "noop", version: pkg.version, targets: [] };
  }

  const results = [];
  for (const t of selectedTargets) {
    const path = discoveryTargetDir(t, home);
    const existed = existsSync(path);
    const previousVersion = existed ? readPreviousVersion(path) : null;
    const status = installStatus({ existed, previousVersion, version: pkg.version });
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
    writeMetadata(path, { pkg, target: t, installedAt: new Date().toISOString() });
    const result = { target: t, status, path, copied, previousVersion, version: pkg.version };
    log(formatTargetResult(result));
    results.push(result);
  }
  log("Extensions: ~/.bf/extensions unchanged");
  return { ok: true, mode: "copied", version: pkg.version, targets: results };
}
