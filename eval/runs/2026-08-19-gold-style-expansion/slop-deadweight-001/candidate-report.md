Detectors returned `[]`. Here is the review.

```text
## Reviso style — HEAD (detached) vs 776dbd4 (0 commits, 2 files)

Found 2 style issues:

1. [P1][conf 95] `includeTotals` parameter is accepted but never read — src/report.ts:11
   Failure: the signature advertises a switch that does not exist. src/summary.ts:4
   passes `true` as if it controls the result; the next caller passes `false`,
   gets totals anyway, and goes looking for the bug in their own code.
   Searched: `includeTotals` repo-wide — only the declaration at src/report.ts:11;
   `buildReport` — sole call site src/summary.ts:4. No dynamic access is possible
   (two files, no manifest, no string-keyed dispatch).
   Fix: drop the parameter — `buildReport(rows: Row[]): Report` — and update
   src/summary.ts:4 to `buildReport(rows)`. If the switch is wanted, make lines 13-14
   honour it.
   (dead weight)

2. [P2][conf 85] `exportReportCsv` has no caller anywhere in the repo — src/report.ts:17
   Failure: dead export ships as maintained surface — the next reader has to
   establish that nothing depends on its CSV quoting before touching it.
   Searched: `exportReportCsv` and case-insensitive `csv` repo-wide — the definition
   at src/report.ts:17 is the only hit. No package.json, index barrel, or other entry
   point establishes it as an intended public API.
   Fix: delete lines 17-21, or land it together with the consumer that needs it.
   (dead weight)

Checked: slop, duplication, length, over-engineering, dead weight, AI tells, deterministic.
Not checked: comments (skipped — the change adds no comments); conventions (skipped — no
CLAUDE.md, AGENTS.md, or lint config in the repo); drift (skipped — base commit 776dbd4 is
empty, so there is no existing code to cite as a baseline); test slop (skipped — the change
adds no tests).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
