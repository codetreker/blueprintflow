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

export function buildRoleRegistry({ coreRolesDir, packRolesDir = null }) {
  const warnings = [];
  const coreRoles = loadRolesFrom(coreRolesDir, "core", warnings);
  const packRoles = loadRolesFrom(packRolesDir, "pack", warnings);

  const roles = new Map();
  for (const r of coreRoles) roles.set(r.id, r);
  for (const r of packRoles) roles.set(r.id, r); // pack 覆盖 core

  const byCapability = new Map();
  for (const r of roles.values()) {
    for (const cap of r.capabilities) {
      if (!byCapability.has(cap)) byCapability.set(cap, []);
      byCapability.get(cap).push(r);
    }
  }
  return { roles, byCapability, warnings };
}
