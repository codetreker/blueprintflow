import fs from "node:fs";
import path from "node:path";
import { woDir } from "./wo-paths.mjs";
import { parseBfMd } from "./parse-bf-md.mjs";
import { parseTaskSpec } from "./parse-task-spec.mjs";
import { buildRoleRegistry } from "../shared/role-registry.mjs";
import { buildPackRegistry } from "../shared/pack-registry.mjs";
import { globalExtensionsDir } from "../shared/install-paths.mjs";

export async function loadWo({ baseHome, woId, installDir }) {
  const wo = woDir(baseHome, woId);
  const bfPath = path.join(wo, "bf.md");
  const errors = [];
  let bf = null;
  try {
    bf = parseBfMd(fs.readFileSync(bfPath, "utf8"));
  } catch (e) {
    return {
      ok: false,
      bf: null,
      bfPath,
      woPath: wo,
      tasks: [],
      packReg: null,
      roleReg: null,
      errors: [{ code: "PARSE_BF", message: e.message, ref: bfPath }],
    };
  }
  // Extension dirs: global is host-neutral under ~/.bf/extensions. Project ext
  // lives in <baseHome>/extensions/. Project wins on same id.
  const globalExt = globalExtensionsDir();
  const extensionPacksDirs = [
    path.join(globalExt, "packs"),
    path.join(baseHome, "extensions", "packs"),
  ];
  const extensionRolesDirs = [
    path.join(globalExt, "roles"),
    path.join(baseHome, "extensions", "roles"),
  ];
  const packReg = buildPackRegistry({
    packsDir: path.join(installDir, "packs"),
    extensionPacksDirs,
  });
  const packRolesDir = packReg.packs.get(bf.frontmatter.Pack)?.rolesDir || null;
  const roleReg = buildRoleRegistry({
    coreRolesDir: path.join(installDir, "roles"),
    packRolesDir,
    extensionRolesDirs,
  });
  const tasks = bf.taskList.map((t) => {
    const specPath = path.join(wo, t.id, "spec.md");
    if (!fs.existsSync(specPath)) {
      errors.push({
        code: "TASK_MISSING",
        message: `task spec missing: ${t.id}/spec.md`,
        ref: specPath,
      });
      return { id: t.id, deps: t.deps, specPath };
    }
    try {
      const spec = parseTaskSpec(fs.readFileSync(specPath, "utf8"));
      return { id: t.id, deps: t.deps, specPath, spec };
    } catch (e) {
      errors.push({ code: "PARSE_TASK", message: e.message, ref: specPath });
      return { id: t.id, deps: t.deps, specPath };
    }
  });
  return {
    ok: errors.length === 0,
    bf,
    bfPath,
    woPath: wo,
    tasks,
    packReg,
    roleReg,
    errors,
  };
}
