// Format the result of cmdVerify.
// Three distinct outcomes — all rendered as plain strings; the dispatcher in
// bf-harness.mjs decides which stream and which exit code:
//   1. verification ran, status SUCCESS   -> stdout: "SUCCESS <abs-path>" (exit 0)
//   2. verification ran, status FAIL      -> stdout: "FAIL <abs-path>"    (exit 1)
//   3. command-level setup failure        -> stderr: "bf-harness verify: <error>" (exit 1)
//
// Load failures route to stderr so the same `FAIL` prefix on stdout always means
// "verification ran and produced a FAIL result", not "the command couldn't start".

export function formatVerifyResult(r) {
  return `${r.status} ${r.path}\n`;
}

export function formatVerifySetupError(r) {
  return `bf-harness verify: ${r.error || "verify failed"}\n`;
}
