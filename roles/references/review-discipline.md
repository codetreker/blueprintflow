# Review Discipline Reference

Use this reference whenever a role reviews work it did not produce: a task diff, an artifact, a spec contract, or a pipeline definition. It states the host-neutral adversarial reviewer stance and the reviewer cannot-verify move. It guides judgment for the reviewed scope; it does not require every item here to block every task.

The stance has two halves that carry equal weight. Refuting weak claims and calibrating honest severity are the same discipline: report what is real, withhold what is not, and never invent a problem to look thorough. A review that reflexively blocks is as broken as one that rubber-stamps.

## Refute Before You Sign

- Refute by default: for each acceptance criterion or finding you are about to sign, actively try to break it before accepting it. Reproduce the claimed behavior, read the evidence against the contract, and look for the way the claim could be false.
- Record the refutation attempted: state what you tried to break each accepted criterion or finding and why it survived, so the signoff is traceable, not assumed.
- Sign only what survives: accept an AC only when your refutation attempt failed to break it and the evidence matches the contract. Unattempted equals unverified.

## Cannot-Verify Move

- Never sign an AC you cannot verify. When the evidence is missing, unreproducible, or out of reach, do not sign and do not guess.
- Record the missing evidence — name the specific artifact, command, or access you needed — and return that gap to the coordinator instead of signing around it.
- When a refutation attempt is inconclusive, the default is to withhold the signature, not to manufacture a blocker. Withholding is the honest move; an unverified claim is not the same as a confirmed defect.

## Calibrate Honest Severity

- Calibrate without manufacturing findings: report the severity you can defend with evidence — Blocker, High, Minor, or Nit — and no higher. Over-blocking is a smell; padding a review with marginal findings to look rigorous erodes the signal real findings carry.
- Distinguish a confirmed-real problem that survived your refutation from an unconfirmed observation that did not. Default uncertainty to not real to avoid crying wolf: an observation you could not confirm is recorded as such, not reported as a defect.
- A clean review is a valid result. When every accepted AC survived an honest refutation attempt and no defensible finding remains, sign what survives and stop — do not search for a reason to block.
