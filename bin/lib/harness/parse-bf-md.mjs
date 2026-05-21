import { parseFrontmatter } from "../shared/parse-frontmatter.mjs";
import { parseAcLine } from "./parse-ac-line.mjs";

const REQUIRED_FM = ["Id", "Desc", "Pack", "State"];

function splitSections(body) {
  const lines = body.split("\n");
  const sections = {};
  let current = null;
  let buf = [];
  const flush = () => { if (current) sections[current] = buf.join("\n").trim(); };
  for (const line of lines) {
    const m = line.match(/^#{1,2}\s+(.+?)\s*$/);
    if (m) {
      flush();
      current = m[1].trim();
      buf = [];
    } else if (current) {
      buf.push(line);
    }
  }
  flush();
  return sections;
}

function parseTaskList(text) {
  if (!text) return [];
  const out = [];
  for (const line of text.split("\n")) {
    const m = line.match(/^-\s+([\w-]+)(?:\s*:\s*(.+))?$/);
    if (!m) continue;
    const id = m[1];
    const deps = m[2] ? m[2].split(",").map(s => s.trim()).filter(Boolean) : [];
    out.push({ id, deps });
  }
  return out;
}

function parseAcSection(text) {
  if (!text) return [];
  const out = [];
  for (const line of text.split("\n")) {
    if (!line.startsWith("- [")) continue;
    const ac = parseAcLine(line);
    if (!ac) throw new Error(`malformed AC line: ${JSON.stringify(line)}`);
    out.push(ac);
  }
  return out;
}

export function parseBfMd(text) {
  const { frontmatter, body } = parseFrontmatter(text);
  for (const k of REQUIRED_FM) {
    if (!(k in frontmatter)) throw new Error(`bf.md frontmatter missing: ${k}`);
  }
  const sections = splitSections(body);
  return {
    frontmatter,
    goal: sections["Goal"] || "",
    requirements: (sections["Requirement"] || "")
      .split("\n").filter(l => l.startsWith("- ")).map(l => l.replace(/^-\s+/, "").trim()),
    acceptanceCriteria: parseAcSection(sections["Acceptance Criteria"]),
    boundary: sections["Boundary"] || "",
    taskList: parseTaskList(sections["Task List"]),
  };
}
