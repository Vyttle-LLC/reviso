# Add the surface lenses

## Why

After `add-the-reader-lenses`, the remaining slop families a normal code
review misses are about a change's *surface*: prose that the change made
false, API area it exposed without a consumer, and types it loosened
where the repo types precisely. Two of these are the P1 "actively
misleads" case — stale docs and loosened types lie to the next reader —
and nothing in the thirteen-lens set claims them.

## What Changes

- `/reviso:style` grows from thirteen lenses to sixteen: **stale docs**,
  **surface area**, and **type slop**.
- **Stale docs** covers existing prose the change made false — README,
  CLAUDE.md/AGENTS.md, CHANGELOG, ADRs, and doc comments on changed
  signatures. It is the only lens that reads *unchanged* lines, and only
  to quote the sentence the change contradicts; the comments lens keeps
  new and changed comments.
- **Surface area** covers exposure without a consumer: a new
  `export`/`public` with one internal caller, a widened signature
  nothing passes, a broadened return type. Dead weight's recorded-search
  protocol applies — the search is for *external* consumers.
- **Type slop** covers loosened types where the repo types precisely:
  `any`/`Any`/`interface{}`, force-unwraps and casts, stringly-typed
  enums, optionals that are never absent — convention-relative with two
  same-language examples.
- The report groups ledger rows into four families — shape, text, reuse,
  tests — so a sixteen-row coverage block stays readable. Family names
  appear in the coverage block; `--explain` keeps per-lens counts.
- Synthetic gold cases per lens (TP + clean look-alike).

Out of scope: `/reviso:review`, the audit finder, detectors, the shared
schema and rubric.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `style-command`: lens set thirteen → sixteen; stale-docs' read-unchanged-
  lines carve-out from the pre-existing exclusion; the lens-family
  coverage block.

## Impact

- `commands/style.md` — three lens bullets, Step 4 gate (stale docs'
  carve-out from the pre-existing rule, surface area's recorded search),
  ledger 13→16 with families, report coverage block, feedback mapping.
- `eval/corpus/` — 6 new synthetic cases.
- `openspec/specs/style-command/spec.md` via the delta.
- `CHANGELOG.md` 0.9.0, `plugin.json` bump.
