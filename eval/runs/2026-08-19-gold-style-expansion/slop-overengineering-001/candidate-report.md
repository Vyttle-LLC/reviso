Detectors returned clean. Here's the report.

```text
## Reviso style — HEAD vs 776dbd4 (0 commits, 2 files)

Found 2 style issues:

1. [P2][conf 92] Strategy interface + factory built for a single caller — src/discount.ts:1
   Failure: three exported types and a factory class encode `total >= 100 ? total * 0.9 : total`.
   `DiscountStrategy` (src/discount.ts:1) has exactly one implementer, `BulkDiscountStrategy`
   (src/discount.ts:11). `DiscountStrategyFactory.create` (src/discount.ts:27) has exactly one
   caller, src/discount.ts:39, and it passes no arguments. `DiscountStrategyFactoryOptions`
   (src/discount.ts:6) is never supplied anywhere — grep for `DiscountStrategyFactory`,
   `threshold`, and `rate` across the repo returns only these definition sites plus the
   defaulting at src/discount.ts:29-30; the repo is two files, so there is no dynamic
   access, DI registration, or string-keyed dispatch to hide a second consumer. The next
   reader has to trace four indirections to learn one rule, and any real second discount
   type will want a different shape than the one guessed here.
   Fix: collapse to the rule itself and keep the knobs as parameters, since that is the only
   variation the factory actually offered:
     export function applyBulkDiscount(total: number, threshold = 100, rate = 0.1): number {
       return total >= threshold ? total * (1 - rate) : total;
     }
   Reintroduce the interface when a second strategy exists.
   (over-engineering; also anchors dead-weight at src/discount.ts:6 and slop across
   src/discount.ts:1-44 — 44 lines where src/checkout.ts does comparable work in 6)

2. [P2][conf 85] Null/undefined guard on a parameter the types make impossible — src/discount.ts:36
   Failure: `total` is declared `number` at src/discount.ts:35, and the sole caller passes
   `items.reduce((sum, item) => sum + item.price, 0)` (src/checkout.ts:4-5), which always
   yields a number. The branch is unreachable, so it reads as a documented contract that
   nullish input is expected and maps to 0 — a claim nothing in the code supports.
   Fix: delete lines 36-38.
   (over-engineering)

Checked: slop, duplication, length, over-engineering, dead weight, AI tells, deterministic.
Not checked: comments (skipped — the change adds no comments), conventions (skipped — no
CLAUDE.md, AGENTS.md, or lint config exists in the repo), drift (skipped — the base commit
is empty, so there is no pre-existing code to cite an established pattern from), test slop
(skipped — the change adds no tests).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Note on the `Not checked` line: drift and conventions are structurally unavailable here rather than clean — the base commit `776dbd4` contains no files, so both added files are the entire repo and there is no norm to measure against. Every judgment above is therefore made against the change's own internals (single-consumer citations, unreachable-branch citations), not against a repo baseline.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
