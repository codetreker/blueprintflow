import { parseFrontmatter } from "./parse-frontmatter.mjs";

export function parseRole(text) {
  const { frontmatter } = parseFrontmatter(text);
  for (const k of ["Id", "Desc", "Capabilities"]) {
    if (!(k in frontmatter)) throw new Error(`role frontmatter missing: ${k}`);
  }
  if (!Array.isArray(frontmatter.Capabilities) || frontmatter.Capabilities.length === 0) {
    throw new Error(`role.Capabilities must be a non-empty list`);
  }
  return {
    id: frontmatter.Id,
    desc: frontmatter.Desc,
    capabilities: frontmatter.Capabilities.slice(),
  };
}
