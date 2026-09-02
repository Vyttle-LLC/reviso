# Design — move-best-practices-to-style

## Context

0.11.0 shipped the lens as an audit finder; 0.11.0's design (archived
change `add-the-best-practices-lens`) settled the contract questions —
opt-in only, closed query vocabulary, fetch-verified sources, offline
version gate. Michael ruled the lens belongs in the style lane. Style is
single-pass with its own evidence-quality rubric and named drop reasons.

## Goals / Non-Goals

**Goals:** same contract, new home; audit fully reverted; the style
lane's structure (ledger, families, rubric, drop reasons) absorbs the
lens without special cases beyond the two named exceptions.

**Non-Goals:** changing the lens's classes, bounds, or contract;
`/reviso:review`; keeping the lens in both verbs.

## Decisions

- **D1 — Inline, not an agent.** Style has no subagents; the lens runs
  in the main pass after ecosystem discovery. The agent file is deleted,
  its content folded into style.md's lens list. The web tools stay out
  of `allowed-tools`; the permission prompt remains the gate.
- **D2 — Third cardinal-rule exception.** The lens is ecosystem-relative
  by definition. Stated in the cardinal-rule paragraph, like the
  comments bar and placeholder text.
- **D3 — Severity exception.** The lens keeps the 0.11.0 class band
  (removed API P1; misuse by documented consequence; advisory P1/P0;
  superseded idiom P2) under the same precedent as deterministic
  detectors keeping theirs. Rationale: a critical advisory is not
  "purely stylistic"; capping it at P1 to fit the style band would
  misstate it.
- **D4 — Gate: `no-source` joins style's protocol reasons.** A candidate
  without a fetched URL + quoted passage drops as `no-source` (step 3,
  beside `no-baseline` / `no-search` / `no-quote`); version
  inapplicability and a consequence-less idiom are the exclusion-list
  entries false-positives.md already carries. Scored on the style
  rubric (evidence quality), which fits: source fetched, quote exact,
  version applies.
- **D5 — Ledger family `ecosystem`.** One row, its own family, always
  named as itself (like deterministic) — a one-lens family hides
  nothing.
- **D6 — Audit reverts wholesale.** Six finders, no `--web` (unknown
  flag note points at style), no Source line, no Web block, ledger back
  to six-or-seven → six rows plus deterministic.

## Risks / Trade-offs

- [0.11.0 users lose `/reviso:audit --web`] → changelog states the move;
  the unknown-flag note names the replacement.
- [Single-pass context grows with web content] → the ≤2-sentence quote
  rule bounds what enters the transcript; the 12/2 bounds hold.
- [P0 from a style verb surprises] → only via a critical advisory with
  external-input exposure; the finding carries the advisory URL.

## Migration Plan

0.13.0. Rerun the `bp-*` gold pair at `REVISO_TIER=style` with `--web`
(and the TP once without, for the Not-checked line). Archive rides this
branch's PR.
