# Feedback

Goal: prepare user-requested GitHub issue feedback without creating duplicate,
unsafe, or low-signal maintainer work.

## Trigger

Start this flow only when the user explicitly asks to prepare, file, or comment
on a GitHub issue for BF feedback in `codetreker/blueprintflow`.

Use this GitHub issue tracker:

```text
https://github.com/codetreker/blueprintflow/issues
```

If the user did not explicitly ask for issue feedback, do not suggest filing an
issue, do not collect feedback in the background, and do not submit anything.

## User Decision Briefs

Before asking the user to choose between materially different feedback paths, present a concise decision brief. Name the decision, relevant context and current evidence, realistic options, tradeoffs or consequences, and a recommendation when evidence supports one. Present the relevant content — such as the redacted draft, duplicate-search results, or target action — inline or as a faithful, decision-sufficient summary; a bare file or path pointer may supplement it but must not replace the shown content.

Use the decision brief for material user decision gates such as choosing whether to reuse an existing issue or open a new issue, proceeding when duplicate search is unavailable, deciding whether a filing boundary blocks submission, or confirming a GitHub side effect after reviewing the redacted draft. Lightweight prompts remain valid for simple factual clarifications, status updates, and obvious yes/no confirmations where the context is already clear.

## Scope

Use this flow for user-facing feedback about BF, including:

- bug reports;
- improvement suggestions;
- unclear documentation;
- usage confusion;
- installation failures;
- design questions.

## Steps

1. Confirm the requested target is BF feedback for `codetreker/blueprintflow`
   at `https://github.com/codetreker/blueprintflow/issues`. If the target is
   unclear, ask the user to identify the repo before continuing. If the target
   is not BF, stop this flow.
2. Gather the minimum useful context:
   - feedback type;
   - observed behavior or request;
   - user impact;
   - expected outcome;
   - BF version, host, operating system, and relevant command output when
     available.
3. Redact secrets, tokens, private code, private paths, and sensitive logs
   before drafting anything for GitHub or searching GitHub issues.
4. Search existing GitHub issues in `codetreker/blueprintflow` for the same
   problem or request. Use a redacted, minimal search query; do not paste
   private logs, tokens, private paths, or private code into the search query.
   If GitHub issue search is unavailable, stop before drafting a new issue and
   ask the user to provide search results or explicitly authorize a draft that
   records "duplicate search unavailable".
5. Prefer to reuse an existing issue when it fully covers the feedback.
   Prepare a concise comment instead of a new issue.
6. Prepare a new issue only when no existing issue fully covers the feedback.
7. Before any GitHub side effect, show the user:
   - duplicate search results;
   - the filing decision;
   - the redacted draft;
   - the target action, either "comment on existing issue" or "open new issue".
8. Submit the comment or issue only after final user confirmation.

## Duplicate Handling

Default to existing-issue reuse. If an existing issue describes the same problem
or request, do not draft a new issue. Draft a short comment with any new
environment details, reproduction notes, impact, or clarifying evidence the
user can add.

Open a new issue only when the feedback is materially different, such as a
different failure mode, different affected surface, or a distinct user impact
not covered by the existing issue.

## Do Not File

Do not prepare a new issue when any of these checks applies:

- The feedback is only personal preference and does not describe user impact or
  a concrete use case.
- A bug report lacks reproducible information and the user will not provide
  more context.
- The problem is outside BF's scope, such as a host LLM, terminal, GitHub, or
  local environment fault that BF cannot reasonably address.
- An existing issue fully covers the feedback and the user has no additional
  evidence or impact to add.
- The report would expose secrets, tokens, private code, or sensitive logs that
  cannot be safely redacted.

When a check blocks filing, explain the reason and ask for the missing safe
information only when more information could make the feedback actionable.

## Draft Shape

For a new issue, use the unified GitHub Feedback template and fill:

- Feedback type.
- Summary.
- Impact.
- Context.
- Duplicate search result.
- Filing rationale.
- Redaction confirmation.
- Expected outcome.

For an existing issue, draft a comment that includes only the new evidence,
impact, environment, or reproduction detail the user wants to add.

## Authorization

Initial user intent is not final submission authorization. After drafting, stop
and ask for final user confirmation. Do not open a new issue, comment on an
existing issue, or add labels until the user approves the final target action
and redacted text.
