import path from "node:path";
import { buildPackRegistry } from "../shared/pack-registry.mjs";
import { buildPipelineRegistry } from "../shared/pipeline-registry.mjs";

export async function cmdListPipelines({ cwd, pack = null, extensionPacksDirs = [] }) {
  const packReg = buildPackRegistry({ packsDir: path.join(cwd, "packs"), extensionPacksDirs });
  const pipelineReg = buildPipelineRegistry({ packReg, pack });
  if (pipelineReg.error) return { ok: false, error: pipelineReg.error };
  const pipelines = [...pipelineReg.pipelines.values()]
    .sort((a, b) => (a.pack === b.pack ? a.id.localeCompare(b.id) : a.pack.localeCompare(b.pack)))
    .map(p => ({ id: p.id, desc: p.desc, pack: p.pack, source: p.source, file: p.file }));
  return { ok: true, pipelines, warnings: pipelineReg.warnings };
}

export function formatListPipelines(r) {
  if (!r.ok) return `${r.error || "list-pipelines failed"}\n`;
  const blocks = [];
  if (!r.pipelines || r.pipelines.length === 0) {
    blocks.push("(no pipelines installed)");
  } else {
    for (const p of r.pipelines) {
      const desc = p.desc && p.desc.length > 0 ? p.desc : "-";
      const file = p.file && p.file.length > 0 ? p.file : "-";
      blocks.push(`Id: ${p.id}\nDesc: ${desc}\nPath: ${file}`);
    }
  }
  const warnings = (r.warnings || []).map(w => `# ${w}`);
  const recordsStr = blocks.join("\n\n---\n\n");
  const warningsStr = warnings.length > 0 ? "\n\n" + warnings.join("\n") : "";
  return recordsStr + warningsStr + "\n";
}
