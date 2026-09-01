Detectors ran clean (`[]`). Here's the review.

## Reviso style — HEAD vs 7fc824c (0 commits, 1 file)

Found 1 style issue:

1. **[P1][conf 88] `any` payload where both sibling handlers declare a typed interface** — `src/api/refunds.ts:4`
   Baseline: `src/api/orders.ts:3-6` declares `interface OrderPayload { sku: string; quantity: number }` and casts at `orders.ts:9` (`req.body as OrderPayload`); `src/api/users.ts:3-6` declares `interface UserPayload { email: string; displayName: string }` and casts at `users.ts:9`. `grep -rn "any" src` returns exactly one hit — the added line — so the repo has no competing `any` idiom, and no lint config or tsconfig exists to make this linter territory.
   Fix: mirror the siblings —
   ```ts
   interface RefundPayload {
     orderId: string;
     amountCents: number;
   }

   const payload = req.body as RefundPayload;
   ```
   (type slop)

Notes on two lenses that came close and did not ship: the three handlers share a validate-then-400-then-201 shape, but at exactly 3 occurrences of incidental handler scaffolding with three different predicates, that is below the duplication bar. `handleCreateRefund` has no caller — `grep -rn "handleCreate" src` finds only the three definitions — but neither sibling export has one either (the repo contains no router or app file), so an uncalled exported handler is the established pattern here, not something this change introduced.

Checked: reuse, deterministic, drift, length, over-engineering, error handling, surface area, AI tells, naming, type slop.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config anywhere in the repo), comments (skipped: the change adds no comments), stale docs (skipped: no docs, README, or changelog in the repo), test slop (skipped: no test files exist or changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
