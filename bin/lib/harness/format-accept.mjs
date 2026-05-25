// Format the result of cmdAccept as line-oriented text.
// Success:
//   SUCCESS
//   bf.md: Draft -> Accepted
//   <task-id>: Draft -> Ready
//   Updated: <timestamp>
// Failure:
//   FAIL
//   <blank line>
//   <top-level error message>
//   <blank line>
//   <CODE> at <ref>
//     <message>
//   ...
//
// The FAIL body shape mirrors format-lint.mjs (blank line separator, indented
// detail block). When cmdAccept returns structured `details`, render them with
// the same `<code> at <ref>` / `LOAD_ERROR at -` blocks as the lint formatter.
//
// cmd-accept returns transitions as structured `{from, to}` pairs so this
// formatter — not the cmd module — owns the display string (arrow glyph,
// direction, capitalization). To switch `->` to `→`, edit this file only.

function renderTransition(t) {
  if (!t) return "";
  return `${t.from} -> ${t.to}`;
}

function renderDetail(e) {
  if (typeof e === "string") {
    const msg = e.replace(/\n/g, "\n  ");
    return [`LOAD_ERROR at -`, `  ${msg}`];
  }
  const code = (e.code || "ERROR").replace(/\n/g, " ");
  const ref = (e.ref || "-").replace(/\n/g, " ");
  const msg = (e.message || "").replace(/\n/g, "\n  ");
  return [`${code} at ${ref}`, `  ${msg}`];
}

export function formatAccept(r) {
  if (!r.ok) {
    const lines = ["FAIL", "", r.error || "accept failed"];
    const details = Array.isArray(r.details) ? r.details : [];
    for (const e of details) {
      lines.push("");
      lines.push(...renderDetail(e));
    }
    return lines.join("\n") + "\n";
  }
  const t = r.transitioned || {};
  const lines = ["SUCCESS"];
  if (t.bf) lines.push(`bf.md: ${renderTransition(t.bf)}`);
  for (const [taskId, transition] of Object.entries(t.tasks || {})) {
    lines.push(`${taskId}: ${renderTransition(transition)}`);
  }
  if (t.timestamp) lines.push(`Updated: ${t.timestamp}`);
  return lines.join("\n") + "\n";
}
