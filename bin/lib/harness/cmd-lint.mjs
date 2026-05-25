import { loadWo } from "./load-wo.mjs";
import { validateWo } from "./validate-wo.mjs";

export async function cmdLint({ baseHome, woId, installDir }) {
  const bundle = await loadWo({ baseHome, woId, installDir });
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

/**
 * Format the result of cmdLint as line-oriented text.
 * Success: `SUCCESS`.
 * Failure: `FAIL` on line 1, then one block per error:
 *   <blank line>
 *   <CODE> at <ref>
 *     <message>
 *
 * Errors come as either {code, message, ref} (from validateWo) or as
 * load-time strings (from bundle.errors). Stringified errors are emitted as
 * a single block under code `LOAD_ERROR`.
 */
export function formatLint(r) {
  if (r.ok) return "SUCCESS\n";
  const lines = ["FAIL"];
  const errs = r.errors || [];
  for (const e of errs) {
    lines.push("");
    if (typeof e === "string") {
      // Normalize embedded newlines so the indented message stays one block.
      const msg = e.replace(/\n/g, "\n  ");
      lines.push(`LOAD_ERROR at -`);
      lines.push(`  ${msg}`);
    } else {
      const code = e.code || "ERROR";
      const ref = e.ref || "-";
      const msg = (e.message || "").replace(/\n/g, "\n  ");
      lines.push(`${code} at ${ref}`);
      lines.push(`  ${msg}`);
    }
  }
  return lines.join("\n") + "\n";
}
