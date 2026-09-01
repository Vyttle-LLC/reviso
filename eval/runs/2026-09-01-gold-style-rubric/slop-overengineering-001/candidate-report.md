I assembled the change, ran the detectors, and applied the sixteen style lenses myself. Report:

```text
## Reviso style — HEAD vs 4eb0b06 (0 commits, 2 files)

Found 2 style issues:

1. [P2][conf 90] Strategy interface + factory scaffolding, one consumer each — src/discount.ts:1
   Failure: four exported types encode a plug-in point that has no second
   implementation and no external caller, so every reader of `applyBulkDiscount`
   must trace through an interface, a class and a static factory to learn that
   the discount is "10% off at 100". Repo-wide grep for `DiscountStrategy`,
   `DiscountStrategyFactory`, `DiscountStrategyFactoryOptions`,
   `BulkDiscountStrategy` returns hits only inside src/discount.ts (the repo is
   two files; no reflection, DI or string-keyed dispatch exists). Absence
   citations: `DiscountStrategy` (:1) has exactly one implementer, `BulkDiscountStrategy`
   (:11); `DiscountStrategyFactory.create` (:27) has exactly one caller,
   discount.ts:39, which passes no arguments — so `DiscountStrategyFactoryOptions`
   (:6) is never populated and `threshold`/`rate` are always the 100/0.1 defaults
   at :29-30. checkout.ts:1 imports only `applyBulkDiscount`.
   Fix: collapse to the function plus two constants, dropping all four exports:
     const BULK_DISCOUNT_THRESHOLD = 100;
     const BULK_DISCOUNT_RATE = 0.1;
     export function applyBulkDiscount(total: number): number {
       return total >= BULK_DISCOUNT_THRESHOLD
         ? total - total * BULK_DISCOUNT_RATE
         : total;
     }
   (over-engineering; also anchors the surface-area candidate on :1, :6, :11, :26)

2. [P2][conf 90] Null/undefined guard on a parameter typed `number` — src/discount.ts:36
   Failure: `if (total === null || total === undefined) return 0;` defends a state
   the type makes unreachable — the parameter is declared `total: number` at
   discount.ts:35, and the sole caller (checkout.ts:5) passes
   `items.reduce((sum, item) => sum + item.price, 0)` from checkout.ts:4, whose
   `0` seed makes a non-number result impossible. The next maintainer reads a
   nullable contract into a signature that does not have one.
   Fix: delete lines 36-38.
   (over-engineering)

Checked: reuse, deterministic, over-engineering, surface area, comments, AI tells, type slop.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md or lint config anywhere in the repo), drift (skipped: the base commit is an empty tree — no pre-existing code to cite two baseline examples from), naming (skipped: same — no baseline), length (skipped: no comparable units in the repo, and absolute thresholds are banned), error handling (skipped: the change contains no throw, catch or rejection), stale docs (skipped: the repo contains no README, CHANGELOG or other prose), test slop (skipped: no test files in the change or the repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Two notes on the run: the base commit is an empty tree, so this change *is* the whole repo — every convention-relative lens (drift, naming, length, error handling) has no baseline to cite and was recorded as skipped rather than clean. The deterministic detector suite ran and returned `[]`.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
