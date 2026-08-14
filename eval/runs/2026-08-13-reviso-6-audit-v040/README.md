# reviso-6 — audit tier, v0.4.0

The first recorded `/reviso:audit` run. Every eval number published before
this one describes `/reviso:review`: `eval/runners/candidate.sh` invokes
that command unconditionally, so the deep tier had never been measured.

This run is the diagnostic the archived `instrument-the-gate` change asked
for — re-run `/reviso:audit --explain` and classify *no candidates
generated* (the finders are the problem) versus *candidates generated and
zeroed* (the gate is). It was produced by hand, because the harness cannot
yet invoke this tier. See `meta.json` for what that means for the run's
identity fields.

## Result

| | |
| --- | --- |
| candidates before the gate | 13 |
| reported | 3, merged to 2 findings |
| cost | $9.73 |

Scores, in the order `--explain` printed them:

| disposition | scores |
| --- | --- |
| reported | 90, 88, 85 |
| dropped — rubric score | 68, 60, 52, 40, 40 |
| dropped — exclusion list | 20, 10, 0 |
| dropped — pre-existing | 5, 5 |

Per-lens candidate yield: prior-reviews 7, bugs 2, conventions 2, history
1, slop 1, comments 0, deterministic 0.

## Reading

**The answer is both, unevenly.** Candidates are generated, so the finders
are not silent — but the dedicated correctness lens produced two of them on
a 44-file, 1953-line diff, and more than half the yield came from a lens
whose evidence is contaminated (below).

**The gate destroys verified findings, and not at its threshold.** Two of
the eight findings in this case's recorded baseline
(`eval/runs/2026-08-03-reviso-6-v0/baseline.json`) were generated here and
then dropped: `match.sh` — "matches at most once" is prompt-enforced only —
at 68, and `extract.sh` — the loud-failure cross-check greps one phrasing —
at 40. Both are the enforcement-vs-claim class
`agents/reviso-finder-bugs.md` designates as deserving explicit attention.

**Nothing occupied 75-79.** The scorer does not quantize to the rubric's
0/25/50/75/100 anchors; it scores continuously, and the band immediately
below the threshold was empty. Moving the threshold to 75 would have
changed nothing on this run.

**A third baseline finding was dropped correctly.** The stale `/reviso
review` spelling at `docs/evals.md:7` was flagged by two lenses and scored
5 as pre-existing. PR #6 modified lines 3-5; line 7 is a context line, so
under `finding-schema.md`'s line-anchoring rule the drop is right — even
though this change is what made that line wrong.

## Caveats that limit what this run proves

- **The history and prior-reviews lenses read the future.** The worktree's
  object store contains commits made after `head_sha`, and both lenses
  reached them via `git log --all`, sourcing evidence from the commits that
  later fixed the issues they flagged. Together they produced 7 of the 13
  candidates. Their yield here is not recall.
- **Two of thirteen verifiers scored without their references**, having
  been denied read access to the rubric and exclusion list at the plugin
  root.
- **Single run, no repetition.** `docs/evals.md` records recall moving on
  10 cases between two identical runs; one run cannot separate a real
  effect from that floor. What it does establish is the score distribution
  and the per-lens yield, which are within-run facts.

## Comparison

`eval/runs/2026-08-03-reviso-6-v0/` is the closest prior artifact — the v0
multi-agent pipeline on this same case, reporting 1 finding at $9.74.
Its baseline protocol is superseded (see that directory's `SUPERSEDED.md`),
so its parity and cost ratios are not comparable with re-aimed runs; the
candidate leg's finding count and cost are.
