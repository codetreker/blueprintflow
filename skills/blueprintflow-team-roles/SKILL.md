---
name: blueprintflow-team-roles
description: "Part of the Blueprintflow methodology. Use when spawning the team or arbitrating role boundaries - provides prompt templates for the 6 roles + Teamlead and enforces Security as an independent role."
version: 1.0.0
---

# Team Roles

> **Role ≠ person.** The 6 roles do not require 6 agents or 6 people. One agent or one person can carry multiple roles (for example PM + Designer). A small team can combine roles, **but Security must stay independent — Architect is not allowed to take it on as well** (see the Security section below).

The setup is 6 roles plus a Teamlead who coordinates, all working together as multiple agents on the product. Each role has its own prompt template, and you spawn whichever ones you need when starting the team (Security is always there, not "as needed").

## Full headcount example

A full 8-person setup, where every responsibility has its own dedicated agent:

- 3 Dev
- 1 Architect
- 1 PM
- 1 QA
- **1 Security (mandatory, independent role)**
- 1 Teamlead (coordination only, doesn't write code)

Designer is added on top when the project needs it (any project with a lot of new visual components should have one).

### Merging roles in practice ("role ≠ person")

Following the "role ≠ person" rule, one agent or person can carry multiple roles, which keeps the headcount lower:

- ✅ PM + Designer (product rules and visual rules naturally line up)
- ✅ QA + Architect (architecture review and testability review look at things from a similar angle)
- ✅ Teamlead also acting as Architect (in a small team the coordinator is often also the lead architect)
- ❌ **Architect + Security is not allowed** (architecture and security are different perspectives — merging them silences both sides)

The relationship between full headcount and merging in practice: full headcount shows you **the boundary between roles**. In real life you merge as your team size requires, **but Security stays independent — that's a hard constraint.**

## Security: mandatory and independent

**Every code change goes through Security review.** This was decided in 2026 and is now a hard rule. None of the following are allowed:

- ❌ "Lazy spawn — only pull Security in when something sensitive shows up" (old rule, retired)
- ❌ Architect doubling as Security (architecture and security are different perspectives, merging them silences both)
- ❌ "This milestone isn't sensitive, skip Security" (auth / capability / cookie domain / cross-org / admin god-mode paths show up everywhere — review everything by default)

Lessons from real life: several security bugs (admin god-mode skipping review, cookie domain mismatch, cross-org data leak) all came from "this didn't look sensitive so we didn't pull Security in". Switching to "always review by default" closes that hole.

## Teamlead (coordinator / facilitator)

**Doesn't write code**, only coordinates:

- Hand out work, watch progress, guard the protocol
- Arbitrate conflicts between roles
- Decide which review path a PR goes through
- Schedule the merge agent
- Run cron checkins (fast 15-min idle checkin / slow 2-4h drift audit)

You don't spawn the Teamlead — the Teamlead is usually the top-level agent, i.e. you yourself.

## The 6 role prompt templates

Once you know your role, only read the matching prompt file:

| Role | Prompt file |
|------|-------------|
| Architect | `references/architect.md` |
| PM | `references/pm.md` |
| Dev | `references/dev.md` |
| QA | `references/qa.md` |
| Designer | `references/designer.md` |
| Security | `references/security.md` |

> **Progressive disclosure.** Only read the prompt for your own role. Don't load the others.

## Shared protocols

### Worktree protocol

- All roles work inside the milestone worktree the Teamlead created (`<repo-root>/.worktrees/<milestone>`)
- One milestone, one worktree, everyone stacks commits in it
- No more `/tmp/` throwaway clones (deprecated, see `blueprintflow:git-workflow`)

### PR protocol

- Top of the PR body: 4 lines of bare metadata, then `## Acceptance` and `## Test plan` H2 sections
- author=lead-agent can't self-approve; use `gh pr comment <num> --body "LGTM"` as the equivalent
- Dual review path: see `blueprintflow:pr-review-flow`

### Five layers of defense against rule drift (hard constraint)

1. spec brief grep cross-check (anti-constraint)
2. acceptance template anchor cross-check (machine-checkable)
3. stance checklist blacklist grep
4. content-lock byte-identical
5. cross-file cross-check during PR review

## Spawning a team — example

```
Agent({ name: "architect", subagent_type: "general-purpose", prompt: <Architect prompt template> })
Agent({ name: "pm", ... })
Agent({ name: "dev-1", ... })
Agent({ name: "dev-2", ... })
Agent({ name: "dev-3", ... })
Agent({ name: "qa", ... })
Agent({ name: "security", ... })  # mandatory, independent role, Architect is not allowed to double
# As needed:
Agent({ name: "designer", ... })
```

> **Real example (Borgee):** the Borgee team spawns agents using horse-themed codenames (feima / yema / zhanma / liema, etc.) — that's a Borgee-internal naming habit. A generic blueprintflow team just spawns by role name (architect / pm / dev / qa / security).

## Teamlead — responsibilities and anti-patterns

### Responsibilities

- **Coordinate, don't do the work.** Hand work out to the 6 roles plus a general-purpose agent (for odd jobs like merge / patch lint / repo patches). Don't run Bash / Write / Edit on the repo yourself.
- **Synthesize multiple sources of diagnosis.** When QA, PM and Architect reports conflict, don't merge them in your head — poke whoever is closest to the root cause (e.g. ask a Dev to disprove it), collect the counter-evidence first, then hand out the next piece of work.
- **Memory of decisions.** Whenever you make an important decision (retracting a previous suggestion, accepting a Dev's counter-argument), broadcast it to the affected reviewers so stale instructions don't sit in their inbox.
- **Authorize for maximum efficiency.** As long as you don't break the charter (4-piece set, dual review, migration version sequencing, etc.) and don't lower quality (anti-constraint grep machine anchors, byte-identical comparison), be flexible. Examples: batch-merge a wave of PRs together, run review subagents in parallel, let acceptance and stance reviewers cross-write each other's pieces, single-reviewer chore PRs that skip dual review, fire a batch processing wave the moment a flood of LGTMs arrives. Don't follow process for process's sake — but never lose the *why* behind the process.
- **Silence detection.** If a role doesn't respond, how you handle it depends on the runtime environment (see `blueprintflow-runtime-adapter`).
- **Issue triage routing.** When the cron sweep finds untriaged GitHub issues, the Teamlead routes them — code improvement / tech debt → Architect, new feature → PM, bug → QA. The Teamlead **routes only, does not classify the type personally** (same posture as "coordinate, don't do the work"). See `blueprintflow-issue-triage` for details.

### Anti-patterns

- ❌ **Blocking on a subagent.** Always spawn the general-purpose agent with `run_in_background: true`. Otherwise the Teamlead is stuck waiting for the result and can't keep coordinating. Background: subagent odd jobs (merge / lint patch) and the Teamlead's main thread (handing out work, collecting LGTMs, synthesizing diagnosis) **are independent by design** — no reason to block.
- ❌ **Patching things yourself.** Seeing red lint or a pending merge and just running `gh api PATCH` / `gh pr merge` yourself — that's Dev odd-job work. Hand it to an agent. Doing it yourself downgrades the Teamlead role.
- ❌ **Inventing causal chains when synthesizing diagnosis.** When you stitch together symptoms from several reviewers, it's easy to imagine "A because B therefore C" when the real cause is D. Have the closest party prove or disprove it — don't do their root-cause work for them.
- ❌ **Not broadcasting a retraction.** You change your mind but don't tell everyone, so reviewers keep working off stale instructions (PM running grep, QA editing content-lock) for nothing.
