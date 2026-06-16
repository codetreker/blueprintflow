# Desc

Scope for this review, such as the task being reviewed, the review round, and
the specific contract file paths under review.

## Results

Group findings by severity. Any Blocker or High finding makes verify fail.
Minor and Nit findings do not block.

Recognized structure (the harness fails CLOSED on anything it cannot recognize):

- Keep the `## Results` section. Under it, use a severity subheading for each
  group: `### Blocker`, `### High`, `### Minor`, `### Nit`. Severity headings are
  matched case-insensitively, accept the singular or plural spelling
  (`### Blocker` or `### Blockers`), and may use any heading depth below
  `## Results` (`###`, `####`, ...).
- Under a severity heading, EVERY non-empty content line counts as one finding,
  whether it is a `- ` bullet or plain prose. Do not write commentary under
  `### Blocker` / `### High` unless you intend it to block.
- When there are NO findings for a severity, leave that heading EMPTY. An empty
  `### Blocker` / `### High` section means "no blocking findings"; any non-empty
  content under it is treated as a blocking finding and fails verify.
- Findings written directly under `## Results` with no severity subheading are
  treated as blocking findings (fail closed), so they are never silently dropped.

Fail-closed rule: a review-result file that lists `## Accepted Criteria` but has
no recognizable `## Results` section is treated as a parse error. The harness
makes verify FAIL and does NOT honor that file's accepted-criteria ids for
sign-off. Always include the `## Results` section, even when it is all-empty.

### Blocker

Blocking issues. Any item here makes verify fail. Include a specific file:line
and description for each finding. Leave this section EMPTY when there are no
blocking findings.

### High

High-severity issues. Any item here makes verify fail. Leave this section EMPTY
when there are no high-severity findings.

### Minor

Medium-severity issues. These do not block, but the responsible actor should
consider addressing them.

### Nit

Suggestions. These do not block.

## Accepted Criteria

Acceptance criteria this reviewer signs off.

Rules:
- Use the original acceptance criterion ids from `bf.md` or the task `spec.md`, such as AC-1 or AC-2.
- During Task Verification / Final Acceptance, if the round has no Blocker or High findings and at least one provider-role review file accepts an AC id, `bf-harness verify` treats that AC as signed.
- Spec Review and some flows may require multiple independent reviewer actor instances. That is a coordinator-enforced actor-independence rule, not something the harness infers mechanically from filenames.
- If a reviewer result file contains any Blocker or High finding, bf-harness does not use this section for signoff because the whole round has already failed.

- {id1}: One sentence explaining how the reviewer verified this criterion
- {id2}: ...
