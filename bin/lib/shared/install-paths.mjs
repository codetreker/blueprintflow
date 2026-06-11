import { join } from "node:path";
import { homedir } from "node:os";
import { existsSync } from "node:fs";

export const SKILL_NAME = "bf";
export const DISCOVERY_TARGETS = ["claude", "codex", "copilot"];

// Back-compat alias for the Claude discovery copy.
// This is NOT the same as the install dir of the BF code (which for `npm install -g`
// lives in npm's node_modules tree).
export function skillsDir(home = homedir()) {
  return discoveryTargetDir("claude", home);
}

export function codexHomeDir(home = homedir()) {
  return process.env.CODEX_HOME || join(home, ".codex");
}

export function discoveryRootDir(target, home = homedir()) {
  switch (target) {
    case "claude": return join(home, ".claude");
    case "codex": return codexHomeDir(home);
    case "copilot": return join(home, ".copilot");
    default: throw new Error(`unknown discovery target: ${target}`);
  }
}

export function discoveryTargetDir(target, home = homedir()) {
  switch (target) {
    case "claude": return join(home, ".claude", "skills", SKILL_NAME);
    case "codex": return join(codexHomeDir(home), "skills", SKILL_NAME);
    case "copilot": return join(home, ".copilot", "skills", SKILL_NAME);
    default: throw new Error(`unknown discovery target: ${target}`);
  }
}

export function isDiscoveryTarget(target) {
  return DISCOVERY_TARGETS.includes(target);
}

export function detectDiscoveryTargets(home = homedir()) {
  return DISCOVERY_TARGETS.filter((target) =>
    existsSync(discoveryRootDir(target, home)) ||
    existsSync(discoveryTargetDir(target, home))
  );
}

export function resolveDiscoveryTargets({ target = null, home = homedir() } = {}) {
  if (target) {
    if (!isDiscoveryTarget(target)) throw new Error(`unknown discovery target: ${target}`);
    return [target];
  }
  return detectDiscoveryTargets(home);
}

export function globalExtensionsDir(home = homedir()) {
  return join(home, ".bf", "extensions");
}
