import { parseFrontmatter } from "./parse-frontmatter.mjs";

function splitSections(body) {
  const lines = body.split("\n");
  const sections = {};
  let current = null;
  let buf = [];
  const flush = () => { if (current) sections[current] = buf.join("\n").trim(); };
  for (const line of lines) {
    const m = line.match(/^#{1,2}\s+(.+?)\s*$/);
    if (m) { flush(); current = m[1].trim(); buf = []; }
    else if (current) buf.push(line);
  }
  flush();
  return sections;
}

const SECTION_KEYS = {
  "When to Use": "whenToUse",
  "Domain Vocabulary": "domainVocabulary",
  "Brainstorm Guidance": "brainstormGuidance",
  "Breakdown Guidance": "breakdownGuidance",
  "Execute Guidance": "executeGuidance",
};

export function parsePack(text) {
  const { frontmatter, body } = parseFrontmatter(text);
  for (const k of ["Id", "Desc"]) {
    if (!(k in frontmatter)) throw new Error(`pack frontmatter missing: ${k}`);
  }
  const raw = splitSections(body);
  const sections = {};
  for (const [k, slug] of Object.entries(SECTION_KEYS)) {
    if (raw[k]) sections[slug] = raw[k];
  }
  if (!sections.whenToUse) {
    throw new Error(`pack.md missing required section: When to Use`);
  }
  return {
    id: frontmatter.Id,
    desc: frontmatter.Desc,
    sections,
  };
}
