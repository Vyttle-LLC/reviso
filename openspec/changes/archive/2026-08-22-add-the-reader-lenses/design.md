# Design — add-the-reader-lenses

## Context

0.7.0 settled the pattern for adding a lens: first-class bullet in Step
3, an evidence protocol the Step 4 gate can check mechanically, a ledger
row, and a synthetic TP/clean pair. This change reuses that pattern
three times and adds nothing structural. The style spec's cardinal rule
(repo norms over taste, two named absolute exceptions) is unchanged —
all three lenses are convention-relative.

## Goals / Non-Goals

**Goals:**

- Give derived state, naming, and error handling each a ledger row so a
  clean report can say they were applied.
- Keep the FP posture: every new finding needs quotable evidence of the
  repo's own norm, or it does not exist.
- Close issue #9.

**Non-Goals:**

- Touching `/reviso:review` or the audit finder (see
  `port-style-lenses-to-the-audit-finder`).
- New detectors. Empty-catch and generic-name regexes were considered
  and are not FP-free by construction; they stay lens territory.
- Grouping lenses into families in the report. Revisit when
  `add-the-surface-lenses` pushes the count past sixteen.

## Decisions

### D1 — Three first-class lenses, not three bullets under drift

Drift already names "naming, error-handling shape" as examples, and
that is exactly why they go unapplied: a sub-bullet has no ledger row,
no count, and no `--explain` line. 0.7.0's D1 made the same call for
the same reason. Alternative rejected: expanding drift's text.

### D2 — Derived state is evidenced by write-site lockstep

A derived-state finding cites every write of the copy and shows each is
a projection of the source written in the same place (the lockstep),
plus every read site. With one read site the fix is inline-the-
projection; with several it is a computed property/getter following
the repo's idiom. No lockstep citation → score 0 (`no-baseline`). This
keeps it textual and quotable, like duplication, and away from
"these fields feel related".

### D3 — Naming and error handling borrow drift's two-example bar

Both lenses flag divergence from how the repo names or handles the same
kind of thing. Two existing same-language examples by `file:line` are
the minimum, the same bar drift uses, so the gate needs no new rule —
only the `no-baseline` reason extends to these lenses. Generic names
(`data`, `result`, `Manager`) are not absolute findings; a repo full of
`FooManager` keeps naming them that way.

### D4 — Same-language comparables

The two-example bar is silent on language, and in polyglot repos a norm
demonstrated in one language was being cited against another. The
clause is added to the baseline-citation requirement for all
convention-relative lenses, not just the new three — it is a
clarification of what "the repo does it this way" always meant.

### D5 — Severity stays in the style band

P2 default. P1 only for the actively-misleading cases: a name that
asserts behavior the code does not have, a catch that silently swallows
an error the repo elsewhere surfaces, derived copies that have already
diverged (which is a bug and belongs to review — then it ships nowhere
here, per the no-bug-hunting rule).

### D6 — One multi-lens synthetic case

The per-lens pairs test recall and precision for one lens at a time.
Nothing in the corpus exercises dedupe, the 8-finding cap, or
most-severe-first ordering under real load. One fixture with ≥10
plantable findings across ≥4 lenses, labeled with the expected
consolidated set, fills that gap.

### D7 — Synthetic fixtures gain `context` files

The naming and error-handling pairs need an existing same-language
baseline: the TP has to diverge from *something*, and the clean case has
to match it. The harness materialized every fixture file as an
uncommitted addition on an empty base, so no baseline existed. Fixture
files now carry `status: "context"` (committed into the base first) or
`status: "added"` (the change under review); `gold.sh` branches on it.
The gold-eval spec already reads "base content committed, diff applied",
so this is the harness catching up to its spec, not a spec change.
Existing fixtures are all-`added` and unaffected.

## Risks / Trade-offs

- [Naming is the most taste-prone lens in the set] → two same-language
  examples required; no absolute generic-name list; field smoke test on
  a real branch before release, with the FP reported via the existing
  feedback path if it fires wrongly.
- [Error-handling overlaps the bugs lane (swallowed error that masks a
  failure)] → style reports the shape divergence only; a swallow that
  hides a real failure is a bug and is left to `/reviso:review`. The
  no-bug-hunting paragraph already covers this.
- [Thirteen lenses in one pass lengthens the run] → measured in the
  field smoke test; if the pass degrades, the lens-family grouping
  deferred in Non-Goals moves up.

## Migration Plan

Additive. Ship as 0.8.0; no flag, no rollback path beyond reverting.

## Open Questions

None blocking. Whether derived state belongs in the audit finder too is
`port-style-lenses-to-the-audit-finder`'s question.
