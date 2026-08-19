# Expand slop detection

## Why

`/reviso:style` covers the P0 slop set (verbosity, reimplementation,
comment restating, duplication, drift) but misses the rest of the
well-known AI-slop taxonomy — over-engineering, dead weight, AI tells in
naming and text, test slop — and its comment lens is too permissive: it
only flags comments that restate code, when the standard we actually hold
is that a comment must earn its place at all. The style lane is the
dedicated home for this; nailing it here is cheaper and safer than
spreading it across three surfaces.

## What Changes

- `/reviso:style` grows from five lenses to ten (plus the deterministic
  row): **over-engineering/YAGNI**, **dead weight**, **AI tells**, and
  **test slop** join, and **comments** is promoted out of the slop lens
  into its own lens.
- The comments lens moves from convention-relative to an **absolute bar**:
  a changed comment must earn its place (the code cannot say it) and be
  minimal. Only a *written* convention (CLAUDE.md demanding doc comments,
  a `require-jsdoc`-style lint rule) overrides the bar — demonstrated
  verbosity in the repo does not. Enforced as a style-command-local gate;
  the shared false-positive exclusion list is untouched, so the other
  lanes keep their behavior.
- Dead weight is scoped **beyond-linter only**: the lens reads the repo's
  lint configs to know what is already covered, and flags only what
  linters can't — helpers/exports with no caller, params accepted but
  ignored, flags never read, branches that can't execute — each with a
  grep-protocol citation as evidence.
- A detector-discovery round runs over the new categories (candidate:
  committed placeholder text like "In a real implementation…"); only
  detectors that are FP-free by construction ship, per the existing D5
  bar. DISCOVERY.md's shipped/rejected tables are updated either way.
- The eval harness learns the style tier: `REVISO_TIER=style` resolves to
  `/reviso:style`, and gold mode can judge it like the other verbs.
- Synthetic gold corpus cases are authored per new category — one
  true-positive diff plus one clean look-alike (precision guard) — wired
  into the existing synthetic-case machinery.

Out of scope (deliberately): `/reviso:review` and the audit's
`reviso-finder-slop` keep their current P0 set; the lane restructure
Michael sketched (review at `/code-review` parity, audit as review plus
style plus architecture) is a separate future change.

## Capabilities

### New Capabilities

None — everything lands in existing capabilities.

### Modified Capabilities

- `style-command`: the lens set expands from five to ten; the comments
  lens gets the absolute earn-its-place bar with the written-convention
  override; dead weight, over-engineering, AI tells, and test slop get
  their evidence requirements spec'd.
- `gold-eval`: the review tier under test may be any Reviso verb —
  `style` joins `review` and `audit` in tier resolution and recorded-run
  metadata.

## Impact

- `commands/style.md` — new lenses, ledger rows, Step-4 gates, severity
  notes, feedback dimension mapping.
- `skills/reviso/detectors/` — discovery round; `detect.awk`/`run.sh`
  only if a candidate clears the bar; `DISCOVERY.md` tables either way.
- `eval/runners/review-tier.sh` (and any caller assuming two tiers) —
  style tier support.
- `eval/corpus/` — new synthetic fixtures + labels; README notes.
- `openspec/specs/style-command/spec.md`, `openspec/specs/gold-eval/spec.md`
  — via delta specs.
- No changes to `agents/*`, `/reviso:review`, the shared finding schema,
  the confidence rubric, or the shared false-positive exclusion list.
