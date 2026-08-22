# Design — add-the-surface-lenses

## Context

Depends on `add-the-reader-lenses` (0.8.0) having merged and its gold
run holding precision. Same lens-addition pattern as 0.7.0 and 0.8.0,
with two wrinkles: stale docs must read lines the change did not touch,
and sixteen ledger rows need grouping.

## Goals / Non-Goals

**Goals:**

- Catch the P1 "misleads the next reader" cases that no lens claims:
  false prose and loosened types.
- Keep the coverage block readable at sixteen lenses.

**Non-Goals:**

- Doc *coverage* (missing docs) — exclusion list: general quality.
- Security or performance lenses — bug/linter lane.
- Porting to the audit finder.

## Decisions

### D1 — Stale docs is a carve-out from "pre-existing lines score 0"

The finding anchors on the *changed* line that falsified the prose; the
unchanged sentence is evidence, quoted verbatim. Step 4's pre-existing
gate (step 2) reads: anchored on a changed line → not pre-existing. No
change to the shared exclusion list; the carve-out is style-local, like
the comments bar. Alternative rejected: anchoring on the doc line,
which the shared gate would zero.

### D2 — Surface area reuses dead weight's search protocol

Dead weight asks "does anyone use this?"; surface area asks "does anyone
*outside this module* use this?". Same grep-and-check-dynamic-access
protocol, same `no-search` drop reason, different question. Kept as a
separate lens so each has a ledger row and so dead weight's "unused"
finding is never softened into "over-exposed".

### D3 — Type slop is convention-relative

`any` is not absolutely wrong; a repo that is `any`-heavy keeps it. Two
same-language examples of the precise form the repo uses for this kind
of value are required. Force-unwrap/cast in Swift/Kotlin and `as` in
TS are in scope; lint-covered cases (`no-explicit-any` configured) are
out, by the dead-weight precedent of reading lint configs first.

### D4 — Four lens families in the coverage block

shape (drift, length, over-engineering, surface area), text (comments,
AI tells, naming, stale docs), reuse (slop, duplication, dead weight,
derived state), tests (test slop), plus deterministic. The ledger is
unchanged — one row per lens — only the default report's `Checked:` /
`Not checked:` lines render by family, naming an individual lens only
when its outcome differs from its family's. `--explain` stays per-lens.
Severity and the 8-finding cap are untouched.

## Risks / Trade-offs

- [Stale docs reads beyond the diff; pass length grows] → scope is
  prose that *names* a changed symbol or behavior, found by grepping
  the changed identifiers across doc paths, not by reading docs whole.
- [Family rendering hides a single `no result` lens] → a lens whose
  outcome differs from its family is always named individually.
- [Type slop fires on deliberate escape hatches] → a written lint
  suppression or an inline disable comment is the exclusion list's
  "explicitly silenced" case and clears it.

## Migration Plan

Additive. 0.9.0. The family rendering changes the default report's
coverage block shape; `docs/` and the README example report update
with it.

## Open Questions

- Whether changelog-style docs (CHANGELOG.md) belong in stale docs at
  all, or whether "the changelog wasn't updated" is process, not style.
  Default: in scope only when an existing entry is *contradicted*, never
  for a missing entry.
