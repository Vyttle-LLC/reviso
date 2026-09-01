## Reviso style — HEAD vs 4d9acfc (0 commits, 2 files)

Found 1 style issue:

1. **[P1][conf 96]** Test mocks the subject under test and asserts its own stub — cannot fail — `tests/pricing.test.ts:5`
   Failure: `finalPrice` is imported at line 1 but never invoked by any test. Line 5 creates `jest.fn().mockReturnValue(110)`, line 6 calls the mock, and lines 7–8 assert `expect(result).toBe(110)` and `expect(mockFinalPrice).toHaveBeenCalledWith(100, 0.1)` — both assert what line 5 just configured, so they hold for any implementation of `finalPrice`, including a deleted one. The second test (`tests/pricing.test.ts:12`, `expect(finalPrice).toBeDefined()`) shares the root cause: it asserts the import resolved, not that the price is right. The file reads as coverage for `finalPrice` while leaving `Math.round(base * (1 + taxRate) * 100) / 100` (`src/pricing.ts:2`) entirely unexercised — a broken rounding or tax formula ships green.
   Fix: call the real function and drop the mock and the definedness test:
   ```ts
   it("applies tax and rounds to two decimals", () => {
     expect(finalPrice(100, 0.1)).toBe(110);
     expect(finalPrice(19.99, 0.075)).toBe(21.49);
   });
   ```
   (test slop)

Checked: tests, length, over-engineering, surface area, AI tells, naming, slop, duplication, dead weight, type slop, deterministic.
Not checked: drift (skipped: base commit is empty — no pre-existing same-language code to establish a baseline), conventions (skipped: no CLAUDE.md / AGENTS.md or lint config in the repo), error handling (skipped: the change contains no error handling), comments (skipped: the change adds no comments), stale docs (skipped: the repo contains no prose docs), derived state (skipped: the change stores no state).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
