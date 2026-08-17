# Parity eval harness

The acceptance test for Reviso's north star: on the same changes,
`/reviso:review` catches every **correctness-tier** finding that the
built-in `/code-review` at **medium** catches. A correctness-tier baseline
finding we miss is a P0 regression. See the PRD (§5, §13) and the
`re-aim-parity-eval` change for why the target names a level: upstream
`/review` is now effort-scaled, and its default (xhigh) is a recall-biased
deep audit with the opposite philosophy to Reviso's precision invariant.
Medium is the level that shares our stance ("every finding you surface
should be one a maintainer would act on") and cost class.

## Flow

```text
corpus entry {repo, pr, base_sha, head_sha}
  │
  ├─ runners/baseline.sh   3 headless "/code-review medium" runs on the
  │                        real PR, subagent fan-out allowed
  │                        → majority baseline (findings in ≥2 of 3 runs)
  ├─ runners/candidate.sh  checkout head_sha, $REVISO_TIER --base base_sha
  │                        → candidate findings from the report
  └─ runners/judge.sh      tier baseline findings (correctness vs cleanup),
                           conservative root-cause matching →
                           matched | missed | claimed_wins + metrics
```

- **Misses in the correctness tier** are listed individually — each is a P0
  regression, not a percentage. Cleanup-tier baseline findings
  (simplification, efficiency, reuse, altitude, conventions, test-coverage,
  observability, deploy-safety — the list lives in `runners/tiers.sh`;
  `duplication` left it when the duplication lens shipped in 0.3.0)
  are reported informationally: Reviso gates that tier by design, and a
  "miss" there is the product working as intended. Unknown or missing
  categories resolve to the correctness tier — ambiguity fails loud, toward
  P0 scope.
- **Claimed wins** (candidate-only findings) count as wins only after a
  verification pass confirms they're real; until then they're suspects.
- **Cost is a first-class metric.** Runners record per-run cost; the judge
  reports `cost_ratio` (candidate ÷ baseline mean) next to parity. Target:
  **≤ 1.5×**. Matching the baseline's findings at 3× its price fails the
  everyday-use bar just as surely as missing findings does.
- **Parse failures are loud.** A baseline run whose output can't be parsed
  fails the run; the baseline is never silently reduced.
- **Degraded runs are loud.** Without subagent fan-out available the
  built-in degrades to a single-pass inline review and says so; a run that
  self-reports that mode fails. It is not the pipeline users get.
- **Findings come from the typed report when possible.** Headless, the
  built-in reports through the `ReportFindings` tool in the run's
  transcript; `report-findings.sh` harvests it (level, category, verdict
  intact) and verifies the reported level matches the pinned one. Prose
  extraction (`extract.sh`) is the fallback.

## The candidate leg names a tier

Reviso ships two review tiers, and they are two different products:
`/reviso:review` is the single-pass inner-loop review, `/reviso:audit` the
deep multi-agent pipeline. Every runner that invokes the candidate leg
requires **`REVISO_TIER`** (`review` or `audit`). There is no default:

```sh
REVISO_TIER=review sh runners/gold.sh crb-cal.com-8087 eval/runs/…
REVISO_TIER=audit  sh runners/gold.sh reviso-6         eval/runs/…
```

An absent or unrecognized value exits with an error naming the accepted
ones, exactly as `REVIEW_CMD` refuses an unpinned upstream level. The
reason is the defect a default caused: `candidate.sh` hardcoded
`/reviso:review`, every caller inherited it, no artifact recorded it, and
so the 48% figure from the 2026-08-07 sweep was read for a week as
"Reviso's recall" when it only ever described the single-pass tier.

- **Cost.** A review-tier case runs ~$2–3; an audit-tier case ran **$9.73**
  on `reviso-6` at v0.4.0 — roughly 3×. A 63-case audit sweep is therefore
  not a routine operation.
- **Which subset.** Full-corpus sweeps stay on the review tier; audit-tier
  sweeps run on a named subset (`REVISO_SWEEP_SUBSET=<name>`).
  `summary.json` records `subset.case_ids`, how many labeled cases the
  corpus holds, and `subset.covers_full_corpus` — so a partial sweep can
  never be read as a full one.
- **Metrics never pool tiers.** `summary.json` keys recall,
  precision-proxy, and clean-case counts under `by_tier`. Cases whose
  `meta.json` predates the tier field land in a visible `unrecorded`
  bucket rather than being absorbed into a real tier's numbers.

**Pre-existing artifacts carry no tier.** Every run recorded before this
landed — including `2026-08-07-gold-sweep-v0` and the 2026-08-03/04 parity
runs — has no `tier` field in its `meta.json`, so `judge.sh` refuses them
as non-comparable. That is by design, not a bug to route around: an
artifact that cannot say which pipeline produced it cannot be compared to
one that can. `JUDGE_ALLOW_TIER_MISMATCH=1` downgrades the refusal to a
`non_comparable` label when an archived run genuinely needs re-judging.
The one exception is the hand-produced
`runs/2026-08-13-reviso-6-audit-v040/`, whose `tier` was written by hand
and is labelled as asserted rather than machine-recorded.

## Gold mode

Parity answers "do we match upstream?"; gold mode answers "are we right?"
— the candidate alone against hand- or benchmark-labeled ground truth, no
upstream invocation anywhere. Per case it costs one candidate run at the
named tier plus matcher calls (on the review tier, ~10× cheaper than a
parity case's three baseline runs), which makes it the sweep you run on
every meaningful pipeline change; parity runs on the `active_parity`
subset at re-baseline events.

```text
REVISO_TIER=<review|audit> runners/gold.sh <case-id> <outdir>   one case
REVISO_TIER=<review|audit> runners/sweep.sh gold <outroot>      every
                                        labeled case + summary.json
```

- **Metrics**: `gold_recall_correctness` (matched correctness-tier gold
  issues ÷ total; cleanup-tier gold misses are informational),
  `precision_proxy_pct` (candidate findings matching any gold issue ÷ all
  candidate findings — a *proxy*: unmatched findings may be
  real-but-unlabeled and are listed as `promotion_candidates` for the
  labels file), and `clean_case_fp_count` (every finding on an
  expected-clean case is a false positive, no matcher call needed).
- Same matcher (`match.sh`) and tiering as parity mode — one calibration
  covers both.
- **Synthetic cases** (no upstream repo) materialize into a throwaway git
  repo as uncommitted additions on an empty base; parity tooling refuses
  them.
- Real cases check out via blobless clone cache (`eval/.cache/clones/`) +
  a detached worktree; expect multi-GB disk for the big upstreams
  (grafana, keycloak) on first use.

## Layout

- `corpus/` — entry schema, the public tier (64 entries: 50 CRB-imported
  real PRs, 13 synthetics, 1 legacy), gold labels under `corpus/labels/`,
  and the importers (see `corpus/README.md`). The private (Vyttle) tier
  lives outside the repo, referenced by `REVISO_EVAL_PRIVATE_CORPUS`.
- `runners/` — `baseline.sh`, `candidate.sh`, `judge.sh`, `gold.sh`,
  `sweep.sh`, plus shared `report-findings.sh` (transcript → findings
  JSON), `extract.sh` (review text → findings JSON), `match.sh` (the
  LLM matcher everything builds on), and `review-tier.sh` (resolves
  `REVISO_TIER` — the *product* under test; `tiers.sh` is the unrelated
  correctness/cleanup split of *findings*).
- `runs/` — run artifacts (raw output + parsed findings + per-run
  `meta.json` + judge reports). `runs/private/` is gitignored; only
  public-tier runs are committed.
- `calibration/` — hand-labeled matcher samples; the judge's numbers are
  not trusted until it agrees with the labels (task 5.5).
- `reference/` — the upstream capture: `extract-builtin.sh` +
  `builtin-skill-notes.md` (structure and drift fingerprints for the
  CLI-embedded skill), and the superseded 2026-08-03 marketplace snapshot.

## Requirements

`claude` CLI (with the target repo's subscription auth), `gh`, `jq`, `git`.
Baseline runs consume real `/code-review` invocations; candidate runs need
this plugin loadable via `--plugin-dir`.

Environment: `REVISO_TIER` (**required**, `review`|`audit` — no default),
`REVIEW_CMD` (default `/code-review medium`; it must name a level — the
runner refuses an unpinned command), `REVISO_SWEEP_SUBSET` (names a
deliberate partial sweep), `BASELINE_MODEL` (default `opus`), `JUDGE_MODEL`
(matcher model override), `REVISO_PLUGIN_DIR` (default: this repo),
`JUDGE_ALLOW_VERSION_MISMATCH` / `JUDGE_ALLOW_TIER_MISMATCH` (downgrade a
comparability refusal to a `non_comparable` label), and `*_CLAUDE_FLAGS`
pass-throughs per script — see script headers.

**Runs carry their identity.** Each baseline run records the CLI version,
the pinned level, and the resolved model IDs in `meta.json`; each candidate
run records the CLI version, the **review tier**, and the resolved model
IDs. The three runs behind a majority baseline must agree on all three, and
`judge.sh` refuses baseline/candidate comparisons across CLI versions
(`JUDGE_ALLOW_VERSION_MISMATCH=1`) or across review tiers, including a
candidate with no recorded tier (`JUDGE_ALLOW_TIER_MISMATCH=1`) — either
downgrades the refusal to a `non_comparable` label. The built-in review
ships inside the CLI, so **a CLI version roll is a re-baseline event** —
re-run the corpus, diff, re-tune — exactly as a tier roll or a model-tier
roll is:

**Models are tiers, not versions.** The plugin pins aliases (`opus`,
`sonnet`, `haiku`) and the baseline defaults to the `opus` alias — both
sides resolve to the current model of the tier, so comparisons stay
same-tier as generations roll. Run artifacts record the *resolved* model
IDs; only compare runs whose resolved pairs match, and treat any tier roll
as a re-baseline event.

**Clean context.** Every runner invokes `claude` with
`--setting-sources project,local`: user-level CLAUDE.md, memory, and
installed plugins are excluded, so the baseline is the *stock built-in*,
the candidate is *this plugin*, and results reproduce on any machine.
Project context (the target repo's own CLAUDE.md, lint configs) stays in —
reading it is part of the review under test. Runs made without this
isolation are smoke tests, not eval results.
