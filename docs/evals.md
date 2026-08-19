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
>
> **Tier attribution (2026-08-14).** Reviso ships two review tiers, and
> until now the harness could only run one of them. **Every number
> published on this page below the audit-tier row measures
> `/reviso:review`, the single-pass inner-loop tier** — the candidate
> runner hardcoded that command, so `/reviso:audit` never ran in any of
> them. The 48% correctness recall is the *review tier's* recall, not
> "Reviso's". The candidate leg now names its tier explicitly
> (`REVISO_TIER=review|audit`, no default), every new run records it, and
> the judge refuses comparisons that cross tiers. **Runs recorded before
> that carry no tier field and are therefore non-comparable under the new
> rule** — see `eval/README.md`.

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

| date | tier | corpus | recall (correctness) | precision proxy | clean cases | artifacts |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-07 | `review` | full public (63 cases: 50 CRB + 13 synthetic) | **48%** (68/139) | 37% (71/189) | 4/5 silent | [runs/2026-08-07-gold-sweep-v0](../eval/runs/2026-08-07-gold-sweep-v0/) |
| 2026-08-08 | `review` | `termic-162` only (1 case, duplication lens) | **100%** (1/1) | 33% (1/3) | n/a | [runs/2026-08-08-gold-termic-162](../eval/runs/2026-08-08-gold-termic-162/) |
| 2026-08-19 | `style` | `slop-*` only (10 cases: 5 TP + 5 expected-clean, one pair per new lens) | **100%** (9/9) | 90% (9/10) | **5/5 silent** | [runs/2026-08-19-gold-style-expansion](../eval/runs/2026-08-19-gold-style-expansion/) |

The first two rows measure `/reviso:review`; their tier column is
attributed retroactively — neither run recorded a tier, because the runner
had only one to record.

The 2026-08-19 row is the style expansion's acceptance run (0.7.0):
`/reviso:style`'s five new lenses (over-engineering, dead weight,
comments, test slop, AI tells) against their authored synthetic pairs —
all five true-positive cases matched every gold finding, all five
expected-clean look-alikes stayed silent. The 90% precision proxy is one
granularity artifact, not an FP: on `slop-comments-001` the candidate
split one root cause (comments restating code) into two findings, both
correct; the extra stands as a promotion candidate. One label was
recalibrated after the run: `slop-testslop-001` originally demanded two
findings, but the command's reporting policy *requires* consolidating the
two can't-fail tests into one — the label now encodes the consolidated
shape, and the case was **re-matched fresh** (not verdict-reuse) against
the corrected label. Per-case cost ~$0.45, `claude-opus-5`. Style-tier
gold runs are meaningful only against style-labeled or expected-clean
cases (see `eval/corpus/README.md`).

The 2026-08-08 row is a single-case acceptance run for the duplication
lens (0.3.0), not a sweep — do not compare its numbers to the row above.
What it establishes: the lens **matched its gold label 1/1**, locating all
seven occurrences of the collision rule, citing each by `file:line`, and
naming a helper with signature and proposed home. Recall for this lane had
never been measured before; the bar's calibration had only ever been
checked as text.

Two notes on the row:

- **The recall figure required a tiering fix.** As first judged this row
  read `n/a`: `duplication` sat in the cleanup family, so the case
  contributed zero in-lane gold and could not move the headline metric —
  a lens Reviso ships, invisible to the number that tracks it. The tier
  split is really in-lane vs out-of-lane, so `duplication` left the
  cleanup list (`eval/runners/tiers.sh`) and the run was **re-judged from
  its recorded output** — same findings, same recorded matcher verdicts,
  new tiering. A future miss on this case is now a listed regression.
- **The 33% precision proxy resolves to one match, one false positive, one
  promotion candidate.** Adjudicated after the run. The FP claimed the GUI
  create path "has no name check at all"; it does — `task_create_sync`
  refuses a colliding name at `lib.rs:3093` ("a worktree already lives at
  … — pick a different name"), since same-name tasks in a project slugify
  to the same worktree path. The finding reached its conclusion by
  reasoning about the guard's *shape* (path-based, not name-based) instead
  of its *effect*, which is the enforcement-vs-claim lens inverted on
  itself. The remaining unmatched finding — a coverage test not extended
  to the new verb — stands as a promotion candidate.

Cost: $2.10, 5m23s, `claude-opus-5`, CLI 2.1.226.

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

## Runs (audit tier)

The deep tier's first recorded measurement. Not a gold row: `reviso-6`
carries no labels file, so there is no recall figure to report — what this
run establishes is the score distribution and the per-lens yield, which
are within-run facts.

| date | tier | case | candidates → reported | cost | artifacts |
| --- | --- | --- | --- | --- | --- |
| 2026-08-13 | `audit` | `reviso-6` @ v0.4.0, hand-produced | 13 → 3 (merged to 2) | $9.73 | [runs/2026-08-13-reviso-6-audit-v040](../eval/runs/2026-08-13-reviso-6-audit-v040/) |
| 2026-08-14 | `audit` | `reviso-6` @ v0.4.0, **runner-produced** | 5 → 1 | $6.42 | [runs/2026-08-14-reviso-6-audit-v040](../eval/runs/2026-08-14-reviso-6-audit-v040/) |
| 2026-08-14 | `review` | `reviso-6` @ v0.4.0 (bound check) | 10 → 4 | $2.04 | [runs/2026-08-14-reviso-6-review-v040](../eval/runs/2026-08-14-reviso-6-review-v040/) |

The 2026-08-14 audit run is now the tier's comparison anchor: same case,
same SHAs, same CLI, but produced by `eval/runners/candidate.sh` with the
identity fields machine-recorded, and with the history bound in place. The
hand-produced row stays in the tree as what it was.

Scores as `--explain` printed them:

| run | reported | rubric-dropped | exclusion | pre-existing |
| --- | --- | --- | --- | --- |
| 2026-08-13 (hand) | 90, 88, 85 | 68, 60, 52, 40, 40 | 20, 10, 0 | 5, 5 |
| 2026-08-14 (runner) | 90 | 55, 50 | — | — |

Per-lens yield moved with it: prior-reviews **7 → 0**, history **1 → 0**,
slop 1 → 0, comments 0 → 1, bugs 2 → 2, conventions 2 → 2.

What the two audit rows establish, each covered in full by the run
directories' READMEs:

- **The history bound works, and cost nothing.** `prior-reviews` and
  `history` had reached commits after the case's head and cited the very
  commits that later fixed what they flagged — 7 of the 13 candidates in
  the hand run. Under the bound both return zero, and the run's own report
  names what it excluded (PR #6, not an ancestor of `e76eda9`) and why the
  history lens dropped its own conclusion (its only evidence was a
  non-ancestor commit). The finding survived anyway at 90, reached by the
  `bugs` lens from in-branch files. Contaminated evidence excluded, no
  reported finding lost.
- **The rest of the gap is run-to-run variance, not this change.** The
  `slop` lens yielded 1 then 0, which is the whole reason the hand run's
  second reported finding has no counterpart; `comments` moved the other
  way. One run against one run cannot separate a real effect from the
  variance floor this page already records elsewhere.
- **The gate dropped two confirmed-real findings** in the hand run, at 68
  and 40, both from the enforcement-vs-claim class. Nothing scored 75–79,
  so moving the threshold to 75 would have changed nothing. What to do
  about that is `recalibrate-the-confidence-rubric`'s business.
- **Report-only held on the deep tier**, checked by the runner's pre/post
  worktree comparison for the first time — eight agents, zero writes.
- **`duration_ms` cannot time this tier.** The runner recorded 22.8s and 1
  turn for a run that took ~8 minutes; those fields see only the
  orchestrator's own turn, not its fan-out. `duration_api_ms` (34 min
  aggregated) is now recorded alongside. On the review tier the two agree.

## Runs (superseded protocol — pre-2026-08-06)

| date | corpus case | version | parity | misses | cost vs `/review` | artifacts |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-08-03 | `reviso-6` (this repo's own P0 PR) | v0 (6-finder pipeline) | **12%** (1/8) | 7 | **3.38×** (target ≤1.5×) | [runs/2026-08-03-reviso-6-v0](../eval/runs/2026-08-03-reviso-6-v0/) |
| 2026-08-04 | `reviso-6` | v0.3 (single-pass, D10 split) | **25%** (2/8) | 6 | **1.42×** ✅ | [runs/2026-08-04-reviso-6-v03](../eval/runs/2026-08-04-reviso-6-v03/) |
| 2026-08-04 | `reviso-6` @ current head | v0.3 **opus** (3-way) | 12% (1/8) | 7 | **1.09×** ✅ | [runs/2026-08-04-reviso-6-3way](../eval/runs/2026-08-04-reviso-6-3way/) |
| 2026-08-04 | `reviso-6` @ current head | v0.3 **sonnet** (3-way) | 0% (0/8) | 8 | 0.62× | same |

The 2026-08-03 row predates the D10 split, when the multi-agent pipeline
was what `/reviso:review` ran; every row after it measures the single-pass
tier. None of them recorded a tier — the field did not exist — so all four
are non-comparable under the current judge rule as well as the superseded
baseline protocol.

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
