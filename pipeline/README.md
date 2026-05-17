# pipeline/ — Core Node Protocols

These are protocols that apply to every Pack's flow nodes. They cover
mechanical-evidence interactions (handoff, criteria-lint, gate verdict
computation, report format) and the cross-Pack methodology for review
context (context-brief, role-evaluator).

Pack-specific protocols (implementer-prompt, executor-protocol,
discussion-protocol, test-design, ux-*) live inside each Pack's
`protocols/` directory.

## Files

- [gate-protocol.md](./gate-protocol.md) — verdict synthesis (used by every gate node)
- [handoff-template.md](./handoff-template.md) — handshake.json shape and validation
- [criteria-lint.md](./criteria-lint.md) — acceptance_criteria mechanical lint
- [report-format.md](./report-format.md) — flow-completion report JSON + presentation
- [context-brief.md](./context-brief.md) — pre-review context composition
- [role-evaluator-prompt.md](./role-evaluator-prompt.md) — multi-role review template
- [evaluator-prompt.md](./evaluator-prompt.md) — single-evaluator variant

## Vendored from OPC

These files were vendored verbatim from `/workspace/opc/pipeline/` at
the fork commit (see [`../UPSTREAM.md`](../UPSTREAM.md)) with brand
renames applied (opc-harness → bf-harness, ~/.opc → ~/.bf, etc.).
