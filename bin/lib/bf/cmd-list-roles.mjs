import fs from "node:fs";
import path from "node:path";
import { buildRoleRegistry } from "../shared/role-registry.mjs";

export async function cmdListRoles({ cwd, pack = null, extensionRolesDirs = [] }) {
  const coreRolesDir = path.join(cwd, "roles");
  let packRolesDir = null;
  if (pack) {
    const packDir = path.join(cwd, "packs", pack);
    if (!fs.existsSync(packDir)) {
      return { ok: false, error: `pack not found: ${pack}` };
    }
    const candidate = path.join(packDir, "roles");
    if (fs.existsSync(candidate)) packRolesDir = candidate;
  }
  const reg = buildRoleRegistry({ coreRolesDir, packRolesDir, extensionRolesDirs });
  const roles = [...reg.roles.values()]
    .sort((a, b) => a.id.localeCompare(b.id))
    .map(r => ({ id: r.id, desc: r.desc, capabilities: r.capabilities, file: r.file, source: r.source }));
  return { ok: true, roles, warnings: reg.warnings };
}
