import fs from "node:fs";
import path from "node:path";
import { parsePipeline } from "../shared/parse-pipeline.mjs";
import { buildPipelineRegistry, findPipeline } from "../shared/pipeline-registry.mjs";
import { INTEGRATION_MODES } from "./integration-mode.mjs";

const VALID_INTEGRATION_MODES = new Set(Object.values(INTEGRATION_MODES));

// Mode B (P1) selector validation + accept-lock immutability.
// - INTEGRATION_INVALID: Integration present but not in {per-task-pr, single-pr}.
//   Absent/empty Integration is valid (=> Mode A / per-task-pr default).
// - INTEGRATION_LOCKED: once State != Draft, the effective Integration mode must
//   equal the harness-written Mode-Lock anchor (captured at accept). A hand-edited
//   post-accept Integration value diverges from the anchor => fail closed.
//   Legacy pre-feature WOs (no Mode-Lock) resolve to per-task-pr; absent anchor is
//   only honored when the effective mode is the Mode A default, so a post-accept
//   add of `Integration: single-pr` with no matching anchor is still rejected.
function effectiveIntegration(raw) {
  // Mirror woIntegrationMode's coercion without throwing: absent, empty string,
  // and the parse-frontmatter empty-value sentinel ([]) all mean the Mode A
  // default. Any other value is returned verbatim for membership testing.
  if (raw == null || raw === "") return INTEGRATION_MODES.PER_TASK_PR;
  if (Array.isArray(raw) && raw.length === 0) return INTEGRATION_MODES.PER_TASK_PR;
  return raw;
}

function normalizeLock(raw) {
  if (raw == null || raw === "") return null;
  if (Array.isArray(raw) && raw.length === 0) return null;
  return raw;
}

// Returns the first integration selector/lock error for this WO, or null.
// Exported so the runtime mode-reading commands (cmd-next, cmd-complete) enforce
// the accept-lock everywhere the mode is acted on — not only at lint/accept,
// which call validateWo. cmd-next/cmd-complete call loadWo only, so without this
// the INTEGRATION_LOCKED gate would be fail-open at runtime.
export function integrationError(bf) {
  const mode = effectiveIntegration(bf.frontmatter.Integration);
  // selector validation: a present-but-unknown value fails closed
  if (typeof mode !== "string" || !VALID_INTEGRATION_MODES.has(mode)) {
    return {
      code: "INTEGRATION_INVALID",
      message: `Integration "${Array.isArray(mode) ? "" : mode}" is not a known mode (expected one of ${[...VALID_INTEGRATION_MODES].join(", ")})`,
    };
  }
  // accept-lock immutability: only binds once the WO has left Draft
  if (bf.frontmatter.State === "Draft") return null;
  const lock = normalizeLock(bf.frontmatter["Mode-Lock"]);
  if (lock === null) {
    // A non-Draft WO has, by definition, passed accept — which always writes the
    // harness-owned Mode-Lock anchor (for BOTH modes). A MISSING anchor therefore
    // means one of: the anchor was hand-deleted (the silent single-pr->Mode-A
    // downgrade bypass), or the WO was accepted before Mode B (v0.8.0) shipped.
    // Either way, fail closed — do NOT silently treat it as Mode A, because that
    // is exactly the bypass. Pre-feature WOs migrate with a one-time anchor line.
    return {
      code: "INTEGRATION_LOCKED",
      message: `non-Draft work object (state ${bf.frontmatter.State}) is missing the harness-owned Mode-Lock anchor; the harness writes it at accept. A work object accepted before Mode B (v0.8.0) migrates with a one-time \`Mode-Lock: per-task-pr\` line in bf.md.`,
    };
  }
  if (lock !== mode) {
    return {
      code: "INTEGRATION_LOCKED",
      message: `Integration "${mode}" was changed after accept; locked to "${lock}" (state ${bf.frontmatter.State})`,
    };
  }
  return null;
}

function validateIntegration(bf, bfPath, errors) {
  const e = integrationError(bf);
  if (e) errors.push({ ...e, ref: bfPath });
}

const EVIDENCE_KINDS = new Set([
  "artifact",
  "command",
  "file",
  "review-note",
  "screenshot",
]);

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

const PIPELINE_FILE_RE = /^[a-z][a-z0-9-]*\.yml$/;

function localPipelineFiles(dir) {
  if (!dir || !fs.existsSync(dir)) return [];
  return fs.readdirSync(dir)
    .filter(n => !n.startsWith("."))
    .map(n => path.join(dir, n));
}

function validateLocalPipelines({ bundle, pipelineReg, selectedPackPipelineReg, errors }) {
  const dir = bundle.localPipelinesDir;
  const referenced = new Set(
    bundle.tasks
      .filter(t => t.spec)
      .map(t => `${t.spec.frontmatter.Pack}/${t.spec.frontmatter.Pipeline}`)
  );
  const seen = new Set();
  for (const file of localPipelineFiles(dir)) {
    const name = path.basename(file);
    if (!fs.statSync(file).isFile() || !PIPELINE_FILE_RE.test(name)) {
      errors.push({ code: "PIPELINE_LOCAL_FILENAME_INVALID", message: `invalid local pipeline filename: ${name}`, ref: file });
      continue;
    }
    const idFromFile = name.replace(/\.yml$/, "");
    let parsed;
    try {
      parsed = parsePipeline(fs.readFileSync(file, "utf8"));
    } catch (e) {
      errors.push({ code: "PIPELINE_LOCAL_PARSE_ERROR", message: e.message, ref: file });
      continue;
    }
    if (parsed.id !== idFromFile) {
      errors.push({ code: "PIPELINE_LOCAL_ID_MISMATCH", message: `local pipeline id "${parsed.id}" != filename "${idFromFile}"`, ref: file });
    }
    if (selectedPackPipelineReg.pipelines.has(`${bundle.bf.frontmatter.Pack}/${parsed.id}`)) {
      errors.push({ code: "PIPELINE_LOCAL_COLLISION", message: `local pipeline id collides with selected pack pipeline: ${parsed.id}`, ref: file });
    }
    if (!referenced.has(`${bundle.bf.frontmatter.Pack}/${parsed.id}`)) {
      errors.push({ code: "PIPELINE_LOCAL_UNREFERENCED", message: `local pipeline is not referenced by any task: ${parsed.id}`, ref: file });
    }
    if (!parsed.instruction) {
      errors.push({ code: "PIPELINE_LOCAL_INSTRUCTION_MISSING", message: `local pipeline ${parsed.id} must have top-level instruction`, ref: file });
    }
    if (!Array.isArray(parsed.stages) || parsed.stages.length === 0) {
      errors.push({ code: "PIPELINE_LOCAL_STAGES_EMPTY", message: `local pipeline ${parsed.id} must have stages`, ref: file });
    }
    seen.clear();
    for (const stage of parsed.stages || []) {
      const sid = String(stage?.id || "").trim();
      if (!sid) {
        errors.push({ code: "PIPELINE_LOCAL_STAGE_ID_EMPTY", message: `local pipeline ${parsed.id} has empty stage id`, ref: file });
      } else if (seen.has(sid)) {
        errors.push({ code: "PIPELINE_LOCAL_STAGE_ID_DUPLICATE", message: `local pipeline ${parsed.id} duplicates stage id ${sid}`, ref: file });
      }
      seen.add(sid);
      if (!String(stage?.instruction || "").trim()) {
        errors.push({ code: "PIPELINE_LOCAL_STAGE_INSTRUCTION_EMPTY", message: `local pipeline ${parsed.id} stage ${sid || "<empty>"} must have instruction`, ref: file });
      }
      const cap = String(stage?.capability || "").trim();
      if (cap && !bundle.roleReg.byCapability.has(cap)) {
        errors.push({ code: "PIPELINE_LOCAL_CAPABILITY_UNKNOWN", message: `local pipeline ${parsed.id} stage ${sid || "<empty>"} capability "${cap}" has no provider`, ref: file });
      }
    }
  }
}

export function validateWo(bundle) {
  const errors = [...bundle.errors];
  const { bf, bfPath, packReg, roleReg, tasks } = bundle;
  if (!bf) return { ok: false, errors };

  validateIntegration(bf, bfPath, errors);

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
    if (t.id === "pipelines") {
      errors.push({
        code: "TASK_ID_RESERVED",
        message: `task id "${t.id}" is reserved`,
        ref: bfPath,
      });
    }
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
  const selectedPackPipelineReg = buildPipelineRegistry({ packReg, pack: bf.frontmatter.Pack });
  const pipelineReg = buildPipelineRegistry({ packReg, pack: bf.frontmatter.Pack, localPipelinesDir: bundle.localPipelinesDir });
  validateLocalPipelines({ bundle, pipelineReg, selectedPackPipelineReg, errors });
  for (const ac of bf.acceptanceCriteria) checkCap(ac.capability, bfPath);
  for (const t of tasks) {
    if (!t.spec) continue;
    if ("Capability" in t.spec.frontmatter) {
      errors.push({
        code: "TASK_CAPABILITY_FORBIDDEN",
        message: `task ${t.id}: use Pipeline instead of task frontmatter Capability`,
        ref: t.specPath,
      });
    }
    if (!findPipeline(pipelineReg, t.spec.frontmatter.Pack, t.spec.frontmatter.Pipeline)) {
      errors.push({
        code: "PIPELINE_NOT_FOUND",
        message: `task ${t.id}: Pipeline=${t.spec.frontmatter.Pipeline} not found in pack ${t.spec.frontmatter.Pack}`,
        ref: t.specPath,
      });
    }
    for (const ac of t.spec.acceptanceCriteria) checkCap(ac.capability, t.specPath);
    const acIds = new Set(t.spec.acceptanceCriteria.map(ac => ac.id));
    const evidenceByAc = new Map(t.spec.acceptanceCriteria.map(ac => [ac.id, []]));
    if (!t.spec.hasEvidenceSection) {
      errors.push({
        code: "EVIDENCE_SECTION_MISSING",
        message: `task ${t.id}: spec.md must include a ## Evidence section`,
        ref: t.specPath,
      });
    }
    const evidenceIds = new Set();
    for (const ev of t.spec.evidence || []) {
      if (evidenceIds.has(ev.id)) {
        errors.push({
          code: "EVIDENCE_DUPLICATE_ID",
          message: `task ${t.id}: evidence id ${ev.id} is duplicated`,
          ref: t.specPath,
        });
      }
      evidenceIds.add(ev.id);
      if (!EVIDENCE_KINDS.has(ev.kind)) {
        errors.push({
          code: "EVIDENCE_KIND_UNKNOWN",
          message: `task ${t.id}: evidence ${ev.id} uses unknown kind ${ev.kind}`,
          ref: t.specPath,
        });
      }
      if (ev.text.trim().length === 0) {
        errors.push({
          code: "EVIDENCE_TEXT_EMPTY",
          message: `task ${t.id}: evidence ${ev.id} must state a required proof`,
          ref: t.specPath,
        });
      }
      if (!acIds.has(ev.acId)) {
        errors.push({
          code: "EVIDENCE_AC_UNKNOWN",
          message: `task ${t.id}: evidence ${ev.id} references unknown AC ${ev.acId}`,
          ref: t.specPath,
        });
      } else {
        evidenceByAc.get(ev.acId).push(ev.id);
      }
    }
    for (const ac of t.spec.acceptanceCriteria) {
      if ((evidenceByAc.get(ac.id) || []).length === 0) {
        errors.push({
          code: "EVIDENCE_MISSING",
          message: `task ${t.id}: AC ${ac.id} has no Evidence entry`,
          ref: t.specPath,
        });
      }
    }
  }

  return { ok: errors.length === 0, errors };
}
