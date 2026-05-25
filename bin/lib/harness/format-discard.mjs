// Format the result of cmdDiscard.
// Success: `Removed <abs-path>`.
// Failure: the error message on stdout.

export function formatDiscard(r) {
  if (!r.ok) return `${r.error || "discard failed"}\n`;
  return `Removed ${r.removed}\n`;
}
