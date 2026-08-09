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
  ├─ runners/candidate.sh  checkout head_sha, /reviso:review --base base_sha
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

## Gold mode

Parity answers "do we match upstream?"; gold mode answers "are we right?"
— the candidate alone against hand- or benchmark-labeled ground truth, no
upstream invocation anywhere. Per case it costs one `/reviso:review` run
plus matcher calls (~10× cheaper than a parity case's three baseline
runs), which makes it the sweep you run on every meaningful pipeline
change; parity runs on the `active_parity` subset at re-baseline events.

```text
runners/gold.sh <case-id> <outdir>     one case
runners/sweep.sh gold <outroot>        every labeled case + summary.json
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
  JSON), `extract.sh` (review text → findings JSON) and `match.sh` (the
  LLM matcher everything builds on).
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

Environment: `REVIEW_CMD` (default `/code-review medium`; it must name a
level — the runner refuses an unpinned command), `BASELINE_MODEL` (default
`opus`), `JUDGE_MODEL` (matcher model override), `REVISO_PLUGIN_DIR`
(default: this repo), and `*_CLAUDE_FLAGS` pass-throughs per script — see
script headers.

**Runs carry their identity.** Each baseline run records the CLI version,
the pinned level, and the resolved model IDs in `meta.json`; the three runs
behind a majority baseline must agree on all three, and `judge.sh` refuses
baseline/candidate comparisons across CLI versions
(`JUDGE_ALLOW_VERSION_MISMATCH=1` downgrades the refusal to a
`non_comparable` label). The built-in review ships inside the CLI, so **a
CLI version roll is a re-baseline event** — re-run the corpus, diff, re-tune
— exactly as a model-tier roll is:

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
