const SEVERITY_TO_KEY = { Blocker: "blocker", High: "high", Minor: "minor", Nit: "nit" };
const AC_ID_RE = /^-\s+([A-Za-z][\w-]*)\s*:/;

function walkSections(text) {
  const lines = text.split("\n");
  const sections = []; // [{ level, name, body[] }]
  let cur = null;
  for (const line of lines) {
    const m = line.match(/^(#{1,3})\s+(.+?)\s*$/);
    if (m) {
      if (cur) sections.push(cur);
      cur = { level: m[1].length, name: m[2].trim(), body: [] };
    } else if (cur) {
      cur.body.push(line);
    }
  }
  if (cur) sections.push(cur);
  return sections;
}

export function parseReviewResult(text) {
  const sections = walkSections(text);
  let desc = "";
  const severities = { blocker: [], high: [], minor: [], nit: [] };
  const acceptedIds = [];

  let inResults = false;
  for (const s of sections) {
    if (s.level === 1 && s.name === "Desc") {
      desc = s.body.join("\n").trim();
    } else if (s.level === 2 && s.name === "Results") {
      inResults = true;
    } else if (s.level === 2 && s.name === "Accepted Criteria") {
      inResults = false;
      for (const line of s.body) {
        const m = line.match(AC_ID_RE);
        if (m) acceptedIds.push(m[1]);
      }
    } else if (inResults && s.level === 3 && SEVERITY_TO_KEY[s.name]) {
      const key = SEVERITY_TO_KEY[s.name];
      for (const line of s.body) {
        const t = line.trim();
        if (t.startsWith("- ")) severities[key].push(t.replace(/^-\s+/, ""));
      }
    } else if (s.level === 2) {
      inResults = false;
    }
  }
  return { desc, severities, acceptedIds };
}
