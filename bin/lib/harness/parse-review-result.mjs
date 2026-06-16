// Severity heading detection is tolerant: case-insensitive, singular/plural,
// and any heading depth deeper than the `## Results` section (h3..h6). The
// canonical review-result.md uses `## Results` + `### Blocker/High/Minor/Nit`,
// which still parses exactly as before.
const SEVERITY_NAMES = [
  { key: "blocker", re: /^blockers?$/ },
  { key: "high", re: /^highs?$/ },
  { key: "minor", re: /^minors?$/ },
  { key: "nit", re: /^nits?$/ },
];
const AC_ID_RE = /^-\s+([A-Za-z][\w-]*)\s*:/;

function severityKey(name) {
  const norm = name.trim().toLowerCase();
  for (const s of SEVERITY_NAMES) {
    if (s.re.test(norm)) return s.key;
  }
  return null;
}

function walkSections(text) {
  const lines = text.split("\n");
  const sections = []; // [{ level, name, body[] }]
  let cur = null;
  for (const line of lines) {
    const m = line.match(/^(#{1,6})\s+(.+?)\s*$/);
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

// Every non-empty, non-heading line under a severity heading is a finding,
// whether it is a `- ` bullet or plain prose. A leading bullet marker is
// stripped so canonical bullet findings read identically to before.
function collectFindingLines(body) {
  const out = [];
  for (const line of body) {
    const t = line.trim();
    if (!t) continue;
    out.push(t.replace(/^[-*+]\s+/, ""));
  }
  return out;
}

export function parseReviewResult(text) {
  const sections = walkSections(text);
  let desc = "";
  const severities = { blocker: [], high: [], minor: [], nit: [] };
  const acceptedIds = [];

  let sawResults = false;
  let sawAcceptedCriteria = false;
  let recognizedFindingStructure = false;
  let inResults = false;
  let resultsLevel = 0;

  for (const s of sections) {
    const nameNorm = s.name.toLowerCase();
    if (s.level === 1 && s.name === "Desc") {
      desc = s.body.join("\n").trim();
      inResults = false;
    } else if (s.level === 2 && nameNorm === "results") {
      sawResults = true;
      inResults = true;
      resultsLevel = s.level;
      // Findings may be listed directly under `## Results` with no severity
      // subheading; treat them as blocking (fail-closed) so they are never
      // silently dropped.
      const direct = collectFindingLines(s.body);
      if (direct.length > 0) {
        for (const f of direct) severities.blocker.push(f);
        recognizedFindingStructure = true;
      }
    } else if (s.level === 2 && nameNorm === "accepted criteria") {
      sawAcceptedCriteria = true;
      inResults = false;
      for (const line of s.body) {
        const m = line.match(AC_ID_RE);
        if (m) acceptedIds.push(m[1]);
      }
    } else if (inResults && s.level > resultsLevel && severityKey(s.name)) {
      const key = severityKey(s.name);
      const findings = collectFindingLines(s.body);
      recognizedFindingStructure = true;
      for (const f of findings) severities[key].push(f);
    } else if (s.level <= 2) {
      // Any other top-level/section-level heading ends the Results scope.
      inResults = false;
    }
  }

  // Fail closed: a review file that signs off acceptance criteria but carries no
  // recognizable Results structure (no `## Results`, or a `## Results` with no
  // severity subheading and no direct findings) is a parse error. Its
  // acceptedIds must not be honored — verify must fail closed on it.
  const parseError = sawAcceptedCriteria && !sawResults;
  return {
    desc,
    severities,
    acceptedIds: parseError ? [] : acceptedIds,
    parseError,
  };
}
