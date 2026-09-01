# Style confidence rubric (0–100)

Revision `style-1`. Scored on by `/reviso:style` only. `/reviso:review`
and `/reviso:audit` score on `confidence-rubric.md`, whose bands measure
impact — will this be hit in practice, does it matter to functionality.
A style finding never impacts functionality, so on that scale every
honest style score is a 50 and nothing clears the gate. This rubric
measures one thing instead: **how well the evidence supports the
finding.** Nothing else.

## What the score measures

Four things, each checkable against the code:

1. **Protocol** — the candidate produced what its lens demands: two
   same-language `file:line` examples of the established pattern (drift,
   naming, error handling, type slop, over-engineering's absence
   citation), the comparable units and their sizes (length), the tell
   quoted verbatim (AI tells), the assertion quoted (test slop), the
   search performed and its result (dead weight, surface area), every
   lockstep write site quoted (derived state), the contradicted sentence
   quoted (stale docs), the existing utility cited (reuse).
2. **Holds** — re-examined against the real code, the cited examples show
   the pattern claimed, the quoted text is there, the search was
   complete, the failure scenario is what would actually happen.
3. **Baseline unambiguous** — the repo demonstrably does it the cited way
   and not also the change's way; a written convention or lint rule
   settles it outright.
4. **Fix concrete** — `suggested_fix` is the rewrite, the name, the
   helper with its signature and home, the narrowed visibility — not a
   direction.

## What the score does not measure

None of these is a scoring input. Scoring one is a defect in the run,
and `--explain` will show it as a protocol-satisfying candidate dropped
at `rubric-score`:

- how important the finding is, or how much it matters to functionality
- how often the code path runs
- whether a senior engineer would bother mentioning it
- how the candidate ranks against the rest of the change
- how long the change is, or how many other findings there are

Those questions are answered before a candidate reaches the gate and
after it leaves. The lens protocol decides what is callable — a
candidate that satisfied it is, by construction, what a senior engineer
calls out in a style review. The severity band decides how much a
finding misleads (P1) or merely costs (P2). The reporting policy — the
P2 floor, consolidation, at most 8 most-severe-first — decides volume.
The gate re-deciding any of them is what empties the report.

## Bands

- **0** — the existing gates: an exclusion-list match, a pre-existing
  issue on lines the change did not modify, or the lens protocol unmet
  (`no-baseline`, `no-search`, `no-quote`).
- **1–49** — the protocol is met on paper and the evidence does not
  survive re-examination: the cited examples do not show the pattern
  claimed, the quote is a paraphrase, the search missed a dynamic-access
  path, the "comparable" units are not comparable, the failure scenario
  would not happen.
- **50–79** — verified, but thin or arguable: the baseline sits at the
  minimum and the repo also demonstrates the change's way in the same
  language; the comparable units are too few to call an outlier; the
  fix is a direction rather than a rewrite.
- **80–89** — protocol satisfied, holds against the code, baseline
  unambiguous, fix concrete. This is the ordinary shipping score for a
  verified style finding.
- **90–100** — 80–89 plus evidence the reader checks without judgment: a
  written convention or lint rule quoted with its `file:line`, an
  existing helper the change reimplements cited by `file:line`, the
  tell or the can't-fail assertion quoted verbatim, the lockstep
  assignment quoted at every write site, the contradicted doc sentence
  quoted. Deterministic detector findings are 100 by definition.

The gate: findings scoring **below 80 are dropped silently.** Every
shipping score falls in the feedback payload's `80s`, `90s`, or `100`
bucket.

## The exclusion list in this lane

Two entries in `false-positives.md` are shaped like importance
judgments: "pedantic nitpicks that a senior engineer wouldn't call out",
and "general code quality issues (…poor documentation) unless explicitly
required in CLAUDE.md". Read as written they would re-import the axis
this rubric removes. In the style lane each matches a candidate **only
when it fails its lens's evidence protocol** — a protocol-satisfying
candidate is scored on its evidence, never scored down under either. The
list itself is unchanged; the review and audit surfaces keep their
reading, as they keep their rubric.
