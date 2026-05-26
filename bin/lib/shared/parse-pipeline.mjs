import YAML from "yaml";

export function parsePipeline(text) {
  const parsed = YAML.parse(text);
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("pipeline must be a YAML mapping");
  }
  for (const k of ["id", "desc"]) {
    if (!(k in parsed) || String(parsed[k] || "").trim().length === 0) {
      throw new Error(`pipeline missing: ${k}`);
    }
  }
  return {
    id: String(parsed.id).trim(),
    desc: String(parsed.desc).trim(),
    instruction: String(parsed.instruction || "").trim(),
    stages: Array.isArray(parsed.stages) ? parsed.stages : [],
  };
}
