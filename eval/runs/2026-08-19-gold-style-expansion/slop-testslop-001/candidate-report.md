## Reviso style — HEAD (detached) vs 776dbd4 (0 commits, 2 files — both untracked)

Found 1 style issue:

1. **[P1][conf 100] Test suite never exercises `finalPrice` — neither test can fail** — tests/pricing.test.ts:5
   Failure: `const mockFinalPrice = jest.fn().mockReturnValue(110)` followed by `expect(result).toBe(110)` asserts only that jest's own mock returns what it was just configured to return; the imported `finalPrice` is never invoked. The second test (tests/pricing.test.ts:12, `expect(finalPrice).toBeDefined()`) is tautological — a successfully imported function export is always defined. `finalPrice` could return `NaN`, drop the rounding, or ignore `taxRate` entirely and this suite stays green, while reading as tax-calculation coverage.
   Fix: call the real function and assert on its output, including the rounding behavior the implementation exists to provide, and delete the `toBeDefined` test:
   ```ts
   it("applies tax and rounds to two decimals", () => {
     expect(finalPrice(100, 0.1)).toBe(110);
     expect(finalPrice(19.99, 0.0825)).toBe(21.64);
   });
   ```
   (test slop)

Checked: slop, duplication, length, over-engineering, dead weight, test slop, AI tells, deterministic.
Not checked: comments (skipped — the change adds no comments); conventions (skipped — no CLAUDE.md, AGENTS.md, or lint config in the repo); drift (skipped — the base commit is empty, so there is no existing code to cite a baseline from).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
