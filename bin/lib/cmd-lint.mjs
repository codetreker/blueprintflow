import { loadWo } from "./load-wo.mjs";
import { validateWo } from "./validate-wo.mjs";

export async function cmdLint({ baseHome, projectSlug, woId, repoRoot }) {
  const bundle = await loadWo({ baseHome, projectSlug, woId, repoRoot });
  // bf.md 解析失败 → 直接返回（其它检查没意义）
  if (!bundle.bf) return { ok: false, errors: bundle.errors };

  const errors = [];
  if (bundle.bf.frontmatter.State !== "Draft") {
    errors.push({
      code: "BAD_STATE",
      message: `lint requires State=Draft, got ${bundle.bf.frontmatter.State}`,
      ref: bundle.bfPath,
    });
  }
  const validation = validateWo(bundle);
  errors.push(...validation.errors);
  if (errors.length > 0) return { ok: false, errors };
  return { ok: true };
}
