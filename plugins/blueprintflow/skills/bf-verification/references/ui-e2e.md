# UI E2E Verification

Use for any user-visible UI: web, desktop, mobile, extension, or CLI UI.

## Three Lines

| Line | Core question | Required actions |
|---|---|---|
| 1. Code-level | Does each acceptance criterion really pass? | Real UI operations: fill, click, navigate, refresh. API/cURL may supplement, never substitute. Capture DOM/network evidence |
| 2. Usability | Can a real user complete an everyday task? | Walk full task flow, probe unmentioned paths, repeat, recover from mistakes, use real data |
| 3. Design | Would a designer object? | Screenshot every viewport, scan at least 3 dimensions per image, re-evaluate familiar components |

Skipping any line means QA did not verify the UI.

## Line 2 Self-Check

- First-time user: would I know what to click?
- If I make a mistake, can I recover?
- After 5 consecutive operations, still smooth?
- After refresh, does state match?

## Line 3 Scan Dimensions

| Dimension | Check |
|---|---|
| Alignment | Same-row baseline, same-column edge |
| Spacing | Breathing room, no crowding or drift |
| Sizing | Visual hierarchy and proportions |
| Direction/state | Arrow semantics and state feedback |
| Hierarchy | Important elements emphasized correctly |
| Semantics | Icons, copy, and errors are understandable |

## Operating Checklist

- PR acceptance reproduced through UI operations.
- Main navigation walked.
- Interactive elements in PR scope clicked at least once.
- One complete real-user flow simulated end-to-end.
- Screenshots captured at 320, 768, 1280, 1920, and user-reported width when relevant.
- Each screenshot scanned across at least 3 dimensions.
- Out-of-scope UI issues filed separately.

## Output Sections

| Section | Content |
|---|---|
| Line 1 | DOM/computedStyle/network evidence |
| Line 2 | Flows walked and friction observed |
| Line 3 | Per-screenshot scan findings and design risks |
| Out-of-scope | Follow-up issues, not silent task expansion |
| Decision | LGTM / HOLD / BLOCK |

## Anti-patterns

- LGTM after only Line 1.
- Screenshots captured but not reviewed.
- DOM truth substituting for visual review.
- API/cURL substituting for UI operations.
- Empty-state-only or happy-path-only verification.
