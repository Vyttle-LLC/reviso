# Eval results

> The harness and the first published run are live — see
> [eval/](../eval/README.md) for how baselines, candidates, and the judge
> work. Yes, the first numbers are bad. That's the point of publishing them.
>
> **Protocol re-aim (2026-08-06).** Upstream `/review` turned out to be an
> effort-scaled skill embedded in the CLI, not the marketplace recipe we
> forked — and its default level (xhigh) is a recall-biased deep audit with
> the opposite philosophy to Reviso's precision invariant. The parity target
> is now the built-in `/code-review` pinned to **medium** (the
> precision-stance level), scored on **correctness-tier** findings only;
> cleanup-tier baseline findings are reported informationally. Baselines
> now run with fan-out allowed and record CLI version + level; a CLI
> version roll re-baselines. Details: `eval/README.md`,
> `eval/reference/builtin-skill-notes.md`, and the `re-aim-parity-eval`
> change. **The runs below predate the re-aim** (see each run dir's
> `SUPERSEDED.md`) — their numbers are internally consistent but not
> comparable with re-aimed runs.

## Metrics glossary

Two metric families, deliberately not comparable to each other:

- **Gold** (absolute, whole corpus, per release): the candidate alone
  against labeled ground truth — 64 labeled cases (50 CRB-imported real
  PRs + 13 synthetics incl. 5 expected-clean + 1 hand-authored). `gold recall
  (correctness)` = matched correctness-tier gold issues ÷ total;
  `precision proxy` = candidate findings matching any gold issue ÷ all
  candidate findings (unmatched ones may be real-but-unlabeled — they
  queue for label promotion, mirroring parity's claimed-wins rule);
  `clean-case FPs` = findings on expected-clean cases. This is the
  number tracked per release.
- **Parity** (relative, `active_parity` subset, per re-baseline event):
  correctness-tier findings of built-in `/code-review` medium
  (majority-of-3) that `/reviso:review` also catches, at ≤1.5× cost.
  This is the market-position check.

## Runs (gold)

| date | corpus | recall (correctness) | precision proxy | clean cases | artifacts |
| --- | --- | --- | --- | --- | --- |
| 2026-08-07 | full public (63 cases: 50 CRB + 13 synthetic) | **48%** (68/139) | 37% (71/189) | 4/5 silent | [runs/2026-08-07-gold-sweep-v0](../eval/runs/2026-08-07-gold-sweep-v0/) |

First-sweep notes — the aggregate is a **floor**, for reasons the
artifacts document case by case:

- **Synthetics: 8/8 bug cases at 100% recall; 4/5 clean cases silent.**
  The one "noisy" clean case (`security-sql-parameterized-001`) drew four
  findings on scaffolding the label never audited (bare `/api/admin/`
  servlet, no auth in sight) — a label-quality question queued for hand
  adjudication, not a gate failure.
- **Real cases are where the 48% lives**, and the zero-recall cluster
  (8 cases, 6 of them grafana/Go) is partly *label disagreement with
  receipts*: e.g. `crb-grafana-76186`, where the review examined the
  gold's exact concern and refuted it with a `file:line` mechanism, then
  shipped an arguably better finding the gold doesn't contain. CRB gold
  also includes classes Reviso excludes on purpose (compiler-catchable
  errors are linter territory). Raw recall against unaudited benchmark
  labels conflates real misses, policy differences, and label noise —
  the promotion/adjudication loop is how they get separated.
- **The deterministic detector lens did not run** in any candidate leg
  (headless permission gap, since fixed in `candidate.sh`) — another
  reason this sweep understates.
- Matcher calibration at this scale is still the spot-check +
  sagechat-15 sample; treat per-case numbers as screening, not verdicts.

## Runs (superseded protocol — pre-2026-08-06)

| date | corpus case | version | parity | misses | cost vs `/review` | artifacts |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-03 | `reviso-6` (this repo's own P0 PR) | v0 (6-finder pipeline) | **12%** (1/8) | 7 | **3.38×** (target ≤1.5×) | [runs/2026-08-03-reviso-6-v0](../eval/runs/2026-08-03-reviso-6-v0/) |
| 2026-08-04 | `reviso-6` | v0.3 (single-pass, D10 split) | **25%** (2/8) | 6 | **1.42×** ✅ | [runs/2026-08-04-reviso-6-v03](../eval/runs/2026-08-04-reviso-6-v03/) |
| 2026-08-04 | `reviso-6` @ current head | v0.3 **opus** (3-way) | 12% (1/8) | 7 | **1.09×** ✅ | [runs/2026-08-04-reviso-6-3way](../eval/runs/2026-08-04-reviso-6-3way/) |
| 2026-08-04 | `reviso-6` @ current head | v0.3 **sonnet** (3-way) | 0% (0/8) | 8 | 0.62× | same |

v0.3 notes: first run after the architecture split (single-pass `review`,
pipeline moved to `audit`) — cost bar cleared on the first attempt, parity
doubled, and both matches were findings every multi-agent version had
missed. Its one extra finding was real (`/review` had it in 1 of 3 runs,
below majority): the first verified win. Intermediate iterations v0.1–v0.2
(pipeline tuning: 0–12% parity, 2.0–3.0×) are recorded in the change's
design doc (D10) rather than as published runs.

3-way notes (opus baseline, all legs same diff): **cost parity achieved**
at the same model tier — 1.09× with detectors, FP gate, and assembly
included. Sonnet halves the cost but found 1 finding to opus's 5: the
single-pass architecture leans on model depth, and the opus pin earns its
price. Two caveats the numbers force us to own: `/review`'s own three runs
found 17/17/6 findings and agreed on only 8 of ~25 distinct ones — so
single-run parity against a majority baseline understates the candidate;
the protocol needs to be symmetric (majority-of-3 both sides). And the
matcher calibration gate (our own published prerequisite) is still unrun —
a gap `/reviso:review` itself flagged in this very round, alongside a spec
contradiction and a stale doc that `/review` missed. Both tools caught
real bugs the other didn't; the miss lists are now mostly non-overlapping
true positives plus policy differences, not one-sided quality gaps.

v0 notes: the one match was the highest-severity finding (write-capable tool
grants — both tools agreed). Several misses are deliberate policy differences
(our false-positive list excludes test-coverage and process nits that
`/review` reports); they're counted against us anyway until we formalize a
policy-exclusion bucket. Same-day outcome: 6 of the baseline's findings were
real bugs, fixed before this page was published.

The parity bar: `/reviso:review` should catch every correctness-tier
finding the built-in `/code-review` at medium catches on the same changes.
Anything it misses in that tier is a P0. Cleanup-tier findings the baseline
reports and Reviso gates are policy, not misses — they're published in an
informational bucket.

We publish the runs we lose alongside the ones we win. A review tool that only
reports its wins is not measuring anything.

This page will cover:

- The corpus: where the cases came from, and how false-positive and
  missed-finding reports become new ones
- Precision and recall per lens, per release
- Head-to-head runs against `/review` and `/code-review`
- The regressions, and what we did about them
