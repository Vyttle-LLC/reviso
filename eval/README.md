# Parity eval harness

The acceptance test for Reviso's north star: on the same changes,
`/reviso:review` catches everything `/review` catches. A baseline finding we
miss is a P0 regression. See the PRD (§5, §13) and the change's `design.md`
(D8).

## Flow

```text
corpus entry {repo, pr, base_sha, head_sha}
  │
  ├─ runners/baseline.sh   3 headless /review runs on the real PR
  │                        → majority baseline (findings in ≥2 of 3 runs)
  ├─ runners/candidate.sh  checkout head_sha, /reviso:review --base base_sha
  │                        → candidate findings from the report
  └─ runners/judge.sh      conservative root-cause matching →
                           matched | missed | claimed_wins + metrics
```

- **Misses** are listed individually — each is a P0 regression, not a
  percentage.
- **Claimed wins** (candidate-only findings) count as wins only after a
  verification pass confirms they're real; until then they're suspects.
- **Cost is a first-class metric.** Runners record per-run cost; the judge
  reports `cost_ratio` (candidate ÷ baseline mean) next to parity. Target:
  **≤ 1.5×**. Matching `/review`'s findings at 3× its price fails the
  everyday-use bar just as surely as missing findings does.
- **Parse failures are loud.** A baseline run whose output can't be parsed
  fails the run; the baseline is never silently reduced.

## Layout

- `corpus/` — entry schema and the public tier (see `corpus/README.md`).
  The private (Vyttle) tier lives outside the repo, referenced by
  `REVISO_EVAL_PRIVATE_CORPUS`.
- `runners/` — `baseline.sh`, `candidate.sh`, `judge.sh`, plus shared
  `extract.sh` (review text → findings JSON) and `match.sh` (the LLM
  matcher both majority and judging build on).
- `runs/` — run artifacts (raw output + parsed findings + judge reports).
  `runs/private/` is gitignored; only public-tier runs are committed.
- `calibration/` — hand-labeled matcher samples; the judge's numbers are
  not trusted until it agrees with the labels (task 5.5).
- `reference/` — the dated snapshot of the upstream recipe we forked;
  re-benchmarking against a newer `/review` is just another eval run
  diffed against runs recorded before it.

## Requirements

`claude` CLI (with the target repo's subscription auth), `gh`, `jq`, `git`.
Baseline runs consume real `/review` invocations; candidate runs need this
plugin loadable via `--plugin-dir`.

Environment: `REVIEW_CMD` (default `/review`), `JUDGE_MODEL` (matcher model
override), `REVISO_PLUGIN_DIR` (default: this repo), and
`*_CLAUDE_FLAGS` pass-throughs per script — see script headers.

**Clean context.** Every runner invokes `claude` with
`--setting-sources project,local`: user-level CLAUDE.md, memory, and
installed plugins are excluded, so the baseline is *stock* `/review`, the
candidate is *this plugin*, and results reproduce on any machine. Project
context (the target repo's own CLAUDE.md, lint configs) stays in — reading
it is part of the review under test. Runs made without this isolation are
smoke tests, not eval results.
