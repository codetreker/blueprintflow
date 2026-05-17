# BF — Blueprintflow

> General evidence-gated work loop framework. Moves Work Objects through states
> via flow graphs, mechanical gates, and independent verification.

**Status: alpha (v0.1.0-alpha).** Core contracts + runtime in place; the
`bf-run` entry skill, packs, and end-to-end flow demos land in later stages.

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

### npm (recommended)

```bash
npm install -g @codetreker/bf
```

Postinstall copies the skill content to `~/.claude/skills/bf/`, and exposes
two binaries on `PATH`:

- `bf-harness` — runtime CLI (init, transition, validate, synthesize, ...)
- `bf` — entry dispatcher (Stage 4 placeholder until the bf-run skill lands)

### Manual (no npm)

```bash
git clone https://github.com/codetreker/blueprintflow.git
cp -r blueprintflow ~/.claude/skills/bf/
```

## Use it

In Claude Code:

```
/bf <task>
```

(In v0.1.0-alpha the `/bf` skill is a placeholder; the live `bf-run` entry
ships in Stage 4. The harness binary is fully functional today — `bf-harness
--help`.)

## Status by stage

| Stage | What | Status |
|---|---|---|
| 1 | Vendor + brand-rename OPC harness | ✅ done |
| 2 | Author 5 Core contract docs | ✅ done |
| 3 | First Pack: product-engineering | pending |
| 4 | bf-run public entry skill | pending |
| 5 | End-to-end demo flow | pending |
| 6 | Remaining pack migration + v6 → v1 migration guide | pending |

Stage progress and design source-of-truth:
[`docs/specs/2026-05-16-bf-fork-design.md`](docs/specs/2026-05-16-bf-fork-design.md).

## What's in this package

```
bf/  (npm package root + skill root)
├── SKILL.md           ← bare-skill entry (Stage 4 fleshes this out)
├── bin/               ← harness CLI + lib/
├── pipeline/          ← Core node protocols (Stage 3 decides what to vendor)
├── roles/             ← 21 OPC roles, vendored; Stage 3 sorts into Core vs Pack
├── packs/             ← embedded Packs (Stage 3 onwards)
├── references/        ← the 5 Core contract docs
├── test/              ← harness test suite (108 passed / 0 failed / 1 deferred)
├── scripts/           ← postinstall
├── UPSTREAM.md        ← OPC fork provenance + delta log
└── package.json
```

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
