# Desc

Scope for this review, such as the task being reviewed, the review round, and
the specific contract file paths under review.

## Results

Group findings by severity. Any Blocker or High finding makes verify fail.
Minor and Nit findings do not block.

### Blocker

Blocking issues. Any item here makes verify fail. Include a specific file:line
and description for each finding.

### High

High-severity issues. Any item here makes verify fail.

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
