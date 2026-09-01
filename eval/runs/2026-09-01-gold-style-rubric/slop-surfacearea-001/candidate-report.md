```text
## Reviso style — HEAD (detached) vs fec3c8a (0 commits, 2 files)

Found 1 style issue:

1. [P2][conf 88] `roundCents` is exported but has no consumer outside its own module — src/billing/totals.ts:4
   Failure: the module's public API advertises a rounding primitive nobody outside it uses; the next
   reader has to search the repo to learn whether it is load-bearing, and a future edit to it must
   assume unknown external callers.
   Search: `grep -rn "roundCents" --include='*.ts' .` returns exactly two hits — the definition at
   totals.ts:4 and one in-module call at totals.ts:10. `grep -rnE "require\(|import\(|\[\"'…'\]|Reflect\."`
   across the repo returns nothing, so there is no dynamic-access path. The repo's counterpart helper
   `clampRate` (src/billing/tax.ts:3) is the same shape — a one-line numeric helper with a single
   in-module caller — and is not exported; every symbol the repo does export has a cross-module
   consumer (src/types.ts:1, src/billing/tax.ts:7, src/billing/totals.ts:8).
   Fix: drop the `export`: `function roundCents(value: number): number {`.
   (surface area)

Checked: reuse (slop, duplication, dead weight), drift, length, over-engineering, surface area,
AI tells, naming, type slop, deterministic.
Not checked: conventions (skipped: no CLAUDE.md / AGENTS.md / lint config in repo),
comments (skipped: no comments in the change), stale docs (skipped: no doc files in repo),
error handling (skipped: no error handling in the change),
derived state (skipped: no stored state in the change),
test slop (skipped: no test files in repo or change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Notes on what I deliberately did not flag: extracting `computeTotal` into `src/billing/totals.ts` sits beside `tax.ts` and mirrors `computeTax`'s signature and body shape, so module layout and naming match the repo. The single-consumer `roundCents` helper itself is not over-engineering — `clampRate` (`src/billing/tax.ts:3`) establishes exactly that idiom; only the `export` diverges. The moved `reduce` is a move, not a second copy, so it stays below the duplication bar.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
