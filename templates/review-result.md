# Desc

Scope for this review, such as the task being reviewed, the review round, and
the specific contract file paths under review.

## Results

### Blocker

### High

### Minor

### Nit

## Accepted Criteria

- {id1}: One sentence explaining how the reviewer verified this criterion
- {id2}: ...

## Reviewer Guidance

This guidance is documentation only; it lives OUTSIDE `## Results`. The `##
Results` section above must contain ONLY the four recognized severity subheadings
and their findings — nothing else.

### How `## Results` is parsed (fail closed)

The harness recognizes ONLY these severity subheadings under `## Results`:
`### Blocker`, `### High`, `### Minor`, `### Nit`. They are matched
case-insensitively, accept the singular or plural spelling (`### Blocker` or
`### Blockers`), and may use any heading depth below `## Results` (`###`,
`####`, ...).

Universal rule — any non-severity content under `## Results` is a parse error and
fails closed:

- A `## Results` that contains any non-severity subheading (for example
  `### Summary`, `### Notes`, `### Findings`) — even alongside the severity
  subheadings — is a parse error.
- Substantive prose written directly under `## Results`, outside any severity
  heading, is a parse error.
- A `## Results` with no recognized severity subheading at all (empty, or only
  unrecognized content) is a parse error.
- A missing `## Results` section is a parse error.

On a parse error the harness makes `bf-harness verify` FAIL and does NOT honor
that file's `## Accepted Criteria` ids for sign-off. Always include the
`## Results` section with the four severity subheadings.

### Writing findings

- Under a severity heading, EVERY non-empty content line counts as one finding,
  whether it is a `- ` bullet or plain prose. Include a specific file:line and
  description for each Blocker or High finding.
- Any Blocker or High finding makes verify fail. Minor and Nit findings do not
  block but the responsible actor should consider addressing them.
- When there are NO findings for a severity, leave that heading EMPTY. An empty
  `### Blocker` / `### High` section means "no blocking findings"; any non-empty
  content under it is treated as a blocking finding and fails verify.
- Do NOT write reviewer commentary, summaries, or sign-off rationale under
  `## Results`. Put it under `## Accepted Criteria` (per AC) or here. Do not bury
  a finding only in `# Desc`.

### Accepted Criteria rules

- Use the original acceptance criterion ids from `bf.md` or the task `spec.md`, such as AC-1 or AC-2.
- During Task Verification / Final Acceptance, if the round has no Blocker or High findings and at least one provider-role review file accepts an AC id, `bf-harness verify` treats that AC as signed.
- Spec Review and some flows may require multiple independent reviewer actor instances. That is a coordinator-enforced actor-independence rule, not something the harness infers mechanically from filenames.
- If a reviewer result file contains any Blocker or High finding, bf-harness does not use this section for signoff because the whole round has already failed.
