The detector suite ran clean (`[]`). Here's the report.

```text
## Reviso style — HEAD (detached) vs d78d538 (0 commits, 3 files)

No style issues found.

Checked: drift, length, over-engineering, surface area, AI tells, naming,
slop, duplication, dead weight, deterministic.
Not checked: conventions (skipped: no CLAUDE.md / AGENTS.md / lint config in
repo), error handling (skipped: change adds no error handling and the repo
has none), comments (skipped: change adds no comments), stale docs (skipped:
repo has no README, ADRs, changelog, or doc comments), derived state
(skipped: change adds no stored or cached state), test slop (skipped: no
test files in repo).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Notes on the two lenses most likely to misfire on this change, since a clean run should explain itself:

- **Surface area** — both new exports in `src/billing/totals.ts` have consumers outside their own module: `computeTotal` from `src/billing/checkout.ts:2,5`, and `roundCents` from `src/reports/summary.ts:1,5`. Grep of `roundCents|computeTotal|averageCents` across `src/` found no dynamic or string-keyed access. Neither is exposure without a consumer.
- **Naming / drift** — `computeTotal` and `roundCents` match the repo's existing verb+noun camelCase (`computeTax` at `src/billing/tax.ts:7`, `clampRate` at `src/billing/tax.ts:3`, `checkoutTotal` at `src/billing/checkout.ts:4`), and `totals.ts` follows `tax.ts`'s layout of named exports over an unexported helper.
