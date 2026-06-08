---
name: repo-update
description: "Part of the Blueprintflow methodology. Use when updating the Blueprintflow repository itself, including the root BF runtime, accepted docs, package metadata, tests, CI, scripts, or release notes."
---

# Repo Update

Use this repo-local entry to change the Blueprintflow repository. Keep durable
maintenance boundaries in accepted docs; keep this skill focused on actions,
gates, and stop conditions.

During normal maintenance, ignore `plugins/blueprintflow/`. Do not read or edit
legacy plugin files, run legacy plugin validation, or bump legacy plugin
manifest versions unless the user explicitly requests legacy plugin work or the
current task intentionally touches those files.

## Flow

All Blueprintflow repo changes go through **worktree -> BF gate -> PR -> normal
merge**. Never push directly to `main`.

1. Create or use a focused worktree.
2. For behavior, architecture, parser, harness, CLI, install/update, package
   layout, or runtime-instruction changes, run the current root BF workflow from
   the shipped BF runtime instructions. Do not duplicate BF command recipes in
   this skill.
3. Validate the changed repo surfaces.
4. Commit and push the focused branch.
5. Open a PR that records BF gate evidence, validation evidence, required
   GitHub review/check status, and blocking conversation status.
6. Merge only after BF gate, required GitHub reviews/checks, and blocking
   conversations are resolved.
7. Clean up the worktree after merge.

## BF Gate

Before PR readiness or merge, verify:

- the relevant BF work object is `Completed`, or the PR records why BF was not
  required;
- required validation commands passed;
- required GitHub reviews and checks passed;
- blocking review comments, check failures, branch policy issues, and
  conversation threads are resolved.

For behavior, architecture, parser, harness, CLI, install/update, package
layout, or runtime-instruction changes, use BF unless the user explicitly says
the request is discussion only.

## Version Gates

- Release-facing BF changes require a semver bump in `package.json` and
  `package-lock.json`.
- Root runtime and discovery-snapshot changes are release-facing when published
  users receive different instructions, files, commands, package layout, or
  install/update behavior.
- Legacy plugin manifest versions change only when explicitly requested legacy
  plugin work touches legacy plugin files.

## Validation

Run for normal root BF changes:

```bash
npm test
git diff --check
.github/scripts/validate-bf-package-layout.sh
.github/scripts/validate-bf-version.sh origin/main
```

Run only when legacy plugin files are intentionally touched:

```bash
.github/scripts/validate-plugin-layout.sh
.github/scripts/validate-skills.sh
.github/scripts/validate-release-version.sh origin/main
```

## Runtime Instruction Review Gate

Run this local gate after editing root runtime instructions, role files, pack
guidance, pipeline definitions, templates, repo-local skills, or skill metadata.

1. Spawn four local reviewers in parallel when the runtime supports it. If
   parallel reviewers are unavailable, run the same four lenses sequentially.
   If four independent reviewer passes cannot be run, stop and record the
   missing review capacity before PR readiness.
2. Give each reviewer the changed file paths, the diff, this `repo-update`
   skill, the relevant accepted docs, and any BF work-object artifacts.
3. Require each reviewer to read every changed runtime instruction file as a
   whole before reading the diff.
4. For failure-driven changes, give every reviewer the recorded
   `symptom -> missing/weak instruction -> owning file -> prevention check`.
5. Require final output with `Blockers`, `Findings`, `Prevention check` when
   applicable, and `LGTM` or `NOT LGTM`.
6. Require each finding to state whether it is informational or must-fix.
7. Cover these lenses:

| Reviewer | Required questions |
|---|---|
| Global value / placement | Does this improve BF repository maintenance or runtime execution? Is the change in the right root runtime, repo instruction, design doc, or validation surface? |
| Process / completeness | Are trigger, action, owner, durable artifact, fallback, validation, and stop condition complete for the updated BF flow? |
| Language / structure | Is the instruction directive, concise, structured, and unambiguous for an orchestrating LLM? |
| Risk / anti-patterns | Does the change create source-of-truth drift, legacy-plugin leakage, version-gate gaps, stale examples, weak validation, or review bypasses? |

8. Record the four reviewer outcomes in the PR body under
   `Runtime Instruction Review Gate`, or in a PR comment linked from that
   section.
9. Fix every blocker and every must-fix finding. Re-run the affected reviewer
   lens after each fix.
10. Treat local reviewer LGTM as a prerequisite only. It does not replace BF
    final acceptance, required GitHub reviews/checks, or user approval when
    requested.
11. Do not mark the PR `BF gate` ready until all four local reviewers return
    LGTM and the durable review artifact is recorded.

## Failure-Driven Updates

When a real BF run fails because an agent stalled, serialized independent work,
bypassed a gate, misrouted, lost context, used legacy plugin source as current
authority, or required repeated user correction:

1. Record the failure as
   `symptom -> missing/weak instruction -> owning file -> prevention check`.
2. Patch the owning root runtime, repo instruction, accepted doc, or validation
   surface. Do not add generic reminders to unrelated files.
3. Ask local reviewers: `Would this exact instruction have prevented the
   observed failure? If not, return NOT LGTM with the missing command.`
4. Record the prevention-check result in the PR review-gate artifact.
5. Stop before PR readiness if the prevention check is missing or NOT LGTM.

## Rules

- Open PRs and merge only through the BF gate.
- Never push directly to `main`.
- Read changed runtime instruction files as whole files, not only diffs.
- No LGTM with open must-fix findings.
- Prefer scoped edits over rewrites unless the file's structure is stale enough
  that a full rewrite is safer and easier to review.
- Write runtime instructions as direct commands.
- Put durable rationale in `docs/`, not runtime files.
- Keep runtime artifacts self-contained; `SKILL.md`, `roles/`, `packs/`,
  `templates/`, and `references/` must not depend on `docs/`.
- Use `docs(<scope>): <description>` for repo-maintenance commits unless the
  change is primarily code behavior.

## When It Does Not Apply

- Business project code: use that project's own workflow.
- Skills or plugins outside this repository: use that project's own flow.
- Pure discussion: record conclusions only when they become accepted BF work.

## How To Invoke

```text
follow skill repo-update
```
