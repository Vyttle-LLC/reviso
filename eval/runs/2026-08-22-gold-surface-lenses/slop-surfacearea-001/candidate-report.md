Detectors returned `[]`. Here's the review.

## Reviso style — HEAD (detached, 0 commits ahead of `a645ecc`) vs `a645ecc` (2 files)

Found 1 style issue:

**1. [P2][conf 85] `roundCents` is exported but has no consumer outside its own module — src/billing/totals.ts:4**
   Baseline: `clampRate` (src/billing/tax.ts:3) is the repo's one comparable arithmetic helper and is module-private; only the module's entry point (`computeTax`, src/billing/tax.ts:7) is exported. `computeTotal` (src/billing/totals.ts:8) follows that pattern correctly — it has a real external caller at src/billing/checkout.ts:5.
   Search: `grep -rn "roundCents" --include="*.ts" .` returns exactly two hits — the definition at totals.ts:4 and the call at totals.ts:10. `grep -rn "require(\|import("` over the repo returns nothing, so there is no dynamic or string-keyed access to fall back on.
   Fix: drop the `export` keyword so it matches `clampRate`. Alternatively, since the body adds nothing to `Math.round`, inline it at totals.ts:10 following src/billing/tax.ts:9 (`return Math.round(subtotal * clampRate(rate))`) and delete the helper — that also removes the single-consumer wrapper.
   (surface area; also flagged by the over-engineering lens as a one-line abstraction with a single consumer at totals.ts:10 — same root cause, one finding)

Checked: drift, length, over-engineering, error handling, surface area, AI tells, naming, slop, duplication, dead weight, deterministic.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in the repo), comments (skipped: the change adds no comments), stale docs (skipped: repo has no README, docs, or doc comments), derived state (skipped: the change adds no stored state — all functions are pure), test slop (skipped: no test files in the repo or the change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Two things I checked and deliberately did not flag: the `items.reduce(...)` subtotal at totals.ts:9 is a verbatim move out of checkout.ts, not a new copy, and its near-twin at tax.ts:8 differs (no `quantity` factor) — two occurrences is below the duplication bar either way.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
