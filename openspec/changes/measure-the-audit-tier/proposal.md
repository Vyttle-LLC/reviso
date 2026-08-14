# Measure the audit tier

## Why

**The deep tier has never been evaluated.** `eval/runners/candidate.sh:36`
invokes `/reviso:review` unconditionally, and both eval specs name that
command inside their requirements (`gold-eval` line 12, `parity-eval`
line 14). Every number this project has published — including the 48%
correctness recall in `eval/runs/2026-08-07-gold-sweep-v0/summary.json` —
describes the single-pass inner-loop review. `/reviso:audit` has no eval
coverage of any kind.

That gap is why a 48% recall figure and field reports of 0–1 findings could
coexist for a week without anyone noticing a contradiction: they are
measurements of two different commands. It is also why `7f1234d` changed
the audit pipeline's model tiers reasoned entirely from a `/reviso:review`
run, and shipped admitting it was "not verified by a fresh sweep."

**The diagnostic run `instrument-the-gate` called for has now happened, by
hand.** Its follow-up section asks for `/reviso:audit --explain` re-run and
classified as *no candidates generated* (finders at fault) versus
*candidates generated and zeroed* (gate at fault). On corpus case
`reviso-6`, at v0.4.0:

| | |
| --- | --- |
| candidates before the gate | 13 |
| reported | 3 (merged into 2 findings) |
| dropped by rubric score | 68, 60, 52, 40, 40 |
| dropped by exclusion list | 20, 10, 0 |
| dropped as pre-existing | 5, 5 |
| cost | $9.73 — matching the recorded v0 run to the cent |

The answer is *both, unevenly*: candidates are generated, but the
correctness lens produced two of them on a 44-file diff, and two
confirmed-real baseline findings were generated and then scored 68 and 40.
That run is the audit tier's first baseline and belongs in the corpus. The
harness cannot currently produce it.

**Two lenses are measured against a future they can see.** On `reviso-6`
the `history` and `prior-reviews` finders reached commits *after* the
case's head via `git log --all` and sourced evidence from the very commits
that later fixed the issues they flagged. Those two lenses supplied 7 of
the 13 candidates. Every in-repo corpus case has this exposure, so their
measured recall is unusable — the run's own report flagged it.

Measurement comes first. Retuning the pipeline before the harness can see
it repeats `7f1234d`: a change shipped on argument, moving nothing.

## What Changes

- **The candidate leg is parameterized by review tier.** `/reviso:audit`
  becomes a first-class candidate alongside `/reviso:review`, in both gold
  and parity mode. The tier is explicit at every invocation; no default
  silently decides which product is under test.
- **Runs record the tier that produced them.** A recorded run without one
  is not comparable, and the judge refuses cross-tier comparisons the same
  way it already refuses cross-CLI-version ones.
- **Finder history access is bounded by the change under review.** No lens
  may source evidence from a ref reachable only through commits after the
  case's head. This closes an eval contamination; on a user's real branch
  the behaviour is unchanged, because there is no future to reach.
- **The `reviso-6` audit run is committed as the audit tier's first
  baseline**, alongside the existing single-pass runs.
- **Non-goal: no lens prompt, gate threshold, rubric, or exclusion-list
  change.** This change only makes the deep tier visible. What the
  measurements then justify is the business of the follow-up changes named
  below, and doing any of it here would destroy the baseline being
  established.

## Capabilities

### New Capabilities

None. Both eval capabilities already exist; this widens what they cover.

### Modified Capabilities

- `gold-eval`: the candidate leg is parameterized by review tier instead of
  fixed to `/reviso:review`; recorded runs carry the tier, and metrics are
  reported per tier rather than pooled.
- `parity-eval`: same parameterization, plus a comparability requirement —
  baseline and candidate must agree on tier, as they already must on CLI
  version and resolved model IDs.
- `review-pipeline`: finders that read git history SHALL be bounded by the
  change under review; evidence reachable only from commits after the
  change's head is inadmissible.

## Impact

- `eval/runners/candidate.sh` (tier parameter), `gold.sh`, `sweep.sh`,
  `judge.sh` (comparability refusal), `meta.json` shape.
- `agents/reviso-finder-history.md`, `agents/reviso-finder-prior-reviews.md`
  — scope their `git log` access.
- New run artifact under `eval/runs/` for the `reviso-6` audit baseline;
  `docs/evals.md` and `eval/README.md` gain the audit tier.
- **Report-only is unchanged.** No new write permissions, no additions to
  any command's `allowed-tools`.
- Repo rules: sign off every commit (`git commit -s`; DCO is required), one
  concern per PR, `markdownlint-cli2` and `lychee` must pass.
- Sequencing: this change unblocks `move-judgment-to-the-orchestrator` and
  `recalibrate-the-confidence-rubric`, neither of which can demonstrate an
  effect until the audit tier is measurable.
- Housekeeping surfaced, not done here: `instrument-the-gate` is 22/22
  complete and still unarchived, and `7c9c073` ("Sharpen the precision
  bar") is held on `feature/termic-review-prompt` pending exactly the
  diagnosis quoted above.
