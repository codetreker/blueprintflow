import fs from "node:fs";
import path from "node:path";
import { parseRole } from "./parse-role.mjs";

function listMdFiles(dir) {
  if (!dir || !fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter(n => n.endsWith(".md") && !n.startsWith("."))
    .map(n => path.join(dir, n));
}

function loadRolesFrom(dir, source, warnings) {
  const out = [];
  for (const file of listMdFiles(dir)) {
    try {
      const text = fs.readFileSync(file, "utf8");
      const role = parseRole(text);
      out.push({ ...role, source, file });
    } catch (e) {
      warnings.push(`skip role ${file}: ${e.message}`);
    }
  }
  return out;
}

// Precedence (later wins): core < packRolesDirs... < extensionRolesDirs...
// Callers should pass extensionRolesDirs ordered global-first, project-last so the project
// override beats everything.
export function buildRoleRegistry({ coreRolesDir, packRolesDir = null, packRolesDirs = [], extensionRolesDirs = [] }) {
  const warnings = [];
  const packDirs = [
    ...(packRolesDir ? [packRolesDir] : []),
    ...packRolesDirs,
  ];
  const layers = [
    [coreRolesDir, "core"],
    ...packDirs.map(d => [d, "pack"]),
    ...extensionRolesDirs.map(d => [d, "extension"]),
  ];

  const roles = new Map();
  for (const [dir, source] of layers) {
    for (const r of loadRolesFrom(dir, source, warnings)) {
      roles.set(r.id, r);
    }
  }

  const byCapability = new Map();
  for (const r of roles.values()) {
    for (const cap of r.capabilities) {
      if (!byCapability.has(cap)) byCapability.set(cap, []);
      byCapability.get(cap).push(r);
    }
  }
  return { roles, byCapability, warnings };
}
