```
## Reviso style — HEAD (detached, at master) vs d568816 (0 commits, 1 file)

No style issues found.

Checked: reuse, deterministic, drift, length, over-engineering, error handling, surface area, AI tells, naming.
Not checked: conventions (skipped: no CLAUDE.md/AGENTS.md or lint config in repo), comments (skipped: change adds no comments), stale docs (skipped: no README/CHANGELOG/ADR/doc prose in repo), test slop (skipped: no test files in repo or change).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Two things worth stating about the zero, since a clean run should explain itself:

- **`payload: any` (refunds.ts:4) was considered and cleared.** Type slop is convention-relative, and this repo demonstrates the exact same line twice — `src/api/orders.ts:4` and `src/api/users.ts:4`, both `const payload: any = req.body;`. There is no tsconfig or ESLint config in the repo to override the demonstrated idiom, so the new file matches its baseline rather than diverging from it.
- **The three-handler repetition was considered and cleared.** `handleCreateRefund` is structurally identical to its two peers, but the duplicated unit is guard-clause-plus-status-response scaffolding, not a rule encoding — each handler's predicate and payload differ (`amountCents <= 0`, `quantity <= 0`, `!email.includes("@")`). At exactly 3 occurrences of incidental similarity, the duplication bar says stay silent.

I also confirmed via grep that no handler in the repo — including the two pre-existing ones — has any caller, router wiring, or dynamic dispatch, so the new export's lack of a consumer is the repo's established shape, not dead weight or surface area.
