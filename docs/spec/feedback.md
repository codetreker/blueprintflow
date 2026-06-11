# Feedback Mechanism

BF supports user-initiated feedback through GitHub issues. The primary audience
is the terminal user, but the executing actor is the user's agent.

## Trigger

The flow starts only when the user explicitly asks the agent to prepare, file,
or comment on a GitHub issue in `codetreker/blueprintflow`. The BF issue
tracker is `https://github.com/codetreker/blueprintflow/issues`. BF does not
add telemetry, automatic reporting, background submission, or agent-initiated
issue suggestions.

## User And Agent Responsibilities

The user owns intent and final authorization. The agent gathers context,
searches existing issues with a redacted query, applies the filing boundary,
redacts sensitive content, drafts the issue or comment, and submits only after
final user confirmation. If GitHub issue search is unavailable, the agent stops
before drafting a new issue and asks the user for search results or explicit
fallback authorization.

Before any GitHub side effect, the agent shows:

- duplicate search results;
- the filing decision;
- the redacted draft;
- the target action.

When feedback handling asks the user to choose between materially different
paths, such as reusing an existing issue, opening a new issue, proceeding
without duplicate search, or abandoning a blocked filing, the agent presents a
decision brief before asking for the choice. The brief includes the decision,
current evidence, realistic options, tradeoffs or consequences, and a supported
recommendation. Final confirmation may remain lightweight when the immediately
preceding draft and target action already make the context obvious.

## Feedback Scope

The unified feedback flow covers bugs, improvement suggestions, unclear
documentation, usage confusion, installation failures, and design questions.

## Duplicate Policy

The default outcome is to reuse an existing issue. If an existing issue fully
covers the feedback, the agent prepares a comment instead of a new issue. A new
issue is appropriate only when the feedback is materially different.

## Filing Boundary

The agent does not prepare a new issue when:

- the feedback is only personal preference without impact or a concrete use
  case;
- a bug report lacks reproducible information and the user will not provide
  more context;
- the problem is outside BF's scope;
- an existing issue fully covers the feedback and there is no new evidence or
  impact to add;
- the report would expose secrets, tokens, private code, or sensitive logs that
  cannot be safely redacted.

## Repository Surface

Runtime guidance lives in `references/feedback.md` so installed BF snapshots
remain self-contained. `SKILL.md` only points to that reference.

GitHub issue intake uses one unified `.github/ISSUE_TEMPLATE/feedback.yml`
template. The template captures feedback type, impact, context, duplicate
search result, filing rationale, redaction confirmation, and expected outcome.
