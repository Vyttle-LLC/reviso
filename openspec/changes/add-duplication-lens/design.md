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

### D1 — One bar, from the labels: ≥3 occurrences or a verbatim block

Ship when the diff contains ≥3 occurrences (including pre-existing
copies, counting the new ones — the termic case is 5 new + 1 closure;
watchos was 2 existing + 1 new) of the same rule-encoding expression, or
a verbatim/near-verbatim block of ~8+ lines duplicated at least once.
Two-instance dups and sub-block snippets go to the notes tier. The bar is
stated verbatim in both surfaces so drift can't loosen it. Alternative —
model judgment per case — rejected: that's how the lane becomes nitpicks.

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

### D4 — Deterministic assist is a hint channel, not a finding source

A detector-style pass (POSIX + rg) that emits candidate duplicate runs
(normalized-whitespace line runs appearing ≥3× in the diff, or added runs
matching existing repo content) into the finder's context. It never
reports directly: the fact "duplicated" is mechanical, but the finding
("extract a helper") is judgment, and the detectors spec requires
FP-free-by-construction for direct findings. Gated: ship only if the
assist demonstrably changes finder recall on the three calibration cases;
otherwise the imperative search protocol (D3) carries the load alone.

### D5 — Release mechanics: this change is 0.3.0

First plugin-surface change since 0.2.0. plugin.json → 0.3.0 and the
CHANGELOG Unreleased section rolls into the 0.3.0 heading in the same PR
— the version-keyed plugin cache means the bump is what delivers both
this lens and nothing-else-pending to installed copies.

## Risks / Trade-offs

- [Duplication lane turns nitpicky and erodes trust] → the bar (D1), the
  helper-naming requirement (D2), P2 severity cap, the existing ≥80
  verify gate, and notes-tier overflow all push the same direction;
  calibration cases include below-bar negatives (sagechat-15) that must
  stay silent.
- [Search protocol slows the single-pass review] → distinctive-identifier
  greps are cheap (rg); bounded per added block; acceptable against the
  <3-min budget — measure on the calibration cases.
- [Assist emits noise the finder over-trusts] → assist is gated (D4) and
  its hints carry no severity; the finder must still construct the
  finding from the code.

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
