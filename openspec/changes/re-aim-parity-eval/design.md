# Design — re-aim-parity-eval

## Context

The eval harness (see `eval/README.md` and the `add-reviso-review` change,
D8) was built when `/review` meant the marketplace code-review recipe: a
single precision-first pipeline with a 0–100 confidence gate. Upstream
`/review` is now a skill embedded in the Claude Code binary, scaled by a
level argument / session effort:

| Level | Shape | Stance | Cap |
| --- | --- | --- | --- |
| low | inline 2-turn hunk scan | — | 4 |
| medium | 8 finder angles → 1-vote CONFIRMED/PLAUSIBLE/REFUTED verify | precision | 8 |
| high | same 8 angles | recall | 10 |
| xhigh/max | 10 angles + gap-sweep pass | recall ("a missed bug ships") | 15 |

Two of our assumptions broke silently. The drift watch hashed the
marketplace file, which no longer feeds `/review`. And `baseline.sh`'s
`--allowedTools` omits Task, which triggers the skill's documented
"single-pass inline" fallback — so every recorded baseline measured a
degraded mode. Empirically (same PR, 2026-08-06): Reviso <3 min / 0 shipped
findings + notes; built-in medium ~9 min / 6 findings; built-in xhigh ~20
min / 17 subagents / 13 findings. Medium and xhigh surfaced materially
different finding sets, confirming majority-of-3 as the only sane baseline
definition.

## Goals / Non-Goals

**Goals:**

- Baseline = built-in `/code-review` at **medium**, real fan-out, pinned
  level, majority-of-3.
- Miss-as-P0 scoped to correctness-category baseline findings.
- Run artifacts self-describe: CLI version, review level, resolved model,
  and whether fan-out actually ran.
- Repeatable upstream capture that doesn't depend on the dead marketplace
  file.
- PR-15 as the first labeled calibration case for the re-aimed judge.

**Non-Goals:**

- No changes to the Reviso pipeline, finder set, or rubric (angle imports
  like removed-behavior auditor / cross-file tracer are a separate change).
- No parity claim against high/xhigh/max (recall-stance levels); those are
  `/reviso:audit`'s eventual concern.
- No re-run of the full corpus inside this change; it re-tools the harness
  and re-baselines one calibration entry.

## Decisions

### D1 — Baseline pins the level in the command, and a fallback-mode run fails loudly

`REVIEW_CMD` default changes from `/review` to `/code-review medium`; the
level is never left to ambient session effort (which defaults to xhigh and
would silently swap the target's philosophy). `baseline.sh` adds Task to
`--allowedTools` so the 8-angle fan-out can run. If a baseline run's output
self-reports the single-pass fallback (the skill states this explicitly when
it can't fan out), the run **fails** — same policy as parse failures: the
baseline is never silently degraded. Alternative considered: keeping
`/review` and trusting defaults — rejected, that's exactly the ambiguity
that burned us.

### D2 — Prefer the skill's typed report over prose parsing

**Revised after the smoke run.** Headless, `ReportFindings` turns out to be
available: the run delegates to an agent that calls it with
`{level, findings}` (each finding `file`/`line`/`summary`/
`failure_scenario`/`category`/`verdict`), while the `-p` result text is a
prose rendering. The deterministic source is therefore the transcript's
ReportFindings call — `report-findings.sh` harvests it (locating the
session under `~/.claude/projects/` via the result's `session_id`) and the
harvested `level` doubles as the level-honored check (D1). Prose extraction
(`extract.sh`, which also keeps a JSON-block fast path) is the fallback,
since transcript layout is a CLI internal that may move.

### D3 — Category-scoped parity, conservative when category is missing

The P0-on-miss rule applies to baseline findings whose category is
`correctness` (or a more specific correctness-shaped slug). Cleanup-tier
categories (`simplification`, `efficiency`, `reuse`, `altitude`,
`conventions`, `test-coverage`) are bucketed and reported informationally —
Reviso deliberately gates that tier, and a "miss" there is the product
working as designed. When a baseline finding has no category, the judge
classifies it, and ambiguity resolves to correctness (fail-loud bias).

### D4 — CLI version is part of the baseline identity

Each baseline run records `claude --version`, the pinned level, and the
resolved model into a `meta.json` beside the existing artifacts. Runs are
comparable only when (CLI version, level, resolved model pair) all match.
A CLI version roll is a re-baseline event — the behavioral drift detector.
This extends the existing "models are tiers" rule in `eval/README.md`,
which already treats tier rolls this way.

### D5 — Upstream capture is behavioral-first; verbatim extraction stays out of the repo

The primary drift signal becomes the eval itself: on CLI version roll,
re-run the corpus baselines and diff against prior runs (the mechanism
`eval/README.md` already prescribes). A raw-text extraction of the embedded
skill (via the documented strings/offset method) is kept **locally only** —
referenced like the private corpus, never committed. Rationale: the old
snapshot was Apache-2.0 upstream text; the built-in skill text ships inside
a proprietary binary with no license to republish. The repo gets: the
extraction method (script + notes), the SHA-256 of the extracted text per
CLI version, and a factual structural summary (levels, angle names, caps,
stances — as in Context above). `eval/reference/README.md` marks the
2026-08-03 marketplace snapshot superseded, retained as history.

### D6 — PR-15 enters the private corpus with three-run labels

The PR-15 case (Vyttle-internal code) becomes a private-tier corpus entry
with a labels file recording, per finding across the three same-change runs
(Reviso, medium, xhigh): source run, category, and the hand verdict
(real / not-real / out-of-lane). This seeds judge calibration under
`eval/calibration/` conventions. Nothing from it — diff text, finding text,
repo names — lands in this repo.

### D7 — Cost target unchanged, denominator re-measured

`cost_ratio ≤ 1.5×` stays, now against the true medium baseline mean
(fan-out included, roughly ~9 min interactive class). Revisit only after
the first re-baselined corpus run; if medium's real cost makes 1.5× trivial
or impossible, that's a finding for docs/evals.md, not a silent retune.

## Risks / Trade-offs

- [Headless `-p` may not support Task fan-out or the level argument as
  expected] → smoke-run first (tasks order this explicitly); if fan-out is
  impossible headless, fall back to driving an interactive session or
  re-scope D1 — but never accept a silent-fallback baseline.
- [Upstream can change the built-in at any CLI release, invalidating
  baselines mid-corpus] → meta.json comparability rule (D4) makes staleness
  detectable instead of silent; pin one CLI version per corpus sweep.
- [Category slugs are upstream's vocabulary and may drift] → D3's
  conservative default (unclassified → correctness) means drift inflates
  P0 scope, which fails loud rather than hiding misses.
- [Legal exposure from committing extracted proprietary prompt text] →
  D5 keeps verbatim text local-only; repo carries method + hash + facts.
- [Majority-of-3 may be weak against medium's run-to-run variance] → the
  PR-15 labels (D6) let us measure variance empirically before trusting
  parity numbers; widen to 5 runs only if the data demands it.

## Migration Plan

1. Land runner/judge/doc changes (additive; old scripts' behavior is
   reproducible via env overrides).
2. Drop a `SUPERSEDED` note into `eval/runs/2026-08-03-*` and
   `2026-08-04-*` directories identifying them as fallback-mode baselines.
3. Smoke-run one baseline (PR-15) on the current CLI; verify fan-out ran
   and meta.json is complete; then it becomes the calibration entry.

Rollback: revert the scripts; old run artifacts were never rewritten.

## Smoke-run findings (2026-08-06, CLI 2.1.223, PR-15)

Settled by the task-1.1 smoke run (`/code-review medium 15` headless,
throwaway clone, Task allowed; $1.65, ~5 min):

- **Level argument honored**: `/code-review medium 15` parsed both level
  and PR target; the typed report came back `level: "medium"`.
- **ReportFindings available headless** — see revised D2. Findings (4)
  carried categories (`correctness`×2, `robustness`, `docs-inconsistency`)
  and verdicts (3 CONFIRMED, 1 PLAUSIBLE).
- **Fan-out did not run at medium**: one delegated agent (26 Bash, 9 Grep,
  1 Read, zero Task calls) worked the angles in-context, with no
  degraded-mode disclaimer. Fan-out at medium is evidently discretionary,
  not guaranteed — so the harness enforces what is enforceable: the
  reported level matches the pinned one, and the degraded-mode disclaimer
  is absent (D1's rejection stands for runs that do disclaim).
- **`--setting-sources project,local` is fine**: the skill ships in the
  binary and ran normally under clean context.
- Run-to-run variance confirmed again: the smoke's 4 findings overlap the
  interactive medium run's 6 only partially (the `alert_enabled` trust
  finding appears in both; the collapse-id pair appears only
  interactively). Majority-of-3 remains load-bearing.

## Open Questions

- Whether the north-star rewording ("everything `/review` medium catches,
  correctness tier") belongs in this change's doc edits or a separate
  README/PRD pass — leaning separate to keep one concern per PR.
- Whether medium's discretionary fan-out changes with diff size (the PR-15
  diff is small); if larger corpus entries reliably fan out, the
  no-disclaimer guard gains teeth. Watch as the corpus grows.
