# Eval results

> The harness and the first published run are live — see
> [eval/](../eval/README.md) for how baselines, candidates, and the judge
> work. Yes, the first numbers are bad. That's the point of publishing them.

## Runs

| date | corpus case | version | parity | misses | cost vs `/review` | artifacts |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-03 | `reviso-6` (this repo's own P0 PR) | v0 (6-finder pipeline) | **12%** (1/8) | 7 | **3.38×** (target ≤1.5×) | [runs/2026-08-03-reviso-6-v0](../eval/runs/2026-08-03-reviso-6-v0/) |
| 2026-08-04 | `reviso-6` | v0.3 (single-pass, D10 split) | **25%** (2/8) | 6 | **1.42×** ✅ | [runs/2026-08-04-reviso-6-v03](../eval/runs/2026-08-04-reviso-6-v03/) |

v0.3 notes: first run after the architecture split (single-pass `review`,
pipeline moved to `audit`) — cost bar cleared on the first attempt, parity
doubled, and both matches were findings every multi-agent version had
missed. Its one extra finding was real (`/review` had it in 1 of 3 runs,
below majority): the first verified win. Intermediate iterations v0.1–v0.2
(pipeline tuning: 0–12% parity, 2.0–3.0×) are recorded in the change's
design doc (D10) rather than as published runs.

v0 notes: the one match was the highest-severity finding (write-capable tool
grants — both tools agreed). Several misses are deliberate policy differences
(our false-positive list excludes test-coverage and process nits that
`/review` reports); they're counted against us anyway until we formalize a
policy-exclusion bucket. Same-day outcome: 6 of the baseline's findings were
real bugs, fixed before this page was published.

The parity bar: `/reviso:review` should catch everything Claude Code's
`/review` catches on the same changes. Anything it misses is a P0.

We publish the runs we lose alongside the ones we win. A review tool that only
reports its wins is not measuring anything.

This page will cover:

- The corpus: where the cases came from, and how false-positive and
  missed-finding reports become new ones
- Precision and recall per lens, per release
- Head-to-head runs against `/review` and `/code-review`
- The regressions, and what we did about them
