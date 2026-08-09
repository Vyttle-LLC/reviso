# Design — add-duplication-lens

## Context

The slop finder's closed P0 set looks only at change-vs-repo; intra-diff
duplication has no owner, and the change-vs-repo item under-fires (#9).
Three labeled cases calibrate the lane (see proposal). Reviso's P0
invariant — precision over recall, an uncertain finding doesn't ship —
must survive the addition: duplication is the classic nitpick lane, and a
noisy version of this lens would be worse than none.

## Goals / Non-Goals

**Goals:**

- Own both duplication directions (new-vs-existing, new-vs-new) in one
  slop item with one bar.
- Every shipped finding names its helper (name, signature, location) and
  its drift-risk scenario; occurrences are cited individually.
- Keep the two surfaces (single-pass lens, finder agent) word-for-word
  aligned on the item's definition.

**Non-Goals:**

- No structural/AST clone detection, no similarity scoring — verbatim or
  near-verbatim (rename-only) evidence, citable by `file:line`, or it
  doesn't ship.
- No new severity tier: duplication stays P2 (P1 only when copies have
  already drifted — that's an active bug vector, not future risk).
- No relaxation for test code (watchos-202 and termic-162 exemplars are
  both partly in tests; the labels say test duplication counts).

## Decisions

### D1 — One bar, from the labels: ≥3 occurrences, hardened at exactly 3

Count occurrences of the same unit of logic — a rule-encoding expression
or predicate, a declaration or definition, or a verbatim/near-verbatim
block — including pre-existing copies alongside the new ones (the termic
case is 5 new + 1 closure; watchos was 2 existing + 1 new). Then:

- **≥4** ships; repetition at that count is itself the evidence.
- **exactly 3** ships only if the unit encodes a rule that can change — a
  predicate, a policy constant, a shared type or contract. Incidental
  three-way similarity (setup boilerplate, assertion scaffolding) is
  silent.
- **≤2** is silent, however long the copied block.

The bar is stated verbatim in both surfaces so drift can't loosen it.
Alternative — model judgment per case — rejected: that's how the lane
becomes nitpicks.

**The three-occurrence tier is deliberately the marginal one** (owner's
calibration, 2026-08-08: "2 items duplicated are a nit/warning, three is
pushing it, 4 is a full blown issue"). Moving the ship bar to ≥4 outright
was rejected because the labels contradict it at exactly one point, and
it is the point that matters: watchos-202's three-occurrence type-alias
copy is labeled `real` and "adjudicated apply-now", and it is Pattern 1
of issue #9 — the report that motivated this lens. A ≥4 bar would
re-silence the case the change exists to fix. Encoding "pushing it" as a
stricter *substance* test at 3, rather than as a higher number, keeps
that case shipping while holding out the incidental look-alikes — which
is exactly what the rejected D4 assist proved is the noise at that count
(nine three-plus-occurrence hints, every one setup or assertion
scaffolding).

**Corrected during calibration (task 2.1).** This decision previously
carried a second arm — "or a verbatim block of ~8+ lines duplicated at
least once" — which let two-instance block copies ship. The labels reject
that: `termic-162-labels.json`'s `bar_evidence` reads "ship at **>=3
occurrences** of a rule-encoding expression **or a substantial verbatim
block**", so ≥3 governs both arms, and the second arm was a
mis-transcription. Every labeled two-instance duplication is
out-of-lane or not-real, including two substantial block copies the old
wording would have shipped as false positives: a ~16-line view skeleton
in watchos-202 (duplication the reviewer deferred on purpose, because
both screens were still diverging) and a line-for-line test-helper copy
in sagechat-15. Length is not a second route past the bar; occurrence
count is the whole bar. The `declaration or definition` unit is likewise
label-driven — watchos-202's shipping case is a third word-for-word copy
of a type alias and its default, which is neither an expression nor a
long block.

**Below-bar routing is silence, not a notes tier** (revised during apply).
The original plan sent below-bar duplication to "the report's notes tier",
but no such tier exists in either report format and nothing here adds one.
Building one was rejected on two grounds: a notes section is exactly where
nitpicks accumulate, which is what this bar exists to prevent; and the
eval harness would miscount it — `eval/runners/extract.sh`'s model
fallback is instructed to "extract every distinct finding", so notes would
be scraped as findings and charged against gold mode's
`precision_proxy_pct` and `clean_case_fp_count`. Below the bar, the lens
says nothing.

### D2 — The fix names the helper, or it's not a finding

`suggested_fix` must contain: helper name, signature, proposed home
(following the repo's existing layout — e.g. "on the task list" per the
termic feedback), and the call-site rewrite for one occurrence. The
failure scenario is the drift risk, stated concretely ("the collision
rule lives in 6 places; change it in one and the others disagree").
Mirrors the existing cite-it-or-it's-not-a-finding discipline of slop
item 3.

### D3 — Search protocol for new-vs-existing, stated imperatively

Before clearing any added block, the finder greps the repo for that
block's most distinctive identifiers/string literals (not whole-line
matches — renames dodge those). This is the #9 fix: the miss wasn't
policy, it was that nothing forced the lookup.

### D4 — Deterministic assist: evaluated, dropped

The proposed assist was a detector-style pass (POSIX + rg) emitting
candidate duplicate runs — normalized-whitespace line runs appearing ≥3×
in the diff, or added runs matching existing repo content — into the
finder's context as hints, never as findings. It was gated: ship only if
it demonstrably improves finder recall on the calibration cases.

**It fails the gate, measurably.** Prototyped and run against the
termic-162 diff (15 files, 886 insertions) — the very case the lens was
built for — the assist:

- **missed the target entirely.** The duplicated predicate occurs seven
  times in added lines, but only two occurrences are byte-identical; the
  rest vary by receiver, by argument, and by which field supplies the
  project id, and three are wrapped mid-expression across lines. Exact
  normalized-line frequency therefore tops out at 2 for the closest pair
  — under its own ≥3 threshold.
- **emitted only noise.** Nine hints at a 20-character floor, five at 40,
  every one of them test scaffolding (stub construction, assertion
  boilerplate). Zero true positives, and the noise is precisely the
  "a linter would catch it / pedantic" material the exclusion list bars.

The lesson generalizes past this case: duplication worth extracting is
similar *under renaming*, which is a token-level property, not a
line-level one. Line matching sees the least interesting instances. The
D3 protocol targets the same signal from the other end — grepping one
distinctive identifier finds all seven occurrences at once — so D3
carries the load alone, as D4's own fallback anticipated. Recorded in
`skills/reviso/detectors/DISCOVERY.md` alongside the other rejects.

A token-frequency assist (normalized identifier n-grams rather than whole
lines) is the version that could clear the gate. Out of scope here; noted
for whoever revisits the recall side.

### D5 — Release mechanics: this change is 0.3.0

First plugin-surface change since 0.2.0. plugin.json → 0.3.0 and the
CHANGELOG Unreleased section rolls into the 0.3.0 heading in the same PR
— the version-keyed plugin cache means the bump is what delivers both
this lens and nothing-else-pending to installed copies.

## Calibration results (task 2.1)

Text-level calibration, 2026-08-08: every duplication-labeled item in the
three private calibration cases, classified by the bar as written above.
Counts and shapes only — no case content lands here, per the corpus
tiering rule.

| case | labeled item (shape) | occurrences | label | lens | ✓ |
| --- | --- | --- | --- | --- | --- |
| termic-162 | collision predicate at 5 call sites + a closure, all new | 6 | real (P2) | ships | ✓ |
| watchos-202 | type alias + its default, third word-for-word copy | 3 (2 prior + 1 new) | real | ships | ✓ |
| watchos-202 | ~16-line view skeleton, deliberately deferred | 2 | out-of-lane | silent | ✓ |
| sagechat-15 | capability policy spelled two ways | 2 | out-of-lane | silent | ✓ |
| sagechat-15 | key derived independently in two places | 2 | not-real | silent | ✓ |
| sagechat-15 | line-for-line test-helper copy | 2 | out-of-lane | silent | ✓ |
| sagechat-15 | constant hardcoded twice | 2 | out-of-lane | silent | ✓ |

7/7 agree. termic-167's lone nitpick is a robustness finding, not
duplication — this lens does not reach it, which is the correct outcome
there too.

The hardened three-occurrence tier changes none of these rows. Only the
watchos-202 type-alias copy sits at exactly 3, and it clears the
substance test comfortably: a transport type and its default is a shared
contract, so a future change to it has to land in all three copies at
once. Everything else is either ≥4 (ships on count alone) or ≤2 (silent
regardless). The tier's teeth show against the D4 prototype's hints
instead — nine runs at three-or-more occurrences, every one setup or
assertion scaffolding, all of which the substance test rejects.

**What this does and does not establish.** It establishes that the bar,
as written, sorts every labeled case the way the labels do — the
precision side, which is the side the invariant cares about. It does not
establish recall: whether a finder actually *locates* the six predicate
copies in a live run is untested until a gold sweep, and the watchos
labels record that the pre-lens slop finder had zero visibility of
exactly this material. Recall stays open, and it is what the D4 assist
(task 2.2) exists to move.

## Risks / Trade-offs

- [Duplication lane turns nitpicky and erodes trust] → the bar (D1), the
  helper-naming requirement (D2), P2 severity cap, the existing ≥80
  verify gate, and below-bar silence all push the same direction;
  calibration cases include below-bar negatives (sagechat-15) that must
  stay silent.
- [Search protocol slows the single-pass review] → distinctive-identifier
  greps are cheap (rg); bounded per added block; acceptable against the
  <3-min budget — measure on the calibration cases.
- [Assist emits noise the finder over-trusts] → resolved by dropping the
  assist outright (D4).
- [Published gold precision drops for a measurement reason, not a quality
  one] → the public corpus carried no duplication labels at all (103
  correctness, 23 security, 13 robustness, 6 efficiency across 63 cases),
  so every duplication finding on a gold case was unmatched by
  construction. Mitigated by adding `termic-162` with a hand-authored
  duplication label, which gives the lane one matchable case. It is one
  case: duplication findings on the other 63 are still unmatchable, so
  read the next sweep's duplication findings as label-promotion candidates
  before reading them as regressions, and say so in `docs/evals.md` when
  the numbers move.

## Migration Plan

1. Land lens text in both surfaces + agent, with the bar and protocol.
2. Verify on the three calibration cases: termic-162 ships, watchos-202
   Transport ships, sagechat-15 dups stay notes/silent.
3. Evaluate the assist (D4) against the same cases; ship or drop.
4. Bump 0.3.0, roll CHANGELOG, merge; marketplace update delivers it.

Rollback: revert the PR; 0.3.x patch release if a noisy lens escapes.

## Open Questions

- Whether `/reviso:audit`'s finder needs a different (lower) bar than the
  inner-loop review — audit is the pre-PR deep pass where cleanup breadth
  is welcome. Leaning: same bar, audit adds breadth elsewhere.
