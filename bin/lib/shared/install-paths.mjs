import { join } from "node:path";
import { homedir } from "node:os";

export const SKILL_NAME = "bf";

// Where Claude Code reads the skill from, and where user-global extensions live.
// This is NOT the same as the install dir of the BF code (which for `npm install -g`
// lives in npm's node_modules tree). Use this for anything user-facing under
// ~/.claude/skills/<SKILL_NAME>/.
export function skillsDir(home = homedir()) {
  return join(home, ".claude", "skills", SKILL_NAME);
}
