import fs from "node:fs";
import path from "node:path";
import { parsePipeline } from "./parse-pipeline.mjs";

const PIPELINE_FILE_RE = /^[a-z][a-z0-9-]*\.yml$/;

function listPipelineFiles(dir) {
  if (!dir || !fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter(n => n.endsWith(".yml") && !n.startsWith("."))
    .map(n => path.join(dir, n));
}

function loadLocalPipelines(localPipelinesDir, pack, warnings) {
  const pipelines = [];
  if (!localPipelinesDir || !fs.existsSync(localPipelinesDir)) return pipelines;
  for (const file of listPipelineFiles(localPipelinesDir)) {
    const name = path.basename(file);
    if (!PIPELINE_FILE_RE.test(name)) {
      warnings.push(`skip local pipeline ${file}: invalid pipeline filename`);
      continue;
    }
    const idFromFile = name.replace(/\.yml$/, "");
    try {
      const parsed = parsePipeline(fs.readFileSync(file, "utf8"));
      if (parsed.id !== idFromFile) {
        warnings.push(`skip local pipeline ${file}: id "${parsed.id}" != filename "${idFromFile}"`);
        continue;
      }
      pipelines.push({
        ...parsed,
        pack,
        source: "local",
        file,
      });
    } catch (e) {
      warnings.push(`skip local pipeline ${file}: ${e.message}`);
    }
  }
  return pipelines;
}

function loadPipelinesForPack(pack, warnings) {
  const pipelines = [];
  const pipelinesDir = path.join(pack.dir, "pipelines");
  for (const file of listPipelineFiles(pipelinesDir)) {
    const name = path.basename(file);
    if (!PIPELINE_FILE_RE.test(name)) {
      warnings.push(`skip pipeline ${file}: invalid pipeline filename`);
      continue;
    }
    const idFromFile = name.replace(/\.yml$/, "");
    try {
      const parsed = parsePipeline(fs.readFileSync(file, "utf8"));
      if (parsed.id !== idFromFile) {
        warnings.push(`skip pipeline ${file}: id "${parsed.id}" != filename "${idFromFile}"`);
        continue;
      }
      pipelines.push({
        ...parsed,
        pack: pack.id,
        source: pack.source,
        file,
      });
    } catch (e) {
      warnings.push(`skip pipeline ${file}: ${e.message}`);
    }
  }
  return pipelines;
}

export function buildPipelineRegistry({ packReg, pack = null, localPipelinesDir = null }) {
  const warnings = [...(packReg.warnings || [])];
  const pipelines = new Map();
  const packs = [];

  if (pack) {
    const found = packReg.packs.get(pack);
    if (!found) return { pipelines, warnings, error: `pack not found: ${pack}` };
    packs.push(found);
  } else {
    packs.push(...packReg.packs.values());
  }

  for (const p of packs) {
    for (const pipeline of loadPipelinesForPack(p, warnings)) {
      pipelines.set(`${pipeline.pack}/${pipeline.id}`, pipeline);
    }
  }
  if (pack && localPipelinesDir) {
    for (const pipeline of loadLocalPipelines(localPipelinesDir, pack, warnings)) {
      const key = `${pack}/${pipeline.id}`;
      if (pipelines.has(key)) {
        warnings.push(`local pipeline id collides with selected pack pipeline: ${pipeline.id}`);
        continue;
      }
      pipelines.set(key, pipeline);
    }
  }
  return { pipelines, warnings };
}

export function findPipeline(reg, pack, id) {
  return reg.pipelines.get(`${pack}/${id}`) || null;
}
