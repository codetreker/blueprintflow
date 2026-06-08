import { spawnSync } from "node:child_process";

export const UPDATE_COMMAND = ["install", "-g", "@codetreker/bf@latest"];

export async function cmdUpdate({ runner = spawnSync, log = console.log } = {}) {
  const commandText = `npm ${UPDATE_COMMAND.join(" ")}`;
  log(`BF update: ${commandText}`);

  try {
    const result = runner("npm", UPDATE_COMMAND, { stdio: "inherit" });
    if (result?.error) {
      return { ok: false, command: commandText, error: result.error.message };
    }
    return { ok: result?.status === 0, command: commandText, status: result?.status };
  } catch (err) {
    return { ok: false, command: commandText, error: String(err?.message || err) };
  }
}
