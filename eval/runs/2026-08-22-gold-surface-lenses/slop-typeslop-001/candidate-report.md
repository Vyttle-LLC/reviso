## Reviso style — HEAD vs 4b9d311 (0 commits, 1 file)

Found 1 style issue:

1. **[P2][conf 92] `payload` typed `any` where sibling handlers declare a payload interface — src/api/refunds.ts:4**
   Baseline: `src/api/orders.ts:3-6` declares `interface OrderPayload { sku: string; quantity: number }` and narrows at `orders.ts:9` with `req.body as OrderPayload`; `src/api/users.ts:3-6` / `users.ts:9` do the identical thing with `UserPayload`. Both are the same language and the same kind of unit (an express create-handler in `src/api/`). No lint config exists in the repo (no `eslint.config.*`, `.eslintrc*`, or `tsconfig.json`), so `no-explicit-any` does not cover this, and there is no inline suppression on the line.
   Fix: follow the two cited files —
   ```ts
   interface RefundPayload {
     orderId: string;
     amountCents: number;
   }

   export function handleCreateRefund(req: Request, res: Response): void {
     const payload = req.body as RefundPayload;
   ```
   `orderId` is read at `refunds.ts:9` but declared nowhere; under `any` neither it nor `amountCents` is checked at all, while the sibling handlers get both fields checked.
   (type slop; also the drift candidate for the missing interface declaration — same root cause, folded in here)

Checked: reuse, deterministic, drift, length, over-engineering, error handling, surface area, AI tells, naming, type slop.
Not checked: conventions (skipped: no CLAUDE.md / AGENTS.md and no lint config in the repo), comments (skipped: the change adds no comments), stale docs (skipped: no README, changelog, ADRs, or doc comments in the repo), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Notes on two lenses that produced candidates but not findings: the export `handleCreateRefund` has no caller anywhere (grep for `handleCreateRefund` across `src/` returns only the definition, and the repo is three files with no router or index), but `handleCreateOrder` and `handleCreateUser` are equally uncalled — app wiring lives outside this slice, so that is the repo's established shape, not dead weight or surface area. The three-handler validate-then-400-then-201 block is incidental scaffolding at exactly 3 occurrences, below the duplication bar.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
