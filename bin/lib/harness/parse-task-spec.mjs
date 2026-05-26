import { parseFrontmatter } from "../shared/parse-frontmatter.mjs";
import { parseAcLine } from "./parse-ac-line.mjs";

const REQUIRED_FM = ["State", "Capability", "Pack", "Desc"];
const EVIDENCE_RE = /^-\s+([A-Za-z][\w-]*)\|([A-Za-z][\w-]*)\|([A-Za-z][\w-]*):\s*(.*)$/;

function splitSections(body) {
  const lines = body.split("\n");
  const sections = {};
  let current = null;
  let buf = [];
  const flush = () => { if (current) sections[current] = buf.join("\n").trim(); };
  for (const line of lines) {
    const m = line.match(/^#{1,2}\s+(.+?)\s*$/);
    if (m) { flush(); current = m[1].trim(); buf = []; }
    else if (current) { buf.push(line); }
  }
  flush();
  return sections;
}

export function parseTaskSpec(text) {
  const { frontmatter, body } = parseFrontmatter(text);
  for (const k of REQUIRED_FM) {
    if (!(k in frontmatter)) throw new Error(`task spec.md frontmatter missing: ${k}`);
  }
  const sections = splitSections(body);
  const hasEvidenceSection = Object.prototype.hasOwnProperty.call(sections, "Evidence");
  const acceptanceCriteria = [];
  for (const line of (sections["Acceptance Criteria"] || "").split("\n")) {
    if (!line.startsWith("- [")) continue;
    const ac = parseAcLine(line);
    if (!ac) throw new Error(`malformed AC line: ${JSON.stringify(line)}`);
    acceptanceCriteria.push(ac);
  }
  const evidence = [];
  for (const line of (sections["Evidence"] || "").split("\n")) {
    if (!line.startsWith("- ")) continue;
    const m = line.match(EVIDENCE_RE);
    if (!m) throw new Error(`malformed Evidence line: ${JSON.stringify(line)}`);
    const [, id, acId, kind, text] = m;
    evidence.push({ id, acId, kind, text: text.trim() });
  }
  return {
    frontmatter,
    task: sections["Task"] || "",
    requirements: (sections["Requirements"] || "")
      .split("\n").filter(l => l.startsWith("- ")).map(l => l.replace(/^-\s+/, "").trim()),
    acceptanceCriteria,
    hasEvidenceSection,
    evidence,
    boundary: sections["Boundary"] || "",
  };
}
