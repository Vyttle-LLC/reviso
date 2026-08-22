# Add the reader lenses

## Why

Three slop families that `/reviso:style` does not see are the ones a human
reader trips over first, and the ones AI-authored diffs over-produce: a
stored field that is always a projection of another (issue #9's second
pattern, still open after 0.7.0), names that hedge or lie, and error
handling that swallows, rewraps without context, or guards code that
cannot throw. Drift mentions naming and error shape in passing, but a
lens with no ledger row is a lens nobody can say was applied.

## What Changes

- `/reviso:style` grows from ten lenses to thirteen: **derived state**,
  **naming**, and **error handling** join as first-class lenses with
  their own ledger rows, `--explain` counts, and feedback mapping.
- Each new lens is convention-relative and carries an evidence protocol
  in the same shape as drift: derived state cites every write site that
  keeps the copy in lockstep plus its read sites; naming and error
  handling cite two existing same-language examples of how the repo
  names or handles the same kind of thing.
- The baseline-citation requirement gains a language clause: the
  comparables a drift-style finding cites MUST be in the same language
  as the changed code. A Swift idiom does not set the norm for a TS file
  in the same repo.
- Synthetic gold cases land per lens (true positive + clean look-alike),
  plus one multi-lens case that exercises the 8-finding cap and dedupe,
  which the per-lens pairs never reach.
- Issue #9 closes on merge: pattern 1 shipped under the exactly-3
  duplication rule; pattern 2 is the derived-state lens.

Out of scope: `/reviso:review`, the audit's `reviso-finder-slop`, the
shared exclusion list and rubric, and the deterministic suite — no
candidate in these families is FP-free by construction.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `style-command`: the lens set expands from ten to thirteen; the
  baseline-citation requirement gains the three new evidence protocols
  and the same-language clause.

## Impact

- `commands/style.md` — three lens bullets, ledger 10→13, Step 4 gate
  for the new evidence protocols, `--explain` example, feedback mapping.
- `eval/corpus/synthetic/`, `labels/`, `public.jsonl`, `README.md` — 7
  new cases.
- `openspec/specs/style-command/spec.md` via the delta.
- `CHANGELOG.md` 0.8.0, `.claude-plugin/plugin.json` bump.
- GitHub issue #9 closed.
