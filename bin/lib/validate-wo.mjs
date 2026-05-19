function detectCycle(bf) {
  const graph = new Map(bf.taskList.map((t) => [t.id, t.deps]));
  const WHITE = 0, GRAY = 1, BLACK = 2;
  const color = new Map([...graph.keys()].map((k) => [k, WHITE]));
  const visit = (n) => {
    if (color.get(n) === GRAY) return true;
    if (color.get(n) === BLACK) return false;
    color.set(n, GRAY);
    for (const d of graph.get(n) || []) if (visit(d)) return true;
    color.set(n, BLACK);
    return false;
  };
  for (const k of graph.keys()) if (visit(k)) return k;
  return null;
}

export function validateWo(bundle) {
  const errors = [...bundle.errors];
  const { bf, bfPath, packReg, roleReg, tasks } = bundle;
  if (!bf) return { ok: false, errors };

  if (!packReg.packs.has(bf.frontmatter.Pack)) {
    errors.push({
      code: "PACK_NOT_FOUND",
      message: `Pack "${bf.frontmatter.Pack}" not in packs/`,
      ref: bfPath,
    });
  }
  for (const t of tasks) {
    if (t.spec && t.spec.frontmatter.Pack !== bf.frontmatter.Pack) {
      errors.push({
        code: "PACK_MISMATCH",
        message: `task ${t.id}: Pack=${t.spec.frontmatter.Pack} != bf.md Pack=${bf.frontmatter.Pack}`,
        ref: t.specPath,
      });
    }
  }
  const ids = new Set(bf.taskList.map((t) => t.id));
  for (const t of bf.taskList) {
    for (const d of t.deps) {
      if (!ids.has(d)) {
        errors.push({
          code: "DEP_UNKNOWN",
          message: `task ${t.id} depends on unknown ${d}`,
          ref: bfPath,
        });
      }
    }
  }
  const cycleAt = detectCycle(bf);
  if (cycleAt) {
    errors.push({
      code: "DEP_CYCLE",
      message: `dependency cycle reachable from ${cycleAt}`,
      ref: bfPath,
    });
  }

  const checkCap = (cap, ref) => {
    if (!roleReg.byCapability.has(cap)) {
      errors.push({
        code: "CAPABILITY_UNKNOWN",
        message: `capability "${cap}" has no provider in roles`,
        ref,
      });
    }
  };
  for (const ac of bf.acceptanceCriteria) checkCap(ac.capability, bfPath);
  for (const t of tasks) {
    if (!t.spec) continue;
    checkCap(t.spec.frontmatter.Capability, t.specPath);
    for (const ac of t.spec.acceptanceCriteria) checkCap(ac.capability, t.specPath);
  }

  return { ok: errors.length === 0, errors };
}
