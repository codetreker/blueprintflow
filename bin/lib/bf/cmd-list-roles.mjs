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

/**
 * Format the result of cmdListRoles as labeled key:value blocks (one block
 * per role, separated by a blank line). Matches the style of `bf-harness
 * next` for consistency across the CLI.
 *
 * Empty: `(no roles installed)`.
 * Failure: `<error>` on stdout.
 * Warnings (if any) appended at the end as `# <warning>` lines.
 *
 * Example:
 *   Id: architect
 *   Desc: System architect — owns design and design review.
 *   Capabilities: [system-architecture, design-review]
 *   Source: core
 *   File: /…/roles/architect.md
 *
 * Every field is on its own line with a stable label; `grep '^Capabilities:'`
 * pulls every role's capability list in one shot.
 */
export function formatListRoles(r) {
  if (!r.ok) return `${r.error || "list-roles failed"}\n`;
  const blocks = [];
  if (!r.roles || r.roles.length === 0) {
    blocks.push("(no roles installed)");
  } else {
    for (const role of r.roles) {
      const desc = role.desc && role.desc.length > 0 ? role.desc : "-";
      const caps = `[${(role.capabilities || []).join(", ")}]`;
      const source = role.source || "-";
      const file = role.file && role.file.length > 0 ? role.file : "-";
      blocks.push(
        `Id: ${role.id}\nDesc: ${desc}\nCapabilities: ${caps}\nSource: ${source}\nFile: ${file}`
      );
    }
  }
  const warnings = (r.warnings || []).map(w => `# ${w}`);
  const recordsStr = blocks.join("\n\n---\n\n");
  const warningsStr = warnings.length > 0 ? "\n\n" + warnings.join("\n") : "";
  return recordsStr + warningsStr + "\n";
}
