Detectors returned clean (`[]`). Searches confirm both dead-weight candidates. Here is the report.

```text
## Reviso style — HEAD vs 9d25170 (0 commits, 2 files)

Found 2 style issues:

1. [P1][conf 95] `includeTotals` parameter is accepted but never read — src/report.ts:11
   Failure: the signature promises the total is optional, so the only caller
   (src/summary.ts:4) passes `true` believing it is switching behavior on. A future
   caller passing `false` gets the total anyway, and nothing in the type system says so.
   Evidence: grepped the repo for `includeTotals` — the single hit is the declaration at
   src/report.ts:11; the body at src/report.ts:12-14 reads only `rows`. No reflection,
   string-keyed dispatch, or DI registration exists (two plain ES modules, static imports).
   Fix: drop the parameter — `buildReport(rows: Row[]): Report` — and update the call site
   to `buildReport(rows)`. If the flag was meant to be real, gate `total` on it instead.
   (dead weight)

2. [P2][conf 92] `exportReportCsv` is exported with no caller anywhere in the repo — src/report.ts:17
   Failure: an unused export is maintained and type-checked forever without exercising its
   behavior; the CSV format it encodes drifts from whatever eventually consumes it.
   Evidence: grepped the repo for `exportReportCsv` — the only hit is the definition at
   src/report.ts:17. No import of it in src/summary.ts (the repo's only other file), no
   dynamic access near the definition.
   Fix: delete it until a consumer exists, or if it is the intended public entry point,
   land it together with the caller that uses it.
   (dead weight)

Checked: reuse, deterministic, drift, length, over-engineering, error handling,
surface area, AI tells, naming.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in the repo),
comments (skipped: the change adds no comments), stale docs (skipped: no README,
CHANGELOG, ADR, or doc prose in the repo), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Two notes on what the coverage block is telling you: this repo's base commit is empty, so the change *is* the whole codebase. That means the convention-relative lenses — drift, naming, error handling, type slop, over-engineering — ran but could not produce findings by construction: there is no pre-existing TypeScript to cite as a baseline, and this command scores an uncited baseline at zero rather than substituting my taste. Read their `returned` rows as "applied, nothing citable," not as a clean bill of health against a norm.

Duplication also returned empty rather than silent-by-oversight: `toFixed(2)` appears at `src/report.ts:12` and `src/summary.ts:5`, which is two occurrences — below the bar, which never ships regardless of how the copies look.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
