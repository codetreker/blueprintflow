---
name: blueprintflow-e2e-verification
description: "Part of the Blueprintflow methodology. Use when QA verifies any client-facing UI / frontend change before LGTM - covers code-level acceptance + product usability + design reasonableness as three required dimensions, not just PR-described acceptance."
---

# UI E2E Verification

QA = **the user's proxy**. Code-level correctness (PR acceptance ✅) is necessary, not sufficient. The sufficient conditions are **the product is usable** and **the design is reasonable**.

**Scope**: client-facing UI / frontend changes only. Backend-only PRs skip this skill entirely.

## Triggers

- Any QA verification for UI / frontend / user-visible change
- Pre-Phase-exit-gate regression smoke
- Final pre-release walkthrough
- User reports several adjacent UI bugs (smoke wasn't thorough)
- "Small CSS / layout tweak" PRs — highest trap risk for Line-1-only verification

## The three lines

| Line | Core question | Required actions |
|---|---|---|
| **1. Code-level** | Does each acceptance criterion really pass? | Real UI operations (form fill / click). API/cURL **can supplement** (e.g. confirm backend stored data) but **cannot substitute** for UI ops. Capture DOM/network evidence |
| **2. Usability** | Can a real user complete an everyday task? | Walk full task flow, probe unmentioned paths, repeat N times, refresh/recover, send real data |
| **3. Design** | Would a designer wince? | Screenshot every viewport, scan ≥3 dimensions per image, re-evaluate components you've seen before |

Skipping any line = QA didn't do their job. **Rigid**: "the change is small, I'll just do Line 1" is exactly how UI bugs reach users.

### Line 2 self-check questions

- "First-time user — would I know what to click?"
- "If I make a mistake, can I recover?"
- "After 5 consecutive operations, still smooth?"
- "After refresh, does state match?"

### Line 3 scan dimensions

| Dimension | What to check |
|---|---|
| Alignment | Same-row baseline, same-column edge |
| Spacing | Breathing room, nothing stuck or drifting |
| Sizing | Visual hierarchy, proportions to neighbors |
| Direction/state | Arrow semantics, state change feedback |
| Hierarchy | Important emphasized, secondary de-emphasized |
| Semantics | Icon meanings clear, copy understandable, error states self-explanatory |

Scan ≥3 dimensions per image. Empty output after real scan = fine. Skipping the scan = not fine.

### Line 3 self-check questions

- "Compared with the most-used product in this category, where does this look amateur?"
- "Is this element's size / spacing / color intentional, or did nobody tune it?"
- "If I show this screenshot to a designer, where will their eyes land first?"

Pick the product in your category that your team uses daily as the comparison reference.

## Operating checklist

```
□ 1. PR acceptance reproduced (Line 1)
□ 2. Main-navigation walkthrough: each tab/entry clicked, pages don't break
□ 3. All interactive elements in PR scope clicked at least once
□ 4. One complete real-user task flow simulated end-to-end
□ 5. Multi-viewport screenshots: 320 / 768 / 1280 / 1920 + user-reported width
□ 6. Each screenshot scanned (≥3 dimensions), findings written down
□ 7. "Designer wince" self-check against category reference product
```

## Output

| Section | Content |
|---|---|
| Line 1 | DOM / computedStyle / network evidence |
| Line 2 | Flows walked, friction observed |
| Line 3 | Per-screenshot scan findings, "wince points" |
| Out-of-scope | UI issues outside PR scope → file as new issues, don't block |
| Decision | LGTM / hold / block |

## Anti-patterns

- ❌ LGTM after only Line 1 (acceptance ≠ sufficient)
- ❌ Screenshots captured but not eye-reviewed
- ❌ DOM truth substituting for visual review
- ❌ UI elements seen but not clicked/questioned
- ❌ Happy path only — no exploratory testing
- ❌ Skipping user-reported viewport size
- ❌ Re-looking at a component without re-evaluating it
- ❌ API/cURL substituting for real UI operations
- ❌ Verifying on empty state only

## Cross-product applicability

- **Any user-visible surface** (web / desktop / mobile / extension / CLI UI) follows the three lines
- **Core daily flow**: every product has one (chat → send message, notes → create note, canvas → create card). Verify any change by walking that flow
- **Comparison reference**: the product in your category your team uses daily — don't hardcode brand names

## Relationship to other skills

- `pr-review-flow`: this skill is what QA's signoff consists of
- `phase-exit-gate`: Line 2+3 walkthrough = regression smoke for UI
- `issue-triage`: out-of-scope findings → new issues

## How to invoke

```
follow skill blueprintflow-e2e-verification
```
