# 2026-09-01 — best-practices lens gold pair, with and without `--web` (0.11.0)

Acceptance run for `add-the-best-practices-lens`: the `bp-deprecated-api`
pair through `REVISO_TIER=audit gold.sh` twice — once with
`REVISO_CMD_ARGS=--web` (the lens in lane) and once without (the lens
skipped, the label out of lane). Plugin at the change's working tree,
claude-opus-5 (orchestrator), claude-sonnet-5 (finders, evidence), claude-haiku-4-5 (triage), CLI 2.1.252. Four runs in parallel, live network for the two
`--web` legs.

| leg | case | result | cost | wall |
| --- | --- | --- | --- | --- |
| `--web` | `bp-deprecated-api-001` | **1/1 matched**, P2, `Source:` cites the python.org datetime page with the "Deprecated since version 3.12" passage | $1.43 | 291 s |
| `--web` | `bp-deprecated-api-clean-001` | **silent** | $1.16 | 237 s |
| no flag | `bp-deprecated-api-001` | 1 finding from the **bugs** lens (naive/aware `TypeError`), matcher pairs it with the label but the label is out of lane (`gold_correctness_count: 0`); coverage block says `best-practices (no --web)` | $1.32 | 24 s |
| no flag | `bp-deprecated-api-clean-001` | **silent**; coverage block says `best-practices (no --web)` | $0.88 | 179 s |

What the run establishes:

- **The class fires on a fetched source.** The finder made 2 searches
  and 2 fetches (bound 12/2 untouched); the shipped finding carries the
  URL and passage, and the bugs and history lenses' independent flags on
  the same line merged into it per the reconcile rule.
- **Version applicability was checked.** The finding names
  `requires-python = ">=3.12"` as the reason the deprecation covers the
  whole support range.
- **The flag-off path is inert.** Without `--web` no web tool was
  granted or used, the ledger row reads `skipped (no --web)`, and
  `tiers.sh` moves the label out of lane — the bugs lens still catching
  the naive-datetime crash is the pre-existing product, not this lens.
- **Precision tripwire held**: both clean look-alikes silent, no
  candidate on the true-positive outside the label's substance.

Field smoke (`/reviso:audit --web --explain` on a real Next.js branch,
23 files) is recorded in `field/` beside this file.

## Field smoke (`field/`)

`/reviso:audit` headless on a real branch — `vyttle.com` `audit-fixes`
(Next.js 16, 11 commits, 24 files) — once with `--web --explain`, once
plain. Reports and meta in `field/`.

| leg | findings | best-practices | cost | wall |
| --- | --- | --- | --- | --- |
| `--web --explain` | 4 (P2s: focus-behind-overlay, aria-hidden contradiction, stale DESIGN.md, 7-file shell duplication) | ran: 6 searches, 5 fetches, bound not hit; **2 candidates, both gated** (`eslint-disable` with written rationale → explicitly-silenced exclusion) | $11.53 | 976s |
| plain | 5 (P1 SupportForm error path + 4 P2s) | `Not checked: best-practices (no --web)` | $11.07 | 934s |

Contract checks, from the `--explain` Web block:

- **Query vocabulary held.** All 6 queries are ecosystem facts —
  `next.js 16`, `eslint-config-next`, `eslint-plugin-react-hooks`
  rule names, react.dev/nextjs.org doc lookups. No repo identifiers,
  paths, diff text, or commit words left the machine.
- **Sources were primary and fetched**: nextjs.org and react.dev doc
  pages only; both candidates cited live rules at the right version.
- **The gate did its job**: the two best-practices candidates were real
  claims about a live lint rule, but both call sites carry block-scoped
  disables with written rationale — the shared "explicitly silenced"
  exclusion, applied at the orchestrator, not by the finder.
- **Cost of the lens** on this branch: ~$0.5 and ~40 s over the plain
  leg (within run-to-run variance; the two legs also differ by ordinary
  audit variance — e.g. the plain leg scored the SupportForm error path
  new-in-change at 80 while the `--web` leg judged it pre-existing).

Variance note, not a lens defect: finding sets differ between legs on
the shared lenses; both reports are internally consistent and every
divergence traces to gate judgment calls (pre-existing vs new), not to
`--web`.
