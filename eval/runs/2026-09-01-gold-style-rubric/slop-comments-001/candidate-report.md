```text
## Reviso style — HEAD (detached) vs cfc35b8 (0 commits, 1 file)

Found 1 style issue:

1. [P2][conf 92] Comments restate the code line for line — src/cart.ts:6
   Also at src/cart.ts:16, :18, :20, :23
   Failure: 15 of the file's 25 lines are comments that say exactly what the
   adjacent code says — `// Initialize the total to zero` above `let total = 0;`,
   `// Loop over each item in the cart` above `for (const item of items)`,
   `// Add the item's price to the running total` above `total += item.price;`,
   `// Return the computed total` above `return total;`. The JSDoc narrates the
   same loop a second time in prose ("First, we initialize the total to zero.
   Then we loop over each item in the array and add its price to the running
   total. Finally, we return the total price to the caller."). A reader must
   read the algorithm three times to learn it once, and every future edit to
   the body silently falsifies all three tellings. No CLAUDE.md, AGENTS.md, or
   lint config exists in this repo, so no written convention demands the
   doc-comment shape.
   Fix: drop all four inline comments and the algorithm narration; the
   signature and body already say it. If a doc comment is wanted, one line:
   `/** Sum of the prices of `items`. */`
   (comments)

Checked: comments, AI tells, naming, slop, duplication, dead weight, drift,
length, over-engineering, surface area, deterministic.
Not checked: conventions (skipped: no CLAUDE.md, AGENTS.md, or lint config in
repo), error handling (skipped: no error handling in the change), derived
state (skipped: no stored state added), stale docs (skipped: no existing docs
in repo), test slop (skipped: no test files changed).
Skipped: nothing.
Style only — for bugs, run /reviso:review (inner loop) or /reviso:audit (pre-PR).
```

Two notes on the scope this run had to work with: the repository contains exactly one file, so every convention-relative lens (drift, naming, error handling, type slop) had no same-language baseline to cite and could only return empty — a second file would give those lenses something to measure against. And `cartTotal`/`Item` have no caller anywhere (searched `cartTotal` across the repo; only the definition matched), but in a single-file repo that carries no signal, so it is not a dead-weight or surface-area finding.

Wrong about something? Say which finding — I can file feedback (metadata-only by default).
