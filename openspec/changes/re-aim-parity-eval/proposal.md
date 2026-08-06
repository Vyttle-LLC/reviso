# Re-aim the parity eval at built-in /code-review medium

## Why

The `/review` Reviso benchmarks against is not the recipe we forked. Upstream
`/review` now resolves to a skill built into the Claude Code binary (present
since at least v2.1.219), effort-scaled from a 4-finding inline scan (low) to a
recall-biased ~20-minute, 17-subagent audit (xhigh, the session default) —
while the marketplace plugin our reference snapshot and drift watch track has
been dead since early 2026. Worse, our recorded baselines never measured the
real thing: `baseline.sh` blocks the Task tool, which triggers the skill's
documented single-pass fallback. The parity north star ("catch everything
/review catches") has silently lost its referent, and the recall-biased
default is philosophically opposed to Reviso's precision-over-recall
invariant. The coherent target is the built-in's **medium** level — the one
level that shares Reviso's precision stance ("every finding you surface should
be one a maintainer would act on") and cost class.

## What Changes

- **Parity target**: baseline becomes built-in `/code-review` pinned to
  **medium** effort, majority-of-3 as today. Parity (P0-on-miss) applies to
  **correctness-category baseline findings only**; cleanup/conventions-tier
  baseline findings are reported informationally, never as P0 regressions.
- **Baseline runner**: allow subagent fan-out (Task) so the real pipeline
  runs instead of the inline fallback; pin the review level explicitly;
  record the Claude Code CLI version in run artifacts. A CLI version roll
  becomes a re-baseline event, extending the existing model-tier-roll rule.
- **Reference snapshot**: replace the marketplace-file snapshot/hash watch
  with a dated extraction of the built-in skill text from the CLI binary,
  plus the documented extraction method so it can be repeated per release.
  The 2026-08-03 marketplace snapshot stays as a historical artifact, marked
  superseded.
- **Prior runs**: `eval/runs/2026-08-03-*` and `2026-08-04-*` artifacts are
  annotated as fallback-mode baselines — kept, but non-comparable with
  re-aimed runs.
- **Calibration corpus**: add the PR-15 case (private tier) with its three
  existing same-change runs (Reviso, built-in medium, built-in xhigh) and
  hand labels as the first calibration entry for the re-aimed judge.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `parity-eval`: baseline redefined (built-in medium with fan-out enabled,
  not stock `/review` at ambient defaults); miss-as-P0 scoped to correctness
  findings; run artifacts must record CLI version and review level; upstream
  drift detection re-pointed from the marketplace file to the CLI-embedded
  skill text.

## Impact

- `eval/runners/baseline.sh` — invocation, allowed tools, level pin, version
  capture.
- `eval/runners/judge.sh` / `match.sh` — category-aware bucketing.
- `eval/reference/` — new dated snapshot + extraction notes; supersession
  note in `README.md`.
- `eval/README.md`, `docs/evals.md` — target, metrics, and re-baseline rules.
- `eval/corpus/` (private tier via `REVISO_EVAL_PRIVATE_CORPUS`) — PR-15
  entry and labels; nothing private lands in-repo.
- North-star language wherever it says "everything `/review` catches"
  (README, PRD references) — now names the level.
- No plugin-pipeline code changes; `/reviso:review` and `/reviso:audit`
  behavior is untouched by this change.
