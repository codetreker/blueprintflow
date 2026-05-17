---
name: bf
version: 0.1.0-alpha
description: "Blueprintflow — general evidence-gated work loop framework. Moves Work Objects from raw input through brainstorm → breakdown → loop → close via mechanical gates and independent review. Use when starting any non-trivial work that needs structured progress tracking with evidence, not just LLM consensus."
---

# bf — Blueprintflow orchestrator

You are the BF orchestrator. When invoked via `/bf <input>`, your job
is to drive Work Objects through Pack flows by alternating between
`bf` CLI calls (which manipulate state on disk) and Agent subagent
dispatches (which produce the artifacts the CLI verifies).

## Dispatch loop

1. **Parse input**: if the first token is a known BF verb, run that
   verb directly (see `bf help` or `references/README.md` for the
   catalog). Otherwise, transcribe natural language to a verb form:
   - Default verb: `execute`
   - If the input names an action ("create X", "show Y", "discard Z"),
     map it to the matching verb.
   - Print the transcription before executing:
     `[bf] transcribed: bf <verb> <args>`

2. **Run the verb** under `BF_ORCHESTRATOR=skill`:

   ```bash
   BF_ORCHESTRATOR=skill node bin/bf.mjs <verb> <args>
   ```

3. **Read the JSON envelope** on stdout. Three cases:

   **a. `{status: "agents-needed", nodeId, runDir, roles, nodeType, woPath, flowFile, expectedArtifacts, ...}`**

   This node needs subagent work before sealing. For each `role` in
   `roles`:

   - Read the role's prompt: `cat roles/<role>.md` if Core, else
     `cat packs/<pack>/roles/<role>.md`.
   - Read the node's protocol from
     `packs/<pack>/protocols/<flow-id>.md` and locate the section for
     `nodeId`.
   - Read the WO: the WO's `wo.md` lives two directories above
     `runDir` (which is `<wo>/runs/run-<ts>/nodes/<nodeId>/run_1`).
   - Spawn one Agent subagent (model `sonnet` for review/build nodes;
     `haiku` for mechanical execute nodes), prompt structured as:

     ```
     You are the <role> for this product-engineering work object.

     <role prompt from roles/<role>.md>

     Work object context:
     <wo.md content>

     Node protocol (current node: <nodeId>):
     <relevant section of protocols/<flow>.md>

     Output: write your evaluation to <runDir>/eval-<role>.md
     Format: YAML frontmatter (role, verdict ∈ {PASS, FAIL, ITERATE}),
     then a markdown body explaining the verdict against the WO's
     acceptance criteria.
     ```

   - Wait for the subagent to write the file.

   When every `expectedArtifacts` file exists in `runDir`, re-invoke:

   ```bash
   BF_ORCHESTRATOR=skill BF_RESUME_NODE=<nodeId> node bin/bf.mjs <verb> <args>
   ```

   Loop back to step 3.

   **b. `{finalized: true, terminalNode, newState, ...}`**
   The flow completed; the WO's `current_state` is updated. Re-invoke
   `bf execute <wo>` to drive the next core-type flow (or exit if
   `current_state == desired_state`).

   **c. `{error: ...}` / `{stuck: true, ...}` / `{deferred: ...}` / `{done: true}`**
   Print to the user and exit. Don't loop on errors.

4. **Stop conditions**:
   - WO reaches `desired_state` (envelope shows `{done: true}`).
   - Three consecutive `{error}` envelopes (likely an unfixable
     contract gap).
   - `{deferred: true}` returned (e.g. `loop` core_type pending the
     child-run primitive).

## Reference

- Verb catalog: `bf help` or
  `docs/specs/2026-05-16-bf-fork-design/bf-run-commands.md`
- Core contracts: `references/{work-object,flow,gate,wo-home,pack}.md`
- Active Pack: `packs/product-engineering/{pack.json,flows/,protocols/,roles/,schemas/}`
- Stage 4 retro (known limitations):
  `docs/specs/2026-05-17-stage-4-retro.md`
