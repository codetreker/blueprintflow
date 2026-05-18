import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkgPath = resolve(__dirname, "../../../package.json");
const { version: PKG_VERSION } = JSON.parse(readFileSync(pkgPath, "utf8"));

export async function version() {
  process.stdout.write(PKG_VERSION + "\n");
  process.exit(0);
}
