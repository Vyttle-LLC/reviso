## Reviso style — HEAD (detached) vs 1e5ecdb (0 commits, 1 file)

Found 2 style issues:

1. [P2][conf 95] Doc comment restates the signature and narrates the loop — src/cart.ts:6
   Failure: the next maintainer reads nine lines of prose to learn what `(items: Item[]): number` already states, and the "First… Then… Finally…" walkthrough will silently go stale the moment the body changes (e.g. a discount or tax term is added) while still reading as authoritative.
   Fix: delete the block. The name `cartTotal`, the parameter type `Item[]`, and the return type `number` carry every fact it asserts. If a doc comment is wanted, one line covering something the types can't say — e.g. whether prices are minor units — is the whole budget.
   (comments)

2. [P2][conf 95] Four inline comments each restate the line beneath them — src/cart.ts:16, 18, 20, 23
   Failure: `// Initialize the total to zero` / `let total = 0`, `// Loop over each item in the cart` / `for (const item of items)`, `// Add the item's price to the running total` / `total += item.price`, `// Return the computed total` / `return total` — the reader parses each statement twice and learns nothing the second time, and the comment density signals that something subtle is happening in a plain summation.
   Fix: delete all four. The loop body is self-describing; nothing here can be clarified by naming, extraction, or types because there is nothing unclear.
   (comments)

Checked: deterministic, slop, comments, duplication, over-engineering, dead weight, AI tells.
Not checked: conventions (skipped — no CLAUDE.md, AGENTS.md, or lint config in the repo); drift (skipped — base commit is empty, so there is no existing code to establish a demonstrated norm); length (skipped — no comparable functions or doc comments in the repo to measure against); test slop (skipped — the change adds no tests).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
