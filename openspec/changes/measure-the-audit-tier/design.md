# Design — Measure the audit tier

## Context

The harness was built around one command. `eval/runners/candidate.sh:35-39`
hardcodes `/reviso:review` in its `claude -p` invocation; `gold.sh:86` and
`sweep.sh:107` call that script positionally, so no caller can vary the
tier. The specs match the code: `gold-eval` and `parity-eval` name
`/reviso:review` inside requirement text, so this is a spec-level gap, not
a missing flag.

Two consequences compound. Published numbers silently describe the
single-pass tier — `2026-08-07-gold-sweep-v0` reports 48% correctness
recall over 63 cases and is universally cited as "Reviso's recall", though
`/reviso:audit` never ran in it. And `7f1234d` retuned audit's model tiers
citing a three-way `/reviso:review` comparison, shipping with an explicit
"not verified by a fresh sweep."

A manual `audit --explain` on `reviso-6` (v0.4.0, $9.73) produced 13
candidates → 3 reported, with the correctness lens contributing 2 and two
confirmed-real baseline findings scored 68 and 40. That run is the artifact
this change must make reproducible, because every downstream retune will be
judged against it.

The same run exposed a second problem: `history` and `prior-reviews`
reached commits after the case's head through `git log --all` and cited the
commits that later fixed the flagged issues. Those lenses produced 7 of 13
candidates. Because the corpus draws cases from this repository, the
contamination is structural rather than incidental.

## Goals / Non-Goals

**Goals:**

- Make `/reviso:audit` a measurable candidate in both gold and parity mode.
- Make every recorded run state which tier produced it, and make the judge
  refuse comparisons that cross tiers.
- Bound finder history access to the change under review, so in-repo
  corpus cases stop measuring lenses against their own future.
- Commit the `reviso-6` audit run as the tier's first baseline.

**Non-Goals:**

- No lens prompt changes, no gate threshold change, no rubric or
  exclusion-list edits. Those are `move-judgment-to-the-orchestrator` and
  `recalibrate-the-confidence-rubric`, and doing any of them here destroys
  the baseline this change exists to establish.
- No new corpus cases. Importing the two field branches is worthwhile and
  belongs elsewhere.
- No attempt to make the two tiers comparable to each other. They are
  different products; the spec forbids pooling them.

## Decisions

**Tier is an explicit parameter, not a default.** `candidate.sh` takes the
tier as a required input and fails when it is absent, rather than
defaulting to `/reviso:review`. A default is what produced the current
situation: every caller inherited one tier and no artifact recorded it, so
the ambiguity was invisible. This mirrors the harness's existing treatment
of the upstream level (`REVIEW_CMD` "must name a level — the runner refuses
an unpinned command"). Alternative considered: default to `review` for
backward compatibility. Rejected — silent defaults are precisely the defect.

**Tier travels in `meta.json` beside CLI version and model IDs.** That file
already carries the identity fields the judge enforces, and the judge
already knows how to refuse on identity mismatch. Adding a fourth field
reuses a working mechanism instead of inventing a parallel one.
Alternative: infer the tier from the report header. Rejected — inference
from output is what the coverage-line bug taught us not to trust.

**Sweep summaries report per tier rather than pooling.** `sweep.sh`'s
aggregation currently emits one recall figure. With two tiers in the run
tree, one figure would be meaningless in a new way. Per-tier keys keep old
artifacts readable and make a missing tier visible as its own bucket.

**History bounding is specified as a finder obligation, not a sandbox.**
The finders' `Bash` grants are already scoped to read-only git; narrowing
them further (e.g. forbidding `--all`) would not stop a finder reading a
sibling ref by name, and would complicate legitimate blame walks. Stating
the admissibility rule in the agent prompt matches how every other finder
constraint in this repo is expressed, and the eval verifies it
behaviourally. Alternative considered: materialize each corpus case in a
truncated clone containing no post-head objects. Genuinely stronger, and
worth doing later — but it is a corpus-tooling change of its own size, and
it cannot fix a user's real repository, where the same rule still applies
to sibling branches.

**The `reviso-6` audit baseline is committed as a normal run artifact.**
It was produced by hand at v0.4.0 before this change existed, so its
`meta.json` is written to record exactly that provenance — including that
its tier field was added retroactively — rather than being presented as a
product of the new runner.

## Risks / Trade-offs

- **Audit runs cost roughly 3× a review run** ($9.73 versus ~$2.9 on
  `reviso-6`), so a 63-case audit sweep is not a routine operation →
  audit-tier sweeps run on a named subset, and full-corpus sweeps stay on
  the review tier. Record the subset in the run tree so a partial sweep is
  never mistaken for a full one.
- **A required tier parameter breaks every existing caller** → all callers
  are in-repo (`gold.sh`, `sweep.sh`, docs); the break is compile-time
  loud, which is the intent.
- **Bounding history access could suppress legitimate findings** on real
  branches that genuinely reference sibling work → the bound is defined
  relative to the change's head, and the run's own report already
  distinguishes "found nothing" from "could not look"; a suppressed
  candidate surfaces under `--explain`.
- **The retroactive `reviso-6` baseline is not reproducible by the new
  runner byte-for-byte** → it is labelled as hand-produced; the first
  runner-produced audit run supersedes it as the comparison anchor, and
  both stay in the tree.

## Migration Plan

1. Land the tier parameter and metadata with `review` passed explicitly at
   every existing call site — no behaviour change, all current artifacts
   stay valid.
2. Add the judge's tier refusal. Existing artifacts lack the field, so they
   become non-comparable by design; that is correct, and `docs/evals.md`
   says so.
3. Land the history bound and re-run one in-repo gold case on the review
   tier to confirm the lens still returns candidates.
4. Commit the `reviso-6` audit baseline, then produce the first
   runner-generated audit run against the same case and compare.

Rollback: the tier parameter and metadata are additive; reverting restores
the previous fixed-tier behaviour without invalidating artifacts written in
between, since an unknown field is ignored by older tooling.

## Open Questions

- Which corpus subset becomes the standing audit-tier sweep? `reviso-6`
  plus the synthetics is cheap but too easy; the CRB cases are the real
  test and the expensive one.
- Should `instrument-the-gate` be archived as part of this change or on its
  own? It is 22/22 complete and its named follow-up is the diagnostic this
  proposal reports.
- `builtin-skill-notes.md` fingerprints CLI 2.1.219–223; this machine runs
  2.1.232. A re-baseline is due independently, and doing it before the
  first audit-tier parity run would avoid immediately invalidating it.
