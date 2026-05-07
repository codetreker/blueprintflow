---
name: blueprintflow-e2e-verification
description: "Part of the Blueprintflow methodology. Use when QA verifies any client-facing UI / frontend change before LGTM - covers code-level acceptance + product usability + design reasonableness as three required dimensions, not just PR-described acceptance."
---

# UI E2E Verification

QA's role is **the user's proxy**: walk the product as a real user would *before* it reaches the user, ask "is this actually usable?", challenge "is this actually well-designed?".

Code-level correctness (PR acceptance ✅) is necessary, not sufficient. The sufficient conditions are **the product is usable** and **the design is reasonable**.

## When this skill triggers

- Any QA real-verification stage for a client UI / frontend / user-visible change
- Pre-Phase-exit-gate regression smoke
- Final pre-release walkthrough
- **Strong signal**: user reports several adjacent UI bugs in a short window — that means smoke walkthrough wasn't done thoroughly before
- Any "looks like a small CSS / layout tweak" PR — these are exactly where QA most easily falls into the trap of only verifying the PR's stated acceptance

## The three lines you must run (any UI change)

A complete UI E2E verification has **three lines**, not one. Skipping any one means QA didn't actually do their job.

### Line 1: Code-level correctness (PR acceptance)
Verify each acceptance criterion from the PR description really reproduces and really passes.

- Use real user actions (form fill / button click) — not API / cURL / `page.evaluate(fetch)`
- Capture concrete evidence: DOM truths, computed styles, network responses, console state
- This is the line most QAs already do well; it's the **necessary** condition

### Line 2: Product usability (user perspective)

**Core question**: Can a real user open the product and complete an everyday task without confusion, friction, or getting stuck?

Operating points:

- **Walk a complete real-user task flow**: not just the PR's one step — open the app → finish a meaningful task (send a message / create content / switch pages / refresh / etc.) end-to-end
- **Probe deliberately for problems**: actively click elements not mentioned in the PR; walk flows not described in the PR; interact in states not covered by the PR
- **Repeat the same action multiple times**: create / delete / switch N times — bugs that surface only after the second or third repetition (state leak / race / accumulated drift) are the ones that survive normal QA and reach users
- **Exit and recover**: refresh / reconnect / close-and-reopen — does the state stay consistent?
- **Send real data**: don't verify on empty states alone; create a record / send a message / upload a file — every step in the data flow should be exercised

Warning signals — ask yourself out loud:

- "If this were my first time, would I know what to click?"
- "If I make a mistake here, can I recover?"
- "After 5 consecutive operations, does the experience still feel smooth?"
- "If I refresh, does what I see match what I saw before refresh?"

### Line 3: Design reasonableness (designer perspective)

**Core question**: If you handed this UI to a designer who doesn't know the implementation, would they wince?

Operating points:

- **Screenshots are triggers, not evidence**: after capturing, you must **review every image with your own eyes** — capturing alone is not the deliverable
- **Look for problems actively in each screenshot** (mark at least 3 candidate issues per image, even if you ultimately decide they aren't bugs):
  - **Alignment**: are elements on the same row baseline-aligned? are elements in the same column edge-aligned?
  - **Spacing**: is there appropriate breathing room between elements? nothing stuck-together, nothing drifting apart absurdly?
  - **Sizing**: do icon / button / text sizes match the visual hierarchy? are proportions to neighboring elements correct?
  - **Direction / state**: do arrow directions match "expand/collapse" semantics? do state changes have visual feedback?
  - **Hierarchy**: is the important thing visually emphasized? is the secondary thing actually de-emphasized?
  - **Semantics**: are icon meanings clear? can first-time users understand the copy? do error states explain themselves?
- **Multi-viewport review**: not only the viewport you changed — review every width a real user might use (mobile / tablet / laptop / desktop)
- **Re-look at the same component you've already seen**: don't ask only "is my change still there?" — also ask "is this component reasonable in itself?"

Warning signals:

- "Compared with the most-used products in this category (whatever the equivalent of your product is — for example, if you're building a chat product, the chat tools your team actually uses every day), where does this look amateur?"
- "Are this element's size / spacing / color this way because there's a reason, or because nobody tuned it?"
- "If I show this screenshot to a designer, where will their eyes land first?"

## Anti-patterns (these are forbidden — every one is a real lesson)

Each of these has produced real bugs that reached users:

- ❌ **LGTM after only verifying PR acceptance** — acceptance is necessary, not sufficient
- ❌ **Capture screenshots without reviewing them with your eyes** — defaulting to "captured = done" without inspecting each image
- ❌ **Use DOM truth / computedStyle to substitute for visual review** — DOM truth ≠ visual truth; an element rendering doesn't mean it looks right
- ❌ **See a UI element but not click / not question it** — seeing a lock icon / Leave button / Manage button without clicking, without asking what its semantics are
- ❌ **Walk only the happy path** — finishing exactly the PR's described steps and stopping; no exploratory testing
- ❌ **Skip the specific viewport the user reported the bug at** — if the user's screenshot is e.g. 288×112, you must reproduce at that size
- ❌ **Re-look at the same component without re-evaluating it** — looking at the same sidebar 4 times asking only "did my change land?", never asking "is this component itself fine?"
- ❌ **Use API / cURL / `page.evaluate(fetch)` to substitute for real UI operations** — backend contract correctness ≠ user experience
- ❌ **Verify on empty state alone** — "No items yet" placeholders cannot validate layout; you must populate data and walk the real flow

## Operating checklist (run after PR acceptance, every UI PR)

After the PR-described acceptance is reproduced, **mandatory** to add these 7 items before LGTM:

```
□ 1. PR acceptance reproduced (Line 1)
□ 2. Main-navigation walkthrough: click each tab / main entry once,
     verify page switches don't break, every page has a reasonable
     default state
□ 3. All visible interactive elements within the PR's scope clicked
     at least once (primary buttons / secondary buttons / icon
     buttons / list items) — not only the one the PR described
□ 4. One complete real user-task flow simulated (from blank to
     finishing a meaningful task): really send data, really refresh,
     really switch tabs, really check notifications — not only the
     PR's one step
□ 5. Multi-viewport screenshots compared: narrow mobile (320) /
     tablet (768) / laptop (1280) / desktop (1920) + the specific
     width the user reported
□ 6. Each screenshot eye-reviewed; per image, mark at least 3
     candidate issue points (alignment / spacing / sizing /
     direction / hierarchy / semantics) — write them down even if
     you decide they aren't bugs
□ 7. "Designer perspective" self-check: "Would a designer who
     doesn't know the implementation wince at this UI? Compared
     with the most-used products in your product's category (for
     example, the equivalent product your own team uses daily),
     where does it look amateur?"
```

## Output: the verification report

After completing all three lines + the checklist, the LGTM message (PR comment + report to Teamlead) must include:

| Section | What goes in it |
|---|---|
| Line 1 evidence | DOM / computedStyle / network response truths — proves code-level correctness |
| Line 2 walkthrough notes | Which user flows you walked; which were smooth; any friction observed |
| Line 3 design review | Every screenshot's at-least-3 candidate issue points; "designer wince points" called out |
| Out-of-scope findings | UI issues found outside the PR's scope (these become new issues for triage; do not block this PR but must be filed) |
| Decision | LGTM / hold-and-explain / block — do not LGTM if any line failed |

## Cross-product applicability

This skill is not bound to any specific product type. Adapt the concrete pixel widths and the comparison reference to the product:

- **Anything user-visible** — web app, desktop app, mobile app, browser extension, command-line UI, etc. — follows the three lines
- **Concrete daily flow**: every product has its own core daily flow (for example, a chat product's daily flow is sending a message; a notes product's is creating a note; a canvas product's is creating a card; a command-line tool's is running a typical command). Verify any change by walking that core flow.
- **Reference product for comparison**: pick the product in the same category that your own team uses every day — that one's daily polish is what users will mentally compare yours against. For example, if you're building a chat product, the chat tool your team actually uses; if you're building a notes product, the notes tool your team actually uses. Don't list specific brand names in this skill — find the right reference per your category.
- **Designer perspective is universal**: ask "would a designer wince?" in any product, no project context required
- **Multi-viewport logic is universal**: mobile / tablet / desktop apply across all UI products; the specific pixel values shift based on whether the product is mobile-first or desktop-first

## Relationship to other skills

- `blueprintflow-pr-review-flow`: defines who reviews and the three-signoff gate. **This skill is what the QA signoff actually consists of**. Without this skill, QA's signoff is just "PR acceptance ✅" — necessary, not sufficient.
- `blueprintflow-phase-exit-gate`: requires regression smoke. The Line 2 + Line 3 walkthrough is the regression smoke for UI changes — without it, the Phase exit is rubber-stamping.
- `blueprintflow-issue-triage`: out-of-scope findings during this skill's verification go through issue-triage as new issues. Do not block the current PR for them.

## Tone (rigid, not flexible)

This skill is **rigid**. Do not adapt away the three-line structure or the operating checklist. The temptation is "the change is small, I'll just verify Line 1" — that temptation is exactly how UI bugs reach users. If you feel the urge to skip Line 2 or Line 3, that is the moment you most need them.
