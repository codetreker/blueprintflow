# BF — Blueprintflow

> General evidence-gated work loop framework. Moves Work Objects through states
> via flow graphs, mechanical gates, and independent verification.

**Status: alpha (v0.2.0-alpha).** Verb-first dispatcher + harness hardening
landed in Stage 4. End-to-end demo with real agent dispatch is Stage 5.

BF is a [bare Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills),
distributed via npm. The package installs a harness binary and post-installs
the skill content into your local Claude Code skills directory.

## What BF is

BF Core is five contracts:

- **Work Object** — the primary citizen; bounded work being advanced
- **Flow** — directed graph of typed nodes moving a WO between states
- **Gate** — mechanical PASS / ITERATE / FAIL decision (no LLM judgement)
- **WO Home** — semi-persistent local store while the WO is in progress
- **Pack** — domain-specific instantiation (schemas + flows + roles)

Plus a runtime (harness, vendored from [OPC](https://github.com/iamtouchskyer/opc))
that enforces independent review, atomic state writes, oscillation
detection, cycle limits, and evidence requirements.

BF tracks **process**, not product. The work product (code, PR, document)
lives in its natural habitat; BF asserts product existence by checking
`acceptance_criteria` pass.

Full design: [`docs/specs/2026-05-16-bf-fork-design.md`](docs/specs/2026-05-16-bf-fork-design.md).
Core contract details: [`references/`](references/).

## Install

### As a Claude Code skill (recommended)

```bash
npm install -g @codetreker/bf
```

postinstall copies the skill into `~/.claude/skills/bf/`. From inside
Claude Code you can then invoke:

```
/bf execute <wo-id>
/bf help
```

### As a CLI (no Claude Code)

The `bf` binary works standalone for everything except natural-language
mode (which needs the surrounding Claude Code LLM):

```bash
bf help
bf create "implement v1 auth" --pack product-engineering
bf show auth-v1
bf tree
```

## Usage tour (v0.2-alpha)

`bf` is verb-first. The 18 verbs group by purpose:

| Group | Verbs | Notes |
|---|---|---|
| Lifecycle | `create`, `execute`, `brainstorm`, `breakdown`, `loop`, `close` | `execute` drives a WO to its `desired_state`; the 4 specific verbs run one core flow each |
| Inspection | `show`, `tree`, `list`, `discard` | Read or remove the WO home (`~/.bf/wo/`) |
| Escape | `skip`, `pass`, `stop`, `goto`, `resume` | Operate on the currently active run |
| Meta | `pack`, `flow`, `help` | Inspect installed Packs / flows / usage |

### Driving a task through

```bash
bf create "shape login form acceptance" --pack product-engineering --schema task
# → creates ~/.bf/wo/shape-login-form-acceptance/wo.md at state 'new'

bf execute shape-login-form-acceptance
# → walks brainstorm-task flow; ends at state 'shaped'

# (Stage 4 v0.2 limitation: leaf tasks go from shaped → doing manually
# until the Stage 5 demo lands the leaf-fast-path.)
vim ~/.bf/wo/shape-login-form-acceptance/wo.md  # set current_state: doing

bf execute shape-login-form-acceptance
# → walks close-leaf-task flow; ends at state 'done'
```

### Status (Stage 4 v0.2)

- verb-first dispatch (all 18 verbs)
- harness-level mechanics (init, seal, transition, finalize, viz with back-edges)
- packs-relative flow loading (no global flow registry needed)
- `npm pack --dry-run` clean
- stub agent dispatch — every role's eval is auto-PASS; Stage 5 plumbs real Claude subagent calls
- `loop` verb defers with a "child-WO dispatch — Stage 5" message
- NL parse handles deterministic patterns only; LLM-driven transcription deferred
- not yet `npm publish`-ed; first publish lands when Stage 5 demo succeeds end-to-end

## Repository layout

This same git repo also holds `plugins/blueprintflow/` — the v6.0.0 BF
methodology plugin (`@codetreker/bf`'s predecessor). It remains installable
via marketplace until v1 cuts over.

## License

(TBD — likely MIT, mirroring OPC. Pinned before first npm publish.)

## Acknowledgements

BF's harness is a narrow fork of [OPC](https://github.com/iamtouchskyer/opc)
at commit `bf7910a` (HARNESS_VERSION 0.10.0). See [UPSTREAM.md](UPSTREAM.md)
for the fork-and-rename delta log.
