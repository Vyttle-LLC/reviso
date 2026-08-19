# Design — expand-slop-detection

## Context

`/reviso:style` (0.6.0) runs five judgment lenses plus two deterministic
detectors. The uncovered slop taxonomy (over-engineering, dead weight, AI
tells, test slop) and a too-permissive comment standard were ruled in
scope on 2026-08-19; `/reviso:review`, the audit finder, and any lane
restructure were ruled out. The comments philosophy is Michael's: code
reads like prose; a comment exists only when the code can't say it, and
then as small as possible.

Constraints that shape everything here:

- **Precision over recall** (repo invariant). Every new lens must carry
  an evidence protocol strong enough to survive the ≥80 confidence gate.
- The shared harness files (`finding-schema.md`, `confidence-rubric.md`,
  `false-positives.md`) are read by the other lanes; changing them changes
  three products. This change touches none of them.
- Detectors ship only FP-free by construction (D5 in DISCOVERY.md).

## Goals / Non-Goals

**Goals:**

- Ten style lenses with spec'd evidence bars; comments held to an
  absolute earn-its-place standard.
- A detector-discovery round over the new categories.
- A measurement loop: style tier in gold mode + synthetic cases per new
  category (one TP, one clean look-alike).

**Non-Goals:**

- No changes to `/reviso:review`, `agents/reviso-finder-slop.md`, or any
  shared harness reference file.
- No lane restructure (review→/code-review parity, audit composition) —
  future change.
- No new finding-schema dimensions: new lenses map to `slop` on the wire,
  as drift/length already do; the ledger carries the precise lens name.

## Decisions

### D1 — New categories are first-class lenses, not bullets inside slop

Each gets its own coverage-ledger row. The ledger's whole point is
distinguishing "found nothing" from "never looked"; folding four new
categories into the slop lens would make one row vouch for five different
searches. Cost: a longer ledger (11 rows) — acceptable, it's one line
each.

Lens set: anti-slop (verbosity + reimplementation), comments,
duplication, conventions, drift, length, over-engineering, dead weight,
test slop, AI tells.

### D2 — The comments bar is absolute, enforced locally in style.md

The bar: a comment earns its place only when code can't say it (naming,
extraction, types), and then minimal. Override: **written** conventions
only (CLAUDE.md/AGENTS.md rule, lint rule like require-jsdoc governing
the changed paths) — demonstrated repo verbosity does not count, exactly
mirroring the test-duplication DAMP ruling's written-rule gate.

Enforcement lives in style.md's Step 4 command-local gate (precedent: the
existing "this command's own gate" baseline check), NOT in the shared
`false-positives.md` "deliberate style is never slop" entry. Amending the
shared list would silently change /reviso:review and the audit — out of
scope. The style.md Step 4 text must explicitly say the deliberate-style
exclusion does not apply to comments-lens candidates, or the exclusion
list read in the same step would kill every comments finding at 0–25.

Alternative rejected: fully absolute (no override) — collides with
conventions-lens compliance when a repo's written rules demand doc
comments; the two lenses would fight.

### D3 — Dead weight scope: beyond-linter, with a mandatory recorded search

In: helpers/exports with no caller repo-wide, params accepted but never
read, flags/config keys never consumed, branches made impossible by
surrounding code. Out (always): unused imports/locals — the exclusion
list's linter-territory rule stands, and the lens reads lint configs to
know what else is already covered. Evidence protocol: the finding states
the identifiers grepped and the empty result; no recorded search → score
0 at self-verify. This is the same no-citation-no-finding shape drift and
duplication already use, so verification stays mechanical.

FP trap acknowledged: dynamic access (reflection, string-keyed dispatch,
DI containers) defeats grep. Mitigation: the lens prompt requires a
distinctive-identifier search (not whole lines) AND a check for dynamic
access patterns near the definition; uncertainty scores below the gate.

### D4 — Only two absolute items: placeholder text and the comments bar

Over-engineering is convention-relative; AI tells mostly are.

Over-engineering must cite absence (the single consumer, the type that
makes the defended state impossible) by file:line, and yields to a
demonstrated repo norm (two examples — same bar as drift). AI tells
(temporal naming, changelog comments, emoji, tone) yield to two existing
repo examples; placeholder text ("in a real implementation…") never does
— there is no repo whose norm is unimplemented code presented as
implemented. Keeping the absolute set to exactly two items keeps the
cardinal rule intact as a rule with named exceptions rather than a
suggestion.

### D5 — Detector discovery: evaluate, don't pre-commit

Candidates to run through the DISCOVERY.md process (sweep Vyttle repo
history, ship only FP-free):

| Candidate | Prior expectation |
| --- | --- |
| `placeholder` — committed placeholder phrases ("in a real implementation", "in production you would", "this is a simplified") in added non-markdown lines | Likely ships with a curated phrase list; suppress markdown and string literals in test fixtures if the sweep hits any |
| Changelog-style comments | Likely rejected → AI-tells lens (judgment: "fixed bug where" can be a legitimate historical note) |
| Temporal naming (`new*`, `*2`, `enhanced*`) | Likely rejected → AI-tells lens (`newUser` is often just a new user) |
| Emoji in code files | Likely rejected → AI-tells lens (legitimate in user-facing strings, CLIs) |

The tasks gate shipping on the sweep result, not on this table; whatever
the outcome, both DISCOVERY.md tables are updated.

### D6 — Eval: style tier + synthetic pairs, labels categorized `slop`

`review-tier.sh` gains `style` (`REVISO_TIER=style` →
`/reviso:style`); its callers already inherit the resolved command.
Synthetic cases follow the existing `synthetic: true` + `fixture`
machinery (gold-only, parity refuses them). Per new category: one
true-positive fixture and one clean look-alike (expected-clean or
labeled-clean for that category) to guard precision — e.g. a defended
impossible state vs a genuinely reachable one; a mock-asserting test vs a
real one; a bloated comment vs an earned constraint comment.

Labels use category `slop`, which is **not** in `tiers.sh`'s cleanup
family, so misses count against `gold_recall_correctness` — the
measurement Michael asked for. `tiers.sh` is untouched. Note: style-tier
runs of *existing* bug-labeled cases would score zero recall by design
(style hunts no bugs); the corpus README gets a line saying style-tier
gold runs are meaningful only against style-labeled or expected-clean
cases.

## Risks / Trade-offs

- [Absolute comments bar generates noise in doc-comment-heavy ecosystems
  (Java, public APIs)] → the written-convention override covers
  configured lint rules; the ≥80 gate plus P2-max severity bounds the
  blast radius; synthetic clean look-alike guards the bar in eval; field
  FPs route through the existing feedback loop and can tighten the lens
  prompt.
- [Dead-weight FPs from dynamic access] → mandatory recorded search +
  dynamic-access check (D3); clean look-alike fixture exercises exactly
  this trap.
- [Ten lenses in one pass dilute attention → shallow application of
  each] → the ledger's no-result outcome exists for honest reporting;
  if field use shows consistent no-results, that's the signal to revisit
  (not pre-solved here).
- [Report cap (8 findings) fills with P2 slop on very sloppy diffs] →
  by design: most-severe-first ordering and consolidation already handle
  it; a sloppier diff earning a fuller report is correct.
- [Placeholder detector FPs on legitimate strings] → discovery sweep is
  the gate; any post-ship FP demotes the detector per the existing D5
  rule.

## Migration Plan

Pure additive prompt/spec/harness work; no data migration. Single PR
(one concern: the slop expansion), version bump per CHANGELOG
convention. Rollback = revert.

## Open Questions

- OQ1: exact placeholder phrase list for the detector — settled by the
  discovery sweep, recorded in DISCOVERY.md.
- OQ2: whether `conventions`-category labels should count as in-lane for
  style-tier gold runs (they're cleanup-family today). Dodged here by
  labeling all new fixtures `slop`; revisit only if a conventions-labeled
  style case ever matters.
