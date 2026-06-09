import { spawnSync } from "node:child_process";

const GITHUB_PR_RE = /^https:\/\/github\.com\/([^/]+)\/([^/]+)\/pull\/([1-9][0-9]*)\/?$/;

export function parseGitHubPrUrl(url) {
  const m = String(url || "").match(GITHUB_PR_RE);
  if (!m) return null;
  return {
    owner: m[1],
    repo: m[2],
    number: Number(m[3]),
    repoSlug: `${m[1]}/${m[2]}`.toLowerCase(),
    url: `https://github.com/${m[1]}/${m[2]}/pull/${m[3]}`,
  };
}

export function parseGitHubRemoteUrl(url) {
  const text = String(url || "").trim();
  const patterns = [
    /^https:\/\/github\.com\/([^/]+)\/(.+?)(?:\.git)?$/,
    /^git@github\.com:([^/]+)\/(.+?)(?:\.git)?$/,
    /^ssh:\/\/git@github\.com\/([^/]+)\/(.+?)(?:\.git)?$/,
  ];
  for (const re of patterns) {
    const m = text.match(re);
    if (!m) continue;
    return {
      owner: m[1],
      repo: m[2],
      repoSlug: `${m[1]}/${m[2]}`.toLowerCase(),
    };
  }
  return null;
}

export function readGitHubPr(url) {
  const r = spawnSync("gh", ["pr", "view", url, "--json", "mergedAt,state,headRefName,url"], {
    encoding: "utf8",
  });
  if (r.status !== 0) {
    return {
      ok: false,
      error: `GitHub PR lookup failed: ${String(r.stderr || r.stdout || "gh command failed").trim()}`,
    };
  }
  try {
    const pr = JSON.parse(String(r.stdout || "{}"));
    return {
      ok: true,
      pr: {
        ...pr,
        merged: pr.state === "MERGED" || Boolean(pr.mergedAt),
      },
    };
  } catch (err) {
    return { ok: false, error: `GitHub PR lookup returned invalid JSON: ${err.message}` };
  }
}
