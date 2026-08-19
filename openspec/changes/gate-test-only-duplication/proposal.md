# Gate test-only duplication on a written convention

## Why

The style verb's first field run (2026-08-19, a Sage Haven branch) shipped
a duplication finding whose seven occurrences were all in one test file —
technically evidenced (the PR had edited six copies in lockstep), but
DRY-applied-to-tests. DAMP is a legitimate, widespread school: repetition
in tests is often deliberate, keeping each test readable in isolation.
Where a style is legitimately contested, a finding is taste, and the
maintainer judged it a false positive — the metric Reviso cares most
about. The detector-discovery sweep hit the same wall earlier: a
duplication-hint prototype was rejected because its nine hits were all
test scaffolding.

A blanket test exemption overcorrects: the termic-162 verification run
shipped a test-code duplication that was right to ship, because that
repo's own skill doc says "use the shared helpers in e2e/helpers.ts."

## What Changes

- Duplication whose occurrences are **all in test code** no longer ships
  by default. It ships only when a **written** repo convention
  (CLAUDE.md / AGENTS.md / lint config / skill doc governing the changed
  paths) demands shared test helpers or deduplicated test logic. A
  demonstrated-but-unwritten helper idiom does not open the gate —
  written rules only, so the outcome is predictable.
- Mixed findings are untouched: if any occurrence is production code, the
  existing bar applies unchanged.
- Encoded once at the gate: a new entry in the shared false-positive
  exclusion list, which review, style, and the audit orchestrator all
  score against. The audit's slop finder still returns test-only
  candidates (finders don't gate; 0.5.0).
- The "Test code counts" lines in `commands/review.md` and
  `commands/style.md` are rewritten to the gated rule so the prompts
  don't contradict the exclusion list.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `review-pipeline`: the calibrated duplication bar gains the test-only
  written-convention gate.

## Impact

- `skills/reviso/references/false-positives.md` — new exclusion entry.
- `commands/review.md`, `commands/style.md` — duplication item's test-code
  clause.
- `agents/reviso-finder-slop.md` — unchanged (finders report everything).
- `CHANGELOG.md` — bullet under the unreleased 0.6.0 entry.
- Stacked on `feature/style-cop` (PR #29); restack with `--onto` after it
  merges.
