All searches came back confirmed. Here's the report.

```text
## Reviso style — HEAD (detached) vs 36ea31c (0 commits, 1 file)

No style issues found.

Checked: reuse, deterministic, drift, length, over-engineering, error handling,
surface area, AI tells, naming, type slop.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config governs
src/api/), comments (skipped: the change adds no comments), stale docs (skipped:
repo contains no README, ADRs, or other prose), test slop (skipped: no test files
in the repo or the change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Two notes on what cleared rather than passed unexamined, since a zero-finding run is only worth what its reasoning is:

- `const payload: any = req.body` at `src/api/refunds.ts:4` is the obvious type-slop candidate, but the lens is convention-relative and the baseline runs the other way: `src/api/orders.ts:4` and `src/api/users.ts:4` are byte-identical. There is no `tsconfig.json`, `package.json`, or ESLint config in the repo, so no `no-explicit-any` rule to lean on either. An `any`-heavy repo keeps its `any` — no finding.
- `handleCreateRefund` is exported with no caller (grep found only its own definition; no `Router`, `app.post`, or dynamic import anywhere under `src/`), but `handleCreateOrder` and `handleCreateUser` are in exactly the same position. The wiring lives outside this repo, so that is the established structure, not dead weight the change introduced.

The three handlers are also near-identical in shape, which I checked against the duplication bar deliberately: the positivity predicate appears in two places (refunds and orders — users validates an email instead), and two never ships however long the block. The three-way similarity is express-handler scaffolding, not a rule a future edit has to change in every copy, so it stays below the bar.
