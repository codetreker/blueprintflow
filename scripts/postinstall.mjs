#!/usr/bin/env node
// Delegate to `bf install`. Run as the npm `postinstall` hook.
import { execFileSync } from "node:child_process";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

try {
  execFileSync(
    process.execPath,
    [join(__dirname, "..", "bin", "bf.mjs"), "install"],
    { stdio: "inherit" }
  );
} catch (err) {
  console.warn(`⚠ BF postinstall failed. Run 'bf install' manually.`);
  console.warn(`  Error: ${err.message}`);
}
