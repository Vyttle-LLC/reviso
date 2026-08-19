## Reviso style — HEAD (detached) vs 776dbd4 (0 commits, 2 files)

Found 3 style issues:

1. **[P1][conf 100] Placeholder text committed (unimplemented code presented as implemented)** — src/format.ts:19
   Failure: `// In a real implementation, this would use the user's locale settings` sits above a plain delegation to `formatBytes`. The code admits it is a stand-in; the next reader believes locale handling is a known gap that lives here, when nothing routes to it.
   Fix: implement the locale path or delete the comment and track the gap in an issue.
   (deterministic)

2. **[P1][conf 90] `formatBytesEnhanced` is a comparative-named parallel variant of `formatBytes` with silently different behavior** — src/format.ts:14
   Failure: two exported byte formatters differ only by an `Enhanced` suffix and disagree on negatives (`formatBytes(-2048)` → `-2048.0 B`, `formatBytesEnhanced(-2048)` → `-2.0 KB`). A caller reaching for the obvious name gets the wrong one, and nothing in the API signals which is current. `formatBytesEnhanced` has exactly one consumer (src/usage.ts:4) and its body delegates entirely to `formatBytes` (src/format.ts:20) after one guard; `formatBytes` has no caller outside that wrapper (grep for `formatBytes` across the repo returns only src/format.ts:3,14,17,20 and src/usage.ts:1,4 — no dynamic or string-keyed access).
   Fix: move the `n < 0` guard into `formatBytes`, delete `formatBytesEnhanced`, and change src/usage.ts:1,4 to import and call `formatBytes`.
   (ai tells; over-engineering)

3. **[P2][conf 90] Both comments on `formatBytesEnhanced` restate the code or narrate its history** — src/format.ts:13, src/format.ts:15
   Failure: `// Enhanced version with better handling of edge cases` says less than the signature does and names no edge case; `// Fixed bug where negative values were not handled` is changelog text describing the commit, not the code — the `if (n < 0)` line below it already says it. Both go stale the moment the function changes, and neither survives the fix in finding 2.
   Fix: delete both. If the negative-recursion needs a note at all, the guard itself is the note.
   (comments; ai tells)

Checked: slop, comments, duplication, length, over-engineering, dead weight, ai tells, deterministic.
Not checked: conventions (skipped — no CLAUDE.md, AGENTS.md, or lint config exists in the repo); drift (skipped — base commit `776dbd4` is empty, so there is no existing code to establish a baseline against); test slop (skipped — no test files in the change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
