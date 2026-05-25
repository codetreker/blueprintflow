// Format the result of cmdStartReview as a single absolute path line.
// Success: the absolute round directory path.
// Failure: the error message on stdout.

export function formatStartReview(r) {
  if (!r.ok) return `${r.error || "start-review failed"}\n`;
  return `${r.dir}\n`;
}
