# Brainstorm

Goal: produce `discussion.md` capturing the user's intent, decisions, and trade-offs.

## Phase Gate

Before pack selection, bootstrap, spec authoring, task breakdown, accept, or execution:

1. Confirm this is a new software-change brainstorm or an existing work object that is still in brainstorm.
2. If the request names an existing work object, read its `discussion.md` and report current brainstorm status before changing anything.
3. If no work object exists, run Pack Selection and Bootstrap below.
4. Report the selected pack, work object path, source coverage state, and the next missing coverage item.
5. Continue only inside the Brainstorm Loop until Exit is satisfied.

## Hard Gates

- Do not author `bf.md`.
- Do not create task specs.
- Do not start task breakdown.
- Do not run Spec Review, `accept`, `next`, or execution commands.
- Do not move to spec authoring until source coverage is complete and the user explicitly agrees to enter spec authoring.
- Do not treat an assistant-led proposal as source material until the user confirms or accepts it.
- Do not resolve multiple coverage gaps in one jump. Work one unresolved coverage gap at a time.
- Write each accepted answer, decision, tradeoff, and proposal update to `discussion.md` as it happens.

`discussion.md` is never locked; you can append to it at any phase.

## User Decision Briefs

Before asking the user to choose between materially different brainstorm paths, present a concise decision brief. Name the decision, relevant context and current evidence, realistic options, tradeoffs or consequences, and a recommendation when evidence supports one.

Keep the Brainstorm Loop focused on one unresolved coverage gap at a time. Lightweight prompts are still valid for simple factual clarifications, status updates, and obvious yes/no confirmations where the immediate context is clear.

## Pack Selection

1. Run `bf list-packs`.
2. Pick the pack whose `Desc` and `When to Use` match the request.
3. Read every `Path:` for the selected pack in output order; later paths have higher priority when guidance conflicts.
4. Use one pack per bf-wo. The selected pack governs role and capability lookup for spec and execution.
5. If two packs match, prefer the one whose `When to Use` lists the request's most specific symptom. If still tied, ask the user.
6. If no pack matches, stop and tell the user. Do not invent a pack.

## Bootstrap

After Pack Selection, bootstrap the work object:

1. Choose a bf-wo id that is readable, stable, and kebab-case.
2. Resolve the BF state home: Git projects use the primary worktree `.bf`; non-Git directories use `<cwd>/.bf`.
3. Create `<state-home>/works/<bf-wo>/`.
4. Copy `templates/discussion.md` to `<state-home>/works/<bf-wo>/discussion.md`.
5. Fill `Pack`, `Creation`, and `Updated`.
6. Append the first accepted discussion entry immediately.

Do not overwrite an existing work object. If the requested id already exists, read it first and treat the request as resume unless the user explicitly asks to abandon and recreate it.

## Brainstorm Loop

Repeat until Exit is satisfied:

1. Read the current `discussion.md`.
2. Read the selected pack's `Brainstorm Guidance`.
3. If project design-doc discovery is not already recorded, follow [project-docs.md](project-docs.md) and record the result in `discussion.md`.
4. Check the Source Coverage Checklist.
5. Report the coverage state and name one unresolved coverage gap.
6. Resolve that one gap by asking the user or by proposing an assistant-led answer.
7. Append the user's answer, accepted proposal, rejected proposal, or open question to `discussion.md` immediately.
8. Repeat from step 1.

Prefer assistant-led proposals when the repo context gives enough signal to make a concrete recommendation. Mark the proposal as proposed, discuss it, and treat it as source material only after the user confirms or accepts it.

## Source Coverage Checklist

Before moving to spec authoring, confirm source coverage in `discussion.md`.
Recorded discussion must answer requirement, acceptance, out-of-scope boundary, important constraints or tradeoffs, evidence shape, remaining open questions or accepted proposals, and task-list rationale inputs.

Every bf.md section must be supportable from `discussion.md`: Goal, Requirement, Acceptance Criteria, Boundary, and Task List rationale. This is an authoring and review discipline, not a formatting requirement.

Only confirmed user input or a confirmed or accepted proposal can support `bf.md`.
Keep `bf.md` concise later; do not quote or cite discussion entries by default.

## Exit

Brainstorm ends only when:

1. Source coverage is complete.
2. No open question affects the contract.
3. The user explicitly agrees to enter spec authoring.

When all three are true, move to [spec-authoring.md](spec-authoring.md).

## Stop Conditions

Stop instead of moving forward when:

- No installed pack matches the request.
- Source coverage is missing and you are about to leave brainstorm.
- The user has not explicitly agreed to enter spec authoring.
- You are about to author `bf.md`, create task specs, or do task breakdown from brainstorm.
- An assistant-led proposal is unconfirmed.
- Project design-doc discovery finds conflicting authority that changes the contract.
