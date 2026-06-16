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

function hasNonWhitespace(body) {
  return body.some((line) => line.trim() !== "");
}

export function parseReviewResult(text) {
  const sections = walkSections(text);
  let desc = "";
  const severities = { blocker: [], high: [], minor: [], nit: [] };
  const acceptedIds = [];

  let sawResults = false;
  let sawAcceptedCriteria = false;
  let inResults = false;
  let resultsLevel = 0;

  // UNIVERSAL default-reject: the `## Results` section is structurally valid only
  // when it contains at least one recognized severity subheading
  // (`### Blocker/High/Minor/Nit`, tolerant) and the ONLY content under it is such
  // recognized severity subheadings, each followed by zero or more finding lines.
  // Any other non-whitespace content under `## Results` — a non-severity
  // subheading and its body (e.g. `### Summary`/`### Notes`), or substantive prose
  // directly under `## Results` outside any severity heading — marks the Results
  // section unrecognized, which fails closed. An entirely empty `## Results` (no
  // severity subheadings at all) is also not a recognized structure.
  let unrecognizedResultsContent = false;
  let sawSeverityHeading = false;

  for (const s of sections) {
    const nameNorm = s.name.toLowerCase();
    if (s.level === 1 && s.name === "Desc") {
      desc = s.body.join("\n").trim();
      inResults = false;
    } else if (s.level === 2 && nameNorm === "results") {
      sawResults = true;
      inResults = true;
      resultsLevel = s.level;
      // Substantive prose directly under `## Results` (outside any severity
      // heading) is not recognized structure -> fail closed.
      if (hasNonWhitespace(s.body)) unrecognizedResultsContent = true;
    } else if (s.level === 2 && nameNorm === "accepted criteria") {
      sawAcceptedCriteria = true;
      inResults = false;
      for (const line of s.body) {
        const m = line.match(AC_ID_RE);
        if (m) acceptedIds.push(m[1]);
      }
    } else if (inResults && s.level > resultsLevel) {
      const key = severityKey(s.name);
      if (key) {
        // Recognized severity subheading: collect its findings (may be empty).
        sawSeverityHeading = true;
        for (const f of collectFindingLines(s.body)) severities[key].push(f);
      } else {
        // Any non-severity subheading under `## Results` (and its body) is
        // unrecognized content -> fail closed, regardless of whether a sibling
        // severity heading is present.
        unrecognizedResultsContent = true;
      }
    } else if (s.level <= 2) {
      // Any other top-level/section-level heading ends the Results scope.
      inResults = false;
    } else if (inResults) {
      // A heading at or above the Results level under the Results scope is also
      // unrecognized content.
      unrecognizedResultsContent = true;
    }
  }

  // Fail closed: a review file that signs off acceptance criteria must carry a
  // recognized `## Results` structure — present, with at least one recognized
  // severity subheading, and no unrecognized content. Missing `## Results`, an
  // empty `## Results` with no severity subheading, or any unrecognized content
  // under it is a parse error: its acceptedIds must not be honored — verify fails
  // closed on it (collectFindings turns parseError into a blocking finding). Any
  // findings parsed from recognized severity headings are retained for
  // diagnostics; they cannot make the file pass while parseError is set.
  const parseError = sawAcceptedCriteria
    && (!sawResults || unrecognizedResultsContent || !sawSeverityHeading);
  return {
    desc,
    severities,
    acceptedIds: parseError ? [] : acceptedIds,
    parseError,
  };
}
