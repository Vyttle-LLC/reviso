# reviso-6 — audit tier, v0.4.0, runner-produced

The first `/reviso:audit` run produced by `eval/runners/candidate.sh` rather
than by hand. It is the counterpart to
`../2026-08-13-reviso-6-audit-v040/`, which recorded the same case at the
same plugin version before the runner could invoke this tier, and it
supersedes that run as the audit tier's comparison anchor. Both stay in the
tree.

Same case, same SHAs, same CLI (2.1.232), same clean-context isolation. Two
things differ: the runner recorded the identity fields instead of a human
asserting them, and the history bound
(`skills/reviso/references/history-bound.md`) had landed.

```text
command   /reviso:audit --base cb3f63a4… --explain
cost      $6.42
wall      ~8 min   (see "The duration field lies" below)
```

## Result

| | |
| --- | --- |
| candidates before the gate | 5 |
| reported | 1 |

| disposition | scores |
| --- | --- |
| reported | 90 |
| dropped — rubric score | 55, 50 |
| dropped — exclusion list | 0 |
| dropped — pre-existing | 0 |

Per-lens candidate yield: conventions 2, bugs 2, comments 1, history 0,
prior-reviews 0, slop 0, deterministic 0.

## Divergence from the hand-produced run

| | 2026-08-13 (hand) | 2026-08-14 (runner) |
| --- | --- | --- |
| candidates | 13 | 5 |
| reported | 3, merged to 2 | 1 |
| cost | $9.73 | $6.42 |
| prior-reviews yield | 7 | 0 |
| history yield | 1 | 0 |
| bugs / conventions | 2 / 2 | 2 / 2 |
| slop / comments | 1 / 0 | 0 / 1 |

The gap has two separate causes, and collapsing them into one number would
hide both.

**The history bound accounts for the two history lenses.** The hand run's
`history` and `prior-reviews` lenses reached commits after the case's head
and sourced evidence from the commits that later fixed what they flagged;
together they supplied 7 of the 13 candidates. Under the bound both return
zero, and this run's own report says why in each case: `prior-reviews`
found the GitHub remote reachable and PRs #1–#5 admissible but carrying no
review comments, and correctly excluded PR #6 as a non-ancestor of
`e76eda9`; `history` independently reached the same bare-`Bash` observation
as the `bugs` lens and dropped it, because its only evidence was a
non-ancestor commit.

That is the bound working rather than the bound silencing: the finding
itself still shipped, at 90, because the `bugs` lens reached it from
in-branch files alone. The contaminated *evidence* was excluded; the
*conclusion* it had been propping up survived on its own merits. Nothing
in the reported findings was lost to the bound.

**Run-to-run variance accounts for the rest**, and is not attributable to
this change. The `slop` lens yielded 1 candidate on 2026-08-13 and 0 here,
which is why the hand run's second reported finding — the P2 at
`skills/reviso/detectors/run.sh:13`, untracked-file findings anchoring to
the wrong path — has no counterpart in this run. `comments` moved the other
way, 0 to 1. The shared `eval/runners/match.sh:30` candidate scored 68 in
the hand run and 55 here. `docs/evals.md` already records recall moving on
10 cases between two identical runs; one run against one run cannot
separate a real effect from that floor, and this table should not be read
as though it can.

**The P0 is the same finding in both runs.** Bare `Bash` on the finder and
verifier agents, all three named, scored 90 here and 90 there. It is
anchored to `agents/reviso-finder-history.md:4` in this run and
`agents/reviso-verifier.md:4` in the hand run — same root cause, different
first-cited file.

## What this run also establishes

**The verifiers had their references.** Two of the thirteen verifiers in
the hand run were denied read access to `confidence-rubric.md` and
`false-positives.md` at the plugin root and scored without them. The
runner's headless grant for the audit tier now includes `Read` for exactly
that reason, and this run's report opens "All lenses and verifiers
resolved."

**Report-only held.** `candidate.sh` snapshots the worktree before the run
and compares after; a mismatch exits non-zero and names it a violation.
This run exited 0. That is the invariant checked on the deep tier for the
first time — the pipeline that fans out to eight agents, none of which
touched the tree.

**The duration field lies on this tier.** `candidate-cost.json` records
`duration_ms: 22813` and `num_turns: 1` for a run that took roughly eight
minutes of wall clock. Those fields describe the orchestrator's own turn;
they cannot see the work it fanned out to subagents. `duration_api_ms` —
2,047,713, about 34 minutes of aggregated API time — is the field that
counts them, and the runner now records it alongside. On the review tier
the two agree (384,749 vs 384,384), because there is no fan-out to miss.

## What it does not establish

No recall figure. `reviso-6` carries no labels file, so there is no gold
judging here and no `gold-judge.json` — this is the candidate leg alone,
which is also all the hand-produced run contains, and is what makes the two
comparable. Labeling this case is not part of `measure-the-audit-tier`.
