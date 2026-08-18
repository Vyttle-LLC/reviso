# reviso-6 — audit tier, v0.5.0, first run with judgment in the orchestrator

The audit-tier leg of `move-judgment-to-the-orchestrator`'s verification
(tasks 6.1, 6.2, 6.5): the first run of the redistributed pipeline —
finders unfiltered, Stage 4 demoted to `reviso-evidence` fact-gathering,
the exclusion list and rubric applied once by the Opus orchestrator with
every candidate in hand. Comparison anchor is
`../2026-08-14-reviso-6-audit-v040/` (same case, same SHAs, same runner).

```text
command   /reviso:audit --base cb3f63a4… --explain
cost      $13.80
api time  62m 53s aggregated   (duration_ms lies for fan-out, as before)
```

## Result

| | v0.4.0 | this run (v0.5.0) |
| --- | --- | --- |
| candidates before the gate | 5 | 21 |
| reported | 1 | 5 (from 9 gate-clearing rows, merged) |
| cost | $6.42 | $13.80 |

Per-lens candidate yield: bugs 8, conventions 5, comments 4, history 2,
slop 2, prior-reviews 0, deterministic 0. All seven lenses returned.

## The two known regressions (task 6.2)

- **`match.sh` — recovered.** "Matches at most once is prompt-enforced
  only" scored 68 under the v0.4.0 distributed gate and died; the
  orchestrator scored it 88 and shipped it, with the concrete
  parity-above-100% scenario.
- **`extract.sh` — not recovered.** Scored 60 (`rubric-score`) and
  dropped. Per the task's own contingency, the gate position was not the
  whole cause here; the band-fit question passes to
  `recalibrate-the-confidence-rubric`.

The dropped finding then demonstrated itself against this very run: the
orchestrator's final headless message was a wrap-up note rather than the
report, `.result` captured only that note, and `extract.sh`'s
cross-check — which greps one phrasing — let an empty `candidate.json`
through silently. `candidate-report.md` in this directory is the run's
verbatim report recovered from the session transcript (the original
`.result` text survives inside `candidate-raw.json`), and
`candidate.json` was regenerated from it with the unmodified
`extract.sh`.

## What the redistributed pipeline did that the old one could not

- The orchestrator discarded evidence from two evidence agents that had
  cited commits unreachable from HEAD (eval-fixture leakage) and
  re-verified the detect.awk claims against the file itself — a
  cross-agent quality judgment no per-candidate verifier could make.
- The gate record shows genuinely comparative behavior: 21 candidates
  scored in one sitting, drop reasons from the closed set, and a
  documented closest-call (`run.sh:22` at 70).
- Report-only held: `candidate.sh`'s pre/post tree comparison passed
  (task 6.5), and no prompt gained a write-capable tool.

## Cost

2.15× the v0.4.0 run, against a 4× candidate yield and 5× reported
findings — the design's cost tripwire ("rises materially without a recall
gain") does not fire, but the number belongs in the next sweep's
comparison.
